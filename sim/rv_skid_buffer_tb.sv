module rv_skid_buffer_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;

    logic in_valid;
    logic in_ready;
    logic [7:0] in_data;
    logic in_last;
    logic out_valid;
    logic out_ready;
    logic [7:0] out_data;
    logic out_last;

    rv_skid_buffer dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .in_data(in_data),
        .in_last(in_last),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data(out_data),
        .out_last(out_last)
    );

    always #5 clk = ~clk;

    initial begin
        #100000;
        $fatal(1, "test timeout");
    end

    initial begin
        in_valid = 1'b0;
        in_data = 8'h00;
        in_last = 1'b0;
        out_ready = 1'b0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        in_valid = 1'b1;
        in_data = 8'h5a;
        in_last = 1'b1;
        @(negedge clk);
        in_valid = 1'b0;

        repeat (2) @(posedge clk);
        if (!out_valid || out_data != 8'h5a || !out_last) begin
            $fatal(1, "buffer did not hold output");
        end

        out_ready = 1'b1;
        @(posedge clk);
        @(posedge clk);
        if (out_valid) begin
            $fatal(1, "buffer did not drain");
        end

        $finish;
    end
endmodule
