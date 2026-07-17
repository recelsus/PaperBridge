module epaper_spi_stream_controller #(
    parameter int CLK_HZ = 50_000_000,
    parameter int SPI_HZ = 10_000_000,
    parameter int RESET_LOW_US = 10_000,
    parameter int RESET_HIGH_US = 10_000,
    parameter bit HOLD_CS_UNTIL_LAST = 1'b0,
    parameter int BUSY_TIMEOUT_CYCLES = 0
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

    output logic       frame_done,
    output logic       timeout,
    output logic       error
);
    localparam int TIMEOUT_CNT_W = (BUSY_TIMEOUT_CYCLES <= 1) ? 1 : $clog2(BUSY_TIMEOUT_CYCLES + 1);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_START_SPI,
        ST_WAIT_SPI
    } state_t;

    state_t state_q, state_d;

    logic                   last_q, last_d;
    logic                   dc_q, dc_d;
    logic                   epd_busy_sync;
    logic                   spi_in_valid;
    logic                   spi_in_ready;
    logic                   spi_busy;
    logic                   spi_transfer_done;
    logic                   reset_ready;
    logic [TIMEOUT_CNT_W-1:0] timeout_cnt_q, timeout_cnt_d;
    logic timeout_d;
    logic error_d;

    epaper_reset_controller #(
        .CLK_HZ(CLK_HZ),
        .RESET_LOW_US(RESET_LOW_US),
        .RESET_HIGH_US(RESET_HIGH_US)
    ) u_reset_controller (
        .clk(clk),
        .rst_n(rst_n),
        .epd_rst_n(epd_rst_n),
        .ready(reset_ready)
    );

    sync_2ff u_epd_busy_sync (
        .clk(clk),
        .rst_n(rst_n),
        .async_i(epd_busy),
        .sync_o(epd_busy_sync)
    );

    spi_tx #(
        .CLK_HZ(CLK_HZ),
        .SPI_HZ(SPI_HZ),
        .HOLD_CS_UNTIL_LAST(HOLD_CS_UNTIL_LAST)
    ) u_spi_tx (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(spi_in_valid),
        .in_ready(spi_in_ready),
        .in_data(in_data[7:0]),
        .in_last(last_q),
        .spi_cs_n(epd_cs_n),
        .spi_sclk(epd_sclk),
        .spi_mosi(epd_mosi),
        .busy(spi_busy),
        .transfer_done(spi_transfer_done)
    );

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
        if (RESET_LOW_US < 0) begin
            $fatal(1, "RESET_LOW_US must be non-negative");
        end
        if (RESET_HIGH_US < 0) begin
            $fatal(1, "RESET_HIGH_US must be non-negative");
        end
        if (BUSY_TIMEOUT_CYCLES < 0) begin
            $fatal(1, "BUSY_TIMEOUT_CYCLES must be non-negative");
        end
    end
`endif

    always @* begin
        state_d     = state_q;
        last_d      = last_q;
        dc_d        = dc_q;
        timeout_cnt_d = timeout_cnt_q;
        timeout_d = timeout;
        error_d = error;

        in_ready    = 1'b0;
        epd_dc      = dc_q;
        frame_done  = 1'b0;
        spi_in_valid = 1'b0;

        case (state_q)
            ST_IDLE: begin
                if (!epd_busy_sync) begin
                    timeout_cnt_d = '0;
                end else if (reset_ready && BUSY_TIMEOUT_CYCLES > 0 && !timeout) begin
                    if (timeout_cnt_q >= BUSY_TIMEOUT_CYCLES - 1) begin
                        timeout_d = 1'b1;
                        error_d = 1'b1;
                    end else begin
                        timeout_cnt_d = timeout_cnt_q + 1'b1;
                    end
                end

                in_ready = reset_ready && !epd_busy_sync && spi_in_ready;
                if (in_valid && in_ready) begin
                    dc_d      = in_data[8];
                    last_d    = in_last;
                    state_d   = ST_START_SPI;
                end
            end

            ST_START_SPI: begin
                spi_in_valid = 1'b1;
                state_d = ST_WAIT_SPI;
            end

            ST_WAIT_SPI: begin
                if (spi_transfer_done) begin
                    state_d = ST_IDLE;
                    if (last_q) begin
                        frame_done = 1'b1;
                    end
                end
            end

            default: state_d = ST_IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q     <= ST_IDLE;
            last_q      <= 1'b0;
            dc_q        <= 1'b0;
            timeout_cnt_q <= '0;
            timeout <= 1'b0;
            error <= 1'b0;
        end else begin
            state_q     <= state_d;
            last_q      <= last_d;
            dc_q        <= dc_d;
            timeout_cnt_q <= timeout_cnt_d;
            timeout <= timeout_d;
            error <= error_d;
        end
    end
endmodule
