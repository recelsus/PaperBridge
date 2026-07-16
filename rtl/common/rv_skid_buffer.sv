module rv_skid_buffer #(
    parameter int DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic [DATA_WIDTH-1:0] in_data,
    input  logic                  in_last,

    output logic                  out_valid,
    input  logic                  out_ready,
    output logic [DATA_WIDTH-1:0] out_data,
    output logic                  out_last
);
    logic                  full_q;
    logic [DATA_WIDTH-1:0] data_q;
    logic                  last_q;

    assign in_ready = !full_q || out_ready;
    assign out_valid = full_q;
    assign out_data = data_q;
    assign out_last = last_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            full_q <= 1'b0;
            data_q <= '0;
            last_q <= 1'b0;
        end else begin
            if (in_valid && in_ready) begin
                full_q <= 1'b1;
                data_q <= in_data;
                last_q <= in_last;
            end else if (out_ready) begin
                full_q <= 1'b0;
            end
        end
    end
endmodule
