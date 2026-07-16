module serial_pin_capture #(
    parameter int PIN_COUNT = 8,
    parameter int TIMESTAMP_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic [PIN_COUNT-1:0]  pins_i,
    input  logic [PIN_COUNT-1:0]  edge_enable_i,
    input  logic [PIN_COUNT-1:0]  level_mask_i,
    input  logic [PIN_COUNT-1:0]  level_value_i,

    output logic                  event_valid,
    input  logic                  event_ready,
    output logic [TIMESTAMP_WIDTH+15:0] event_data,
    output logic                  overflow
);
    localparam logic [7:0] EVENT_EDGE  = 8'h01;
    localparam logic [7:0] EVENT_LEVEL = 8'h02;

    logic [PIN_COUNT-1:0] pins_meta_q;
    logic [PIN_COUNT-1:0] pins_q;
    logic [PIN_COUNT-1:0] pins_prev_q;
    logic                 level_match_prev_q;
    logic [TIMESTAMP_WIDTH-1:0] timestamp_q;

    logic pending_q, pending_d;
    logic [TIMESTAMP_WIDTH+15:0] event_q, event_d;
    logic [7:0] pins_event;
    logic overflow_d;

    wire [PIN_COUNT-1:0] changed = (pins_q ^ pins_prev_q) & edge_enable_i;
    wire level_match = ((pins_q & level_mask_i) == (level_value_i & level_mask_i))
                    && (level_mask_i != '0);
    wire level_enter = level_match && !level_match_prev_q;

`ifndef SYNTHESIS
    initial begin
        if (PIN_COUNT < 1 || PIN_COUNT > 8) begin
            $fatal(1, "PIN_COUNT must be from 1 to 8 for the 8-bit event pin field");
        end
        if (TIMESTAMP_WIDTH < 1) begin
            $fatal(1, "TIMESTAMP_WIDTH must be greater than zero");
        end
    end
`endif

    always @* begin
        pins_event = '0;
        for (int i = 0; i < PIN_COUNT && i < 8; i++) begin
            pins_event[i] = pins_q[i];
        end
    end

    always @* begin
        pending_d = pending_q;
        event_d = event_q;
        overflow_d = overflow;

        if (pending_q && event_ready) begin
            pending_d = 1'b0;
        end

        if (!pending_d) begin
            if (changed != '0) begin
                pending_d = 1'b1;
                event_d = {EVENT_EDGE, pins_event, timestamp_q};
            end else if (level_enter) begin
                pending_d = 1'b1;
                event_d = {EVENT_LEVEL, pins_event, timestamp_q};
            end
        end else if ((changed != '0) || level_enter) begin
            overflow_d = 1'b1;
        end

        if (pending_q && event_ready && ((changed != '0) || level_enter)) begin
            if (changed != '0) begin
                pending_d = 1'b1;
                event_d = {EVENT_EDGE, pins_event, timestamp_q};
            end else begin
                pending_d = 1'b1;
                event_d = {EVENT_LEVEL, pins_event, timestamp_q};
            end
        end
    end

    assign event_valid = pending_q;
    assign event_data = event_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pins_meta_q <= '0;
            pins_q <= '0;
            pins_prev_q <= '0;
            level_match_prev_q <= 1'b0;
            timestamp_q <= '0;
            pending_q <= 1'b0;
            event_q <= '0;
            overflow <= 1'b0;
        end else begin
            pins_meta_q <= pins_i;
            pins_q <= pins_meta_q;
            pins_prev_q <= pins_q;
            level_match_prev_q <= level_match;
            timestamp_q <= timestamp_q + 1'b1;
            pending_q <= pending_d;
            event_q <= event_d;
            overflow <= overflow_d;
        end
    end
endmodule
