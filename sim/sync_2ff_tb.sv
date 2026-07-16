module sync_2ff_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic async_i;
    logic sync_o;

    sync_2ff dut (
        .clk(clk),
        .rst_n(rst_n),
        .async_i(async_i),
        .sync_o(sync_o)
    );

    always #5 clk = ~clk;

    initial begin
        #100000;
        $fatal(1, "test timeout");
    end

    initial begin
        async_i = 1'b0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        if (sync_o !== 1'b0) begin
            $fatal(1, "unexpected reset value");
        end

        @(negedge clk);
        async_i = 1'b1;

        @(posedge clk);
        @(negedge clk);
        if (sync_o !== 1'b0) begin
            $fatal(1, "sync_o changed too early");
        end

        @(posedge clk);
        @(negedge clk);
        if (sync_o !== 1'b1) begin
            $fatal(1, "sync_o did not update after two stages");
        end

        @(negedge clk);
        async_i = 1'b0;

        @(posedge clk);
        @(negedge clk);
        if (sync_o !== 1'b1) begin
            $fatal(1, "sync_o dropped too early");
        end

        @(posedge clk);
        @(negedge clk);
        if (sync_o !== 1'b0) begin
            $fatal(1, "sync_o did not drop after two stages");
        end

        $finish;
    end
endmodule
