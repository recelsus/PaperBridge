`ifndef PAPERBRIDGE_GENERIC_SSD16XX_2IN13_PROFILE_SVH
`define PAPERBRIDGE_GENERIC_SSD16XX_2IN13_PROFILE_SVH

localparam int PANEL_WIDTH_PX = 122;
localparam int PANEL_HEIGHT_PX = 250;
localparam int PANEL_LINE_BYTES = 16;
localparam int PANEL_FRAME_BYTES = PANEL_LINE_BYTES * PANEL_HEIGHT_PX;

localparam bit PANEL_BUSY_ACTIVE_HIGH = 1'b1;
localparam bit PANEL_WHITE_IS_ONE = 1'b1;
localparam bit PANEL_MSB_FIRST = 1'b1;

localparam logic [7:0] PANEL_CMD_DRIVER_OUTPUT_CONTROL = 8'h01;
localparam logic [7:0] PANEL_CMD_DATA_ENTRY_MODE = 8'h11;
localparam logic [7:0] PANEL_CMD_SW_RESET = 8'h12;
localparam logic [7:0] PANEL_CMD_DISPLAY_UPDATE_CONTROL = 8'h22;
localparam logic [7:0] PANEL_CMD_MASTER_ACTIVATE = 8'h20;
localparam logic [7:0] PANEL_CMD_WRITE_BW_RAM = 8'h24;
localparam logic [7:0] PANEL_CMD_WRITE_RED_RAM = 8'h26;
localparam logic [7:0] PANEL_CMD_BORDER_WAVEFORM = 8'h3c;
localparam logic [7:0] PANEL_CMD_SET_RAM_X = 8'h44;
localparam logic [7:0] PANEL_CMD_SET_RAM_Y = 8'h45;
localparam logic [7:0] PANEL_CMD_SET_RAM_X_COUNTER = 8'h4e;
localparam logic [7:0] PANEL_CMD_SET_RAM_Y_COUNTER = 8'h4f;

`endif
