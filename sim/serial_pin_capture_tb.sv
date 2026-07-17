module serial_pin_capture_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;

    logic [3:0] pins_i;
    logic [3:0] edge_enable_i;
    logic [3:0] level_mask_i;
    logic [3:0] level_value_i;
    logic event_valid;
    logic event_ready;
    logic [47:0] event_data;
    logic overflow;
    logic [1:0] wrap_pins_i;
    logic wrap_event_valid;
    logic wrap_event_ready;
    logic [19:0] wrap_event_data;
    logic wrap_overflow;
    logic [3:0] wrap_ts0;
    logic [3:0] wrap_ts1;

    serial_pin_capture #(
        .PIN_COUNT(4),
        .TIMESTAMP_WIDTH(32),
        .FIFO_DEPTH(2)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pins_i(pins_i),
        .edge_enable_i(edge_enable_i),
        .level_mask_i(level_mask_i),
        .level_value_i(level_value_i),
        .event_valid(event_valid),
        .event_ready(event_ready),
        .event_data(event_data),
        .overflow(overflow)
    );

    serial_pin_capture #(
        .PIN_COUNT(2),
        .TIMESTAMP_WIDTH(4),
        .FIFO_DEPTH(2)
    ) wrap_dut (
        .clk(clk),
        .rst_n(rst_n),
        .pins_i(wrap_pins_i),
        .edge_enable_i(2'b01),
        .level_mask_i(2'b00),
        .level_value_i(2'b00),
        .event_valid(wrap_event_valid),
        .event_ready(wrap_event_ready),
        .event_data(wrap_event_data),
        .overflow(wrap_overflow)
    );

    always #5 clk = ~clk;

    initial begin
        #100000;
        $fatal(1, "test timeout");
    end

    initial begin
        pins_i = 4'b0000;
        edge_enable_i = 4'b0001;
        level_mask_i = 4'b0000;
        level_value_i = 4'b0000;
        event_ready = 1'b0;
        wrap_pins_i = 2'b00;
        wrap_event_ready = 1'b0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (3) @(posedge clk);

        pins_i = 4'b0010;
        repeat (5) @(posedge clk);
        if (event_valid) begin
            $fatal(1, "edge-disabled pin generated an event");
        end
        pins_i = 4'b0000;
        repeat (5) @(posedge clk);

        pins_i = 4'b0001;
        wait (event_valid);

        if (event_data[47:40] != 8'h01 || event_data[35:32] != 4'b0001) begin
            $fatal(1, "unexpected edge event: %08h", event_data);
        end

        event_ready = 1'b1;
        @(posedge clk);
        event_ready = 1'b0;
        wait (!event_valid);

        edge_enable_i = 4'b0000;
        pins_i = 4'b0000;
        repeat (5) @(posedge clk);
        edge_enable_i = 4'b0011;
        pins_i = 4'b0011;
        wait (event_valid);
        if (event_data[47:40] != 8'h01 || event_data[35:32] != 4'b0011) begin
            $fatal(1, "unexpected multi-pin edge event: %08h", event_data);
        end
        event_ready = 1'b1;
        @(posedge clk);
        event_ready = 1'b0;
        wait (!event_valid);
        edge_enable_i = 4'b0001;

        level_mask_i = 4'b0010;
        level_value_i = 4'b0010;
        pins_i = 4'b0011;
        wait (event_valid);

        if (event_data[47:40] != 8'h02 || event_data[35:32] != 4'b0011) begin
            $fatal(1, "unexpected level event: %08h", event_data);
        end

        event_ready = 1'b1;
        @(posedge clk);
        event_ready = 1'b0;
        wait (!event_valid);

        repeat (5) @(posedge clk);
        if (event_valid) begin
            $fatal(1, "level trigger repeated while level stayed true");
        end

        pins_i = 4'b0001;
        repeat (4) @(posedge clk);
        pins_i = 4'b0011;
        wait (event_valid);
        if (event_data[47:40] != 8'h02) begin
            $fatal(1, "level trigger did not fire on re-entry");
        end

        event_ready = 1'b1;
        @(posedge clk);
        event_ready = 1'b0;
        wait (!event_valid);

        level_mask_i = 4'b0000;
        edge_enable_i = 4'b0000;
        pins_i = 4'b0000;
        repeat (4) @(posedge clk);

        edge_enable_i = 4'b0001;
        pins_i = 4'b0001;
        wait (event_valid);
        pins_i = 4'b0000;
        repeat (4) @(posedge clk);

        if (overflow) begin
            $fatal(1, "overflow set while FIFO still had space");
        end

        if (event_data[47:40] != 8'h01 || event_data[35:32] != 4'b0001) begin
            $fatal(1, "unexpected first FIFO event: %08h", event_data);
        end
        event_ready = 1'b1;
        @(posedge clk);
        event_ready = 1'b0;
        @(negedge clk);
        if (event_data[47:40] != 8'h01 || event_data[35:32] != 4'b0000) begin
            $fatal(1, "unexpected second FIFO event: %08h", event_data);
        end
        event_ready = 1'b1;
        @(posedge clk);
        event_ready = 1'b0;
        wait (!event_valid);

        pins_i = 4'b0000;
        repeat (4) @(posedge clk);

        pins_i = 4'b0001;
        wait (event_valid);
        pins_i = 4'b0000;
        repeat (4) @(posedge clk);
        pins_i = 4'b0001;
        repeat (4) @(posedge clk);
        pins_i = 4'b0000;
        repeat (4) @(posedge clk);
        pins_i = 4'b0001;
        repeat (4) @(posedge clk);

        if (!overflow) begin
            $fatal(1, "overflow was not set when capture FIFO filled");
        end

        event_ready = 1'b1;
        @(posedge clk);

        wrap_pins_i = 2'b00;
        wrap_event_ready = 1'b1;
        repeat (20) @(posedge clk);
        wrap_pins_i = 2'b01;
        wait (wrap_event_valid);
        @(negedge clk);
        wrap_ts0 = wrap_event_data[3:0];
        wrap_pins_i = 2'b00;
        repeat (18) @(posedge clk);
        wrap_pins_i = 2'b01;
        wait (wrap_event_valid);
        @(negedge clk);
        wrap_ts1 = wrap_event_data[3:0];
        if (wrap_ts1 >= wrap_ts0) begin
            $fatal(1, "timestamp did not wrap as expected: %01h -> %01h",
                   wrap_ts0, wrap_ts1);
        end

        $finish;
    end
endmodule
