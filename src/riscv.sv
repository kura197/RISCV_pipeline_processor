`include "lib_pkg.sv";

module riscv #(parameter WIDTH=32, IADDR=16, DADDR=16)
(
    input logic clk,
    input logic reset_n,
    input logic [WIDTH-1:0] init_pc,
    output logic [IADDR-1:0] imem_addr,
    input logic [WIDTH-1:0] imem_rdata,
    output logic [DADDR-1:0] dmem_addr,
    output logic [WIDTH-1:0] dmem_wdata,
    output logic [3:0] dmem_wr_en,
    input logic [WIDTH-1:0] dmem_rdata,
    output logic fin
);

import lib_pkg::*;

op_type_t op_type, reg_op_type;
logic [2:0] funct3_d, funct3_m;
logic [6:0] funct7_d;

logic sel_alu0;
logic sel_alu1;
alu_type_t alu_type;
logic sel_ex;
logic sel_res;
logic sel_rf_wr;
logic rf_wr_en;
logic sel_pc;
cmp_type_t cmp_type;
logic cmp_res;
logic ecall;
logic [WIDTH-1:0] dmem_rdata_ex;
logic [1:0] sel_rdata1_f, sel_rdata2_f;
logic [4:0] rd_ex, rd_mem, rd_wb, rs1_dec, rs2_dec, rs1_ex, rs2_ex;
logic load_hazard;
logic mem_to_reg_m, mem_to_reg_ex;
logic [3:0] dmem_wr_en_dec;

datapath #(
    .WIDTH(WIDTH),
    .IADDR(IADDR),
    .DADDR(DADDR)
) datapath (
    .clk(clk),
    .reset_n(reset_n),
    .init_pc(init_pc),
    .op_type(op_type),
    .reg_op_type(reg_op_type),
    .funct3_d(funct3_d),
    .funct3_m(funct3_m),
    .funct7_d(funct7_d),
    .imem_addr(imem_addr),
    .imem_rdata(imem_rdata),
    .dmem_addr(dmem_addr),
    .dmem_wdata(dmem_wdata),
    .dmem_rdata(dmem_rdata_ex),
    .sel_alu0(sel_alu0),
    .sel_alu1(sel_alu1),
    .alu_type(alu_type),
    .sel_ex(sel_ex),
    .sel_res(sel_res),
    .sel_rf_wr(sel_rf_wr),
    .rf_wr_en(rf_wr_en),
    .sel_pc(sel_pc),
    .cmp_type(cmp_type),
    .cmp_out(cmp_res),
    .sel_rdata1_f(sel_rdata1_f),
    .sel_rdata2_f(sel_rdata2_f),
    .rd_ex(rd_ex),
    .rd_mem(rd_mem),
    .rd_wb(rd_wb),
    .rs1_dec(rs1_dec),
    .rs2_dec(rs2_dec),
    .rs1_ex(rs1_ex),
    .rs2_ex(rs2_ex),
    .load_hazard(load_hazard),
    .mem_to_reg_ex(mem_to_reg_ex),
    .mem_to_reg_m(mem_to_reg_m),
    .dmem_wr_en_dec(dmem_wr_en_dec),
    .dmem_wr_en(dmem_wr_en),
    .ecall(ecall),
    .fin(fin)
);

controller #(
) controller (
    .op_type(op_type),
    .reg_op_type(reg_op_type),
    .funct3(funct3_d),
    .funct7(funct7_d),
    .cmp_res(cmp_res),
    .sel_alu0(sel_alu0),
    .sel_alu1(sel_alu1),
    .alu_type(alu_type),
    .sel_ex(sel_ex),
    .dmem_wr_en(dmem_wr_en_dec),
    .sel_res(sel_res),
    .sel_rf_wr(sel_rf_wr),
    .rf_wr_en(rf_wr_en),
    .sel_pc(sel_pc),
    .cmp_type(cmp_type),
    .fin(ecall)
);

mem_extent #(
    .WIDTH(WIDTH)
) mem_extent (
    .load(mem_to_reg_m),
    .funct3(funct3_m),
    .in(dmem_rdata),
    .out(dmem_rdata_ex)
);

hazard_detector #(
) hazard_detector (
    .rd_ex(rd_ex),
    .rd_mem(rd_mem),
    .rd_wb(rd_wb),
    .rs1_dec(rs1_dec),
    .rs2_dec(rs2_dec),
    .rs1_ex(rs1_ex),
    .rs2_ex(rs2_ex),
    .sel_rdata1_f(sel_rdata1_f),
    .sel_rdata2_f(sel_rdata2_f),
    .load(mem_to_reg_ex),
    .load_hazard(load_hazard)
);

endmodule