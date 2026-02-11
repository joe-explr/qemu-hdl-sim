#ifdef __cplusplus
#define DPI_LINKER_DECL extern "C"
#else
#define DPI_LINKER_DECL
#endif

#include "acc.h"

#if 0
#define PCIE_DPRINTF(fmt, ...)                                                 \
    do {                                                                       \
        fprintf(stderr, "PCIE: " fmt, ##__VA_ARGS__);                          \
    } while (0)
#else
#define PCIE_DPRINTF(fmt, ...)
#endif

DPI_LINKER_DECL void
C_setup_pcie_connection(unsigned long busw, unsigned short vendorid,
                        unsigned short deviceid, char attributes,
                        char valid_bars[6], unsigned long bar_size[6],
                        unsigned long bar_offset[6],
                        unsigned short msix_vec_num,
                        unsigned short msix_table_bar, unsigned long msix_table_offset,
                        unsigned short msix_pba_bar, unsigned long msix_pba_offset);
DPI_LINKER_DECL void C_poll(unsigned int *req_type, unsigned long *addr,
                            unsigned int *len, unsigned int *size,
                            unsigned long *strb, unsigned char *data);
DPI_LINKER_DECL void C_qemu_step();
DPI_LINKER_DECL void C_req_read(long addr, int width, int len, int id);
DPI_LINKER_DECL void C_resp_read(long addr, unsigned char *data);
DPI_LINKER_DECL void C_req_write(long addr, int width, int len,
                                 unsigned char *data, unsigned long *strb);
DPI_LINKER_DECL void C_resp_write();
DPI_LINKER_DECL void C_req_interrupt(int vector);

// Globals
zsock_t *qemu_req = NULL;
zsock_t *qemu_resp = NULL;
zsock_t *hdl_req = NULL;
zsock_t *hdl_resp = NULL;
zpoller_t *poller = NULL;
zsock_t *initsock = NULL;
zsock_t *initsock2 = NULL;
static unsigned long BUSW = 0; // Bus width in bytes
static ACCConf conf;

// Helpers
uint8_t log2c(uint64_t x) {
    uint8_t log = (x & x - 1) ? 1 : 0;
    while (x >>= 1)
        log++;
    return log;
}

void C_teardown_pcie_connection() {
    // deinit frame
    // deinit poller
    zpoller_destroy(&poller);
    // deinit 0mq sockets
    zsock_destroy(&qemu_req);
    zsock_destroy(&qemu_resp);
    zsock_destroy(&hdl_req);
    zsock_destroy(&hdl_resp);
    zsock_destroy(&initsock);
    zsock_destroy(&initsock2);
    PCIE_DPRINTF("PCIE socket connection teardown complete.\n");
}

// DPI functions
void C_setup_pcie_connection(unsigned long busw, unsigned short vendorid,
                             unsigned short deviceid, char attributes,
                             char valid_bars[6], unsigned long bar_size[6],
                             unsigned long bar_offset[6],
                             unsigned short msix_vec_num,
                             unsigned short msix_table_bar, unsigned long msix_table_offset,
                             unsigned short msix_pba_bar, unsigned long msix_pba_offset)
{
    int i;
    // Bus width parameter
    BUSW = busw;
    // TODO: set up bar configuration here
    conf.device_id = deviceid;
    conf.vendor_id = vendorid;
    conf.is_64 = (attributes & 1) == 1;
    conf.prefetch = (attributes & 2) == 2;
    for (i = 0; i < 6; i++) {
        conf.bar[i].is_valid = valid_bars[i];
        conf.bar[i].size = 1ULL << bar_size[i];
        conf.bar[i].offset = bar_offset[i];
    }
    conf.msix_vec_num       = msix_vec_num      ;   
    conf.msix_table_bar     = msix_table_bar    ;
    conf.msix_table_offset  = msix_table_offset ;
    conf.msix_pba_bar       = msix_pba_bar      ;
    conf.msix_pba_offset    = msix_pba_offset   ;

    printf("Device ID: %X\n", conf.device_id);
    printf("Vendor ID: %X\n", conf.vendor_id);
    printf("64-bit mode: %d\n", conf.is_64);
    printf("Prefetch: %d\n", conf.prefetch);
    for (i = 0; i < 6; i++) {
        if (conf.bar[i].is_valid) {
            printf("BAR[%d]: Size = %lx Offset = %lx\n", i,
                   1 << conf.bar[i].size, conf.bar[i].offset);
        }
    }
    printf("msix_vec_num       = %d\n" , msix_vec_num      );   
    printf("msix_table_bar     = %d\n" , msix_table_bar    );
    printf("msix_table_offset  = %lX\n", msix_table_offset );
    printf("msix_pba_bar       = %d\n" , msix_pba_bar      );
    printf("msix_pba_offset    = %lX\n", msix_pba_offset   );

    int port = atoi(getenv("NPU_COSIM_PORT"));
    // initialize 0mq sockets
    char buffer[50];

    sprintf(buffer, SOCK_BASE, RECV_SOCK, port-1);
    initsock = zsock_new_pull(buffer); // init condition

    sprintf(buffer, SOCK_BASE, SEND_SOCK, port + 10);
    initsock2 = zsock_new_push(buffer);

    sprintf(buffer, SOCK_BASE, RECV_SOCK, port);
    qemu_req = zsock_new_pull(buffer); // request from qemu
    sprintf(buffer, SOCK_BASE, SEND_SOCK, port + 1);
    qemu_resp = zsock_new_push(buffer); // hdl response to request
    sprintf(buffer, SOCK_BASE, SEND_SOCK, port + 2);
    hdl_req = zsock_new_push(buffer); // request from hdl
    sprintf(buffer, SOCK_BASE, RECV_SOCK, port + 3);
    hdl_resp = zsock_new_pull(buffer); // qemu response to request
    sprintf(buffer, SOCK_BASE, SEND_SOCK, port + 6);
    // set up 0mq poller
    poller = zpoller_new(initsock, qemu_req, hdl_resp, NULL);
    assert(poller);
    atexit(C_teardown_pcie_connection);

    PCIE_DPRINTF("PCIE socket connection setup complete.\n");
}

void C_poll(unsigned int *req_type, unsigned long *v_addr, unsigned int *v_len,
            unsigned int *v_size, unsigned long *v_strb,
            unsigned char *v_data) {
    zsock_t *sock = zpoller_wait(poller, 0);
    // no useful data
    if (!sock) {
        *req_type = NOOP;
        return;
    }
    // useful data
    
    if (sock == initsock) {
        zframe_t *frame_req = zframe_recv(initsock);
        zframe_destroy(&frame_req);
     	zframe_t *frame_rsp = zframe_new(&conf, sizeof(ACCConf));
     	assert(frame_rsp);
        int rv = zframe_send(&frame_rsp, initsock2, 0);
     	//assert(rv == 0);
        zframe_destroy(&frame_rsp);
        PCIE_DPRINTF("C: H->Q init\n");
        *req_type = NOOP;
    }
    else if (sock == qemu_req) {
        zframe_t *frame = zframe_recv(qemu_req);
        assert(frame);
        ACCData *acc_data = (ACCData *)zframe_data(frame);
        // clear buffer
        // need for both read and write
        uint64_t addr = acc_data->address + conf.bar[acc_data->bar_num].offset;
        // uint64_t mask = -1;
        uint32_t size = acc_data->data_size;
        uint32_t axi_size = 0;
        uint32_t axi_len = 0;
        uint32_t align_offset = addr % BUSW;
        // Calculate bursts
        if (size > BUSW)
            axi_len = (size % BUSW) ? size / BUSW : size / BUSW - 1;
        // Calculate size
        axi_size = log2c(size);
        // READ from qemu
        if (acc_data->op == READ) {
            PCIE_DPRINTF("C: Q->H RD: addr: %lx\n", addr);
            // Request read from hdl
            *req_type = M_RD;
            *v_addr = addr;
            *v_len = axi_len;
            *v_size = axi_size;
            // Clean resource
            zframe_destroy(&frame);
        }
        // WRITE from qemu
        else {
            // Request write on hdl
            *req_type = M_WR;
            // Qemu writes are only of size 1,2,4,8 (and 16?)
            *v_strb = (1 << size) - 1;
            *v_strb <<= align_offset;
            memcpy(v_data + align_offset, acc_data->data,
                   BUFF_SIZE - align_offset);
            *v_addr = addr;
            *v_size = axi_size;
            *v_len = axi_len;
            // debug
            PCIE_DPRINTF("C: Q->H WR: addr: %lx len: %d size: %d strb: %lx\n",
                         addr, axi_len, axi_size, v_strb[0]);
            // Clean resource
            zframe_destroy(&frame);
        }
    } else if (sock == hdl_resp) {
        // Response from QEMU
        PCIE_DPRINTF("C: H->Q RD\n");
        *req_type = S_RD;
        zframe_t *frame = zframe_recv(hdl_resp);
        assert(frame);
        ACCData *acc_data = (ACCData *)zframe_data(frame);
        uint32_t size = acc_data->data_size;
        // Copy read data to correct location
        uint32_t align_offset = (acc_data->address) % BUSW;
        memcpy(v_data + align_offset, acc_data->data, size);
        // Clean resource
        zframe_destroy(&frame);
    }
}

void C_qemu_step() {
    // int rv = zframe_send(&adv_step, ls_sock, ZFRAME_REUSE + ZFRAME_DONTWAIT);
}

void C_req_read(long addr, int width, int len, int id) {
    PCIE_DPRINTF("C: H->Q: RD: ADDR=0x%x, WIDTH=%u, LEN=%u\n", addr, width,
                 len);

    int rv;
    uint32_t size = (len + 1) * (1 << width);

    ACCData acc;
    // memset(&acc, 0, sizeof(ACCData));
    acc.data_size = size;
    acc.address = addr;
    acc.op = READ;
    acc.id = id;
    /* Create frame containing data to send */
    zframe_t *frame = zframe_new(&acc, sizeof(ACCData));
    assert(frame);
    /* Send frame */
    rv = zframe_send(&frame, hdl_req, 0);
    assert(rv == 0);
}

void C_resp_read(long addr, unsigned char *data) {
    PCIE_DPRINTF("C: Q->H RD: addr: %lx complete\n", addr);
    ACCData acc;
    uint32_t align_offset = addr % BUSW;
    // Update data
    memcpy(acc.data, data + align_offset, BUFF_SIZE - align_offset);
    /* Create frame containing data to send */
    zframe_t *frame = zframe_new(&acc, sizeof(ACCData));
    assert(frame);
    // Send response to qemu
    int rv = zframe_send(&frame, qemu_resp, 0);
    assert(rv == 0);
}

void C_resp_write() {
    PCIE_DPRINTF("C: Q->H WR: complete\n");
    ACCData acc;
    // Update data
    /* Create frame containing data to send */
    zframe_t *frame = zframe_new(&acc, sizeof(ACCData));
    assert(frame);
    // Send response to qemu
    int rv = zframe_send(&frame, qemu_resp, 0);
    assert(rv == 0);
}

void C_req_write(long addr, int width, int len, unsigned char *data,
                 unsigned long *strb) {
    PCIE_DPRINTF("C: H->Q: WR: ADDR=0x%x, WIDTH=%u, LEN=%u\n", addr, width,
                 len);
    int rv;
    uint32_t size = (len + 1) * (1 << width);

    ACCData acc;
    // memset(&acc, 0, sizeof(ACCData));
    acc.data_size = size;
    acc.address = addr;
    acc.op = WRITE;
    /* Copy write data to correct location */
    int i, j, k = 0;
    for (i = 0; i <= len; i++) {
        for (j = 0; j < BUSW; j++) {
            if (strb[i] & 1)
                acc.data[k++] = data[(i * BUSW) + j];
            strb[i] >>= 1;
        }
    }
    /* Create frame containing data to send */
    zframe_t *frame = zframe_new(&acc, sizeof(ACCData));
    assert(frame);
    /* Send frame */
    rv = zframe_send(&frame, hdl_req, 0);
    assert(rv == 0);
}

void C_req_interrupt(int vector) {
    PCIE_DPRINTF("C: H->Q: INTR: VECTOR=0x%x\n", vector);
    int rv;
    ACCData acc;
    // memset(&acc, 0, sizeof(ACCData));
    acc.op = INTR;
    acc.vector = vector;
    /* Create frame containing data to send */
    zframe_t *frame = zframe_new(&acc, sizeof(ACCData));
    assert(frame);
    /* Send frame */
    rv = zframe_send(&frame, hdl_req, 0);
    assert(rv == 0);
}

