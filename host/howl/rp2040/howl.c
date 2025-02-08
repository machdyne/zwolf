/*
 * Howl Firmware
 * Copyright (c) 2023 Raspberry Pi (Trading) Ltd.
 * Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <strings.h>
#include <ctype.h>


#ifdef SIM
#include <ncurses.h>
#else
#include "pico/stdlib.h"
#include "hardware/watchdog.h"
#include "hardware/i2c.h"
#include "pico/stdlib.h"
#include "pico/binary_info.h"
#endif

// GPIOs
#define HOWL_SDA		0
#define HOWL_SCL		1

#define ENABLE_PULLUPS	false // zwolf hosts usually have external pullups

#define I2C_BAUDRATE	10*1000	// 10KHz
#define I2C_TIMEOUT 	1000000	// us = 1000ms = 1s
#define BUFLEN 32

void howl_cmd(char cmd, int arg0, int arg1);
void howl_i2c_set(uint8_t addr, uint8_t reg, uint8_t val);
uint8_t howl_i2c_get(uint8_t addr);
void howl_i2c_scan(void);
void howl_parse(char *buf);

uint8_t howl_dev_addr = 0x00;

int main(void) {

#ifdef SIM
	initscr();
	noecho();
#else
	stdio_init_all();
	while (!stdio_usb_connected()) {
		sleep_ms(100);
	}
#endif

	printf("# howl initializing ...\r\n");

#ifndef SIM
	// configure I2C pins
	int baudrate = i2c_init(i2c_default, I2C_BAUDRATE);
	printf("# i2c freq %i\r\n", baudrate);
	gpio_set_function(HOWL_SDA, GPIO_FUNC_I2C);
	gpio_set_function(HOWL_SCL, GPIO_FUNC_I2C);

	// external I2C pull-ups are expected
	gpio_set_pulls(HOWL_SDA, ENABLE_PULLUPS, false);
	gpio_set_pulls(HOWL_SCL, ENABLE_PULLUPS, false);
#endif

	// parser
   char buf[BUFLEN];
   int bptr = 0;
   int c;

	bzero(buf, BUFLEN);

	// wait for commands
	while (1) {


#ifdef SIM
		c = getch();
#else
		c = getchar();
#endif

		if (c > 0) {

			if (c == 0x0a || c == 0x0d) {
				putchar(0x0a);
				putchar(0x0d);
				fflush(stdout);
				howl_parse(buf);
				bptr = 0;
				bzero(buf, BUFLEN);
				continue;
			}

			if (bptr >= BUFLEN - 1) {
				printf("# buffer overflow\r\n");
				bptr = 0;
				bzero(buf, BUFLEN);
				continue;
			}

			putchar(c);
			fflush(stdout);
			buf[bptr++] = c;

		}

	}

	return 0;

}

char last_cmd = 0;
int last_arg0, last_arg1;

void howl_parse(char *buf) {

	char *tok;
	char cmd = tolower(buf[0]);

	int arg0, arg1;
	int arg = 0;

	tok = strtok(buf, "\t ");

	while (1) {

		tok = strtok(NULL, "\t ");
		if (tok == NULL) break;
		if (arg == 0) arg0 = strtol(tok, NULL, 16);
		if (arg == 1) arg1 = strtol(tok, NULL, 16);
		++arg;

	}

	howl_cmd(cmd, arg0, arg1);

	if (cmd) {
		last_cmd = cmd;
		last_arg0 = arg0;
		last_arg1 = arg1;
	}

}

void howl_cmd(char cmd, int arg0, int arg1) {

	printf("> %c %.2x %.2x\r\n", cmd, arg0, arg1);

	if (cmd == 'd') {
		howl_dev_addr = arg0;
		printf("! [addr %.2x]\r\n", howl_dev_addr);
	} else if (cmd == 'r') {
		uint8_t v = howl_i2c_get(howl_dev_addr);
		printf("< [addr %.2x] recv %.2x\r\n", howl_dev_addr, v);
	} else if (cmd == 'w') {
		printf("> [addr %.2x reg %.2x] send %.2x\r\n", howl_dev_addr, arg0, arg1);
		howl_i2c_set(howl_dev_addr, arg0, arg1);
	} else if (cmd == 's') {
		howl_i2c_scan();
	} else if (cmd == 0x00) {
		howl_cmd(last_cmd, last_arg0, last_arg1);
	} else {
		printf("commands:\r\n");
		printf(" d <hex_i2c_addr>       set active device (00 = broadcast)\r\n");
		printf(" r                      read\r\n");
		printf(" w <hex_reg> <hex_val>  write to data register\r\n");
		printf(" s                      scan for devices\r\n");
		printf(" <enter>                repeat last command\r\n");
	}

}

void howl_i2c_scan(void) {

	printf("\nI2C Bus Scan\n");
	printf("   0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F\n");

	for (int addr = 0; addr < (1 << 7); ++addr) {
		if (addr % 16 == 0) {
			printf("%02x ", addr);
		}

		// Perform a 1-byte dummy read from the probe address. If a slave
		// acknowledges this address, the function returns the number of bytes
		// transferred. If the address byte is ignored, the function returns
		// -1.

		// Skip over any reserved addresses.
		int ret;
		uint8_t rxdata;

#ifndef SIM
		ret = i2c_read_timeout_us(i2c_default, addr, &rxdata, 1, false,
				1000);
#endif

		printf(ret < 0 ? "." : "@");
		printf(addr % 16 == 15 ? "\n" : "  ");

	}

}

void howl_i2c_set(uint8_t addr, uint8_t reg, uint8_t val) {

	int ret;
	uint8_t buf[2];

	buf[0] = reg;
	buf[1] = val;

#ifndef SIM
	ret = i2c_write_timeout_us(i2c_default, addr, buf, 2, false, I2C_TIMEOUT);
	if (ret == PICO_ERROR_TIMEOUT) printf(" timeout\r\n");
#endif

}

uint8_t howl_i2c_get(uint8_t addr) {

	int ret;
	uint8_t out[1];

	out[0] = 0x00;

#ifndef SIM
	ret = i2c_read_timeout_us(i2c_default, addr, out, 1, false, I2C_TIMEOUT);
	if (ret == PICO_ERROR_TIMEOUT) printf(" timeout\r\n");
#endif

	return out[0];

}
