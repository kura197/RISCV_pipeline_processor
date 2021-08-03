module hazard_detector #(
) 
(
    input [4:0] rd_mem,
    input [4:0] rd_wb,
    input [4:0] rs1_ex,
    input [4:0] rs2_ex,
    output [1:0] sel_rdata1_f,
    output [1:0] sel_rdata2_f
);

//// TODO: support stall

assign sel_rdata1_f = (rd_mem == rs1_ex) ? 2'b01 :
                      (rd_wb == rs1_ex)  ? 2'b10 : 2'b00;

assign sel_rdata2_f = (rd_mem == rs2_ex) ? 2'b01 :
                      (rd_wb == rs2_ex)  ? 2'b10 : 2'b00;
    
endmodule