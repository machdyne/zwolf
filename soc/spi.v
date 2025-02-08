/*
 * Zwölf
 * Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
 *
 * SPI master interface for FRAM
 *
 */

module spi #()
(
	input [12:0] addr,
	output reg [7:0] rdata,
	input [7:0] wdata,
	output reg ready,
	input valid,
	input write,
	input clk,
	input resetn,
   output reg ss,
   output reg sck,
	output reg mosi,
	input miso,
);

	// SPI master

	reg [2:0] state;

	localparam [2:0]
		STATE_IDLE			= 4'd0,
		STATE_INIT			= 4'd1,
		STATE_START			= 4'd2,
		STATE_CMD			= 4'd3,
		STATE_ADDR			= 4'd4,
		STATE_WAIT			= 4'd5,
		STATE_XFER			= 4'd6,
		STATE_END			= 4'd7;

	reg [15:0] buffer;
	reg [3:0] xfer_bits;

	always @(posedge clk) begin

		if (!resetn) begin

			xfer_bits <= 0;
			ready <= 0;

			state <= STATE_IDLE;

		end else if (valid && !ready && state == STATE_IDLE) begin

			state <= STATE_START;
			xfer_bits <= 0;

		end else if (!valid && ready) begin

			ready <= 0;

		end else if (xfer_bits) begin

			mosi <= buffer[15];

			if (sck) begin
				sck <= 0;
			end else begin
				sck <= 1;
				buffer <= {buffer, miso};
				xfer_bits <= xfer_bits - 1;
			end

		end else case (state)

			STATE_IDLE: begin
				ss <= 1;
				sck <= 0;
			end

			STATE_START: begin
				ss <= 0;
				state <= STATE_CMD;
			end

			STATE_CMD: begin
				if (write) buffer[15:8] <= 8'h02; else buffer[15:8] <= 8'h03;
				xfer_bits <= 8;
				state <= STATE_ADDR;
			end

			STATE_ADDR: begin
				buffer <= addr;
				xfer_bits <= 16;
				state <= STATE_XFER;
			end

			STATE_XFER: begin
				if (write) begin
					buffer <= wdata;
				end
				xfer_bits <= 8;
				state <= STATE_END;
			end

			STATE_END: begin
				if (write)
					ss <= 1;
				rdata <= buffer;
				ready <= 1;
				state <= STATE_IDLE;
			end

		endcase

	end

endmodule
