module epaper_spi_stream_controller_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;

    logic in_valid;
    logic in_ready;
    logic [8:0] in_data;
    logic in_last;
    logic epd_busy;
    logic epd_cs_n;
    logic epd_sclk;
    logic epd_mosi;
    logic epd_dc;
    logic epd_rst_n;
    logic frame_done;
    logic epd_sclk_q;

    logic [7:0] sampled_byte;
    int sampled_count;

    epaper_spi_stream_controller #(
        .CLK_HZ(1_000_000),
        .SPI_HZ(250_000),
        .RESET_LOW_US(2),
        .RESET_HIGH_US(2)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .in_data(in_data),
        .in_last(in_last),
        .epd_busy(epd_busy),
        .epd_cs_n(epd_cs_n),
        .epd_sclk(epd_sclk),
        .epd_mosi(epd_mosi),
        .epd_dc(epd_dc),
        .epd_rst_n(epd_rst_n),
        .frame_done(frame_done)
    );

    always #5 clk = ~clk;

    initial begin
        #100000;
        $fatal(1, "test timeout");
    end

    always @(negedge clk) begin
        epd_sclk_q <= epd_sclk;
        if (!epd_cs_n && epd_sclk && !epd_sclk_q) begin
            sampled_byte = {sampled_byte[6:0], epd_mosi};
            sampled_count = sampled_count + 1;
        end
    end

    initial begin
        in_valid = 1'b0;
        in_data = '0;
        in_last = 1'b0;
        epd_busy = 1'b0;
        epd_sclk_q = 1'b0;
        sampled_byte = '0;
        sampled_count = 0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        wait (in_ready);
        @(negedge clk);
        in_data = {1'b1, 8'ha5};
        in_last = 1'b1;
        in_valid = 1'b1;
        @(posedge clk);
        @(negedge clk);
        in_valid = 1'b0;
        in_last = 1'b0;

        wait (frame_done);
        @(posedge clk);

        if (epd_dc != 1'b1) begin
            $fatal(1, "dc pin was not driven as data");
        end

        if (sampled_count != 8 || sampled_byte != 8'ha5) begin
            $fatal(1, "unexpected spi byte: count=%0d byte=%02h",
                   sampled_count, sampled_byte);
        end

        $finish;
    end
endmodule
