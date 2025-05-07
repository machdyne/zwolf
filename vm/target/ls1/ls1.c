/*
 * Zwölf LS1 Firmware
 * Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
 *
 */

#include <stdio.h>
#include <stdint.h>

#include "ch32v003fun.h"
#include "i2c_slave.h"

#define CH32V003_SPI_IMPLEMENTATION
#define CH32V003_SPI_NSS_SOFTWARE_ANY_MANUAL
#define CH32V003_SPI_SPEED_HZ 1000000
#define CH32V003_SPI_DIRECTION_2LINE_TXRX
#define CH32V003_SPI_CLK_MODE_POL0_PHA0

#include "ch32v003_SPI.h"

#include "../../include/zwolf.h"
#include "../../include/target.h"
#include "ls1.h"

volatile uint8_t sram[1024];
volatile uint8_t i2c_addr;
volatile uint8_t i2c_regs[255] = {0x00};

void i2c_onWrite(uint8_t reg, uint8_t length);
void i2c_onRead(uint8_t reg);

uint8_t fram_read(int addr);
void fram_write(int addr, unsigned char d);
void fram_write_enable(void);

int main()
{
   SystemInit();
   funGpioInitAll();

	// set up SPI master interface for FRAM
   SPI_init();
   SPI_begin_8();

   (SPI_SS_PORT)->CFGLR &= ~(0xf<<(4*SPI_SS));
   (SPI_SS_PORT)->CFGLR |= (GPIO_Speed_10MHz | GPIO_CNF_OUT_PP)<<(4*SPI_SS);

	// set SS high
	(SPI_SS_PORT)->BSHR = (1<<SPI_SS);

	// default address; user code can set this with SIO
	i2c_addr = 0x0c;

   // configure I2C slave
	funPinMode(PC1, GPIO_CFGLR_OUT_10Mhz_AF_OD); // SDA
	funPinMode(PC2, GPIO_CFGLR_OUT_10Mhz_AF_OD); // SCL

	SetupI2CSlave(i2c_addr, i2c_regs, sizeof(i2c_regs),
		i2c_onWrite, i2c_onRead, false);

	Delay_Ms(250);

	// init zwolf CPU; stack pointer is end of SRAM
	zw_cpu_init(0x23ff);

	// main loop
	zw_cpu_run();

};

uint8_t fram_read(int addr) {

	(SPI_SS_PORT)->BSHR = (1<<(16+SPI_SS));

	SPI_transfer_8(0x03);   // READ

	SPI_transfer_8((addr >> 8) & 0xff);
	SPI_transfer_8(addr & 0xff);

	uint8_t d = SPI_transfer_8(0x00);

	(SPI_SS_PORT)->BSHR = (1<<SPI_SS);

	return(d);

}

void fram_write_enable(void) {

	(SPI_SS_PORT)->BSHR = (1<<(16+SPI_SS));
   SPI_transfer_8(0x06);   // WREN
	(SPI_SS_PORT)->BSHR = (1<<SPI_SS);

}

void fram_write(int addr, unsigned char d) {

   fram_write_enable(); // auto-disabled after each write

	(SPI_SS_PORT)->BSHR = (1<<(16+SPI_SS));

   SPI_transfer_8(0x02);   // WRITE
   SPI_transfer_8((addr >> 8) & 0xff);
   SPI_transfer_8(addr & 0xff);
   SPI_transfer_8(d);

	(SPI_SS_PORT)->BSHR = (1<<SPI_SS);

}

void i2c_onWrite(uint8_t reg, uint8_t length) {

	uint8_t val = i2c_regs[reg];

//	printf("i2c_onWrite reg: %x len: %x val: %x\n\r", reg, length, val);

   if (reg == 0x80) {
		if ((val & 0x80) == 0x80) zw_cpu_halt();
		if ((val & 0x40) == 0x40) zw_cpu_reset();
		if ((val & 0x20) == 0x20) zw_cpu_execute(i2c_regs[0x81]);
   }

}

