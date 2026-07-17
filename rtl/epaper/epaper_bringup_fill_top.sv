module epaper_bringup_fill_top #(
    parameter int CLK_HZ = 50_000_000,
    parameter int SPI_HZ = 1_000_000,
    parameter int RESET_LOW_US = 10_000,
    parameter int RESET_HIGH_US = 10_000,
    parameter int COUNT_WIDTH = 24
) (
    input  logic                   clk,
    input  logic                   rst_n,

    input  logic                   start,
    input  logic [7:0]             fill_byte,
    input  logic [COUNT_WIDTH-1:0] byte_count,
    input  logic                   epd_busy,

    output logic                   epd_cs_n,
    output logic                   epd_sclk,
    output logic                   epd_mosi,
    output logic                   epd_dc,
    output logic                   epd_rst_n,

    output logic                   busy,
    output logic                   done,
    output logic                   timeout,
    output logic                   error
);
    logic reset_ready;
    logic fill_start_q;
    logic fill_valid;
    logic fill_ready;
    logic [8:0] fill_data;
    logic fill_last;
    logic fill_busy;
    logic fill_done;
    logic spi_done;

    typedef enum logic [1:0] {
        ST_WAIT_RESET,
        ST_IDLE,
        ST_FILL
    } state_t;

    state_t state_q;

    epaper_reset_controller #(
        .CLK_HZ(CLK_HZ),
        .RESET_LOW_US(RESET_LOW_US),
        .RESET_HIGH_US(RESET_HIGH_US)
    ) u_reset (
        .clk(clk),
        .rst_n(rst_n),
        .epd_rst_n(epd_rst_n),
        .ready(reset_ready)
    );

    epaper_frame_fill #(
        .COUNT_WIDTH(COUNT_WIDTH)
    ) u_fill (
        .clk(clk),
        .rst_n(rst_n),
        .start(fill_start_q),
        .fill_byte(fill_byte),
        .byte_count(byte_count),
        .out_valid(fill_valid),
        .out_ready(fill_ready),
        .out_data(fill_data),
        .out_last(fill_last),
        .busy(fill_busy),
        .done(fill_done)
    );

    epaper_spi_stream_controller #(
        .CLK_HZ(CLK_HZ),
        .SPI_HZ(SPI_HZ),
        .RESET_LOW_US(0),
        .RESET_HIGH_US(0),
        .HOLD_CS_UNTIL_LAST(1'b1)
    ) u_spi (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(fill_valid),
        .in_ready(fill_ready),
        .in_data(fill_data),
        .in_last(fill_last),
        .epd_busy(epd_busy),
        .epd_cs_n(epd_cs_n),
        .epd_sclk(epd_sclk),
        .epd_mosi(epd_mosi),
        .epd_dc(epd_dc),
        .epd_rst_n(),
        .frame_done(spi_done),
        .timeout(timeout),
        .error(error)
    );

    assign busy = (state_q != ST_IDLE) || fill_busy;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= ST_WAIT_RESET;
            fill_start_q <= 1'b0;
            done <= 1'b0;
        end else begin
            fill_start_q <= 1'b0;
            done <= 1'b0;

            case (state_q)
                ST_WAIT_RESET: begin
                    if (reset_ready) begin
                        state_q <= ST_IDLE;
                    end
                end

                ST_IDLE: begin
                    if (start) begin
                        fill_start_q <= 1'b1;
                        state_q <= ST_FILL;
                    end
                end

                ST_FILL: begin
                    if (spi_done) begin
                        state_q <= ST_IDLE;
                        done <= 1'b1;
                    end
                end

                default: state_q <= ST_WAIT_RESET;
            endcase
        end
    end
endmodule
