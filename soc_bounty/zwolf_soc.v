module zwolf_soc (
    input wire clk,
    input wire rst_n,
    input wire scl,
    inout wire sda,
    output wire spi_clk,
    output wire spi_mosi,
    input wire spi_miso,
    output wire spi_cs_n
);

    wire [7:0] cpu_addr, cpu_wdata, cpu_rdata;
    wire cpu_we;
    wire [7:0] i2c_addr, i2c_wdata;
    wire i2c_we;
    wire [7:0] spi_rdata;
    wire spi_busy;

    reg cpu_halt;
    reg spi_rw;
    reg [7:0] spi_a, spi_d;

    wire act_we = cpu_halt ? i2c_we : cpu_we;
    wire [7:0] act_addr = cpu_halt ? i2c_addr : cpu_addr;
    wire [7:0] act_wdata = cpu_halt ? i2c_wdata : cpu_wdata;

    wire spi_start = act_we && (act_addr == 8'hF2);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_halt <= 0; spi_rw <= 0;
            spi_a <= 0; spi_d <= 0;
        end else begin
            if (act_we) case (act_addr)
                8'hF0: spi_d <= act_wdata;
                8'hF1: spi_a <= act_wdata;
                8'hF2: spi_rw <= act_wdata[0];
                8'hF3: cpu_halt <= act_wdata[0];
                default: ;
            endcase
        end
    end

    wire [7:0] rmux = (act_addr == 8'hF0) ? spi_rdata :
                      (act_addr == 8'hF2) ? {7'd0, spi_busy} : 8'd0;
    assign cpu_rdata = rmux;

    zwolf_cpu u_cpu (
        .clk(clk), .rst_n(rst_n), .halt(cpu_halt),
        .addr(cpu_addr), .wdata(cpu_wdata),
        .rdata(cpu_rdata), .we(cpu_we)
    );

    zwolf_spi u_spi (
        .clk(clk), .rst_n(rst_n),
        .start(spi_start), .rw(spi_rw),
        .addr(spi_a), .wdata(spi_d),
        .rdata(spi_rdata), .busy(spi_busy),
        .sck(spi_clk), .mosi(spi_mosi),
        .miso(spi_miso), .cs_n(spi_cs_n)
    );

    zwolf_i2c u_i2c (
        .clk(clk), .rst_n(rst_n),
        .scl(scl), .sda(sda),
        .reg_addr(i2c_addr), .reg_wdata(i2c_wdata),
        .reg_we(i2c_we)
    );

endmodule


module zwolf_cpu (
    input wire clk,
    input wire rst_n,
    input wire halt,
    output reg [7:0] addr,
    output wire [7:0] wdata,
    input wire [7:0] rdata,
    output wire we
);

    localparam F0 = 3'd0;
    localparam F1 = 3'd1;
    localparam EX = 3'd2;
    localparam F2 = 3'd3;
    localparam W2 = 3'd4;
    localparam MR = 3'd5;

    reg [2:0] state;
    reg [7:0] pc, ra, rb;
    reg zf;
    reg [3:0] op;
    reg rd, rs;

    wire [7:0] rdv = rd ? rb : ra;
    wire [7:0] rsv = rs ? rb : ra;

    assign wdata = rsv;
    assign we = (state == EX && op == 4'h3);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= F0; pc <= 0; ra <= 0; rb <= 0;
            zf <= 0; op <= 0; rd <= 0; rs <= 0; addr <= 0;
        end else if (halt) begin
            state <= F0;
        end else begin
            case (state)
                F0: begin addr <= pc; state <= F1; end

                F1: begin
                    op <= rdata[7:4];
                    rd <= rdata[3];
                    rs <= rdata[2];
                    pc <= pc + 8'd1;
                    if (rdata[7:4] == 4'h1 ||
                        rdata[7:4] == 4'h9 ||
                        rdata[7:4] == 4'hA ||
                        rdata[7:4] == 4'hB)
                        state <= F2;
                    else
                        state <= EX;
                end

                EX: begin
                    case (op)
                        4'h0: ;
                        4'h2: begin addr <= rsv; state <= MR; end
                        4'h3: addr <= rdv;
                        4'h4: begin
                            if (rd) rb <= rdv + rsv; else ra <= rdv + rsv;
                            zf <= ((rdv + rsv) == 0);
                        end
                        4'h5: begin
                            if (rd) rb <= rdv - rsv; else ra <= rdv - rsv;
                            zf <= ((rdv - rsv) == 0);
                        end
                        4'h6: begin
                            if (rd) rb <= rdv & rsv; else ra <= rdv & rsv;
                            zf <= ((rdv & rsv) == 0);
                        end
                        4'h7: begin
                            if (rd) rb <= rdv | rsv; else ra <= rdv | rsv;
                            zf <= ((rdv | rsv) == 0);
                        end
                        4'h8: begin
                            if (rd) rb <= rdv ^ rsv; else ra <= rdv ^ rsv;
                            zf <= ((rdv ^ rsv) == 0);
                        end
                        4'hF: ;
                        default: ;
                    endcase
                    if (op != 4'h2) state <= F0;
                end

                F2: begin addr <= pc; state <= W2; end

                W2: begin
                    pc <= pc + 8'd1;
                    case (op)
                        4'h1: begin
                            if (rd) rb <= rdata; else ra <= rdata;
                            zf <= (rdata == 0);
                        end
                        4'h9: pc <= rdata;
                        4'hA: if (zf) pc <= rdata;
                        4'hB: if (!zf) pc <= rdata;
                        default: ;
                    endcase
                    state <= F0;
                end

                MR: begin
                    if (rd) rb <= rdata; else ra <= rdata;
                    zf <= (rdata == 0);
                    state <= F0;
                end

                default: state <= F0;
            endcase
        end
    end
endmodule


module zwolf_spi (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire rw,
    input wire [7:0] addr,
    input wire [7:0] wdata,
    output wire [7:0] rdata,
    input wire miso,
    output reg busy,
    output reg sck,
    output reg mosi,
    output reg cs_n
);

    localparam IDLE  = 2'd0;
    localparam SHIFT = 2'd1;
    localparam NEXT  = 2'd2;
    localparam GAP   = 2'd3;

    reg [1:0] state;
    reg [2:0] bcnt;
    reg [7:0] sr;
    reg ph;
    reg [2:0] bphase;

    assign rdata = sr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; busy <= 0; sck <= 0; mosi <= 0;
            cs_n <= 1; bcnt <= 0; sr <= 0;
            ph <= 0; bphase <= 0;
        end else begin
            case (state)
                IDLE: begin
                    cs_n <= 1; sck <= 0;
                    if (start && !busy) begin
                        busy <= 1;
                        cs_n <= 0; bcnt <= 7; ph <= 0;
                        if (rw) begin
                            sr <= 8'h06; bphase <= 0;
                        end else begin
                            sr <= 8'h03; bphase <= 1;
                        end
                        state <= SHIFT;
                    end
                end

                SHIFT: begin
                    if (!ph) begin
                        mosi <= sr[7]; sck <= 0; ph <= 1;
                    end else begin
                        sck <= 1;
                        sr <= {sr[6:0], miso};
                        if (bcnt == 0) begin
                            sck <= 0; state <= NEXT;
                        end else begin
                            bcnt <= bcnt - 3'd1; ph <= 0;
                        end
                    end
                end

                NEXT: begin
                    ph <= 0; bcnt <= 7;
                    case (bphase)
                        3'd0: begin
                            cs_n <= 1; sr <= 8'h02; bphase <= 1;
                            state <= GAP;
                        end
                        3'd1: begin sr <= 8'h00; bphase <= 2; state <= SHIFT; end
                        3'd2: begin sr <= addr; bphase <= 3; state <= SHIFT; end
                        3'd3: begin sr <= rw ? wdata : 8'd0; bphase <= 4; state <= SHIFT; end
                        3'd4: begin
                            cs_n <= 1; sck <= 0; busy <= 0;
                            state <= IDLE;
                        end
                        default: state <= IDLE;
                    endcase
                end

                GAP: begin cs_n <= 0; sck <= 0; state <= SHIFT; end
            endcase
        end
    end
endmodule


module zwolf_i2c (
    input wire clk,
    input wire rst_n,
    input wire scl,
    inout wire sda,
    output reg [7:0] reg_addr,
    output reg [7:0] reg_wdata,
    output reg reg_we
);

    parameter I2C_ADDR = 7'h12;

    reg sda_oe;
    assign sda = sda_oe ? 1'b0 : 1'bz;

    reg [1:0] scl_sync, sda_sync;
    wire scl_s = scl_sync[1];
    wire sda_s = sda_sync[1];

    reg scl_prev, sda_prev;
    wire scl_rise = scl_s & ~scl_prev;
    wire scl_fall = ~scl_s & scl_prev;
    wire start_cond = scl_s & sda_prev & ~sda_s;
    wire stop_cond = scl_s & ~sda_prev & sda_s;

    localparam ST_IDLE    = 3'd0;
    localparam ST_DEVADDR = 3'd1;
    localparam ST_DEVACK  = 3'd2;
    localparam ST_RX      = 3'd3;
    localparam ST_DATACK  = 3'd4;

    reg [2:0] state;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    reg first_byte;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_sync <= 2'b11; sda_sync <= 2'b11;
            scl_prev <= 1; sda_prev <= 1;
            state <= ST_IDLE; sda_oe <= 0;
            reg_we <= 0; reg_addr <= 0; reg_wdata <= 0;
            shift_reg <= 0; bit_cnt <= 0;
            first_byte <= 1;
        end else begin
            scl_sync <= {scl_sync[0], scl};
            sda_sync <= {sda_sync[0], sda};
            scl_prev <= scl_s;
            sda_prev <= sda_s;
            reg_we <= 0;

            if (stop_cond) begin
                state <= ST_IDLE; sda_oe <= 0; first_byte <= 1;
            end else if (start_cond) begin
                state <= ST_DEVADDR; bit_cnt <= 7; sda_oe <= 0;
            end else begin
                case (state)
                    ST_IDLE: sda_oe <= 0;

                    ST_DEVADDR: if (scl_rise) begin
                        shift_reg <= {shift_reg[6:0], sda_s};
                        if (bit_cnt == 0) state <= ST_DEVACK;
                        else bit_cnt <= bit_cnt - 3'd1;
                    end

                    ST_DEVACK: if (scl_fall) begin
                        if (shift_reg[7:1] == I2C_ADDR && !shift_reg[0]) begin
                            sda_oe <= 1;
                            bit_cnt <= 7;
                            state <= ST_RX;
                        end else begin
                            sda_oe <= 0; state <= ST_IDLE;
                        end
                    end

                    ST_RX: begin
                        if (scl_fall) sda_oe <= 0;
                        if (scl_rise) begin
                            shift_reg <= {shift_reg[6:0], sda_s};
                            if (bit_cnt == 0) state <= ST_DATACK;
                            else bit_cnt <= bit_cnt - 3'd1;
                        end
                    end

                    ST_DATACK: if (scl_fall) begin
                        sda_oe <= 1;
                        if (first_byte) begin
                            reg_addr <= shift_reg;
                            first_byte <= 0;
                        end else begin
                            reg_wdata <= shift_reg;
                            reg_we <= 1;
                        end
                        bit_cnt <= 7; state <= ST_RX;
                    end

                    default: state <= ST_IDLE;
                endcase
            end
        end
    end
endmodule
