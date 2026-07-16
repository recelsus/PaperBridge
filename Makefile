IVERILOG ?= iverilog
VVP ?= vvp

.PHONY: test test-packer test-capture test-epaper clean
test: test-packer test-capture test-epaper

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

clean:
	rm -f /tmp/fb_1bpp_packer_tb.vvp
	rm -f /tmp/serial_pin_capture_tb.vvp
	rm -f /tmp/epaper_spi_stream_controller_tb.vvp
