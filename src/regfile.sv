module regfile #(parameter WIDTH=32, ADDR=5)
(
    input logic clk,
    input logic reset_n,
    input logic wr_en,
    input logic [ADDR-1:0] rs1,
    input logic [ADDR-1:0] rs2,
    input logic [ADDR-1:0] rd,
    output logic [WIDTH-1:0] rdata1,
    output logic [WIDTH-1:0] rdata2,
    input logic [WIDTH-1:0] wdata
);

localparam nENTRY = 2**ADDR;
logic [WIDTH-1:0] data [nENTRY];

assign rdata1 = (rs1 == 0) ? 32'd0 : data[rs1];
assign rdata2 = (rs2 == 0) ? 32'd0 : data[rs2];

always_ff @(posedge clk) 
    if(!reset_n) begin
        for(int i = 0; i < nENTRY; i++)
            data[i] <= 0;
        data[2] <= 32'h1000;
    end
    else if(wr_en)
        data[rd] <= wdata;

endmodule