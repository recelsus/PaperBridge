module epaper_window_sequence_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;

    logic start;
    logic out_valid;
    logic out_ready;
    logic [8:0] out_data;
    logic out_last;
    logic busy;
    logic done;

    logic [8:0] expected [0:12];
    int idx;

    epaper_window_sequence dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .x_start_px(16'd8),
        .x_end_px(16'd23),
        .y_start(16'h0012),
        .y_end(16'h0123),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data(out_data),
        .out_last(out_last),
        .busy(busy),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        expected[0]  = {1'b0, 8'h44};
        expected[1]  = {1'b1, 8'h01};
        expected[2]  = {1'b1, 8'h02};
        expected[3]  = {1'b0, 8'h45};
        expected[4]  = {1'b1, 8'h12};
        expected[5]  = {1'b1, 8'h00};
        expected[6]  = {1'b1, 8'h23};
        expected[7]  = {1'b1, 8'h01};
        expected[8]  = {1'b0, 8'h4e};
        expected[9]  = {1'b1, 8'h01};
        expected[10] = {1'b0, 8'h4f};
        expected[11] = {1'b1, 8'h12};
        expected[12] = {1'b1, 8'h00};

        start = 1'b0;
        out_ready = 1'b1;
        idx = 0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        while (!done) begin
            @(posedge clk);
            if (out_valid) begin
                if (out_data != expected[idx]) begin
                    $fatal(1, "step %0d expected %03h got %03h", idx, expected[idx], out_data);
                end
                if ((idx == 12) != out_last) begin
                    $fatal(1, "unexpected out_last at step %0d", idx);
                end
                idx = idx + 1;
            end
        end

        if (idx != 13) begin
            $fatal(1, "unexpected step count %0d", idx);
        end

        $finish;
    end
endmodule
