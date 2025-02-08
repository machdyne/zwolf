/*
 * Zwölf
 * Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
 *
 * 64K BRAM
 *
 */

module bsram #()
(
	input clk,
	input resetn,
	input [15:0] addr,
	output reg [7:0] rdata,
	input [7:0] wdata,
	input valid,
	input write,
	output reg ready
);

	reg [7:0] bsram [0:65535];
   initial $readmemh("../output/counter.bin.hex", bsram);

	always @(posedge clk) begin

		if (!valid)
			ready <= 0;
		else begin
			if (write)
				bsram[addr] <= wdata;
			else
				rdata <= bsram[addr];
			ready <= 1;
		end

	end

endmodule
