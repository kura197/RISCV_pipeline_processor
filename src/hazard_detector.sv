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
    output logic stall_f,
    output logic stall_d,
    output logic flush_e
);

logic stall_load;
assign stall_load = load && ((rd_ex == rs1_dec) || (rd_ex == rs2_dec));
assign stall_f = stall_load;
assign stall_d = stall_load;
assign flush_e = stall_load;

assign sel_rdata1_f = (rs1_ex != 0 && rd_mem == rs1_ex) ? 2'b01 :
                      (rs1_ex != 0 && rd_wb == rs1_ex)  ? 2'b10 : 2'b00;

assign sel_rdata2_f = (rs2_ex != 0 && rd_mem == rs2_ex) ? 2'b01 :
                      (rs2_ex != 0 && rd_wb == rs2_ex)  ? 2'b10 : 2'b00;
    
endmodule