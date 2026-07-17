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
    logic timeout;
    logic error;
    logic hold_in_valid;
    logic hold_in_ready;
    logic [8:0] hold_in_data;
    logic hold_in_last;
    logic hold_epd_cs_n;
    logic hold_epd_sclk;
    logic hold_epd_mosi;
    logic hold_epd_dc;
    logic hold_epd_rst_n;
    logic hold_frame_done;
    logic hold_timeout;
    logic hold_error;
    logic hold_sclk_q;
    logic hold_cs_seen_high_between;
    int hold_sampled_count;
    int hold_sampled_byte_count;
    logic epd_sclk_q;

    logic [7:0] sampled_byte;
    logic [7:0] sampled_bytes [0:3];
    logic sampled_dc [0:3];
    int sampled_count;
    int sampled_byte_count;
    int reset_low_count;
    int reset_high_wait_count;
    int clk_cycle_count;
    int last_sclk_rise_cycle;
    int sclk_rise_delta;
    int sclk_rise_checks;

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
        .frame_done(frame_done),
        .timeout(timeout),
        .error(error)
    );

    epaper_spi_stream_controller #(
        .CLK_HZ(1_000_000),
        .SPI_HZ(250_000),
        .RESET_LOW_US(2),
        .RESET_HIGH_US(2),
        .HOLD_CS_UNTIL_LAST(1'b1)
    ) hold_dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(hold_in_valid),
        .in_ready(hold_in_ready),
        .in_data(hold_in_data),
        .in_last(hold_in_last),
        .epd_busy(1'b0),
        .epd_cs_n(hold_epd_cs_n),
        .epd_sclk(hold_epd_sclk),
        .epd_mosi(hold_epd_mosi),
        .epd_dc(hold_epd_dc),
        .epd_rst_n(hold_epd_rst_n),
        .frame_done(hold_frame_done),
        .timeout(hold_timeout),
        .error(hold_error)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        clk_cycle_count <= clk_cycle_count + 1;
    end

    always @(negedge clk) begin
        hold_sclk_q <= hold_epd_sclk;
        if (!hold_epd_cs_n && hold_epd_sclk && !hold_sclk_q) begin
            hold_sampled_count = hold_sampled_count + 1;
            if ((hold_sampled_count % 8) == 7) begin
                hold_sampled_byte_count = hold_sampled_byte_count + 1;
            end
        end
        if (hold_sampled_byte_count == 1 && hold_epd_cs_n) begin
            hold_cs_seen_high_between = 1'b1;
        end
    end

    initial begin
        #100000;
        $fatal(1, "test timeout");
    end

    always @(negedge clk) begin
        epd_sclk_q <= epd_sclk;
        if (!epd_cs_n && epd_sclk && !epd_sclk_q) begin
            if (last_sclk_rise_cycle >= 0 && (sampled_count % 8) != 0) begin
                sclk_rise_delta = clk_cycle_count - last_sclk_rise_cycle;
                if (sclk_rise_delta != 4) begin
                    $fatal(1, "unexpected SCLK rising-edge period: %0d cycles",
                           sclk_rise_delta);
                end
                sclk_rise_checks = sclk_rise_checks + 1;
            end
            last_sclk_rise_cycle = clk_cycle_count;

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

    task automatic hold_send_word(input logic dc, input logic [7:0] byte_value, input logic last_value);
        begin
            wait (hold_in_ready);
            @(negedge clk);
            hold_in_data = {dc, byte_value};
            hold_in_last = last_value;
            hold_in_valid = 1'b1;
            @(posedge clk);
            @(negedge clk);
            hold_in_valid = 1'b0;
            hold_in_last = 1'b0;
        end
    endtask

    initial begin
        in_valid = 1'b0;
        in_data = '0;
        in_last = 1'b0;
        hold_in_valid = 1'b0;
        hold_in_data = '0;
        hold_in_last = 1'b0;
        epd_busy = 1'b0;
        epd_sclk_q = 1'b0;
        hold_sclk_q = 1'b0;
        hold_cs_seen_high_between = 1'b0;
        hold_sampled_count = 0;
        hold_sampled_byte_count = 0;
        sampled_byte = '0;
        sampled_count = 0;
        sampled_byte_count = 0;
        reset_low_count = 0;
        reset_high_wait_count = 0;
        clk_cycle_count = 0;
        last_sclk_rise_cycle = -1;
        sclk_rise_delta = 0;
        sclk_rise_checks = 0;
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
        if (sclk_rise_checks < 14) begin
            $fatal(1, "too few SCLK period checks: %0d", sclk_rise_checks);
        end

        if (sampled_bytes[0] != 8'h12 || sampled_dc[0] != 1'b0) begin
            $fatal(1, "unexpected command byte: dc=%0b byte=%02h",
                   sampled_dc[0], sampled_bytes[0]);
        end

        if (sampled_bytes[1] != 8'ha5 || sampled_dc[1] != 1'b1) begin
            $fatal(1, "unexpected data byte: dc=%0b byte=%02h",
                   sampled_dc[1], sampled_bytes[1]);
        end
        if (timeout || error) begin
            $fatal(1, "unexpected timeout/error in normal transfer");
        end

        wait (hold_in_ready);
        hold_send_word(1'b0, 8'h33, 1'b0);
        wait (hold_sampled_byte_count == 1);
        hold_send_word(1'b1, 8'hcc, 1'b1);
        wait (hold_frame_done);
        repeat (2) @(posedge clk);
        @(negedge clk);
        if (hold_cs_seen_high_between) begin
            $fatal(1, "CS deasserted between bytes in hold-CS mode");
        end
        if (!hold_epd_cs_n) begin
            $fatal(1, "CS did not deassert after last byte in hold-CS mode");
        end
        if (hold_timeout || hold_error) begin
            $fatal(1, "unexpected timeout/error in hold-CS transfer");
        end

        $finish;
    end
endmodule
