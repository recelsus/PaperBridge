module epaper_spi_timeout_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic in_ready;
    logic epd_rst_n;
    logic timeout;
    logic error;

    epaper_spi_stream_controller #(
        .CLK_HZ(1_000_000),
        .SPI_HZ(250_000),
        .RESET_LOW_US(1),
        .RESET_HIGH_US(1),
        .BUSY_TIMEOUT_CYCLES(3)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(1'b0),
        .in_ready(in_ready),
        .in_data(9'h000),
        .in_last(1'b0),
        .epd_busy(1'b1),
        .epd_cs_n(),
        .epd_sclk(),
        .epd_mosi(),
        .epd_dc(),
        .epd_rst_n(epd_rst_n),
        .frame_done(),
        .timeout(timeout),
        .error(error)
    );

    always #5 clk = ~clk;

    initial begin
        #100000;
        $fatal(1, "test timeout");
    end

    initial begin
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        wait (epd_rst_n);
        wait (timeout);

        if (!error) begin
            $fatal(1, "timeout did not set error");
        end
        if (in_ready) begin
            $fatal(1, "in_ready asserted while busy timeout active");
        end

        repeat (4) @(posedge clk);
        if (!timeout || !error) begin
            $fatal(1, "timeout/error did not stay sticky");
        end

        $finish;
    end
endmodule
