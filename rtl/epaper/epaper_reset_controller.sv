module epaper_reset_controller #(
    parameter int CLK_HZ = 50_000_000,
    parameter int RESET_LOW_US = 10_000,
    parameter int RESET_HIGH_US = 10_000
) (
    input  logic clk,
    input  logic rst_n,

    output logic epd_rst_n,
    output logic ready
);
    localparam longint RESET_LOW_CYCLES = (RESET_LOW_US == 0)
                                        ? 0
                                        : ((longint'(CLK_HZ) * longint'(RESET_LOW_US)) + 999_999) / 1_000_000;
    localparam longint RESET_HIGH_CYCLES = (RESET_HIGH_US == 0)
                                         ? 0
                                         : ((longint'(CLK_HZ) * longint'(RESET_HIGH_US)) + 999_999) / 1_000_000;
    localparam int RESET_CNT_MAX = (RESET_LOW_CYCLES > RESET_HIGH_CYCLES)
                                 ? RESET_LOW_CYCLES
                                 : RESET_HIGH_CYCLES;
    localparam int RESET_CNT_W = (RESET_CNT_MAX <= 1) ? 1 : $clog2(RESET_CNT_MAX + 1);

    typedef enum logic [1:0] {
        ST_RESET_LOW,
        ST_RESET_HIGH,
        ST_READY
    } state_t;

    state_t state_q;
    logic [RESET_CNT_W-1:0] reset_cnt_q;

`ifndef SYNTHESIS
    initial begin
        if (CLK_HZ <= 0) begin
            $fatal(1, "CLK_HZ must be greater than zero");
        end
        if (RESET_LOW_US < 0) begin
            $fatal(1, "RESET_LOW_US must be non-negative");
        end
        if (RESET_HIGH_US < 0) begin
            $fatal(1, "RESET_HIGH_US must be non-negative");
        end
    end
`endif

    assign epd_rst_n = (state_q != ST_RESET_LOW);
    assign ready = (state_q == ST_READY);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= ST_RESET_LOW;
            reset_cnt_q <= '0;
        end else begin
            case (state_q)
                ST_RESET_LOW: begin
                    if (RESET_LOW_CYCLES == 0 || reset_cnt_q >= RESET_LOW_CYCLES - 1) begin
                        reset_cnt_q <= '0;
                        state_q <= ST_RESET_HIGH;
                    end else begin
                        reset_cnt_q <= reset_cnt_q + 1'b1;
                    end
                end

                ST_RESET_HIGH: begin
                    if (RESET_HIGH_CYCLES == 0 || reset_cnt_q >= RESET_HIGH_CYCLES - 1) begin
                        reset_cnt_q <= '0;
                        state_q <= ST_READY;
                    end else begin
                        reset_cnt_q <= reset_cnt_q + 1'b1;
                    end
                end

                ST_READY: begin
                    state_q <= ST_READY;
                end

                default: begin
                    state_q <= ST_RESET_LOW;
                    reset_cnt_q <= '0;
                end
            endcase
        end
    end
endmodule
