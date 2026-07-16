module sync_2ff #(
    parameter bit RESET_VALUE = 1'b0
) (
    input  logic clk,
    input  logic rst_n,
    input  logic async_i,
    output logic sync_o
);
    logic stage_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_q <= RESET_VALUE;
            sync_o <= RESET_VALUE;
        end else begin
            stage_q <= async_i;
            sync_o <= stage_q;
        end
    end
endmodule
