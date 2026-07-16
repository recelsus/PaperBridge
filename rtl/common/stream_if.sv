interface stream_if #(
    parameter int DATA_WIDTH = 8
) (
    input  logic clk,
    input  logic rst_n
);
    logic                  valid;
    logic                  ready;
    logic [DATA_WIDTH-1:0] data;
    logic                  last;

    modport source (
        input  clk,
        input  rst_n,
        output valid,
        input  ready,
        output data,
        output last
    );

    modport sink (
        input  clk,
        input  rst_n,
        input  valid,
        output ready,
        input  data,
        input  last
    );
endinterface
