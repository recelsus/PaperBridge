IVERILOG ?= iverilog
VVP ?= vvp

.PHONY: test test-packer test-capture test-epaper test-window test-fill test-skid clean
test: test-packer test-capture test-epaper test-window test-fill test-skid

test-packer:
	$(IVERILOG) -g2012 -o /tmp/fb_1bpp_packer_tb.vvp \
		templates/03_framebuffer_packer/fb_1bpp_packer.sv \
		sim/fb_1bpp_packer_tb.sv
	$(VVP) /tmp/fb_1bpp_packer_tb.vvp

test-capture:
	$(IVERILOG) -g2012 -o /tmp/serial_pin_capture_tb.vvp \
		templates/02_protocol_capture_trigger/serial_pin_capture.sv \
		sim/serial_pin_capture_tb.sv
	$(VVP) /tmp/serial_pin_capture_tb.vvp

test-epaper:
	$(IVERILOG) -g2012 -o /tmp/epaper_spi_stream_controller_tb.vvp \
		templates/01_spi_epaper_controller/epaper_spi_stream_controller.sv \
		sim/epaper_spi_stream_controller_tb.sv
	$(VVP) /tmp/epaper_spi_stream_controller_tb.vvp

test-window:
	$(IVERILOG) -g2012 -o /tmp/epaper_window_sequence_tb.vvp \
		templates/04_panel_command_builder/epaper_window_sequence.sv \
		sim/epaper_window_sequence_tb.sv
	$(VVP) /tmp/epaper_window_sequence_tb.vvp

test-fill:
	$(IVERILOG) -g2012 -o /tmp/epaper_frame_fill_tb.vvp \
		templates/05_frame_fill_generator/epaper_frame_fill.sv \
		sim/epaper_frame_fill_tb.sv
	$(VVP) /tmp/epaper_frame_fill_tb.vvp

test-skid:
	$(IVERILOG) -g2012 -o /tmp/rv_skid_buffer_tb.vvp \
		rtl/common/rv_skid_buffer.sv \
		sim/rv_skid_buffer_tb.sv
	$(VVP) /tmp/rv_skid_buffer_tb.vvp

clean:
	rm -f /tmp/fb_1bpp_packer_tb.vvp
	rm -f /tmp/serial_pin_capture_tb.vvp
	rm -f /tmp/epaper_spi_stream_controller_tb.vvp
	rm -f /tmp/epaper_window_sequence_tb.vvp
	rm -f /tmp/epaper_frame_fill_tb.vvp
	rm -f /tmp/rv_skid_buffer_tb.vvp
