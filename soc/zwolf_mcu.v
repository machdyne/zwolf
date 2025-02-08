/*
 * Zwölf MCU
 * Copyright (c) 2024 Lone Dynamics Corporation. All rights reserved.
 *
 */

module zwolf_mcu #()
(

	input CLK_48,

	input GPIOA,	// scl
	inout GPIOB,	// sda
	inout GPIOC,
	inout GPIOD,

`ifndef BSRAM
   output SPI_SS_RAM,
`ifndef FPGA_ECP5
   output SPI_SCK,
`endif
   input SPI_MISO,
   output SPI_MOSI,
`endif

);

   reg [1:0] resetn_counter = 0;
   wire resetn = &resetn_counter;

   always @(posedge clk) begin
      if (!resetn)
         resetn_counter <= resetn_counter + 1;
   end

	wire clk = CLK_48;

`ifndef BSRAM
`ifdef FPGA_ECP5
   wire SPI_SCK;
   USRMCLK usrmclk0 (.USRMCLKI(SPI_SCK), .USRMCLKTS(1'b0));
`endif
`endif

	// I2C
	wire [6:0] i2c_addr;

	// GPIO
	wire [1:0] cpu_gpio_dir;
	wire [1:0] cpu_gpio_out;

   assign {GPIOD, GPIOC} = cpu_gpio_dir ? cpu_gpio_out : 2'bz;

	// CPU
	wire [12:0] mem_addr;
	wire [7:0] mem_wdata;
	wire [7:0] mem_rdata;
	wire [7:0] cpu_ioreg;

	wire mem_write;
	wire mem_valid;
	wire mem_ready;

	wire ext_halt;
	wire ext_reset;
	wire ext_execute;

	zwolf_cpu #() zwolf_cpu0 (
		.clk(clk),
		.resetn(resetn),
		.mem_addr(mem_addr),		// cpu wants to do something with this address
		.mem_rdata(mem_rdata),	// cpu wants to read into this from memory
		.mem_wdata(mem_wdata),	// cpu wants to write this to memory
		.mem_write(mem_write),	// cpu wants to write (otherwise it wants to read)
		.mem_valid(mem_valid),	// cpu address is valid
		.mem_ready(mem_ready),	// let the cpu know that the memory is ready
		.io_rdata(i2c_ioreg),
		.io_wdata(cpu_ioreg),
		.i2c_addr(i2c_addr),
		.ext_halt(ext_halt),
		.ext_reset(ext_reset),
		.ext_execute(ext_execute),
		.gpio_in({GPIOD, GPIOC}),
		.gpio_out(cpu_gpio_out),
		.gpio_dir(cpu_gpio_dir),
	);

	// MEMORY

`ifdef BSRAM
   bsram #() bsram_i (
		.clk(clk),
		.resetn(resetn),
		.addr(mem_addr),
		.wdata(mem_wdata),
		.rdata(mem_rdata),
		.valid(mem_valid),
		.ready(mem_ready),
		.write(mem_write)
	);
`else
	wire ss;
	assign SPI_SS_RAM = ~ss;	// XXX: fram on obst mmod is active high
   spi #() spi0 (
		.clk(clk),
		.resetn(resetn),
		.addr(mem_addr),
		.wdata(mem_wdata),
		.rdata(mem_rdata),
		.valid(mem_valid),
		.ready(mem_ready),
		.write(mem_write),
		.ss(ss),
		.sck(SPI_SCK),
		.mosi(SPI_MOSI),
		.miso(SPI_MISO),
	);
`endif

	wire [7:0] i2c_ioreg;
   i2c #() i2c0 (
		.clk(clk),
		.resetn(resetn),
		.scl(GPIOA),
		.sda(GPIOB),
		.i2c_addr(i2c_addr),
		.i2c_wdata(cpu_ioreg),
		.i2c_rdata(i2c_ioreg),
		.cpu_halt(ext_halt),
		.cpu_reset(ext_reset),
		.cpu_execute(ext_execute),
	);

endmodule
