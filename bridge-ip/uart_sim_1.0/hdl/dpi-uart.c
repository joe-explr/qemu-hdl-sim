#ifdef __cplusplus
#define DPI_LINKER_DECL  extern "C"
#else
#define DPI_LINKER_DECL
#endif

#include "acc.h"

#if 1
    #define UART_DPRINTF(fmt, ...)                                          \
    do {                                                                    \
        fprintf(stderr, "UART: " fmt, ##__VA_ARGS__);                       \
    } while (0)
#else
    #define UART_DPRINTF(fmt, ...)
#endif

DPI_LINKER_DECL void C_uart_poll(unsigned char* data_available);
DPI_LINKER_DECL void C_uart_rx(unsigned int* c);
DPI_LINKER_DECL void C_uart_tx(unsigned int c);
DPI_LINKER_DECL void C_setup_uart_connection();

zsock_t *uart_rx = NULL;
zsock_t *uart_tx = NULL;
zpoller_t *poller_uart = NULL;

void C_teardown_uart_connection() {
    //deinit poller_uart
    zpoller_destroy(&poller_uart);
    //deinit 0mq sockets
    zsock_destroy(&uart_rx);
    zsock_destroy(&uart_tx);
    
    UART_DPRINTF("socket connection teardown complete.\n");
}

//DPI functions
void C_setup_uart_connection() {
    int port = atoi(getenv("NPU_COSIM_PORT"));
    //initialize 0mq sockets
    char buffer[50];
    sprintf(buffer, SOCK_BASE, RECV_SOCK, port + 8);
    uart_rx = zsock_new_pull(buffer);     //uart receive
    memset(buffer, 0, 50);
    sprintf(buffer, SOCK_BASE, SEND_SOCK, port + 9);
    uart_tx = zsock_new_push(buffer);     //uart transmit
    assert(uart_rx && uart_tx);
    //set up 0mq poller_uart
    poller_uart = zpoller_new(uart_rx, NULL);
    assert(poller_uart);

    atexit(C_teardown_uart_connection);

    UART_DPRINTF("socket connection setup complete.\n");
}

void C_uart_poll(unsigned char* data_available) {
    zsock_t *sock = zpoller_wait(poller_uart, 0);
    *data_available = (sock == NULL);
}

void C_uart_rx(unsigned int* c) {
    zsock_t *sock = zpoller_wait(poller_uart, 0);
    if (sock == NULL) {
        return;
    }
    zframe_t *frame = zframe_recv(uart_rx);
    *c = *(unsigned int*) zframe_data(frame);
    zframe_destroy(&frame);
}

void C_uart_tx(unsigned int data) {
    char c = (char)data;
    UART_DPRINTF("sending: %02x\t%c\n", data, c);
    zsock_t *frame = zframe_new(&c, sizeof(char));
    zframe_send(&frame, uart_tx, 0);
}
