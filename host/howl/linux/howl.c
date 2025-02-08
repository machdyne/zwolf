/*
 * Zwölf Howl for Linux VM
 * Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
 *
 * This lets you send commands to a Zwölf VM running on Linux.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <assert.h>
#include <zmq.h>

void show_usage(char *argv[]) {
	printf("%s: [-h] <hex_addr> <hex_reg> [hex_data]\n", argv[0]);
}

int main (int argc, char *argv[])
{

	int opt;
	uint8_t dir = 1;

	while ((opt = getopt(argc, argv, "h")) != -1) {
		switch (opt) {
			case 'h': show_usage(argv); return(0); break;
		}
	}

	if (argc - optind < 2) {
		show_usage(argv);
		return(0);
	}

	uint8_t i2c_addr = strtol(argv[optind], NULL, 16);
	uint8_t i2c_reg = strtol(argv[optind+1], NULL, 16);
	uint8_t i2c_data;
	if (argc - optind >= 3) {
		dir = 0;
		i2c_data = strtol(argv[optind+2], NULL, 16);
	}

	void *context = zmq_ctx_new ();
	void *requester = zmq_socket (context, ZMQ_REQ);
	int rc = zmq_connect (requester, "tcp://localhost:1212");
	assert(rc == 0);

	if (dir) {
		printf("reading addr: %.2x reg: %.2x\n", i2c_addr, i2c_reg);
	} else {
		printf("writing addr: %.2x reg: %.2x data: %.2x\n",
			i2c_addr, i2c_reg, i2c_data);
	}

	uint8_t buf[3];

	buf[0] = (i2c_addr << 1) | dir;
	buf[1] = i2c_reg;
	buf[2] = i2c_data;

	rc = zmq_send (requester, buf, 3, 0);
	assert(rc == 3);

	printf("receiving\n");
	zmq_recv (requester, buf, 2, 0);
	printf ("received: %.2x %.2x\n", buf[0], buf[1]);

	zmq_close (requester);
	zmq_ctx_destroy (context);
	return 0;
}
