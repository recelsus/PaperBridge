module epaper_spi_stream_controller #(
    parameter int CLK_HZ = 50_000_000,
    parameter int SPI_HZ = 10_000_000,
    parameter int RESET_LOW_US = 10_000,
    parameter int RESET_HIGH_US = 10_000
) (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       in_valid,
    output logic       in_ready,
    input  logic [8:0] in_data,   // {dc, byte}
    input  logic       in_last,

    input  logic       epd_busy,
    output logic       epd_cs_n,
    output logic       epd_sclk,
    output logic       epd_mosi,
    output logic       epd_dc,
    output logic       epd_rst_n,

    output logic       frame_done
);
    localparam int SPI_DIV = (CLK_HZ + (2 * SPI_HZ) - 1) / (2 * SPI_HZ);
    localparam int SPI_DIV_W = (SPI_DIV <= 1) ? 1 : $clog2(SPI_DIV);
    localparam int RESET_LOW_CYCLES = (CLK_HZ / 1_000_000) * RESET_LOW_US;
    localparam int RESET_HIGH_CYCLES = (CLK_HZ / 1_000_000) * RESET_HIGH_US;
    localparam int RESET_CNT_MAX = (RESET_LOW_CYCLES > RESET_HIGH_CYCLES)
                                 ? RESET_LOW_CYCLES
                                 : RESET_HIGH_CYCLES;
    localparam int RESET_CNT_W = (RESET_CNT_MAX <= 1) ? 1 : $clog2(RESET_CNT_MAX + 1);

    typedef enum logic [2:0] {
        ST_RESET_LOW,
        ST_RESET_HIGH,
        ST_IDLE,
        ST_SHIFT_LOW,
        ST_SHIFT_HIGH
    } state_t;

    state_t state_q, state_d;

    logic [RESET_CNT_W-1:0] reset_cnt_q, reset_cnt_d;
    logic [SPI_DIV_W-1:0]   spi_cnt_q, spi_cnt_d;
    logic [2:0]             bit_cnt_q, bit_cnt_d;
    logic [7:0]             shreg_q, shreg_d;
    logic                   last_q, last_d;
    logic                   dc_q, dc_d;

    wire spi_tick = (spi_cnt_q == SPI_DIV - 1);

    always_comb begin
        state_d     = state_q;
        reset_cnt_d = reset_cnt_q;
        spi_cnt_d   = spi_cnt_q;
        bit_cnt_d   = bit_cnt_q;
        shreg_d     = shreg_q;
        last_d      = last_q;
        dc_d        = dc_q;

        in_ready    = 1'b0;
        epd_cs_n    = 1'b1;
        epd_sclk    = 1'b0;
        epd_mosi    = shreg_q[7];
        epd_dc      = dc_q;
        epd_rst_n   = 1'b1;
        frame_done  = 1'b0;

        case (state_q)
            ST_RESET_LOW: begin
                epd_rst_n = 1'b0;
                if (reset_cnt_q >= RESET_LOW_CYCLES - 1) begin
                    reset_cnt_d = '0;
                    state_d = ST_RESET_HIGH;
                end else begin
                    reset_cnt_d = reset_cnt_q + 1'b1;
                end
            end

            ST_RESET_HIGH: begin
                epd_rst_n = 1'b1;
                if (reset_cnt_q >= RESET_HIGH_CYCLES - 1) begin
                    reset_cnt_d = '0;
                    state_d = ST_IDLE;
                end else begin
                    reset_cnt_d = reset_cnt_q + 1'b1;
                end
            end

            ST_IDLE: begin
                in_ready = !epd_busy;
                if (in_valid && in_ready) begin
                    dc_d      = in_data[8];
                    shreg_d   = in_data[7:0];
                    last_d    = in_last;
                    bit_cnt_d = 3'd7;
                    spi_cnt_d = '0;
                    state_d   = ST_SHIFT_LOW;
                end
            end

            ST_SHIFT_LOW: begin
                epd_cs_n = 1'b0;
                epd_sclk = 1'b0;
                if (spi_tick) begin
                    spi_cnt_d = '0;
                    state_d = ST_SHIFT_HIGH;
                end else begin
                    spi_cnt_d = spi_cnt_q + 1'b1;
                end
            end

            ST_SHIFT_HIGH: begin
                epd_cs_n = 1'b0;
                epd_sclk = 1'b1;
                if (spi_tick) begin
                    spi_cnt_d = '0;
                    if (bit_cnt_q == 3'd0) begin
                        state_d = ST_IDLE;
                        if (last_q) begin
                            frame_done = 1'b1;
                        end
                    end else begin
                        bit_cnt_d = bit_cnt_q - 1'b1;
                        shreg_d = {shreg_q[6:0], 1'b0};
                        state_d = ST_SHIFT_LOW;
                    end
                end else begin
                    spi_cnt_d = spi_cnt_q + 1'b1;
                end
            end

            default: state_d = ST_RESET_LOW;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q     <= ST_RESET_LOW;
            reset_cnt_q <= '0;
            spi_cnt_q   <= '0;
            bit_cnt_q   <= '0;
            shreg_q     <= '0;
            last_q      <= 1'b0;
            dc_q        <= 1'b0;
        end else begin
            state_q     <= state_d;
            reset_cnt_q <= reset_cnt_d;
            spi_cnt_q   <= spi_cnt_d;
            bit_cnt_q   <= bit_cnt_d;
            shreg_q     <= shreg_d;
            last_q      <= last_d;
            dc_q        <= dc_d;
        end
    end
endmodule
