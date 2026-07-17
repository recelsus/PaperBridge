module epaper_frame_fill #(
    parameter int COUNT_WIDTH = 24
) (
    input  logic                   clk,
    input  logic                   rst_n,

    input  logic                   start,
    input  logic [7:0]             fill_byte,
    input  logic [COUNT_WIDTH-1:0] byte_count,

    output logic                   out_valid,
    input  logic                   out_ready,
    output logic [8:0]             out_data,
    output logic                   out_last,

    output logic                   busy,
    output logic                   done
);
    typedef enum logic [1:0] {
        ST_IDLE,
        ST_CMD,
        ST_DATA
    } state_t;

    state_t state_q;
    logic [COUNT_WIDTH-1:0] remaining_q;

    assign busy = (state_q != ST_IDLE);
    assign out_valid = (state_q != ST_IDLE);
    assign out_data = (state_q == ST_CMD) ? {1'b0, 8'h24} : {1'b1, fill_byte};
    assign out_last = (state_q == ST_DATA) && (remaining_q == 1);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= ST_IDLE;
            remaining_q <= '0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state_q)
                ST_IDLE: begin
                    if (start) begin
                        remaining_q <= byte_count;
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
