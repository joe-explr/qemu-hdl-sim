/*
 * QEMU PCIe device for communication with HDL simulation.
 */

#include "qemu/osdep.h"
#include "qapi/error.h"
#include "qemu/cutils.h"
#include "hw/hw.h"
#include "hw/i386/pc.h"
#include "hw/pci/pci.h"
#include "hw/pci/msi.h"
#include "hw/pci/msix.h"
#include "system/kvm.h"
#include "migration/migration.h"
#include "qemu/error-report.h"
#include "qom/object_interfaces.h"
#include "qapi/visitor.h"
#include "net/net.h"
#include "chardev/char-fe.h"
#include "qemu/atomic.h"
#include "acc/acc.h"

#include <inttypes.h>
#include <stdarg.h>

typedef enum ACCLogLevel {
    ACC_LOG_OFF = 0,
    ACC_LOG_ERROR = 1,
    ACC_LOG_WARN = 2,
    ACC_LOG_INFO = 3,
    ACC_LOG_DEBUG = 4,
    ACC_LOG_TRACE = 5,
} ACCLogLevel;

static gsize acc_log_inited;
static int acc_log_level;
static int acc_zmq_warn_ms;
static gint64 acc_log_t0_us;
static uint64_t acc_global_txid;

static int acc_parse_loglevel(const char *s)
{
    if (!s || !*s) {
        return ACC_LOG_ERROR;
    }
    if (!g_ascii_strcasecmp(s, "off") || !g_ascii_strcasecmp(s, "0")) {
        return ACC_LOG_OFF;
    }
    if (!g_ascii_strcasecmp(s, "error") || !g_ascii_strcasecmp(s, "err") ||
        !g_ascii_strcasecmp(s, "1")) {
        return ACC_LOG_ERROR;
    }
    if (!g_ascii_strcasecmp(s, "warn") || !g_ascii_strcasecmp(s, "warning") ||
        !g_ascii_strcasecmp(s, "2")) {
        return ACC_LOG_WARN;
    }
    if (!g_ascii_strcasecmp(s, "info") || !g_ascii_strcasecmp(s, "3")) {
        return ACC_LOG_INFO;
    }
    if (!g_ascii_strcasecmp(s, "debug") || !g_ascii_strcasecmp(s, "dbg") ||
        !g_ascii_strcasecmp(s, "4")) {
        return ACC_LOG_DEBUG;
    }
    if (!g_ascii_strcasecmp(s, "trace") || !g_ascii_strcasecmp(s, "5")) {
        return ACC_LOG_TRACE;
    }
    return ACC_LOG_ERROR;
}

static void acc_log_init(void)
{
    if (g_once_init_enter(&acc_log_inited)) {
        const char *lvl = getenv("ACCELERATOR_LOG_LEVEL");
        const char *dbg = getenv("ACCELERATOR_DEBUG");
        const char *warn_ms = getenv("ACCELERATOR_ZMQ_WARN_MS");

        acc_log_t0_us = g_get_monotonic_time();
        acc_log_level = ACC_LOG_ERROR;
        acc_zmq_warn_ms = 0;

        if (lvl) {
            acc_log_level = acc_parse_loglevel(lvl);
        } else if (dbg && strcmp(dbg, "0") != 0) {
            acc_log_level = acc_parse_loglevel(dbg);
            if (acc_log_level <= ACC_LOG_ERROR) {
                acc_log_level = ACC_LOG_DEBUG;
            }
        }

        if (warn_ms && *warn_ms) {
            acc_zmq_warn_ms = atoi(warn_ms);
            if (acc_zmq_warn_ms < 0) {
                acc_zmq_warn_ms = 0;
            }
        }

        g_once_init_leave(&acc_log_inited, 1);
    }
}

static const char *acc_log_level_str(int level)
{
    switch (level) {
    case ACC_LOG_ERROR:
        return "ERROR";
    case ACC_LOG_WARN:
        return "WARN";
    case ACC_LOG_INFO:
        return "INFO";
    case ACC_LOG_DEBUG:
        return "DEBUG";
    case ACC_LOG_TRACE:
        return "TRACE";
    default:
        return "OFF";
    }
}

static void acc_logv(int level, const char *func, int line, const char *fmt,
                     va_list ap)
{
    acc_log_init();
    if (level > acc_log_level || acc_log_level == ACC_LOG_OFF) {
        return;
    }

    gint64 now_us = g_get_monotonic_time();
    gint64 delta_ms = (now_us - acc_log_t0_us) / 1000;
    fprintf(stderr, "ACCELERATOR[%s +%" PRId64 "ms] %s:%d: ",
            acc_log_level_str(level), delta_ms, func, line);
    vfprintf(stderr, fmt, ap);
    fputc('\n', stderr);
    fflush(stderr);
}

static void acc_log(int level, const char *func, int line, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    acc_logv(level, func, line, fmt, ap);
    va_end(ap);
}

