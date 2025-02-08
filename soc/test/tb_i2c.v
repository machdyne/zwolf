`timescale 1ns / 1ns

module test_i2c ();

reg clk = 0;
reg resetn = 0;

wire [7:0] i2c_ioreg;
wire ext_halt;
wire ext_reset;
wire ext_execute;

wire tb_sda;
reg tb_scl = 0;

reg [7:0] cpu_ioreg = 8'h79;
reg [7:0] tb_read_reg;

i2c #() i2c0 (
	.clk(clk),
	.resetn(resetn),
	.scl(tb_scl),
	.sda(tb_sda),
	.i2c_addr(7'h05),
	.i2c_wdata(cpu_ioreg),
	.i2c_rdata(i2c_ioreg),
	.cpu_halt(ext_halt),
	.cpu_reset(ext_reset),
	.cpu_execute(ext_execute)
);


reg ack;

reg tb_sda_low;
assign tb_sda = (tb_sda_low) ? 1'b0 : 1'bz;
pullup(tb_sda);

always
	#1 clk = !clk;

always
	#8 tb_scl = !tb_scl;

initial
begin
	$dumpfile("output/i2c.vcd"); 
	$dumpvars(0, test_i2c);

	resetn <= 0;
	tb_sda_low <= 0;
	#2;
	resetn <= 1;
	#10;

	// i2c master write:
	tb_sda_low <= 1;			// start
	#8;
	write(8'b00001010);		// address (0x0a == 0x05 << 1 + write)
	wack();
	write(8'h80);				// register
	wack();
	write(8'h99);				// value
	wack();

	tb_sda_low <= 1;			// stop
	#24;
	tb_sda_low <= 0;			// stop

	#16;

	// i2c master read:
	tb_sda_low <= 1;			// start
	#8;
	write(8'b00001011);		// address (0x0b = 0x05 << 1 + read)
	wack();

	tb_sda_low <= 0;			// read

	read();
	wack();

	tb_sda_low <= 1;			// stop
	#24;
	tb_sda_low <= 0;			// stop

	#512 $finish;

end

task wack;
	begin
		tb_sda_low <= 0;
		ack <= 1;
		#16;
		ack <= 0;
	end
endtask

task write (reg [7:0] data);
	integer ii;
	for (ii=7; ii>=0; ii=ii-1) begin
			$display("write bit %d: %b", ii, data[ii]);
			tb_sda_low <= ~data[ii];
			#16;
	end
endtask

task read ();
	integer ii;
	for (ii=7; ii>=0; ii=ii-1) begin
			$display("read bit %d: %b", ii, tb_sda);
			tb_read_reg[ii] <= tb_sda;
			//tb_read_reg[7 - ii] <= tb_sda;
			#16;
	end
endtask

initial
   $monitor("[%t] scl: %b sda: %b ack: %b ioreg: %h",
      $time, tb_scl, tb_sda, ack, i2c_ioreg);

endmodule
