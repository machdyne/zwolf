/*
 * Zwölf Virtual Machine
 * Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
 *
 * An implementation of the Zwölf CPU written in C.
 *
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include "zwolf.h"
#include "target.h"

// registers
uint8_t a, b;
uint16_t pc;
uint16_t sp;
uint16_t spr;
uint8_t sr;
uint8_t run;

// temp registers
uint16_t ba;
uint8_t t;

uint8_t zw_debug = 1;

void zw_cpu_init(uint16_t initial_sp) {

	pc = 0;
	sp = spr = initial_sp;
	run = 1;

}

void zw_cpu_reset(void) {
	if (zw_debug) printf("zw_cpu_reset\n");
	zw_cpu_init(spr);
}

void zw_cpu_halt(void) {
	if (zw_debug) printf("zw_cpu_halt\n");
	run = 0;
}

int zw_cpu_running(void) {
	return run;
}

void zw_cpu_run(void) {

	while(1) {
		if (run) {
			zw_cpu_step();
		}
	}

}

void zw_cpu_step(void) {
	uint8_t op;
	op = zw_read8(pc);
	zw_cpu_execute(op);
}

void zw_cpu_execute(uint8_t op) {

	if (zw_debug)
		printf("zw_cpu_execute [pc:%4x sp:%4x a: %2x b: %2x] op: %2x\n",
			pc, sp, a, b, op);

	// NOP (clears SR)
	if (op == ZW_OP_NOP) {

		sr = 0;
		++pc;

	// PUSH (push reg a onto top of stack)
	} else if (op == ZW_OP_PUSH) {

		zw_write8(--sp, a);
		++pc;

	// POP (pop top of stack and place in reg a)
	} else if (op == ZW_OP_POP) {

		a = zw_read8(sp++);
		++pc;

	// CP (copy stack item a into reg a) (aka DUPN)
	} else if (op == ZW_OP_CP) {

		a = zw_read8(sp + a);
		++pc;

	// SWAP (swap values of reg a and reg b)
	} else if (op == ZW_OP_SWAP) {

		t = a;
		a = b;
		b = t;
		++pc;

	// LPC (load program counter)
	} else if (op == ZW_OP_LPC) {

		b = (pc >> 8) & 0xff; a = (pc & 0xff);
		++pc;

	// LIO
	} else if (op == ZW_OP_LIO) {

		a = zw_io_load(b);
		++pc;

	// SIO
	} else if (op == ZW_OP_SIO) {

		zw_io_store(b, a);
		++pc;

	// SSP (set stack pointer to b:a)
	} else if (op == ZW_OP_SSP) {

		sp = ((b << 8) & 0xff00) | (a & 0xff);
		++pc;

	// LI (load immediate lower 7 bits into reg a)
	} else if ((op & 0x80) == 0x80) {

		a = op ^ 0x80;
		++pc;

	// JP
	} else if ((op & 0x20) == 0x20) {

		t = 0;

		switch (op) {
			case (ZW_OP_JP): t = 1; break;
			case (ZW_OP_JZ): if ((sr & ZW_SR_ZERO) == ZW_SR_ZERO) t = 1; break;
			case (ZW_OP_JF): if ((sr & ZW_SR_FLOW) == ZW_SR_FLOW) t = 1; break;
		}

		if (t)
			pc = (b << 8) + a;
		else
			++pc;

	// ALU
	} else if ((op & 0x10) == 0x10) {

		uint8_t f = ((sr & ZW_SR_FLOW) == ZW_SR_FLOW) ? 1 : 0;

		switch (op) {

			case(ZW_OP_ADD):
				a = a + b + f; if (b > 0xff) sr |= ZW_SR_FLOW; break;
			case(ZW_OP_SUB):
				a = a - b - f; if (b > a) sr |= ZW_SR_FLOW; break;
			case(ZW_OP_AND): a = a & b; break;
			case(ZW_OP_OR): a = a | b; break;
			case(ZW_OP_XOR): a = a ^ b; break;
			case(ZW_OP_SH): a = a | 0x80; break;

		}

		if (a == 0) sr |= ZW_SR_ZERO;

		++pc;

	}

}
