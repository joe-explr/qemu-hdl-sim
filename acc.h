#include <errno.h>
#include <czmq.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <zmq.h>

// DEVICE SPECS
#define ACC_VENDOR_ID (0x10EE)
#define ACC_DEVICE_ID (0xC951)

// BAR REGION OFFSET
//#define BAR_OFFSET_BAR0 (0x80000000U)
//#define BAR_OFFSET_BAR2 (0xC0000000U)
// Size of BAR regions
//#define REGION_SIZE_BAR0 (  2 * (1 << 20)) //   2MB
//#define REGION_SIZE_BAR2 (512 * (1 << 20)) // 512MB
// Number of MSI Interrupts
#define NUM_MSI_VEC (1)
#define ACC_NUM_MSIX_VEC (3)
#define ACC_MSIX_BAR_TABLE (0)
#define ACC_MSIX_OFFSET_TABLE (0x90000)
#define ACC_MSIX_BAR_PBA (0)
#define ACC_MSIX_OFFSET_PBA (0x91000)


#define TCP_MODE  "%stcp://127.0.0.1:%d"
#define IPC_MODE  "%sipc:///tmp/cosim-%d.sock"
#define SOCK_BASE TCP_MODE

#define SEND_SOCK "@"
#define RECV_SOCK ">"

#define PKTBUFF_SIZE (10000)
#define BUFF_SIZE (4096) /* 4K bytes buffer size */

typedef enum ACCOperations { NOOP, READ, WRITE, INTR, INIT } ACCOp;

typedef enum QEMUOperations { M_RD = 1, M_WR, S_RD } QEMUOp;

typedef struct {
  uint32_t id;               /* transaction id - unused */
  uint32_t data_size;        /* size of data sent */
  uint64_t address;          /* address on which operation was made */
  ACCOp op;                  /* type of operation */
  uint8_t bar_num;           /* bar that operation was performed on */
  unsigned char data[BUFF_SIZE]; /* data buffer */
  uint32_t vector;           /* interrupt vector */
} ACCData;

typedef struct {
  uint8_t last;
  uint32_t size;
  uint32_t id;
  unsigned char data[BUFF_SIZE]; /* Temporarily 4k max packet size */
} ACCNICData;

typedef struct {
    bool is_valid;
    uint64_t size;
    uint64_t offset;
} BARConf; 

typedef struct {
    BARConf bar[6];
    bool is_64;
    bool prefetch;
    uint16_t device_id;
    uint16_t vendor_id;
    uint16_t msix_vec_num;
    uint16_t msix_table_bar;
    uint64_t msix_table_offset;
    uint16_t msix_pba_bar;
    uint64_t msix_pba_offset;
} ACCConf;

