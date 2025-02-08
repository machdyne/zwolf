/*
 * Zwölf
 * Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
 *
 * I2C slave interface
 *
 */

module i2c
(
	input clk,
	input resetn,
   input scl,
   inout sda,
	input [6:0] i2c_addr,
	input [7:0] i2c_wdata,
	output reg [7:0] i2c_rdata,
	output reg cpu_halt,
	output reg cpu_reset,
	output reg cpu_execute
);

	// I2C slave
	assign sda = (sda_low) ? 1'b0 : 1'bz;
	reg sda_low;

	reg scl_meta;
	reg scl_prev;
	reg sda_meta;
	reg sda_prev;
	wire scl_rise = (scl_meta && !scl_prev);
	wire scl_fall = (!scl_meta && scl_prev);
	wire sda_rise = (sda_meta && !sda_prev);
	wire sda_fall = (!sda_meta && sda_prev);

	wire i2c_addr_match =
		((i2c_sr[7:1] == 0) || (i2c_addr == i2c_sr[7:1]));

	reg [7:0] i2c_sr;
	reg [3:0] i2c_bits;
	reg i2c_read;
	reg [7:0] i2c_reg;
	reg [1:0] i2c_phase;
	reg i2c_addr_ok;
	reg i2c_start;

	always @(posedge clk or negedge resetn) begin

		cpu_halt <= 0;
		cpu_reset <= 0;
		cpu_execute <= 0;

		if (!resetn) begin

			i2c_read <= 0;
			i2c_start <= 0;
			i2c_phase <= 0;
			i2c_bits <= 0;
			sda_low <= 0;
			sda_meta <= 0;
			scl_meta <= 0;
			sda_prev <= 0;
			scl_prev <= 0;

		end else begin

			scl_meta <= scl;
			scl_prev <= scl_meta;
			sda_meta <= sda;
			sda_prev <= sda_meta;

			if (scl_meta && sda_fall) begin	// start
				i2c_addr_ok <= 0;
				i2c_start <= 1;
				i2c_bits <= 0;
				i2c_phase <= 0;
				i2c_read <= 0;
			end

			if (scl_meta && sda_rise) begin	// stop
				i2c_start <= 0;
				i2c_phase <= 0;
			end

			if (i2c_start && scl_rise && !i2c_read) begin
				i2c_sr <= { i2c_sr[6:0], sda_meta };
			end

			if (i2c_start && scl_fall) begin

				sda_low <= 0;

				if (i2c_addr_ok && i2c_read && i2c_phase == 1) begin
					if (i2c_bits == 8) begin
						sda_low <= 0;	// nack
					end else begin
						sda_low <= ~i2c_wdata[7 - i2c_bits];
					end
				end

				i2c_bits <= i2c_bits + 1;

				if (i2c_bits == 8) begin

					i2c_bits <= 0;
					i2c_phase <= i2c_phase + 1;

					case (i2c_phase)
						0: begin
							if	(i2c_addr_match) begin
								i2c_addr_ok <= 1;
								sda_low <= 1;	// ack
							end
							i2c_read <= i2c_sr[0];
						end
						1: begin
							if (i2c_addr_ok && !i2c_read) begin
								i2c_reg <= i2c_sr;
								sda_low <= 1;	// ack
							end
						end
						2: begin
							if (i2c_addr_ok && !i2c_read) begin
								if (i2c_reg == 8'h80) begin
									if (i2c_sr[7]) cpu_halt <= 1;
									if (i2c_sr[6]) cpu_reset <= 1;
									if (i2c_sr[5]) cpu_execute <= 1;
								end else begin
									i2c_rdata <= i2c_sr;
								end
								sda_low <= 1;	// ack
							end
						end
					endcase

				end

			end
		end
	end

endmodule
