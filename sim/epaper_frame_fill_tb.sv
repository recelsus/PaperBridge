module epaper_frame_fill_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;

    logic start;
    logic out_valid;
    logic out_ready;
    logic [8:0] out_data;
    logic out_last;
    logic busy;
    logic done;
    int idx;

    epaper_frame_fill #(
        .COUNT_WIDTH(8)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .fill_byte(8'hff),
        .byte_count(8'd3),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data(out_data),
        .out_last(out_last),
        .busy(busy),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        #100000;
        $fatal(1, "test timeout");
    end

    initial begin
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
                if (idx == 0 && out_data != {1'b0, 8'h24}) begin
                    $fatal(1, "expected command 0x24, got %03h", out_data);
                end
                if (idx > 0 && out_data != {1'b1, 8'hff}) begin
                    $fatal(1, "expected fill data, got %03h", out_data);
                end
                if ((idx == 3) != out_last) begin
                    $fatal(1, "unexpected out_last at idx %0d", idx);
                end
                idx = idx + 1;
            end
        end

        if (idx != 4) begin
            $fatal(1, "unexpected output count %0d", idx);
        end

        $finish;
    end
endmodule
