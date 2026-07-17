module spi_tx #(
    parameter int CLK_HZ = 50_000_000,
    parameter int SPI_HZ = 10_000_000
) (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       in_valid,
    output logic       in_ready,
    input  logic [7:0] in_data,

    output logic       spi_cs_n,
    output logic       spi_sclk,
    output logic       spi_mosi,

    output logic       busy,
    output logic       transfer_done
);
    localparam int SPI_DIV = (CLK_HZ + (2 * SPI_HZ) - 1) / (2 * SPI_HZ);
    localparam int SPI_DIV_W = (SPI_DIV <= 1) ? 1 : $clog2(SPI_DIV);

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_LOW,
        ST_HIGH
    } state_t;

    state_t state_q;
    logic [SPI_DIV_W-1:0] spi_cnt_q;
    logic [2:0] bit_cnt_q;
    logic [7:0] shreg_q;

`ifndef SYNTHESIS
    initial begin
        if (CLK_HZ <= 0) begin
            $fatal(1, "CLK_HZ must be greater than zero");
        end
        if (SPI_HZ <= 0) begin
            $fatal(1, "SPI_HZ must be greater than zero");
        end
        if (SPI_HZ > (CLK_HZ / 2)) begin
            $fatal(1, "SPI_HZ must be less than or equal to CLK_HZ / 2");
        end
    end
`endif

    assign in_ready = (state_q == ST_IDLE);
    assign busy = (state_q != ST_IDLE);
    assign spi_cs_n = (state_q == ST_IDLE);
    assign spi_sclk = (state_q == ST_HIGH);
    assign spi_mosi = shreg_q[7];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= ST_IDLE;
            spi_cnt_q <= '0;
            bit_cnt_q <= '0;
            shreg_q <= '0;
            transfer_done <= 1'b0;
        end else begin
            transfer_done <= 1'b0;

            case (state_q)
                ST_IDLE: begin
                    spi_cnt_q <= '0;
                    if (in_valid) begin
                        shreg_q <= in_data;
                        bit_cnt_q <= 3'd7;
                        state_q <= ST_LOW;
                    end
                end

                ST_LOW: begin
                    if (spi_cnt_q == SPI_DIV - 1) begin
                        spi_cnt_q <= '0;
                        state_q <= ST_HIGH;
                    end else begin
                        spi_cnt_q <= spi_cnt_q + 1'b1;
                    end
                end

                ST_HIGH: begin
                    if (spi_cnt_q == SPI_DIV - 1) begin
                        spi_cnt_q <= '0;
                        if (bit_cnt_q == 3'd0) begin
                            state_q <= ST_IDLE;
                            transfer_done <= 1'b1;
                        end else begin
                            bit_cnt_q <= bit_cnt_q - 1'b1;
                            shreg_q <= {shreg_q[6:0], 1'b0};
                            state_q <= ST_LOW;
                        end
                    end else begin
                        spi_cnt_q <= spi_cnt_q + 1'b1;
                    end
                end

                default: state_q <= ST_IDLE;
            endcase
        end
    end
endmodule
