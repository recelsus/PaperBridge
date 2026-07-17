module epaper_spi_bad_param_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic in_ready;

    epaper_spi_stream_controller #(
        .CLK_HZ(1_000_000),
        .SPI_HZ(750_000),
        .RESET_LOW_US(0),
        .RESET_HIGH_US(0)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(1'b0),
        .in_ready(in_ready),
        .in_data(9'h000),
        .in_last(1'b0),
        .epd_busy(1'b0),
        .epd_cs_n(),
        .epd_sclk(),
        .epd_mosi(),
        .epd_dc(),
        .epd_rst_n(),
        .frame_done()
    );

    always #5 clk = ~clk;

    initial begin
        #1000;
        $fatal(1, "bad parameter test did not fail");
    end
endmodule
