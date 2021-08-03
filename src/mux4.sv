module mux4 #(parameter WIDTH=32)
(
    input logic [1:0] sel,
    input logic [WIDTH-1:0] in0,
    input logic [WIDTH-1:0] in1,
    input logic [WIDTH-1:0] in2,
    input logic [WIDTH-1:0] in3,
    output logic [WIDTH-1:0] out
);

logic [WIDTH-1:0] d0, d1;

mux2 #(
    .WIDTH(WIDTH)
) mux2_0 (
    .sel(sel[0]),
    .in0(in0),
    .in1(in1),
    .out(d0)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_1 (
    .sel(sel[0]),
    .in0(in2),
    .in1(in3),
    .out(d1)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_2 (
    .sel(sel[1]),
    .in0(d0),
    .in1(d1),
    .out(out)
);

endmodule