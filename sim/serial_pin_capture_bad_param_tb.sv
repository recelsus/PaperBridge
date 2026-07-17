module serial_pin_capture_bad_param_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic event_valid;
    logic [23:0] event_data;
    logic overflow;

    serial_pin_capture #(
        .PIN_COUNT(9),
        .TIMESTAMP_WIDTH(8),
        .FIFO_DEPTH(1)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pins_i(9'h000),
        .edge_enable_i(9'h000),
        .level_mask_i(9'h000),
        .level_value_i(9'h000),
        .event_valid(event_valid),
        .event_ready(1'b0),
        .event_data(event_data),
        .overflow(overflow)
    );

    always #5 clk = ~clk;

    initial begin
        #1000;
        $fatal(1, "bad parameter test did not fail");
    end
endmodule
