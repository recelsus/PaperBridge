module fb_1bpp_packer #(
    parameter bit MSB_FIRST = 1'b1,
    parameter bit INVERT = 1'b0
) (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       pixel_valid,
    output logic       pixel_ready,
    input  logic       pixel_i,
    input  logic       pixel_last,

    output logic       byte_valid,
    input  logic       byte_ready,
    output logic [7:0] byte_o,
    output logic       byte_last
);
    logic [7:0] shreg_q, shreg_d;
    logic [2:0] count_q, count_d;
    logic       out_valid_q, out_valid_d;
    logic [7:0] out_byte_q, out_byte_d;
    logic       out_last_q, out_last_d;
    logic [7:0] packed_next;
    logic       pixel_value;

    wire output_blocked = out_valid_q && !byte_ready;
    wire will_complete_byte = (count_q == 3'd7) || pixel_last;

    assign pixel_ready = !output_blocked;
    assign byte_valid = out_valid_q;
    assign byte_o = out_byte_q;
    assign byte_last = out_last_q;

    always @* begin
        shreg_d = shreg_q;
        count_d = count_q;
        out_valid_d = out_valid_q;
        out_byte_d = out_byte_q;
        out_last_d = out_last_q;
        packed_next = shreg_q;
        pixel_value = pixel_i ^ INVERT;

        if (out_valid_q && byte_ready) begin
            out_valid_d = 1'b0;
            out_last_d = 1'b0;
        end

        if (pixel_valid && pixel_ready) begin
            if (MSB_FIRST) begin
                packed_next[3'd7 - count_q] = pixel_value;
            end else begin
                packed_next[count_q] = pixel_value;
            end
            shreg_d = packed_next;

            if (will_complete_byte) begin
                out_valid_d = 1'b1;
                out_byte_d = packed_next;
                out_last_d = pixel_last;
                shreg_d = '0;
                count_d = '0;
            end else begin
                count_d = count_q + 1'b1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shreg_q <= '0;
            count_q <= '0;
            out_valid_q <= 1'b0;
            out_byte_q <= '0;
            out_last_q <= 1'b0;
        end else begin
            shreg_q <= shreg_d;
            count_q <= count_d;
            out_valid_q <= out_valid_d;
            out_byte_q <= out_byte_d;
            out_last_q <= out_last_d;
        end
    end
endmodule
