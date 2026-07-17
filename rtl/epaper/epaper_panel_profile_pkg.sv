package epaper_panel_profile_pkg;
    localparam logic [7:0] EPD_CMD_DRIVER_OUTPUT_CONTROL    = 8'h01;
    localparam logic [7:0] EPD_CMD_GATE_DRIVING_VOLTAGE     = 8'h03;
    localparam logic [7:0] EPD_CMD_SOURCE_DRIVING_VOLTAGE   = 8'h04;
    localparam logic [7:0] EPD_CMD_BOOSTER_SOFT_START       = 8'h0c;
    localparam logic [7:0] EPD_CMD_DEEP_SLEEP               = 8'h10;
    localparam logic [7:0] EPD_CMD_DATA_ENTRY_MODE          = 8'h11;
    localparam logic [7:0] EPD_CMD_SW_RESET                 = 8'h12;
    localparam logic [7:0] EPD_CMD_TEMPERATURE_SENSOR       = 8'h18;
    localparam logic [7:0] EPD_CMD_MASTER_ACTIVATE          = 8'h20;
    localparam logic [7:0] EPD_CMD_DISPLAY_UPDATE_CONTROL_1 = 8'h21;
    localparam logic [7:0] EPD_CMD_DISPLAY_UPDATE_CONTROL_2 = 8'h22;
    localparam logic [7:0] EPD_CMD_WRITE_BW_RAM             = 8'h24;
    localparam logic [7:0] EPD_CMD_WRITE_RED_RAM            = 8'h26;
    localparam logic [7:0] EPD_CMD_WRITE_VCOM_REGISTER      = 8'h2c;
    localparam logic [7:0] EPD_CMD_WRITE_LUT_REGISTER       = 8'h32;
    localparam logic [7:0] EPD_CMD_BORDER_WAVEFORM          = 8'h3c;
    localparam logic [7:0] EPD_CMD_SET_RAM_X                = 8'h44;
    localparam logic [7:0] EPD_CMD_SET_RAM_Y                = 8'h45;
    localparam logic [7:0] EPD_CMD_SET_RAM_X_COUNTER        = 8'h4e;
    localparam logic [7:0] EPD_CMD_SET_RAM_Y_COUNTER        = 8'h4f;

    localparam int EPD_2IN13_WIDTH_PX  = 122;
    localparam int EPD_2IN13_HEIGHT_PX = 250;
    localparam int EPD_2IN13_X_BYTES   = 16;

    localparam int EPD_2IN9_WIDTH_PX   = 128;
    localparam int EPD_2IN9_HEIGHT_PX  = 296;
    localparam int EPD_2IN9_X_BYTES    = 16;

    localparam int EPD_4IN2_WIDTH_PX   = 400;
    localparam int EPD_4IN2_HEIGHT_PX  = 300;
    localparam int EPD_4IN2_X_BYTES    = 50;
endpackage
