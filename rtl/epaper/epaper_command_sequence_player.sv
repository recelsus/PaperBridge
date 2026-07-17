module epaper_command_sequence_player #(
    parameter int DELAY_WIDTH = 16
) (
    input  logic                   clk,
    input  logic                   rst_n,

    input  logic                   start,
    input  logic                   seq_valid,
    output logic                   seq_ready,
    input  logic [2:0]             seq_op,
    input  logic [DELAY_WIDTH-1:0] seq_data,
    input  logic                   epd_busy,

    output logic                   out_valid,
    input  logic                   out_ready,
    output logic [8:0]             out_data,
    output logic                   out_last,

    output logic                   busy,
    output logic                   done
);
    localparam logic [2:0] OP_CMD       = 3'd0;
    localparam logic [2:0] OP_DATA      = 3'd1;
    localparam logic [2:0] OP_DELAY     = 3'd2;
    localparam logic [2:0] OP_WAIT_IDLE = 3'd3;
    localparam logic [2:0] OP_END       = 3'd7;

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_FETCH,
        ST_DELAY,
        ST_WAIT_IDLE
    } state_t;

    state_t state_q;
    logic [DELAY_WIDTH-1:0] delay_q;

    wire is_send = (seq_op == OP_CMD) || (seq_op == OP_DATA);

`ifndef SYNTHESIS
    initial begin
        if (DELAY_WIDTH < 1) begin
            $fatal(1, "DELAY_WIDTH must be greater than zero");
        end
    end
`endif

    assign busy = (state_q != ST_IDLE);
    assign out_valid = (state_q == ST_FETCH) && seq_valid && is_send;
    assign out_data = {seq_op == OP_DATA, seq_data[7:0]};
    assign out_last = (state_q == ST_FETCH) && seq_valid && (seq_op == OP_END);
    assign seq_ready = (state_q == ST_FETCH)
                    && (!seq_valid
                        || ((is_send && out_ready)
                         || (seq_op == OP_DELAY)
                         || (seq_op == OP_WAIT_IDLE)
                         || (seq_op == OP_END)));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= ST_IDLE;
            delay_q <= '0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state_q)
                ST_IDLE: begin
                    if (start) begin
                        state_q <= ST_FETCH;
                    end
                end

                ST_FETCH: begin
                    if (seq_valid && seq_ready) begin
                        case (seq_op)
                            OP_CMD,
                            OP_DATA: begin
                                state_q <= ST_FETCH;
                            end

                            OP_DELAY: begin
                                delay_q <= seq_data;
                                if (seq_data == '0) begin
                                    state_q <= ST_FETCH;
                                end else begin
                                    state_q <= ST_DELAY;
                                end
                            end

                            OP_WAIT_IDLE: begin
                                if (epd_busy) begin
                                    state_q <= ST_WAIT_IDLE;
                                end else begin
                                    state_q <= ST_FETCH;
                                end
                            end

                            OP_END: begin
                                state_q <= ST_IDLE;
                                done <= 1'b1;
                            end

                            default: begin
                                state_q <= ST_FETCH;
                            end
                        endcase
                    end
                end

                ST_DELAY: begin
                    if (delay_q <= 1) begin
                        delay_q <= '0;
                        state_q <= ST_FETCH;
                    end else begin
                        delay_q <= delay_q - 1'b1;
                    end
                end

                ST_WAIT_IDLE: begin
                    if (!epd_busy) begin
                        state_q <= ST_FETCH;
                    end
                end

                default: state_q <= ST_IDLE;
            endcase
        end
    end
endmodule
