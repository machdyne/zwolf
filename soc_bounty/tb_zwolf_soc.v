`timescale 1ns/1ps

module tb_zwolf_soc;

    reg clk = 0;
    reg rst_n = 0;
    reg scl = 1;
    wire sda;
    reg sda_drive = 1;
    reg sda_oe = 0;
    
    wire spi_clk, spi_mosi, spi_cs_n;
    reg spi_miso = 0;

    // SDA tristate model
    assign sda = sda_oe ? sda_drive : 1'bz;
    pullup(sda);

    zwolf_soc dut (
        .clk(clk),
        .rst_n(rst_n),
        .scl(scl),
        .sda(sda),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n)
    );

    always #10 clk = ~clk; // 50MHz

    // I2C bit-bang tasks
    task i2c_start;
        begin
            sda_oe = 1; sda_drive = 1; #200;
            scl = 1; #200;
            sda_drive = 0; #200; // SDA falls while SCL high = START
            scl = 0; #200;
        end
    endtask

    task i2c_stop;
        begin
            sda_oe = 1; sda_drive = 0;
            scl = 0; #200;
            scl = 1; #200;
            sda_drive = 1; #200; // SDA rises while SCL high = STOP
            sda_oe = 0; #200;
        end
    endtask

    task i2c_write_byte;
        input [7:0] data;
        integer i;
        begin
            sda_oe = 1;
            for (i = 7; i >= 0; i = i - 1) begin
                sda_drive = data[i];
                #100;
                scl = 1; #200;
                scl = 0; #200;
            end
            // ACK clock - release SDA, read ACK from slave
            sda_oe = 0; #100;
            scl = 1; #200;
            if (sda === 0)
                $display("  ACK received");
            else
                $display("  NACK! (sda=%b)", sda);
            scl = 0; #200;
        end
    endtask

    // SPI FRAM model - simple echo/loopback
    reg [7:0] fram_mem [0:255];
    reg [7:0] fram_sr = 0;
    reg [2:0] fram_bit = 0;
    reg [2:0] fram_state = 0; // 0=CMD,1=ADDR_H,2=ADDR_L,3=DATA
    reg [7:0] fram_cmd = 0;
    reg [7:0] fram_addr = 0;
    integer fi;
    
    initial begin
        for (fi = 0; fi < 256; fi = fi + 1)
            fram_mem[fi] = 8'hA5; // default fill
    end

    always @(posedge spi_clk) begin
        if (!spi_cs_n) begin
            fram_sr <= {fram_sr[6:0], spi_mosi};
            fram_bit <= fram_bit + 1;
        end
    end

    always @(negedge spi_clk) begin
        if (!spi_cs_n && fram_state == 4) // DATA phase read
            spi_miso <= fram_mem[fram_addr][7 - fram_bit];
    end

    always @(posedge spi_cs_n) begin
        // Transaction ended
        if (fram_state == 4 && fram_cmd == 8'h02) begin
            fram_mem[fram_addr] <= fram_sr;
            $display("  FRAM WRITE: addr=0x%02x data=0x%02x", fram_addr, fram_sr);
        end
        fram_state <= 0;
        fram_bit <= 0;
    end

    always @(negedge spi_cs_n) begin
        fram_bit <= 0;
        fram_state <= 1; // expecting CMD
    end

    // Track byte boundaries in SPI
    always @(posedge spi_clk) begin
        if (!spi_cs_n && fram_bit == 7) begin
            case (fram_state)
                1: begin fram_cmd <= {fram_sr[6:0], spi_mosi}; fram_state <= 2; end
                2: begin fram_state <= 3; end // ADDR_H (ignored, always 0)
                3: begin fram_addr <= {fram_sr[6:0], spi_mosi}; fram_state <= 4; end
                4: begin end // DATA
            endcase
        end
    end

    // Main test
    initial begin
        $dumpfile("tb_zwolf_soc.vcd");
        $dumpvars(0, tb_zwolf_soc);

        // Reset
        #100;
        rst_n = 1;
        #500;

        $display("");
        $display("=== TEST 1: I2C Halt CPU ===");
        i2c_start();
        i2c_write_byte(8'h24); // addr 0x12 + W
        i2c_write_byte(8'hF3); // reg addr = 0xF3 (halt)
        i2c_write_byte(8'h01); // data = 1 (halt CPU)
        i2c_stop();
        #1000;

        $display("");
        $display("=== TEST 2: I2C Write SPI Address ===");
        i2c_start();
        i2c_write_byte(8'h24); // addr 0x12 + W
        i2c_write_byte(8'hF1); // reg addr = 0xF1 (SPI addr)
        i2c_write_byte(8'h42); // addr = 0x42
        i2c_stop();
        #1000;

        $display("");
        $display("=== TEST 3: I2C Write SPI Data ===");
        i2c_start();
        i2c_write_byte(8'h24); // addr 0x12 + W
        i2c_write_byte(8'hF0); // reg addr = 0xF0 (SPI data)
        i2c_write_byte(8'hBE); // data = 0xBE
        i2c_stop();
        #1000;

        $display("");
        $display("=== TEST 4: I2C Trigger SPI Write ===");
        i2c_start();
        i2c_write_byte(8'h24); // addr 0x12 + W
        i2c_write_byte(8'hF2); // reg addr = 0xF2 (SPI control)
        i2c_write_byte(8'h01); // rw=1 (write)
        i2c_stop();

        // Wait for SPI transaction to complete
        #50000;

        $display("");
        $display("=== TEST 5: Verify FRAM Write ===");
        if (fram_mem[8'h42] == 8'hBE)
            $display("  PASS: FRAM[0x42] = 0x%02x", fram_mem[8'h42]);
        else
            $display("  FAIL: FRAM[0x42] = 0x%02x (expected 0xBE)", fram_mem[8'h42]);

        $display("");
        $display("=== TEST 6: I2C Resume CPU ===");
        i2c_start();
        i2c_write_byte(8'h24); // addr 0x12 + W
        i2c_write_byte(8'hF3); // reg addr = 0xF3
        i2c_write_byte(8'h00); // data = 0 (resume)
        i2c_stop();
        #2000;

        // Let CPU run a few cycles
        #5000;

        $display("");
        $display("=== ALL TESTS COMPLETE ===");
        $finish;
    end

    // Timeout
    initial begin
        #500000;
        $display("TIMEOUT!");
        $finish;
    end

endmodule
