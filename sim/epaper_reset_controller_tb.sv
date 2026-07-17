module epaper_reset_controller_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic epd_rst_n;
    logic ready;
    int low_cycles;
    int high_wait_cycles;

    epaper_reset_controller #(
        .CLK_HZ(1_000_000),
        .RESET_LOW_US(3),
        .RESET_HIGH_US(2)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .epd_rst_n(epd_rst_n),
        .ready(ready)
    );

    always #5 clk = ~clk;

    initial begin
        #100000;
        $fatal(1, "test timeout");
    end

    initial begin
        low_cycles = 0;
        high_wait_cycles = 0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        while (!epd_rst_n) begin
            low_cycles = low_cycles + 1;
            @(posedge clk);
        end

        while (!ready) begin
            if (!epd_rst_n) begin
                $fatal(1, "reset pin dropped during high wait");
            end
            high_wait_cycles = high_wait_cycles + 1;
            @(posedge clk);
        end

        if (low_cycles < 3) begin
            $fatal(1, "reset low too short: %0d", low_cycles);
        end

        if (high_wait_cycles < 2) begin
            $fatal(1, "reset high wait too short: %0d", high_wait_cycles);
        end

        repeat (4) @(posedge clk);
        if (!ready || !epd_rst_n) begin
            $fatal(1, "reset controller did not stay ready");
        end

        $finish;
    end
endmodule
