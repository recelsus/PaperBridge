`ifndef PAPERBRIDGE_PANEL_PROFILE_SVH
`define PAPERBRIDGE_PANEL_PROFILE_SVH

localparam int PANEL_WIDTH_PX = 0;
localparam int PANEL_HEIGHT_PX = 0;
localparam int PANEL_LINE_BYTES = 0;

localparam bit PANEL_BUSY_ACTIVE_HIGH = 1'b1;
localparam bit PANEL_WHITE_IS_ONE = 1'b1;
localparam bit PANEL_MSB_FIRST = 1'b1;

localparam logic [7:0] PANEL_CMD_SW_RESET = 8'h12;
localparam logic [7:0] PANEL_CMD_DISPLAY_UPDATE_CONTROL = 8'h22;
localparam logic [7:0] PANEL_CMD_MASTER_ACTIVATE = 8'h20;
localparam logic [7:0] PANEL_CMD_WRITE_BW_RAM = 8'h24;
localparam logic [7:0] PANEL_CMD_WRITE_RED_RAM = 8'h26;
localparam logic [7:0] PANEL_CMD_SET_RAM_X = 8'h44;
localparam logic [7:0] PANEL_CMD_SET_RAM_Y = 8'h45;
localparam logic [7:0] PANEL_CMD_SET_RAM_X_COUNTER = 8'h4e;
localparam logic [7:0] PANEL_CMD_SET_RAM_Y_COUNTER = 8'h4f;

`endif
