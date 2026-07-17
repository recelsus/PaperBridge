IVERILOG ?= iverilog
VVP ?= vvp

.PHONY: test test-packer test-capture test-epaper test-epaper-timeout test-epaper-reset test-window test-fill test-skid test-sync test-bad-params clean
test: test-packer test-capture test-epaper test-epaper-timeout test-epaper-reset test-window test-fill test-skid test-sync test-bad-params

test-packer:
	$(IVERILOG) -g2012 -o /tmp/fb_1bpp_packer_tb.vvp \
		rtl/framebuffer/fb_1bpp_packer.sv \
		sim/fb_1bpp_packer_tb.sv
	$(VVP) /tmp/fb_1bpp_packer_tb.vvp

test-capture:
	$(IVERILOG) -g2012 -o /tmp/serial_pin_capture_tb.vvp \
		rtl/capture/serial_pin_capture.sv \
		sim/serial_pin_capture_tb.sv
	$(VVP) /tmp/serial_pin_capture_tb.vvp

test-epaper:
	$(IVERILOG) -g2012 -o /tmp/epaper_spi_stream_controller_tb.vvp \
		rtl/common/sync_2ff.sv \
		rtl/spi/spi_tx.sv \
		rtl/epaper/epaper_reset_controller.sv \
		rtl/epaper/epaper_spi_stream_controller.sv \
		sim/epaper_spi_stream_controller_tb.sv
	$(VVP) /tmp/epaper_spi_stream_controller_tb.vvp

test-epaper-timeout:
	$(IVERILOG) -g2012 -o /tmp/epaper_spi_timeout_tb.vvp \
		rtl/common/sync_2ff.sv \
		rtl/spi/spi_tx.sv \
		rtl/epaper/epaper_reset_controller.sv \
		rtl/epaper/epaper_spi_stream_controller.sv \
		sim/epaper_spi_timeout_tb.sv
	$(VVP) /tmp/epaper_spi_timeout_tb.vvp

test-epaper-reset:
	$(IVERILOG) -g2012 -o /tmp/epaper_reset_controller_tb.vvp \
		rtl/epaper/epaper_reset_controller.sv \
		sim/epaper_reset_controller_tb.sv
	$(VVP) /tmp/epaper_reset_controller_tb.vvp

test-window:
	$(IVERILOG) -g2012 -o /tmp/epaper_window_sequence_tb.vvp \
		rtl/epaper/epaper_window_sequence.sv \
		sim/epaper_window_sequence_tb.sv
	$(VVP) /tmp/epaper_window_sequence_tb.vvp

test-fill:
	$(IVERILOG) -g2012 -o /tmp/epaper_frame_fill_tb.vvp \
		rtl/epaper/epaper_frame_fill.sv \
		sim/epaper_frame_fill_tb.sv
	$(VVP) /tmp/epaper_frame_fill_tb.vvp

test-skid:
	$(IVERILOG) -g2012 -o /tmp/rv_skid_buffer_tb.vvp \
		rtl/common/rv_skid_buffer.sv \
		sim/rv_skid_buffer_tb.sv
	$(VVP) /tmp/rv_skid_buffer_tb.vvp

test-sync:
	$(IVERILOG) -g2012 -o /tmp/sync_2ff_tb.vvp \
		rtl/common/sync_2ff.sv \
		sim/sync_2ff_tb.sv
	$(VVP) /tmp/sync_2ff_tb.vvp

test-bad-params:
	$(IVERILOG) -g2012 -o /tmp/epaper_spi_bad_param_tb.vvp \
		rtl/common/sync_2ff.sv \
		rtl/spi/spi_tx.sv \
		rtl/epaper/epaper_reset_controller.sv \
		rtl/epaper/epaper_spi_stream_controller.sv \
		sim/epaper_spi_bad_param_tb.sv
	@if $(VVP) /tmp/epaper_spi_bad_param_tb.vvp >/tmp/epaper_spi_bad_param_tb.log 2>&1; then \
		cat /tmp/epaper_spi_bad_param_tb.log; \
		echo "expected epaper bad parameter simulation to fail"; \
		exit 1; \
	else \
		cat /tmp/epaper_spi_bad_param_tb.log; \
	fi
	$(IVERILOG) -g2012 -o /tmp/serial_pin_capture_bad_param_tb.vvp \
		rtl/capture/serial_pin_capture.sv \
		sim/serial_pin_capture_bad_param_tb.sv
	@if $(VVP) /tmp/serial_pin_capture_bad_param_tb.vvp >/tmp/serial_pin_capture_bad_param_tb.log 2>&1; then \
		cat /tmp/serial_pin_capture_bad_param_tb.log; \
		echo "expected capture bad parameter simulation to fail"; \
		exit 1; \
	else \
		cat /tmp/serial_pin_capture_bad_param_tb.log; \
	fi

clean:
	rm -f /tmp/fb_1bpp_packer_tb.vvp
	rm -f /tmp/serial_pin_capture_tb.vvp
	rm -f /tmp/epaper_spi_stream_controller_tb.vvp
	rm -f /tmp/epaper_spi_timeout_tb.vvp
	rm -f /tmp/epaper_reset_controller_tb.vvp
	rm -f /tmp/epaper_window_sequence_tb.vvp
	rm -f /tmp/epaper_frame_fill_tb.vvp
	rm -f /tmp/rv_skid_buffer_tb.vvp
	rm -f /tmp/sync_2ff_tb.vvp
	rm -f /tmp/epaper_spi_bad_param_tb.vvp
	rm -f /tmp/serial_pin_capture_bad_param_tb.vvp
	rm -f /tmp/epaper_spi_bad_param_tb.log
	rm -f /tmp/serial_pin_capture_bad_param_tb.log
