IVERILOG ?= iverilog
VVP ?= vvp

.PHONY: test
test:
	$(IVERILOG) -g2012 -o /tmp/fb_1bpp_packer_tb.vvp \
		templates/03_framebuffer_packer/fb_1bpp_packer.sv \
		sim/fb_1bpp_packer_tb.sv
	$(VVP) /tmp/fb_1bpp_packer_tb.vvp
