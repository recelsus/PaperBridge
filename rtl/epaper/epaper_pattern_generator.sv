module epaper_pattern_generator #(
    parameter int COUNT_WIDTH = 24,
    parameter int LINE_BYTES = 16
) (
    input  logic                   clk,
    input  logic                   rst_n,

    input  logic                   start,
    input  logic [2:0]             pattern_mode,
    input  logic [7:0]             fill_byte,
    input  logic [COUNT_WIDTH-1:0] byte_count,

    output logic                   out_valid,
    input  logic                   out_ready,
    output logic [8:0]             out_data,
    output logic                   out_last,

    output logic                   busy,
    output logic                   done
);
    localparam logic [2:0] PATTERN_FILL        = 3'd0;
    localparam logic [2:0] PATTERN_CHECKER     = 3'd1;
    localparam logic [2:0] PATTERN_VSTRIPES    = 3'd2;
    localparam logic [2:0] PATTERN_HSTRIPES    = 3'd3;
    localparam logic [2:0] PATTERN_WALKING_ONE = 3'd4;

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_CMD,
        ST_DATA
    } state_t;

    state_t state_q;
    logic [COUNT_WIDTH-1:0] remaining_q;
    logic [COUNT_WIDTH-1:0] index_q;
    logic [7:0] pattern_byte;

`ifndef SYNTHESIS
    initial begin
        if (COUNT_WIDTH < 1) begin
            $fatal(1, "COUNT_WIDTH must be greater than zero");
        end
        if (LINE_BYTES < 1) begin
            $fatal(1, "LINE_BYTES must be greater than zero");
        end
    end
`endif

    always @* begin
        case (pattern_mode)
            PATTERN_FILL: begin
                pattern_byte = fill_byte;
            end

            PATTERN_CHECKER: begin
                pattern_byte = index_q[0] ? 8'h55 : 8'haa;
            end

            PATTERN_VSTRIPES: begin
                pattern_byte = 8'hf0;
            end

            PATTERN_HSTRIPES: begin
                pattern_byte = ((index_q / LINE_BYTES) & 1) ? 8'h00 : 8'hff;
            end

            PATTERN_WALKING_ONE: begin
                pattern_byte = 8'h01 << index_q[2:0];
            end

            default: begin
                pattern_byte = fill_byte;
            end
        endcase
    end

    assign busy = (state_q != ST_IDLE);
    assign out_valid = (state_q != ST_IDLE);
    assign out_data = (state_q == ST_CMD) ? {1'b0, 8'h24} : {1'b1, pattern_byte};
    assign out_last = (state_q == ST_DATA) && (remaining_q == 1);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= ST_IDLE;
            remaining_q <= '0;
            index_q <= '0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state_q)
                ST_IDLE: begin
                    if (start) begin
                        remaining_q <= byte_count;
                        index_q <= '0;
                        state_q <= ST_CMD;
                    end
                end

                ST_CMD: begin
                    if (out_ready) begin
                        if (remaining_q == '0) begin
                            state_q <= ST_IDLE;
                            done <= 1'b1;
                        end else begin
                            state_q <= ST_DATA;
                        end
                    end
                end

                ST_DATA: begin
                    if (out_ready) begin
                        index_q <= index_q + 1'b1;
                        if (remaining_q == 1) begin
                            remaining_q <= '0;
                            state_q <= ST_IDLE;
                            done <= 1'b1;
                        end else begin
                            remaining_q <= remaining_q - 1'b1;
                        end
                    end
                end

                default: state_q <= ST_IDLE;
            endcase
        end
    end
endmodule
