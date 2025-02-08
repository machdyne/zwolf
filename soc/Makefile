YOSYS=/usr/local/bin/yosys
NEXTPNR=/usr/local/bin/nextpnr-ice40

RTL=zwolf_mcu.v zwolf_cpu.v spi.v i2c.v
RTL_DEV=zwolf_mcu.v zwolf_cpu.v spi.v i2c.v bsram.v

zwolf_ls2:
	mkdir -p output
	yosys -q -p "synth_ice40 -abc2 -top zwolf_mcu -json output/soc.json" $(RTL)
	nextpnr-ice40 --lp384 --package qn32 --pcf boards/ls2.pcf \
		--asc output/soc.txt --json output/soc.json --pre-pack constraints.py \
		--pcf-allow-unconstrained --opt-timing --placer-heap-cell-placement-timeout 0
	icebox_explain output/soc.txt > output/soc.ex
	icetime -d lp384 -c 48 -mtr output/soc.rpt output/soc.txt
	icepack output/soc.txt output/soc.bin

zwolf_obst:
	mkdir -p output
	yosys -q -DBSRAM -DDEV -DFPGA_ECP5 -p "synth_ecp5 -top zwolf_mcu -json output/blinky_obst.json" $(RTL_DEV)
	nextpnr-ecp5 --12k --package CABGA256 --lpf boards/obst_v0.lpf --json output/blinky_obst.json --textcfg output/obst_blinky_out.config --lpf-allow-unconstrained
	ecppack -v --compress --freq 2.4 output/obst_blinky_out.config --bit output/obst.bit

zwolf_krote:
	mkdir -p output
	yosys -q -p "synth_ice40 -top mysoc -json output/soc.json" $(RTL)
	nextpnr-ice40 --hx4k --package bg121 --pcf boards/krote.pcf \
		--asc output/soc.txt --json output/soc.json --pre-pack constraints.py \
		--pcf-allow-unconstrained --opt-timing
	icebox_explain output/soc.txt > output/soc.ex
	#icetime -d hx4k -c 50 -mtr output/soc.rpt output/soc.txt
	icepack output/soc.txt output/soc.bin

zwolf_winzig:
	mkdir -p output
	yosys -q -p "synth_ice40 -top mysoc -json output/soc.json" $(RTL)
	nextpnr-ice40 --lp384 --package qn32 --pcf boards/winzig.pcf \
		--asc output/soc.txt --json output/soc.json --pre-pack constraints.py \
		--pcf-allow-unconstrained --opt-timing
	icebox_explain output/soc.txt > output/soc.ex
	icetime -d lp384 -c 50 -mtr output/soc.rpt output/soc.txt
	icepack output/soc.txt output/soc.bin

test_i2c:
	iverilog -g2005-sv -DTESTBENCH -v -o output/test_i2c i2c.v test/tb_i2c.v
	vvp output/test_i2c -lxt2

prog_ls2:
	ldprog -s output/soc.bin

prog_obst:
	openFPGALoader -c usb-blaster output/obst.bit

clean:
	rm -f output/*
	cd firmware && make clean

.PHONY: firmware prog clean test
