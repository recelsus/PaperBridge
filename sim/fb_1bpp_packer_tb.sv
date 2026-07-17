module fb_1bpp_packer_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;

    logic pixel_valid;
    logic pixel_ready;
    logic pixel_i;
    logic pixel_last;
    logic byte_valid;
    logic byte_ready;
    logic [7:0] byte_o;
    logic byte_last;
    int output_count;

    logic lsb_pixel_valid;
    logic lsb_pixel_ready;
    logic lsb_pixel_i;
    logic lsb_pixel_last;
    logic lsb_byte_valid;
    logic lsb_byte_ready;
    logic [7:0] lsb_byte_o;
    logic lsb_byte_last;

    logic inv_pixel_valid;
    logic inv_pixel_ready;
    logic inv_pixel_i;
    logic inv_pixel_last;
    logic inv_byte_valid;
    logic inv_byte_ready;
    logic [7:0] inv_byte_o;
    logic inv_byte_last;

    fb_1bpp_packer dut (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_valid(pixel_valid),
        .pixel_ready(pixel_ready),
        .pixel_i(pixel_i),
        .pixel_last(pixel_last),
        .byte_valid(byte_valid),
        .byte_ready(byte_ready),
        .byte_o(byte_o),
        .byte_last(byte_last)
    );

    fb_1bpp_packer #(
        .MSB_FIRST(1'b0)
    ) lsb_dut (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_valid(lsb_pixel_valid),
        .pixel_ready(lsb_pixel_ready),
        .pixel_i(lsb_pixel_i),
        .pixel_last(lsb_pixel_last),
        .byte_valid(lsb_byte_valid),
        .byte_ready(lsb_byte_ready),
        .byte_o(lsb_byte_o),
        .byte_last(lsb_byte_last)
    );

    fb_1bpp_packer #(
        .INVERT(1'b1)
    ) inv_dut (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_valid(inv_pixel_valid),
        .pixel_ready(inv_pixel_ready),
        .pixel_i(inv_pixel_i),
        .pixel_last(inv_pixel_last),
        .byte_valid(inv_byte_valid),
        .byte_ready(inv_byte_ready),
        .byte_o(inv_byte_o),
        .byte_last(inv_byte_last)
    );

    always #5 clk = ~clk;

    initial begin
        #100000;
        $fatal(1, "test timeout");
    end

    task automatic reset_dut;
        begin
            rst_n = 1'b0;
            pixel_valid = 1'b0;
            pixel_i = 1'b0;
            pixel_last = 1'b0;
            byte_ready = 1'b0;
            lsb_pixel_valid = 1'b0;
            lsb_pixel_i = 1'b0;
            lsb_pixel_last = 1'b0;
            lsb_byte_ready = 1'b0;
            inv_pixel_valid = 1'b0;
            inv_pixel_i = 1'b0;
            inv_pixel_last = 1'b0;
            inv_byte_ready = 1'b0;
            output_count = 0;
            repeat (4) @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);
        end
    endtask

    task automatic send_pixel(input logic bit_value, input logic last_value);
        begin
            @(negedge clk);
            pixel_valid = 1'b1;
            pixel_i = bit_value;
            pixel_last = last_value;
            @(posedge clk);
            while (!pixel_ready) begin
                @(posedge clk);
            end
            @(negedge clk);
            pixel_valid = 1'b0;
            pixel_last = 1'b0;
        end
    endtask

    task automatic expect_byte(input logic [7:0] expected_byte, input logic expected_last);
        begin
            wait (byte_valid);
            @(negedge clk);
            if (byte_o != expected_byte || byte_last != expected_last) begin
                $fatal(1, "expected byte=%02h last=%0b, got byte=%02h last=%0b",
                       expected_byte, expected_last, byte_o, byte_last);
            end
            output_count = output_count + 1;
            byte_ready = 1'b1;
            @(posedge clk);
            @(negedge clk);
            byte_ready = 1'b0;
        end
    endtask

    task automatic send_lsb_pixel(input logic bit_value, input logic last_value);
        begin
            @(negedge clk);
            lsb_pixel_valid = 1'b1;
            lsb_pixel_i = bit_value;
            lsb_pixel_last = last_value;
            @(posedge clk);
            while (!lsb_pixel_ready) begin
                @(posedge clk);
            end
            @(negedge clk);
            lsb_pixel_valid = 1'b0;
            lsb_pixel_last = 1'b0;
        end
    endtask

    task automatic expect_lsb_byte(input logic [7:0] expected_byte, input logic expected_last);
        begin
            wait (lsb_byte_valid);
            @(negedge clk);
            if (lsb_byte_o != expected_byte || lsb_byte_last != expected_last) begin
                $fatal(1, "expected lsb byte=%02h last=%0b, got byte=%02h last=%0b",
                       expected_byte, expected_last, lsb_byte_o, lsb_byte_last);
            end
            lsb_byte_ready = 1'b1;
            @(posedge clk);
            @(negedge clk);
            lsb_byte_ready = 1'b0;
        end
    endtask

    task automatic send_inv_pixel(input logic bit_value, input logic last_value);
        begin
            @(negedge clk);
            inv_pixel_valid = 1'b1;
            inv_pixel_i = bit_value;
            inv_pixel_last = last_value;
            @(posedge clk);
            while (!inv_pixel_ready) begin
                @(posedge clk);
            end
            @(negedge clk);
            inv_pixel_valid = 1'b0;
            inv_pixel_last = 1'b0;
        end
    endtask

    task automatic expect_inv_byte(input logic [7:0] expected_byte, input logic expected_last);
        begin
            wait (inv_byte_valid);
            @(negedge clk);
            if (inv_byte_o != expected_byte || inv_byte_last != expected_last) begin
                $fatal(1, "expected inverted byte=%02h last=%0b, got byte=%02h last=%0b",
                       expected_byte, expected_last, inv_byte_o, inv_byte_last);
            end
            inv_byte_ready = 1'b1;
            @(posedge clk);
            @(negedge clk);
            inv_byte_ready = 1'b0;
        end
    endtask

    task automatic run_partial_case(input int pixel_count);
        logic [7:0] expected;
        begin
            reset_dut();
            expected = '0;
            for (int i = 0; i < pixel_count; i++) begin
                expected[7 - i] = (i % 2) == 0;
                send_pixel((i % 2) == 0, i == pixel_count - 1);
            end
            expect_byte(expected, 1'b1);
        end
    endtask

    initial begin
        for (int n = 1; n <= 7; n++) begin
            run_partial_case(n);
        end

        reset_dut();
        send_pixel(1'b1, 1'b0);
        send_pixel(1'b0, 1'b0);
        send_pixel(1'b1, 1'b0);
        send_pixel(1'b0, 1'b0);
        send_pixel(1'b1, 1'b0);
        send_pixel(1'b0, 1'b0);
        send_pixel(1'b1, 1'b0);
        send_pixel(1'b0, 1'b1);
        expect_byte(8'b10101010, 1'b1);

        reset_dut();
        for (int i = 0; i < 8; i++) begin
            send_pixel(1'b1, 1'b0);
        end
        expect_byte(8'hff, 1'b0);
        send_pixel(1'b0, 1'b1);
        expect_byte(8'h00, 1'b1);

        reset_dut();
        for (int i = 0; i < 8; i++) begin
            send_pixel(1'b0, 1'b0);
        end
        expect_byte(8'h00, 1'b0);

        reset_dut();
        for (int i = 0; i < 8; i++) begin
            send_pixel(1'b1, 1'b0);
        end
        wait (byte_valid);
        @(negedge clk);
        if (byte_o != 8'hff || byte_last != 1'b0 || pixel_ready != 1'b0) begin
            $fatal(1, "backpressure hold failed: byte=%02h last=%0b ready=%0b",
                   byte_o, byte_last, pixel_ready);
        end
        repeat (3) begin
            @(posedge clk);
            @(negedge clk);
            if (byte_o != 8'hff || byte_last != 1'b0 || pixel_ready != 1'b0) begin
                $fatal(1, "output changed during backpressure");
            end
        end
        byte_ready = 1'b1;
        @(posedge clk);

        reset_dut();
        send_pixel(1'b1, 1'b0);
        send_pixel(1'b1, 1'b0);
        @(negedge clk);
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        if (byte_valid) begin
            $fatal(1, "byte_valid stayed high during reset");
        end
        rst_n = 1'b1;
        @(posedge clk);
        send_pixel(1'b0, 1'b1);
        expect_byte(8'h00, 1'b1);

        reset_dut();
        send_lsb_pixel(1'b1, 1'b0);
        send_lsb_pixel(1'b0, 1'b0);
        send_lsb_pixel(1'b1, 1'b0);
        send_lsb_pixel(1'b0, 1'b1);
        expect_lsb_byte(8'h05, 1'b1);

        reset_dut();
        for (int i = 0; i < 8; i++) begin
            send_lsb_pixel((i % 2) == 0, i == 7);
        end
        expect_lsb_byte(8'h55, 1'b1);

        reset_dut();
        send_inv_pixel(1'b1, 1'b0);
        send_inv_pixel(1'b0, 1'b0);
        send_inv_pixel(1'b1, 1'b0);
        send_inv_pixel(1'b0, 1'b1);
        expect_inv_byte(8'h50, 1'b1);

        $finish;
    end
endmodule
