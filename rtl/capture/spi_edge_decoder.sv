module spi_edge_decoder #(
    parameter int TIMESTAMP_WIDTH = 32,
    parameter int PIN_CS_N = 0,
    parameter int PIN_SCLK = 1,
    parameter int PIN_MOSI = 2,
    parameter int PIN_DC = 3,
    parameter bit CPOL = 1'b0,
    parameter bit CPHA = 1'b0
) (
    input  logic                         clk,
    input  logic                         rst_n,

    input  logic                         event_valid,
    output logic                         event_ready,
    input  logic [TIMESTAMP_WIDTH+15:0]  event_data,

    output logic                         byte_valid,
    input  logic                         byte_ready,
    output logic [7:0]                   byte_o,
    output logic                         dc_o,
    output logic                         frame_done
);
    localparam logic [7:0] EVENT_EDGE = 8'h01;

    logic [7:0] pins_now;
    logic [7:0] event_type;
    logic       cs_n_now;
    logic       sclk_now;
    logic       mosi_now;
    logic       dc_now;
    logic       cs_active_q;
    logic       sclk_q;
    logic [7:0] shreg_q;
    logic [2:0] bit_count_q;
    logic       sample_edge;
    logic       sclk_active_edge;

`ifndef SYNTHESIS
    initial begin
        if (TIMESTAMP_WIDTH < 1) begin
            $fatal(1, "TIMESTAMP_WIDTH must be greater than zero");
        end
        if (PIN_CS_N < 0 || PIN_CS_N > 7 || PIN_SCLK < 0 || PIN_SCLK > 7
                || PIN_MOSI < 0 || PIN_MOSI > 7 || PIN_DC < 0 || PIN_DC > 7) begin
            $fatal(1, "SPI decoder pin indices must be from 0 to 7");
        end
        if (CPHA != 1'b0) begin
            $fatal(1, "spi_edge_decoder currently supports CPHA=0 only");
        end
    end
`endif

    assign pins_now = event_data[TIMESTAMP_WIDTH +: 8];
    assign event_type = event_data[TIMESTAMP_WIDTH+8 +: 8];
    assign cs_n_now = pins_now[PIN_CS_N];
    assign sclk_now = pins_now[PIN_SCLK];
    assign mosi_now = pins_now[PIN_MOSI];
    assign dc_now = pins_now[PIN_DC];
    assign sclk_active_edge = CPOL ? (sclk_q && !sclk_now) : (!sclk_q && sclk_now);
    assign sample_edge = event_valid && (event_type == EVENT_EDGE)
                      && cs_active_q && !cs_n_now && sclk_active_edge;
    assign event_ready = !byte_valid || byte_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cs_active_q <= 1'b0;
            sclk_q <= CPOL;
            shreg_q <= '0;
            bit_count_q <= '0;
            byte_valid <= 1'b0;
            byte_o <= '0;
            dc_o <= 1'b0;
            frame_done <= 1'b0;
        end else begin
            frame_done <= 1'b0;

            if (byte_valid && byte_ready) begin
                byte_valid <= 1'b0;
            end

            if (event_valid && event_ready) begin
                if (cs_active_q && cs_n_now) begin
                    frame_done <= 1'b1;
                    bit_count_q <= '0;
                    shreg_q <= '0;
                end

                cs_active_q <= !cs_n_now;
                sclk_q <= sclk_now;

                if (sample_edge) begin
                    shreg_q <= {shreg_q[6:0], mosi_now};
                    if (bit_count_q == 3'd7) begin
                        byte_o <= {shreg_q[6:0], mosi_now};
                        dc_o <= dc_now;
                        byte_valid <= 1'b1;
                        bit_count_q <= '0;
                    end else begin
                        bit_count_q <= bit_count_q + 1'b1;
                    end
                end

                if (cs_n_now) begin
                    bit_count_q <= '0;
                    shreg_q <= '0;
                end
            end
        end
    end
endmodule
