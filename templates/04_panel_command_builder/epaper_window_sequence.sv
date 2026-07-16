module epaper_window_sequence (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start,
    input  logic [15:0] x_start_px,
    input  logic [15:0] x_end_px,
    input  logic [15:0] y_start,
    input  logic [15:0] y_end,

    output logic        out_valid,
    input  logic        out_ready,
    output logic [8:0]  out_data,
    output logic        out_last,

    output logic        busy,
    output logic        done
);
    localparam int STEP_COUNT = 13;

    logic [3:0] step_q;
    logic       active_q;

    logic [7:0] byte_value;
    logic       dc_value;

    always @* begin
        dc_value = 1'b0;
        byte_value = 8'h00;

        case (step_q)
            4'd0:  begin dc_value = 1'b0; byte_value = 8'h44; end
            4'd1:  begin dc_value = 1'b1; byte_value = x_start_px[10:3]; end
            4'd2:  begin dc_value = 1'b1; byte_value = x_end_px[10:3]; end
            4'd3:  begin dc_value = 1'b0; byte_value = 8'h45; end
            4'd4:  begin dc_value = 1'b1; byte_value = y_start[7:0]; end
            4'd5:  begin dc_value = 1'b1; byte_value = y_start[15:8]; end
            4'd6:  begin dc_value = 1'b1; byte_value = y_end[7:0]; end
            4'd7:  begin dc_value = 1'b1; byte_value = y_end[15:8]; end
            4'd8:  begin dc_value = 1'b0; byte_value = 8'h4e; end
            4'd9:  begin dc_value = 1'b1; byte_value = x_start_px[10:3]; end
            4'd10: begin dc_value = 1'b0; byte_value = 8'h4f; end
            4'd11: begin dc_value = 1'b1; byte_value = y_start[7:0]; end
            4'd12: begin dc_value = 1'b1; byte_value = y_start[15:8]; end
            default: begin dc_value = 1'b0; byte_value = 8'h00; end
        endcase
    end

    assign out_valid = active_q;
    assign out_data = {dc_value, byte_value};
    assign out_last = (step_q == STEP_COUNT - 1);
    assign busy = active_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_q <= 1'b0;
            step_q <= '0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;

            if (!active_q && start) begin
                active_q <= 1'b1;
                step_q <= '0;
            end else if (active_q && out_ready) begin
                if (step_q == STEP_COUNT - 1) begin
                    active_q <= 1'b0;
                    step_q <= '0;
                    done <= 1'b1;
                end else begin
                    step_q <= step_q + 1'b1;
                end
            end
        end
    end
endmodule
