#ifdef __cplusplus
#define DPI_LINKER_DECL  extern "C"
#else
#define DPI_LINKER_DECL
#endif

#include "acc.h"

#if 1
    #define NIC_DPRINTF(fmt, ...)                                           \
    do {                                                                    \
        fprintf(stderr, "NIC: " fmt, ##__VA_ARGS__);                        \
    } while (0)
#else
    #define NIC_DPRINTF(fmt, ...)
#endif

DPI_LINKER_DECL void C_send_packet(int id, int size, unsigned char *data);
DPI_LINKER_DECL void C_nic_poll(unsigned char* req, unsigned int* vlen, unsigned long* vkeep, unsigned char* vdata);
DPI_LINKER_DECL void C_setup_nic_connection(int bus_width);

//Globals
static zsock_t *nic_req = NULL;
static zsock_t *nic_resp = NULL;
static zpoller_t *poller_nic = NULL;

// Width of the bus in bytes
static int BUSW = 0;

void C_teardown_nic_connection() {
    //deinit poller_nic
    zpoller_destroy(&poller_nic);
    //deinit 0mq sockets
    zsock_destroy(&nic_req);
    zsock_destroy(&nic_resp);
    
    //NIC_DPRINTF("socket connection teardown complete.\n");
}

//DPI functions
void C_setup_nic_connection(int bus_width) {
    int port = atoi(getenv("NPU_COSIM_PORT"));
    //initialize 0mq sockets
    char buffer[50];
    sprintf(buffer, SOCK_BASE, RECV_SOCK, port + 4);
    nic_req = zsock_new_pull(buffer);     //nic request
    sprintf(buffer, SOCK_BASE, SEND_SOCK, port + 5);
    nic_resp = zsock_new_push(buffer);    //nic response
    assert(nic_req && nic_resp);
    //set up 0mq poller_nic
    poller_nic = zpoller_new(nic_req, NULL);
    assert(poller_nic);

    atexit(C_teardown_nic_connection);

    BUSW = bus_width;
    NIC_DPRINTF("Socket connection setup complete. BUSW = %d\n", BUSW);
}

void C_send_packet(int id, int size, unsigned char *data) {
    
    int rv, i;

    ACCNICData acc_data;
    //memset(&acc_data, 0, sizeof(ACCNICData));
    //Copy write data to correct location
    acc_data.id = id;
    acc_data.size = size;
    memcpy(acc_data.data, data, BUFF_SIZE);
    zframe_t *frame = zframe_new (&acc_data, sizeof(ACCNICData));
    assert(frame);
    //Send frame
    rv = zframe_send(&frame, nic_resp, 0);
    assert(rv == 0);
    NIC_DPRINTF("TX data:\n");
    // debug
    for(i = 0; i < size; i++) {
        fprintf(stderr, "%X", data[i]);
    }
    NIC_DPRINTF("  End\n");
    return;
}

void C_nic_poll(unsigned char* req, unsigned int* vlen, unsigned long* vkeep, unsigned char* vdata) {
    //Poll for a frame from qemu
    *req = 0;
    zsock_t *sock = zpoller_wait(poller_nic, 0);
    if(sock != nic_req) {
        return;
    }
    NIC_DPRINTF("RX\n");
    //qemu sent data
    zframe_t *frame = zframe_recv(nic_req);
    assert(frame);
    ACCNICData *acc_data = (ACCNICData*) zframe_data(frame);
    uint32_t size = acc_data->size;
    uint32_t align_offset = (size % BUSW);
    size = (align_offset) ? size / BUSW : size / BUSW - 1;
    uint64_t keep = (1ULL << align_offset) - 1;
    if ( ! align_offset )
        keep = ~keep;
    NIC_DPRINTF("Q->H Size: %u Len: %u Keep: %x\n", acc_data->size, size, keep);
    // Set signals
    *req = 1;
    *vlen = size;
    *vkeep = keep;
    memcpy(vdata, acc_data->data, BUFF_SIZE);
    //Clean resource
    NIC_DPRINTF("Len: %d\tKeep: %x Data:", *vlen, *vkeep);
    int i;
    for(i = 0; i < acc_data->size; i++) {
        fprintf(stderr, "%X", vdata[i]);
    }
    fprintf(stderr, "\n");
    zframe_destroy(&frame);
}
