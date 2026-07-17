module serial_pin_capture #(
    parameter int PIN_COUNT = 8,
    parameter int TIMESTAMP_WIDTH = 32,
    parameter int FIFO_DEPTH = 4
) (
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic [PIN_COUNT-1:0]  pins_i,
    input  logic [PIN_COUNT-1:0]  edge_enable_i,
    input  logic [PIN_COUNT-1:0]  rising_enable_i,
    input  logic [PIN_COUNT-1:0]  falling_enable_i,
    input  logic [PIN_COUNT-1:0]  level_mask_i,
    input  logic [PIN_COUNT-1:0]  level_value_i,
    input  logic                  arm_i,

    output logic                  event_valid,
    input  logic                  event_ready,
    output logic [TIMESTAMP_WIDTH+15:0] event_data,
    output logic                  overflow
);
    localparam logic [7:0] EVENT_EDGE  = 8'h01;
    localparam logic [7:0] EVENT_LEVEL = 8'h02;
    localparam int EVENT_WIDTH = TIMESTAMP_WIDTH + 16;
    localparam int FIFO_PTR_WIDTH = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH);
    localparam int FIFO_COUNT_WIDTH = (FIFO_DEPTH <= 1) ? 2 : $clog2(FIFO_DEPTH + 1);

    logic [PIN_COUNT-1:0] pins_meta_q;
    logic [PIN_COUNT-1:0] pins_q;
    logic [PIN_COUNT-1:0] pins_prev_q;
    logic                 level_match_prev_q;
    logic [TIMESTAMP_WIDTH-1:0] timestamp_q;

    logic [EVENT_WIDTH-1:0] fifo_q [0:FIFO_DEPTH-1];
    logic [FIFO_PTR_WIDTH-1:0] rd_ptr_q;
    logic [FIFO_PTR_WIDTH-1:0] wr_ptr_q;
    logic [FIFO_COUNT_WIDTH-1:0] fifo_count_q;
    logic [7:0] pins_event;
    logic [EVENT_WIDTH-1:0] next_event;
    logic event_fire;
    logic fifo_pop;
    logic fifo_push;
    logic fifo_full;

    wire [PIN_COUNT-1:0] rising_enabled = rising_enable_i | edge_enable_i;
    wire [PIN_COUNT-1:0] falling_enabled = falling_enable_i | edge_enable_i;
    wire [PIN_COUNT-1:0] rising_edge = pins_q & ~pins_prev_q & rising_enabled;
    wire [PIN_COUNT-1:0] falling_edge = ~pins_q & pins_prev_q & falling_enabled;
    wire [PIN_COUNT-1:0] edge_hit = rising_edge | falling_edge;
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
        if (FIFO_DEPTH < 1) begin
            $fatal(1, "FIFO_DEPTH must be greater than zero");
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
        if (edge_hit != '0) begin
            next_event = {EVENT_EDGE, pins_event, timestamp_q};
        end else begin
            next_event = {EVENT_LEVEL, pins_event, timestamp_q};
        end
    end

    assign event_fire = arm_i && ((edge_hit != '0) || level_enter);
    assign fifo_pop = event_valid && event_ready;
    assign fifo_full = (fifo_count_q == FIFO_DEPTH);
    assign fifo_push = event_fire && (!fifo_full || fifo_pop);
    assign event_valid = (fifo_count_q != '0);
    assign event_data = fifo_q[rd_ptr_q];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pins_meta_q <= '0;
            pins_q <= '0;
            pins_prev_q <= '0;
            level_match_prev_q <= 1'b0;
            timestamp_q <= '0;
            rd_ptr_q <= '0;
            wr_ptr_q <= '0;
            fifo_count_q <= '0;
            for (int i = 0; i < FIFO_DEPTH; i++) begin
                fifo_q[i] <= '0;
            end
            overflow <= 1'b0;
        end else begin
            pins_meta_q <= pins_i;
            pins_q <= pins_meta_q;
            pins_prev_q <= pins_q;
            level_match_prev_q <= level_match;
            timestamp_q <= timestamp_q + 1'b1;

            if (fifo_pop) begin
                if (rd_ptr_q == FIFO_DEPTH - 1) begin
                    rd_ptr_q <= '0;
                end else begin
                    rd_ptr_q <= rd_ptr_q + 1'b1;
                end
            end

            if (fifo_push) begin
                fifo_q[wr_ptr_q] <= next_event;
                if (wr_ptr_q == FIFO_DEPTH - 1) begin
                    wr_ptr_q <= '0;
                end else begin
                    wr_ptr_q <= wr_ptr_q + 1'b1;
                end
            end else if (event_fire && fifo_full && !fifo_pop) begin
                overflow <= 1'b1;
            end

            case ({fifo_push, fifo_pop})
                2'b10: fifo_count_q <= fifo_count_q + 1'b1;
                2'b01: fifo_count_q <= fifo_count_q - 1'b1;
                default: fifo_count_q <= fifo_count_q;
            endcase
        end
    end
endmodule
