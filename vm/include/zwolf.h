void zw_cpu_init(uint16_t initial_sp);
void zw_cpu_reset(void);
void zw_cpu_halt(void);
int zw_cpu_running(void);
void zw_cpu_execute(uint8_t op);
void zw_cpu_run(void);
void zw_cpu_step(void);

#define ZW_SR_ZERO 1
#define ZW_SR_FLOW 2

#define ZW_OP_NOP			0x00
#define ZW_OP_PUSH		0x01
#define ZW_OP_POP			0x02
#define ZW_OP_CP			0x03
#define ZW_OP_SWAP		0x04

#define ZW_OP_ADD			0x10
#define ZW_OP_SUB			0x11
#define ZW_OP_AND			0x12
#define ZW_OP_OR			0x13
#define ZW_OP_XOR			0x14
#define ZW_OP_SH			0x15

#define ZW_OP_JP			0x20
#define ZW_OP_JZ			0x21
#define ZW_OP_JF			0x22

#define ZW_OP_LPC			0x30
#define ZW_OP_SSP			0x32

#define ZW_OP_LIO			0x40
#define ZW_OP_SIO			0x41

#define ZW_OP_LI			0x80

