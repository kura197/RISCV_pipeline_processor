module flopr #(parameter WIDTH=32)
(
    input logic clk,
    input logic reset_n,
    input logic [WIDTH-1:0] init,
    input logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out
);

always_ff @(posedge clk)
    if(!reset_n)
        out <= init;
    else 
        out <= in;

endmodule