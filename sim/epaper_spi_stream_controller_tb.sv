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
    logic [7:0] sampled_bytes [0:3];
    logic sampled_dc [0:3];
    int sampled_count;
    int sampled_byte_count;
    int reset_low_count;
    int reset_high_wait_count;

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
            if ((sampled_count % 8) == 0) begin
                sampled_dc[sampled_byte_count] = epd_dc;
            end
            sampled_byte = {sampled_byte[6:0], epd_mosi};
            if ((sampled_count % 8) == 7) begin
                sampled_bytes[sampled_byte_count] = sampled_byte;
                sampled_byte_count = sampled_byte_count + 1;
            end
            sampled_count = sampled_count + 1;
        end
    end

    task automatic send_word(input logic dc, input logic [7:0] byte_value, input logic last_value);
        begin
            wait (in_ready);
            @(negedge clk);
            in_data = {dc, byte_value};
            in_last = last_value;
            in_valid = 1'b1;
            @(posedge clk);
            @(negedge clk);
            in_valid = 1'b0;
            in_last = 1'b0;
        end
    endtask

    initial begin
        in_valid = 1'b0;
        in_data = '0;
        in_last = 1'b0;
        epd_busy = 1'b0;
        epd_sclk_q = 1'b0;
        sampled_byte = '0;
        sampled_count = 0;
        sampled_byte_count = 0;
        reset_low_count = 0;
        reset_high_wait_count = 0;
        for (int i = 0; i < 4; i++) begin
            sampled_bytes[i] = '0;
            sampled_dc[i] = 1'b0;
        end

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        while (!epd_rst_n) begin
            reset_low_count = reset_low_count + 1;
            @(posedge clk);
        end
        while (!in_ready) begin
            reset_high_wait_count = reset_high_wait_count + 1;
            @(posedge clk);
        end

        if (reset_low_count < 2) begin
            $fatal(1, "reset low was too short: %0d cycles", reset_low_count);
        end
        if (reset_high_wait_count < 2) begin
            $fatal(1, "reset high wait was too short: %0d cycles", reset_high_wait_count);
        end

        epd_busy = 1'b1;
        repeat (4) @(posedge clk);
        if (in_ready) begin
            $fatal(1, "in_ready asserted while synchronized busy was active");
        end

        epd_busy = 1'b0;
        send_word(1'b0, 8'h12, 1'b0);
        wait (sampled_byte_count == 1);
        send_word(1'b1, 8'ha5, 1'b1);

        wait (frame_done);
        if (!frame_done) begin
            $fatal(1, "frame_done was not observable as a pulse");
        end
        repeat (2) @(posedge clk);
        @(negedge clk);
        if (frame_done) begin
            $fatal(1, "frame_done stayed high for more than one cycle");
        end

        if (sampled_byte_count != 2) begin
            $fatal(1, "unexpected spi byte count: %0d", sampled_byte_count);
        end

        if (sampled_bytes[0] != 8'h12 || sampled_dc[0] != 1'b0) begin
            $fatal(1, "unexpected command byte: dc=%0b byte=%02h",
                   sampled_dc[0], sampled_bytes[0]);
        end

        if (sampled_bytes[1] != 8'ha5 || sampled_dc[1] != 1'b1) begin
            $fatal(1, "unexpected data byte: dc=%0b byte=%02h",
                   sampled_dc[1], sampled_bytes[1]);
        end

        $finish;
    end
endmodule
