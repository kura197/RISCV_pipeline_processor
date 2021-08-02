module memory #(parameter WIDTH=32, ADDR=10)
(
    input logic clk,
    input logic wr_en,
    input logic [ADDR-1:0] addr,
    output logic [WIDTH-1:0] rdata,
    input logic [WIDTH-1:0] wdata
);

localparam nENTRY = 2**ADDR;
logic [WIDTH-1:0] data [nENTRY];

assign rdata = data[addr];

always_ff @(posedge clk) 
    if(wr_en)
        data[addr] <= wdata;

endmodule