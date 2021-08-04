module flopencr #(parameter WIDTH=32)
(
    input logic clk,
    input logic reset_n,
    input logic [WIDTH-1:0] init,
    input logic wr_en,
    input logic clr,
    input logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out
);

always_ff @(posedge clk)
    if(!reset_n)
        out <= init;
    else if(clr)
        out <= init;
    else if(wr_en)
        out <= in;

endmodule