#define ACC_LOG(_level, _fmt, ...)                                             \
    acc_log((_level), __func__, __LINE__, (_fmt), ##__VA_ARGS__)

/* Backwards compatible macros already used throughout this file */
#define ACCELERATOR_EPRINTF(fmt, ...) ACC_LOG(ACC_LOG_ERROR, fmt, ##__VA_ARGS__)
#define ACCELERATOR_DPRINTF(fmt, ...) ACC_LOG(ACC_LOG_DEBUG, fmt, ##__VA_ARGS__)
#define ACCELERATOR_TPRINTF(fmt, ...) ACC_LOG(ACC_LOG_TRACE, fmt, ##__VA_ARGS__)

static uint64_t acc_next_txid(void)
{
    return qatomic_fetch_add(&acc_global_txid, 1) + 1;
}

static zframe_t *acc_zframe_recv_logged(zsock_t *sock, const char *sock_name,
                                       uint64_t txid, const char *ctx)
{
    acc_log_init();

    if (acc_zmq_warn_ms <= 0) {
        ACCELERATOR_DPRINTF("txid=%" PRIu64 " waiting recv %s (%s)", txid,
                            sock_name, ctx ? ctx : "");
        zframe_t *frame = zframe_recv(sock);
        if (!frame) {
            ACCELERATOR_EPRINTF("txid=%" PRIu64 " recv failed %s (%s)", txid,
                                sock_name, ctx ? ctx : "");
            return NULL;
        }
        ACCELERATOR_TPRINTF("txid=%" PRIu64 " recv ok %s size=%zu (%s)", txid,
                            sock_name, zframe_size(frame), ctx ? ctx : "");
        return frame;
    }

    zpoller_t *poller = zpoller_new(sock, NULL);
    if (!poller) {
        ACCELERATOR_EPRINTF("txid=%" PRIu64 " poller_new failed %s (%s)", txid,
                            sock_name, ctx ? ctx : "");
        return zframe_recv(sock);
    }

    gint64 start_us = g_get_monotonic_time();
    while (1) {
        zsock_t *which = (zsock_t *)zpoller_wait(poller, acc_zmq_warn_ms);
        if (zpoller_terminated(poller)) {
            ACCELERATOR_EPRINTF("txid=%" PRIu64 " poller terminated %s (%s)",
                                txid, sock_name, ctx ? ctx : "");
            zpoller_destroy(&poller);
            return NULL;
        }
        if (zpoller_expired(poller) || which != sock) {
            gint64 elapsed_ms = (g_get_monotonic_time() - start_us) / 1000;
            ACC_LOG(ACC_LOG_WARN,
                    "txid=%" PRIu64 " still waiting %s after %" PRId64 "ms (%s)",
                    txid, sock_name, elapsed_ms, ctx ? ctx : "");
            continue;
        }
        break;
    }
    zpoller_destroy(&poller);

    zframe_t *frame = zframe_recv(sock);
    if (!frame) {
        ACCELERATOR_EPRINTF("txid=%" PRIu64 " recv failed %s (%s)", txid,
                            sock_name, ctx ? ctx : "");
        return NULL;
    }
    ACCELERATOR_DPRINTF("txid=%" PRIu64 " recv ok %s size=%zu (%s)", txid,
                        sock_name, zframe_size(frame), ctx ? ctx : "");
    return frame;
}

typedef struct ACCPCIeState {
    PCIDevice parent_obj;
    /* BARs */
    MemoryRegion bars[6];
    /* NIC */
    NICState *nic;
    NICConf conf;
    /* Serial support */
    CharBackend chr;
    MemoryRegion mmserial;
    /* msix */
    MemoryRegion msix;

    /* QEMU-HDL Communication Channels */
    zsock_t *qemu_req;
    zsock_t *qemu_resp;
    zsock_t *hdl_req;
    zsock_t *hdl_resp;
    zsock_t *nic_req;
    zsock_t *nic_resp;
    zsock_t *serial_tx;
    zsock_t *serial_rx;

} ACCPCIeState;

// Device Configuration
static ACCConf hdlconf_storage;
static ACCConf *hdlconf = &hdlconf_storage;
//zsock_t *initsock;
//zframe_t *initframe;
/* This defines Emulated Network card name */
#define TYPE_ACC_PCIE "accelerator-pcie"
#define ACC_PCIE(obj) OBJECT_CHECK(ACCPCIeState, (obj), TYPE_ACC_PCIE)

static void
acc_unuse_msix_vectors(ACCPCIeState *s, int num_vectors)
{
    int i;
    ACCELERATOR_DPRINTF("msix_vector_unuse count=%d", num_vectors);
    for (i = 0; i < num_vectors; i++) {
        msix_vector_unuse(PCI_DEVICE(s), i);
    }
}

static bool
acc_use_msix_vectors(ACCPCIeState *s, int num_vectors)
{
    int i;
    ACCELERATOR_DPRINTF("msix_vector_use count=%d entries_nr=%d", num_vectors,
                        PCI_DEVICE(s)->msix_entries_nr);
    for (i = 0; i < num_vectors; i++)   {
        if (i >= PCI_DEVICE(s)->msix_entries_nr)  {
            acc_unuse_msix_vectors (s, i);
            return false;
        }
        msix_vector_use(PCI_DEVICE(s), i);
    //    int res = msix_vector_use(PCI_DEVICE(s), i);
    //    if (res < 0) {
    //        acc_unuse_msix_vectors(s, i);
    //        return false;
    //    }
    }
    return true;
}

static void
acc_init_msix(ACCPCIeState *s)
{
    PCIDevice *d = PCI_DEVICE(s);
    ACCELERATOR_DPRINTF("msix_init vec_num=%u table_bar=%u table_off=0x%" PRIx64
                        " pba_bar=%u pba_off=0x%" PRIx64,
                        hdlconf->msix_vec_num, hdlconf->msix_table_bar,
                        hdlconf->msix_table_offset, hdlconf->msix_pba_bar,
                        hdlconf->msix_pba_offset);
    //int res = msix_init(PCI_DEVICE(s), ACC_NUM_MSIX_VEC,
    //                    &s->bars[ACC_MSIX_BAR_TABLE],
    //                    ACC_MSIX_BAR_TABLE, ACC_MSIX_OFFSET_TABLE,
    //                    &s->bars[ACC_MSIX_BAR_PBA],
    //                    ACC_MSIX_BAR_PBA, ACC_MSIX_OFFSET_PBA,
    //                    0x00, NULL);
    int res = msix_init(PCI_DEVICE(s), hdlconf->msix_vec_num,
                        &s->bars[hdlconf->msix_table_bar],
                        hdlconf->msix_table_bar, hdlconf->msix_table_offset,
                        &s->bars[hdlconf->msix_pba_bar],
                        hdlconf->msix_pba_bar, hdlconf->msix_pba_offset,
                        0x00, NULL);


    if (res < 0) {
        ACCELERATOR_EPRINTF("Fail to do msix_init %s:%d", __func__, __LINE__);
        exit(0);
    } else {
        //if (!acc_use_msix_vectors(s, ACC_NUM_MSIX_VEC)) {
        //    msix_uninit(d, &s->bars[ACC_MSIX_BAR_TABLE], &s->bars[ACC_MSIX_BAR_PBA]);
        if (!acc_use_msix_vectors(s, hdlconf->msix_vec_num)) {
            msix_uninit(d, &s->bars[hdlconf->msix_table_bar], &s->bars[hdlconf->msix_pba_bar]);
        }
    }
}

static void
acc_cleanup_msix(ACCPCIeState *s)
{
    if (msix_present(PCI_DEVICE(s))) {
        ACCELERATOR_DPRINTF("msix_cleanup vec_num=%u", hdlconf->msix_vec_num);
        //acc_unuse_msix_vectors(s, ACC_NUM_MSIX_VEC);
        //msix_uninit(PCI_DEVICE(s), &s->bars[ACC_MSIX_BAR_TABLE], &s->bars[ACC_MSIX_BAR_PBA]);
        acc_unuse_msix_vectors(s, hdlconf->msix_vec_num);
        msix_uninit(PCI_DEVICE(s), &s->bars[hdlconf->msix_table_bar], &s->bars[hdlconf->msix_pba_bar]);
    }
}

/*
Callback for write operation on BAR0. This is where data is sent from QEMU to
HDL over ZMQ sockets. When creating a new BAR with MMIO it is important that
this callback is implemented for that BAR (address translation is done on HDL
side, hence the correct offsets need to be added.)
*/
#define MMIO_WRITE_BAR(_num)                                                   \
    static void mmio_write_bar##_num(void *opaque, hwaddr addr, uint64_t val,  \
                                     unsigned size) {                          \
        ACCPCIeState *s = opaque;                                              \
        uint64_t txid = acc_next_txid();                                       \
        ACCData acc_req;                                                       \
        memset(&acc_req, 0, sizeof(ACCData));                                  \
        /*Important to add offset for the BAR as address translation is done   \
         * on HDL side */                                                      \
        acc_req.id = (uint32_t)txid;                                           \
        acc_req.bar_num = _num;                                                \
        acc_req.address = (uint64_t)(addr);                                    \
        memcpy(&acc_req.data, &val, sizeof(uint64_t));                         \
        acc_req.op = WRITE;                                                    \
        acc_req.data_size = size;                                              \
        ACCELERATOR_TPRINTF(                                                   \
            "txid=%" PRIu64 " BAR[%d] WR addr=0x%016" PRIx64 " size=%u val=0x%016" \
            PRIx64,                                                            \
            txid, _num, (uint64_t)addr, size, (uint64_t)val);                  \
        /*Create frame containing data to send */                              \
        zframe_t *frame = zframe_new(&acc_req, sizeof(ACCData));               \
        if (!frame) {                                                          \
            ACCELERATOR_EPRINTF("BAR[%d] WR ERROR %s:%d", _num, __func__,     \
                                __LINE__);                                     \
        }                                                                      \
        /* Send frame:                                                         \
           ZMQ write is non-blocking while the library's underlying queue is   \
           not full. when it is, send is blocking.                             \
        */                                                                     \
        ACCELERATOR_DPRINTF("txid=%" PRIu64 " BAR[%d] WR send -> qemu_req",     \
                            txid, _num);                                       \
        int rv = zframe_send(&frame, s->qemu_req, 0);                          \
        if (rv != 0) {                                                         \
            ACCELERATOR_EPRINTF("BAR[%d] WR ERROR %s:%d", _num, __func__,     \
                                __LINE__);                                     \
        }                                                                      \
        /* Wait for response */                                                \
        frame = acc_zframe_recv_logged(s->qemu_resp, "qemu_resp", txid,        \
                                       "mmio_write_bar" #_num);               \
        if (!frame) {                                                          \
            ACCELERATOR_EPRINTF("txid=%" PRIu64 " BAR[%d] WR no response",      \
                                txid, _num);                                   \
        } else {                                                               \
            zframe_destroy(&frame);                                            \
        }                                                                      \
    }

MMIO_WRITE_BAR(0)
MMIO_WRITE_BAR(1)
MMIO_WRITE_BAR(2)
MMIO_WRITE_BAR(3)
MMIO_WRITE_BAR(4)
MMIO_WRITE_BAR(5)

/*
Callback for read operation on BAR0. This is a blocking read. QEMU will "hang"
while HDL services the read request. It will return when HDL has responded with
data over socket. There is no timeout and this can cause the program to hang
indefinitely.
*/
#define MMIO_READ_BAR(_num)                                                    \
    static uint64_t mmio_read_bar##_num(void *opaque, hwaddr addr,             \
                                        unsigned size) {                       \
        ACCPCIeState *s = opaque;                                              \
        uint64_t txid = acc_next_txid();                                       \
        ACCData acc_req;                                                       \
        memset(&acc_req, 0, sizeof(ACCData));                                  \
        /* Setup request fields                                                \
           Important to add offset for the BAR as address translation is done  \
           on HDL side                                                         \
        */                                                                     \
        acc_req.id = (uint32_t)txid;                                           \
        acc_req.bar_num = _num;                                                \
        acc_req.address = (uint64_t)(addr);                                    \
        acc_req.op = READ;                                                     \
        acc_req.data_size = size;                                              \
        ACCELERATOR_TPRINTF("txid=%" PRIu64 " BAR[%d] RD addr=0x%016" PRIx64    \
                            " size=%u",                                        \
                            txid, _num, (uint64_t)addr, size);                 \
        /* Create frame containing data to send */                             \
        zframe_t *frame = zframe_new(&acc_req, sizeof(ACCData));               \
        if (!frame) {                                                          \
            ACCELERATOR_EPRINTF("BAR[%d] RD ERROR %s:%d", _num, __func__,     \
                                __LINE__);                                     \
        }                                                                      \
        /* Send frame */                                                       \
        ACCELERATOR_DPRINTF("txid=%" PRIu64 " BAR[%d] RD send -> qemu_req",     \
                            txid, _num);                                       \
        int rv = zframe_send(&frame, s->qemu_req, 0);                          \
        if (rv != 0) {                                                         \
            ACCELERATOR_EPRINTF("BAR[%d] RD ERROR %s:%d", _num, __func__,     \
                                __LINE__);                                     \
        }                                                                      \
        /* Wait for response */                                                \
        frame = acc_zframe_recv_logged(s->qemu_resp, "qemu_resp", txid,        \
                                       "mmio_read_bar" #_num);                \
        if (!frame) {                                                          \
            ACCELERATOR_EPRINTF("txid=%" PRIu64 " BAR[%d] RD no response",      \
                                txid, _num);                                   \
            return 0;                                                          \
        }                                                                      \
        if (zframe_size(frame) < sizeof(ACCData)) {                            \
            ACCELERATOR_EPRINTF(                                               \
                "txid=%" PRIu64 " BAR[%d] RD short frame size=%zu",            \
                txid, _num, zframe_size(frame));                               \
            zframe_destroy(&frame);                                            \
            return 0;                                                          \
        }                                                                      \
        ACCData *acc_data = (ACCData *)zframe_data(frame);                     \
        uint64_t data = 0;                                                     \
        switch (size) {                                                        \
        case 1:                                                                \
            data = *(uint8_t *)acc_data->data;                                 \
            break;                                                             \
        case 2:                                                                \
            data = *(uint16_t *)acc_data->data;                                \
            break;                                                             \
        case 4:                                                                \
            data = *(uint32_t *)acc_data->data;                                \
            break;                                                             \
        case 8:                                                                \
            data = *(uint64_t *)acc_data->data;                                \
            break;                                                             \
        default:                                                               \
            ACCELERATOR_EPRINTF("BAR[%d] Unsupported read size %u", _num,     \
                                size);                                         \
        }                                                                      \
        ACCELERATOR_TPRINTF("txid=%" PRIu64 " BAR[%d] RD addr=0x%016" PRIx64   \
                            " -> 0x%016" PRIx64,                               \
                            txid, _num, (uint64_t)addr, data);                 \
        zframe_destroy(&frame);                                                \
        return data;                                                           \
    }

MMIO_READ_BAR(0)
MMIO_READ_BAR(1)
MMIO_READ_BAR(2)
MMIO_READ_BAR(3)
MMIO_READ_BAR(4)
MMIO_READ_BAR(5)

/*
Callback called when there is activity on the HDL request socket. This callback
will handle the request made by HDL and respond appropriately. Since address
translation is done on HDL side, no need for it on QEMU.
*/
static void handle_hdl_request(void *opaque) {
    ACCPCIeState *s = opaque;
    PCIDevice *dev = PCI_DEVICE(s);
    ACCELERATOR_TPRINTF("enter handle_hdl_request dev=%p", dev);
    int rv;
    // Poller so that no hdl packets are missed
    zpoller_t *poller = zpoller_new(s->hdl_req, NULL);
    if (!poller) {
        ACCELERATOR_EPRINTF("HDL REQ ERROR %s:%d", __func__, __LINE__);
    }
    while (1) {
        zsock_t *which = (zsock_t *)zpoller_wait(poller, 0);
        int terminate = zpoller_expired(poller) || zpoller_terminated(poller) ||
                        which != s->hdl_req;

        if (terminate) {
            zpoller_destroy(&poller);
            ACCELERATOR_TPRINTF("exit handle_hdl_request terminate=%d", terminate);
            return;
        }

        zframe_t *frame = zframe_recv(s->hdl_req);
        if (!frame) {
            ACCELERATOR_EPRINTF("HDL REQ ERROR %s:%d", __func__, __LINE__);
            exit(1);
            continue;
        }
        if (zframe_size(frame) < sizeof(ACCData)) {
            ACCELERATOR_EPRINTF("HDL REQ short frame size=%zu", zframe_size(frame));
            zframe_destroy(&frame);
            exit(1);
            continue;
        }
        ACCData *acc_data = (ACCData *)zframe_data(frame);

        ACCOp req = acc_data->op;
        uint64_t addr = acc_data->address;
        ACCELERATOR_TPRINTF("HDL REQ op=%d addr=0x%016" PRIx64 " size=%u vec=%u",
                            req, addr, acc_data->data_size, acc_data->vector);
        switch (req) {
        case READ:
            ACCELERATOR_DPRINTF("HDL->Host READ addr=0x%016" PRIx64 " size=%u", addr,
                                acc_data->data_size);
            cpu_physical_memory_read(addr, acc_data->data, acc_data->data_size);
            // Send frame
            rv = zframe_send(&frame, s->hdl_resp, ZFRAME_REUSE);
            if (rv != 0) {
                ACCELERATOR_EPRINTF("HDL REQ ERROR %s:%d", __func__,
                                    __LINE__);
                exit(1);

            }
            break;
        case WRITE:
            ACCELERATOR_DPRINTF("HDL->Host WRITE addr=0x%016" PRIx64 " size=%u", addr,
                                acc_data->data_size);
            cpu_physical_memory_write(addr, acc_data->data,
                                      acc_data->data_size);
            break;
        case INTR:
            ACCELERATOR_DPRINTF("HDL->Host INTR vector=%u", acc_data->vector);
            //msi_notify(dev, acc_data->vector);
            msix_notify(dev, acc_data->vector);
            break;
        case NOOP:
        default:
            break;
        }
        zframe_destroy(&frame);
    }
}

/*
MMIO options for BAR region
*/
#define MEM_REGION_OPS_BAR(_num)                                               \
    {                                                                          \
        .read = mmio_read_bar##_num, .write = mmio_write_bar##_num,            \
        .endianness = DEVICE_NATIVE_ENDIAN,                                    \
        .valid = {                                                             \
            .min_access_size = 1, .max_access_size = 8,                        \
        },                                                                     \
        .impl = {                                                              \
            .min_access_size = 1, .max_access_size = 8,                        \
        },                                                                     \
    }

static const MemoryRegionOps mmio_ops_bar[6] = {
    MEM_REGION_OPS_BAR(0), MEM_REGION_OPS_BAR(1), MEM_REGION_OPS_BAR(2),
    MEM_REGION_OPS_BAR(3), MEM_REGION_OPS_BAR(4), MEM_REGION_OPS_BAR(5)};

static const char *bar_names[6] = {"mmio-bar0", "mmio-bar1", "mmio-bar2",
                                   "mmio-bar3", "mmio-bar4", "mmio-bar5"};

// NIC Features
// Transmit processed packet recieved from HDL
static void net_tx_packet(void *opaque) {
    ACCPCIeState *s = opaque;
    ACCELERATOR_TPRINTF("enter net_tx_packet nic=%p", s->nic);
    zpoller_t *poller = zpoller_new(s->nic_resp, NULL);
    assert(poller);
    // ZMQ doesn't write until the last send (i.e all the partial messages are
    // here)
    while (1) {
        zsock_t *which = (zsock_t *)zpoller_wait(poller, 0);
        int terminate = zpoller_expired(poller) || zpoller_terminated(poller) ||
                        which != s->nic_resp;
        if (terminate) {
            zpoller_destroy(&poller);
            return;
        }
        // ACCELERATOR_DPRINTF("NIC: recieved packet from hdl\n");
        // ACCELERATOR_DPRINTF("in %s:%d\n", __func__, __LINE__);
        zframe_t *frame = zframe_recv(s->nic_resp);
        assert(frame);
        if (zframe_size(frame) < sizeof(ACCNICData)) {
            ACCELERATOR_EPRINTF("NIC RX short frame size=%zu", zframe_size(frame));
            zframe_destroy(&frame);
            exit(1);
            continue;
        }
        ACCNICData *acc_data = (ACCNICData *)zframe_data(frame);
        ACCELERATOR_DPRINTF("NIC: HDL->OS send size=%u", acc_data->size);
        qemu_send_packet(qemu_get_queue(s->nic), acc_data->data,
                         acc_data->size);
        zframe_destroy(&frame);
    }
}

// Recieve packet from OS and send to HDL NIC
static ssize_t net_rx_packet(NetClientState *nc, const uint8_t *buf,
                             size_t size) {
    ACCPCIeState *s = qemu_get_nic_opaque(nc);
    ACCNICData acc_req;
    memset(&acc_req, 0, sizeof(ACCNICData));
    acc_req.size = size;
    acc_req.id = 1;
    memcpy(acc_req.data, buf, size);
    // Create frame containing data to send
    zframe_t *frame = zframe_new(&acc_req, sizeof(ACCNICData));
    assert(frame);
    // Send frame
    ACCELERATOR_DPRINTF("NIC: OS->HDL send size=%zu", size);
    int rv = zframe_send(&frame, s->nic_req, 0);
    assert(rv == 0);
    ACCELERATOR_DPRINTF("NIC: sent packet to hdl\n");
    return size;
}

// NIC Info
static NetClientInfo net_acc_info = {.type = NET_CLIENT_DRIVER_NIC,
                                     .size = sizeof(ACCPCIeState),
                                     .receive = net_rx_packet};

// Serial Support

static uint64_t serial_read(void *opaque, hwaddr addr, unsigned size) {
    ACCELERATOR_DPRINTF("serial_read addr=0x%" HWADDR_PRIx " size=%u", addr, size);
    return 0;
}

static void serial_write(void *opaque, hwaddr addr, uint64_t value,
                         unsigned size) {
    ACCELERATOR_DPRINTF("serial_write addr=0x%" HWADDR_PRIx " size=%u val=0x%016" PRIx64,
                        addr, size, value);
    return;
}

static const MemoryRegionOps serial_mmio_ops = {
    .read = serial_read,
    .write = serial_write,
    .valid =
        {
            .min_access_size = 1, .max_access_size = 1,
        },
    .endianness = DEVICE_NATIVE_ENDIAN,
};

static int serial_can_rx(void *opaque) { return 1; }

static void serial_rx(void *opaque, const uint8_t *buf, int size) {
    ACCPCIeState *s = opaque;
    ACCELERATOR_DPRINTF("serial_rx size=%d", size);
    zframe_t *frame = zframe_new(buf, size);
    zframe_send(&frame, s->serial_rx, 0);
}

static void serial_tx(void *opaque) {
    ACCPCIeState *s = opaque;
    ACCELERATOR_TPRINTF("enter serial_tx");
    zpoller_t *poller = zpoller_new(s->serial_tx, NULL);
    assert(poller);
    // ZMQ doesn't write until the last send (i.e all the partial messages are
    // here)
    while (1) {
        zsock_t *which = (zsock_t *)zpoller_wait(poller, 0);
        int terminate = zpoller_expired(poller) || zpoller_terminated(poller) ||
                        which != s->serial_tx;
        if (terminate) {
            zpoller_destroy(&poller);
            return;
        }
        zframe_t *frame = zframe_recv(s->serial_tx);
        uint8_t *c = zframe_data(frame);
        ACCELERATOR_TPRINTF("serial_tx byte=0x%02x", c ? c[0] : 0);
        qemu_chr_fe_write(&s->chr, c, 1);
        zframe_destroy(&frame);
    }
}

//static void serial_event(void *opaque, int event) { return; }
static void serial_event(void *opaque, QEMUChrEvent event) { return; }

// QDev settings
/* Potential Null checks required ?
 */
static void acc_pcie_realize(PCIDevice *dev, Error **errp) {

    ACCPCIeState *s = ACC_PCIE(dev);
    DeviceState *d = DEVICE(dev);

    int i;
    uint8_t *pci_conf;
    char buffer[50];

    const char *port_str = getenv("NPU_COSIM_PORT");
    if (!port_str || !*port_str) {
        error_setg(errp, "NPU_COSIM_PORT environment variable not set");
        return;
    }
    int port = atoi(port_str);
    ACCELERATOR_DPRINTF("acc_pcie_realize dev=%p id=%s NPU_COSIM_PORT=%d", dev,
                        d->id ? d->id : "(null)", port);
    pci_conf = dev->config;
    pci_conf[PCI_COMMAND] = PCI_COMMAND_IO | PCI_COMMAND_MEMORY;

    // PCI_BASE_ADDRESS_SPACE_MEMORY | PCI_BASE_ADDRESS_MEM_PREFETCH |
    // PCI_BASE_ADDRESS_MEM_TYPE_64;
    uint8_t attr = PCI_BASE_ADDRESS_SPACE_MEMORY;
    if (hdlconf->is_64) {
        attr |= PCI_BASE_ADDRESS_MEM_TYPE_64;
    }
    if (hdlconf->prefetch) {
        attr |= PCI_BASE_ADDRESS_MEM_PREFETCH;
    }
    for (i = 0; i < 6; i++) {
        if (hdlconf->bar[i].is_valid) {
            ACCELERATOR_DPRINTF("BAR[%d] init size=0x%" PRIx64 " name=%s", i,
                                hdlconf->bar[i].size, bar_names[i]);
            // Initialize BAR regions
            memory_region_init_io(&s->bars[i], OBJECT(s), &mmio_ops_bar[i], s,
                                  bar_names[i], hdlconf->bar[i].size);
            // Register BAR regions
            pci_register_bar(dev, i, attr, &s->bars[i]);
        }
    }



    // request from qemu
    sprintf(buffer, SOCK_BASE, SEND_SOCK, port);
    ACCELERATOR_DPRINTF("ZMQ qemu_req endpoint=%s", buffer);
    s->qemu_req = zsock_new_push(buffer);
    // hdl response to request
    sprintf(buffer, SOCK_BASE, RECV_SOCK, port + 1);
    ACCELERATOR_DPRINTF("ZMQ qemu_resp endpoint=%s", buffer);
    s->qemu_resp = zsock_new_pull(buffer);
    // request from hdl
    sprintf(buffer, SOCK_BASE, RECV_SOCK, port + 2);
    ACCELERATOR_DPRINTF("ZMQ hdl_req endpoint=%s", buffer);
    s->hdl_req = zsock_new_pull(buffer);
    // qemu response to request
    sprintf(buffer, SOCK_BASE, SEND_SOCK, port + 3);
    ACCELERATOR_DPRINTF("ZMQ hdl_resp endpoint=%s", buffer);
    s->hdl_resp = zsock_new_push(buffer);
    // nic request
    sprintf(buffer, SOCK_BASE, SEND_SOCK, port + 4);
    ACCELERATOR_DPRINTF("ZMQ nic_req endpoint=%s", buffer);
    s->nic_req = zsock_new_push(buffer);
    // nic response
    sprintf(buffer, SOCK_BASE, RECV_SOCK, port + 5);
    ACCELERATOR_DPRINTF("ZMQ nic_resp endpoint=%s", buffer);
    s->nic_resp = zsock_new_pull(buffer);
    // serial rx
    sprintf(buffer, SOCK_BASE, SEND_SOCK, port + 8);
    ACCELERATOR_DPRINTF("ZMQ serial_rx endpoint=%s", buffer);
    s->serial_rx = zsock_new_push(buffer);
    // serial tx
    sprintf(buffer, SOCK_BASE, RECV_SOCK, port + 9);
    ACCELERATOR_DPRINTF("ZMQ serial_tx endpoint=%s", buffer);
    s->serial_tx = zsock_new_pull(buffer);

    assert(s->qemu_req && s->qemu_resp);
    assert(s->hdl_req && s->hdl_resp);
    assert(s->nic_req && s->nic_resp);
    assert(s->serial_tx && s->serial_rx);

    // Listen for requests from HDL (register zsock fd with QEMU)
    size_t opt_len = sizeof(int);
    int fd;
    void *zmq_sock = zsock_resolve(s->hdl_req);
    int rv = zmq_getsockopt(zmq_sock, ZMQ_FD, &fd, &opt_len);
    if (rv != 0) {
        ACCELERATOR_EPRINTF("zmq_getsockopt(ZMQ_FD) hdl_req failed: %s",
                            zmq_strerror(errno));
        exit(1);
    } else {
        ACCELERATOR_DPRINTF("hdl_req fd=%d registered", fd);
        qemu_set_fd_handler(fd, handle_hdl_request, NULL, s);
    }

    zmq_sock = zsock_resolve(s->nic_resp);
    rv = zmq_getsockopt(zmq_sock, ZMQ_FD, &fd, &opt_len);
    if (rv != 0) {
        ACCELERATOR_EPRINTF("zmq_getsockopt(ZMQ_FD) nic_resp failed: %s",
                            zmq_strerror(errno));
        exit(1);
    } else {
        ACCELERATOR_DPRINTF("nic_resp fd=%d registered", fd);
        qemu_set_fd_handler(fd, net_tx_packet, NULL, s);
    }

    zmq_sock = zsock_resolve(s->serial_tx);
    rv = zmq_getsockopt(zmq_sock, ZMQ_FD, &fd, &opt_len);
    if (rv != 0) {
        ACCELERATOR_EPRINTF("zmq_getsockopt(ZMQ_FD) serial_tx failed: %s",
                            zmq_strerror(errno));
        exit(1);
    } else {
        ACCELERATOR_DPRINTF("serial_tx fd=%d registered", fd);
        qemu_set_fd_handler(fd, serial_tx, NULL, s);
    }

    // NIC init
    qemu_macaddr_default_if_unset(&s->conf.macaddr);
    s->nic = qemu_new_nic(&net_acc_info, &s->conf,
                          object_get_typename(OBJECT(dev)), d->id,
                          &d->mem_reentrancy_guard, s);
    qemu_format_nic_info_str(qemu_get_queue(s->nic), s->conf.macaddr.a);

    // MSI init
    //msi_init(dev, 0x00, NUM_MSI_VEC, false, false, errp);
    acc_init_msix(s);

    // Serial init
    memory_region_init_io(&s->mmserial, NULL, &serial_mmio_ops, s,
                          "serial-mmio", 8);
    qemu_chr_fe_set_handlers(&s->chr, serial_can_rx, serial_rx, serial_event,
                             NULL, s, NULL, true);
    qemu_chr_fe_set_echo(&s->chr, true);
}

static void acc_pcie_exit(PCIDevice *dev) {
    ACCPCIeState *s = ACC_PCIE(dev);
    ACCELERATOR_DPRINTF("acc_pcie_exit dev=%p", dev);

    acc_cleanup_msix(s);

    zsock_destroy(&s->hdl_req);
    zsock_destroy(&s->hdl_resp);
    zsock_destroy(&s->qemu_req);
    zsock_destroy(&s->qemu_resp);
    zsock_destroy(&s->nic_req);
    zsock_destroy(&s->nic_resp);
}
static void acc_pcie_reset(DeviceState *ds) { /*TODO*/
    ACCELERATOR_DPRINTF("acc_pcie_reset ds=%p", ds);
}

static const Property acc_pcie_properties[] = {
    DEFINE_NIC_PROPERTIES(ACCPCIeState, conf),
    DEFINE_PROP_CHR("chardev", ACCPCIeState, chr),
};

/* Suspected Entry point of the device */
static void acc_pcie_class_init(ObjectClass *klass, const void *data) {
    DeviceClass *dc = DEVICE_CLASS(klass);
    PCIDeviceClass *k = PCI_DEVICE_CLASS(klass);
    char buffer[50];
    const char *port_str = getenv("NPU_COSIM_PORT");
    if (!port_str || !*port_str) {
        ACCELERATOR_EPRINTF("NPU_COSIM_PORT environment variable not set; cannot init device");
        exit(1);
    }
    int port = atoi(port_str);
    ACCELERATOR_DPRINTF("acc_pcie_class_init NPU_COSIM_PORT=%d", port);

    ACCData acc_init_req;
    memset(&acc_init_req, 0, sizeof(acc_init_req));
    uint64_t txid = acc_next_txid();
    acc_init_req.bar_num = 16;
    acc_init_req.address = (uint64_t)(9999);
    acc_init_req.op = INIT;
    acc_init_req.data_size = 32;
    acc_init_req.id = (uint32_t)txid;

    sprintf(buffer,SOCK_BASE, SEND_SOCK, port-1);
    ACCELERATOR_DPRINTF("INIT send endpoint=%s", buffer);
    zsock_t *initsock = zsock_new_push(buffer);
    zframe_t *initframe=zframe_new(&acc_init_req, sizeof(ACCData));
    int rv = zframe_send(&initframe, initsock, 0);
    assert(rv == 0);

    sprintf(buffer,SOCK_BASE, RECV_SOCK, port+10);
    ACCELERATOR_DPRINTF("INIT recv endpoint=%s", buffer);
    zsock_t *initsock2 = zsock_new_pull(buffer);
    // Wait for response 
    zframe_t *initframe2 = acc_zframe_recv_logged(initsock2, "init_resp", txid,
                                                  "class_init");
    if (!initframe2) {
         ACCELERATOR_EPRINTF("INIT ERROR: no response");
         exit(1);
    }
    if (zframe_size(initframe2) < sizeof(ACCConf)) {
        ACCELERATOR_EPRINTF("INIT ERROR: short ACCConf frame size=%zu",
                            zframe_size(initframe2));
        exit(1);
    }
    memcpy(&hdlconf_storage, zframe_data(initframe2), sizeof(ACCConf));
    ACCELERATOR_DPRINTF(
        "INIT ok vendor_id=0x%04x device_id=0x%04x is_64=%d prefetch=%d msix_vec_num=%u",
        hdlconf->vendor_id, hdlconf->device_id, hdlconf->is_64, hdlconf->prefetch,
        hdlconf->msix_vec_num);

    k->realize = acc_pcie_realize;
    k->exit = acc_pcie_exit;
    k->vendor_id = hdlconf->vendor_id;
    k->device_id = hdlconf->device_id;
    k->class_id = PCI_CLASS_NETWORK_ETHERNET;
    k->revision = 1;

    set_bit(DEVICE_CATEGORY_MISC, dc->categories);
    device_class_set_legacy_reset(dc, acc_pcie_reset);
    device_class_set_props(dc,acc_pcie_properties);
    dc->desc = "PCIe HDL-VM Data Transfer with NIC Support";

    zframe_destroy(&initframe);
    zframe_destroy(&initframe2);
    zsock_destroy(&initsock);
    zsock_destroy(&initsock2);
}

static const TypeInfo acc_pcie_info = {.name = TYPE_ACC_PCIE,
                                       .parent = TYPE_PCI_DEVICE,
                                       .instance_size = sizeof(ACCPCIeState),
                                       .class_init = acc_pcie_class_init,
                                       .interfaces = (InterfaceInfo[]) {
                                                     {INTERFACE_PCIE_DEVICE},
                                                     {INTERFACE_CONVENTIONAL_PCI_DEVICE}
                                                     }
                                      };

static void acc_pcie_register_types(void) {
    type_register_static(&acc_pcie_info);
}

type_init(acc_pcie_register_types);
