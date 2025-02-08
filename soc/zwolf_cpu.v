/*
 * Zwölf CPU
 * Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
 *
 */

module zwolf_cpu
(

	input clk,
	input resetn,
	output reg [12:0] mem_addr,
	input [7:0] mem_rdata,
	output reg [7:0] mem_wdata,
	output reg mem_write,
	output reg mem_valid,
	input mem_ready,
	input [1:0] gpio_in,
	output reg [1:0] gpio_out,
	output reg [1:0] gpio_dir,
	input [7:0] io_rdata,
	output reg [7:0] io_wdata,
	output reg [6:0] i2c_addr,
	input ext_halt,
	input ext_reset,
	input ext_execute,
`ifdef DEV
	output [7:0] dbg
`endif

);

	parameter INIT_PC = 13'h0000;
	parameter INIT_SP = 13'h1fff;

	reg [7:0] op;
	reg [7:0] a, b;
	reg [12:0] pc;
	reg [12:0] sp;
	reg [1:0] sr;

	reg [2:0] state;
	reg run;

`ifdef DEV
	reg [15:0] delay;
	assign dbg = io_rdata;
	//assign dbg = mem_rdata;
	//assign dbg = pc[7:0];
	//assign dbg = state;
	//assign dbg = sp[7:0];
	//assign dbg = mem_rdata;
	//assign dbg = { 5'b00000, state };
`endif

	localparam [2:0]
		STATE_INIT = 3'd0,
		STATE_FETCH = 3'd1,
		STATE_LOAD = 3'd2,
		STATE_STORE = 3'd3,
		STATE_EXECUTE = 3'd4;

	wire [7:0] alu_result =
		mem_rdata[2:0] == 3'h0 ? a + b + sr[1] :
		mem_rdata[2:0] == 3'h1 ? a - b - sr[1] :
		mem_rdata[2:0] == 3'h2 ? a & b :
		mem_rdata[2:0] == 3'h3 ? a | b :
		mem_rdata[2:0] == 3'h4 ? a ^ b :
		mem_rdata[2:0] == 3'h5 ? a | 8'h80 : 8'b0;

	always @(posedge clk) begin

		delay <= delay + 1;

		if (!resetn || ext_reset) begin

			run <= 0;
			state <= STATE_INIT;
			i2c_addr <= 7'h0c;

		end else if (delay == 0) begin

			if (mem_ready) begin
				mem_valid <= 0;
				mem_write <= 0;
			end

			(* parallel_case *)
			case (state)

				STATE_INIT: begin
					state <= STATE_FETCH;
					mem_write <= 0;
					mem_valid <= 0;
					pc <= INIT_PC;
					sp <= INIT_SP;
					run <= 1;
				end

				STATE_FETCH: begin
					if (mem_ready) begin
						if (run) begin
							op <= mem_rdata;
							state <= STATE_EXECUTE;
						end
					end else if (!mem_valid) begin
						mem_addr <= pc;
						mem_valid <= 1;
					end
				end

				STATE_LOAD: begin
					if (mem_ready) begin
						a <= mem_rdata;
						state <= STATE_FETCH;
					end else if (!mem_valid) begin
						mem_addr <= sp;
						mem_valid <= 1;
					end
				end

				STATE_STORE: begin
					if (mem_ready) begin
						state <= STATE_FETCH;
					end
				end

				STATE_EXECUTE: begin

					(* parallel_case *)
					case (1'b1)

						// nop (no operation; but clear status register)
						(op == 8'h00): begin
							sr <= 0;
							state <= STATE_FETCH;
						end

						// push (push reg a onto top of stack)
						(op == 8'h01): begin
							mem_addr <= sp;
							mem_wdata <= a;
							mem_valid <= 1;
							mem_write <= 1;
							sp <= sp - 1;
							state <= STATE_STORE;
						end

						// pop (pop top of stack and place in reg a)
						(op == 8'h02): begin
							sp <= sp + 1;
							state <= STATE_LOAD;
						end

						// cp (copy stack item a into reg a)
						(op == 8'h03): begin
							mem_addr <= sp + a;
							mem_valid <= 1;
							state <= STATE_LOAD;
						end

						// swap (swap value of reg a with reg b)
						(op == 8'h04): begin
							a <= b;
							b <= a;
						end

						// alu
						(op >= 8'h10 && op <= 8'h15): begin
							a <= alu_result;
						end

						// jp (jump to address in b:a)
						(op == 8'h20): pc <= {b, a};
						(op == 8'h21): if (sr[0]) pc <= {b, a};
						(op == 8'h22): if (sr[1]) pc <= {b, a};

						// lpc (load pc)
						(op == 8'h30): begin
							{b, a} = pc;
						end

						// lio (load from i/o port)
						(op == 8'h40): begin
							if (b == 8'h10) a <= gpio_dir;
							if (b == 8'h11) a <= gpio_in;
							if (b == 8'h7f) a <= i2c_addr;
							if (b == 8'h81) a <= io_rdata;
						end

						// sio (store to i/o port)
						(op == 8'h41): begin
							if (b == 8'h10) gpio_dir <= a;
							if (b == 8'h11) gpio_out <= a;
							if (b == 8'h7f) i2c_addr <= a;
							if (b == 8'h81) io_wdata <= a;
						end

						// li (load immediate value of 0-127 into reg a)
						(op & 8'h80) == 8'h80: begin
							a <= op ^ 8'h80;
						end

					endcase

					if (op < 8'h20 || op > 8'h22) pc <= pc + 1;
					if (op > 8'h03) state <= STATE_FETCH;

				end

			endcase

		end else begin

			if (ext_halt) run <= 0;

			if (ext_execute) begin
				op = io_rdata;
				state <= STATE_EXECUTE;
			end

		end

	end

endmodule
