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

    always #5 clk = ~clk;

    task automatic send_pixel(input logic bit_value, input logic last_value);
        begin
            pixel_valid = 1'b1;
            pixel_i = bit_value;
            pixel_last = last_value;
            @(posedge clk);
            while (!pixel_ready) begin
                @(posedge clk);
            end
            pixel_valid = 1'b0;
            pixel_last = 1'b0;
        end
    endtask

    initial begin
        pixel_valid = 1'b0;
        pixel_i = 1'b0;
        pixel_last = 1'b0;
        byte_ready = 1'b0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        send_pixel(1'b1, 1'b0);
        send_pixel(1'b0, 1'b0);
        send_pixel(1'b1, 1'b0);
        send_pixel(1'b0, 1'b0);
        send_pixel(1'b1, 1'b0);
        send_pixel(1'b0, 1'b0);
        send_pixel(1'b1, 1'b0);
        send_pixel(1'b0, 1'b1);

        @(posedge clk);
        if (!byte_valid || byte_o != 8'b10101010 || !byte_last) begin
            $fatal(1, "unexpected packed byte: valid=%0b byte=%02h last=%0b",
                   byte_valid, byte_o, byte_last);
        end

        byte_ready = 1'b1;
        @(posedge clk);
        $finish;
    end
endmodule