void i2c_onRead(uint8_t reg) {

	uint8_t val = i2c_regs[reg];
//	printf("i2c_onRead reg: %x val: %x\n\r", reg, val);

}

// --

uint8_t zw_read8(uint16_t addr)
{

	// external FRAM
	if (addr >= 0x0000 && addr <= 0x1fff)
		return fram_read(addr);

	// internal SRAM
	else if (addr >= 0x2000 && addr <= 0x23ff) 
		return sram[addr ^ 0x2000];

	else return 0x00;

}

void zw_write8(uint16_t addr, uint8_t data)
{

	// external FRAM
	if (addr >= 0x0000 && addr <= 0x2000)
		fram_write(addr, data);

	// internal SRAM
	else if (addr >= 0x2000 && addr <= 0x23ff) 
		sram[addr ^ 0x2000] = data;

}

uint8_t zw_gpio_read8(uint8_t port)
{
	return 0x00;
}

void zw_gpio_write8(uint8_t port, uint8_t data)
{
}

uint8_t zw_io_load(uint8_t port) {

   if (port == 0x11) {

		uint8_t val;

		printf(" GET GPIO %2x\n", port);

		val |= 7 << (ZW_GPIOH_PORT)->INDR & (1 << (ZW_GPIOH & 0xf));
		val |= 6 << (ZW_GPIOG_PORT)->INDR & (1 << (ZW_GPIOG & 0xf));
		val |= 5 << (ZW_GPIOF_PORT)->INDR & (1 << (ZW_GPIOF & 0xf));
		val |= 4 << (ZW_GPIOE_PORT)->INDR & (1 << (ZW_GPIOE & 0xf));
		val |= 3 << (ZW_GPIOD_PORT)->INDR & (1 << (ZW_GPIOD & 0xf));
		val |= 2 << (ZW_GPIOC_PORT)->INDR & (1 << (ZW_GPIOC & 0xf));
		// GPIOA and GPIOB are only used for the global I2C bus on this target

   } else if (port >= 0x80) {

		return i2c_regs[port];

	}
   return 0; 
}

void zw_io_store(uint8_t port, uint8_t data) {

   if (port == 0x10) {

		printf(" SET GPIO DIR %2x = %2x\n", port, data);

		if ((data & 0x80) == 0x80)
			(ZW_GPIOH_PORT)->CFGLR |= (GPIO_Speed_10MHz | GPIO_CNF_OUT_PP)<<(4*ZW_GPIOH);
		else
			(ZW_GPIOH_PORT)->CFGLR |= (GPIO_Speed_10MHz | GPIO_CNF_IN_FLOATING)<<(4*ZW_GPIOH);

		if ((data & 0x40) == 0x40)
			(ZW_GPIOG_PORT)->CFGLR |= (GPIO_Speed_10MHz | GPIO_CNF_OUT_PP)<<(4*ZW_GPIOG);
		else
			(ZW_GPIOG_PORT)->CFGLR |= (GPIO_Speed_10MHz | GPIO_CNF_IN_FLOATING)<<(4*ZW_GPIOG);

		// TODO: support GPIOC to GPIOH


   } if (port == 0x11) {

		printf(" SET GPIO %2x = %2x\n", port, data);

		if ((data & 0x80) == 0x80)
			(ZW_GPIOH_PORT)->BSHR = (1 << ZW_GPIOH);
		else
			(ZW_GPIOH_PORT)->BSHR = (1 << (16 + ZW_GPIOH));

		if ((data & 0x40) == 0x40)
			(ZW_GPIOG_PORT)->BSHR = (1 << ZW_GPIOG);
		else
			(ZW_GPIOG_PORT)->BSHR = (1 << (16 + ZW_GPIOG));

		// TODO: support GPIOC to GPIOH

	} if (port >= 0x80) {
		i2c_regs[port] = data;
	}

}

int zw_getchar() {
	return -1;
}

void zw_putchar(char c)
{
	putchar(c);
}
