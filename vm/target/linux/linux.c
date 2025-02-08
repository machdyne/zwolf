/*
 * Zwölf Virtual Machine
 * Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
 *
 * An implementation of the Zwölf MCU for Linux.
 *
 */

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <assert.h>
#include <zmq.h>

#include "zwolf.h"
#include "target.h"

#define DELAY 100000

#define MEM_SIZE 8192

uint8_t addr;
uint8_t mem[MEM_SIZE];
uint8_t i2c_addr;
uint8_t i2c_regs[128] = { 0 };

void *zmq_ctx;
void *zmq_responder;

void i2c_check(void);

void main(int argc, char *argv[]) {

	i2c_addr = 0x0c;

	zmq_ctx = zmq_ctx_new();
	zmq_responder = zmq_socket(zmq_ctx, ZMQ_REP);
	int rc = zmq_bind(zmq_responder, "tcp://*:1212");
	assert (rc == 0);

	if (argc > 1) {
		printf("initializing memory with %s\n", argv[1]);
		FILE *f = fopen(argv[1], "rb");
		fseek(f, 0L, SEEK_END);
		int fsize = ftell(f);
		rewind(f);
		if (fsize > MEM_SIZE) fsize = MEM_SIZE;
		fread(mem, fsize, 1, f);
		fclose(f);
	}

	zw_cpu_init(0x1fff);

	while(1) {
	
		if (zw_cpu_running())
			zw_cpu_step();

		i2c_check();
		usleep(DELAY);

	}

}

void i2c_check(void) {

	uint8_t ok = 1;

	char buf[3];
	int rc = zmq_recv(zmq_responder, buf, 3, ZMQ_DONTWAIT);

	if (rc != 3) return;

	uint8_t addr = buf[0] >> 1;
	uint8_t read = (buf[0] & 0x01) == 0x01;
	uint8_t reg = buf[1];
	uint8_t val = buf[2];

	printf("received addr: %.2x read: %.2x reg: %.2x val: %.2x\n",
		addr, read, reg, val);

	if (addr != i2c_addr) ok = 0;
	if (reg < 0x80) ok = 0;

	if (ok && !read) {	// write
		printf("i2c_regs[%.2x] = %.2x\n", reg, val);
		i2c_regs[reg] = val;
		if (reg == 0x80) {
			if ((val & 0x80) == 0x80) zw_cpu_halt();
			if ((val & 0x40) == 0x40) zw_cpu_reset();
			if ((val & 0x20) == 0x20) zw_cpu_execute(i2c_regs[0x81]);
		}
	}

	buf[0] = ok;
	buf[1] = i2c_regs[reg];
	zmq_send(zmq_responder, buf, 2, 0);

}

// --

uint8_t zw_read8(uint16_t addr)
{
	if (addr < MEM_SIZE)
		return mem[addr];
	else
		return 0x00;
}

void zw_write8(uint16_t addr, uint8_t data)
{
	if (addr < MEM_SIZE)
		mem[addr] = data;
}

uint8_t zw_io_load(uint8_t port) {
	if (port == 0x10) printf(" GET GPIO DIR %.2x\n", port);
	if (port == 0x11) printf(" GET GPIO %.2x\n", port);
	else if (port >= 0x80) return i2c_regs[port ^ 0x80];
	else return 0;
}

void zw_io_store(uint8_t port, uint8_t data) {
	if (port == 0x10) printf(" SET GPIO DIR %.2x = %.2x\n", port, data);
	if (port == 0x11) printf(" SET GPIO %.2x = %.2x\n", port, data);
	if (port >= 0x80) i2c_regs[port ^ 0x80] = data;
}

void zw_putchar(char c)
{
	putchar(c);
	fflush(stdout);
}
