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

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (3) @(posedge clk);

        pins_i = 4'b0001;
        wait (event_valid);

        if (event_data[47:40] != 8'h01 || event_data[35:32] != 4'b0001) begin
            $fatal(1, "unexpected edge event: %08h", event_data);
        end

        event_ready = 1'b1;
        @(posedge clk);
        event_ready = 1'b0;
        wait (!event_valid);

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
        $finish;
    end
endmodule
