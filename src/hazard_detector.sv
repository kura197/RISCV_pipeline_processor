`include "lib_pkg.sv";

module hazard_detector 
import lib_pkg::*;
#(
) 
(
    input logic [4:0] rd_ex,
    input logic [4:0] rd_mem,
    input logic [4:0] rd_wb,
    input logic [4:0] rs1_dec,
    input logic [4:0] rs2_dec,
    input logic [4:0] rs1_ex,
    input logic [4:0] rs2_ex,
    output logic [1:0] sel_rdata1_f,
    output logic [1:0] sel_rdata2_f,
    input logic load,
    output logic load_hazard
);

assign load_hazard = load && ((rd_ex == rs1_dec) || (rd_ex == rs2_dec));

assign sel_rdata1_f = (rs1_ex != 0 && rd_mem == rs1_ex) ? 2'b01 :
                      (rs1_ex != 0 && rd_wb == rs1_ex)  ? 2'b10 : 2'b00;

assign sel_rdata2_f = (rs2_ex != 0 && rd_mem == rs2_ex) ? 2'b01 :
                      (rs2_ex != 0 && rd_wb == rs2_ex)  ? 2'b10 : 2'b00;
    
endmodule