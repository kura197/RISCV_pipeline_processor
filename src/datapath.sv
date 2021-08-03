`include "lib_pkg.sv";

module datapath 
import lib_pkg::*;
#(parameter WIDTH=32, IADDR=10, DADDR=10)
(
    input logic clk,
    input logic reset_n,
    input logic [WIDTH-1:0] init_pc,
    output op_type_t op_type,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [IADDR-1:0] imem_addr,
    input logic [WIDTH-1:0] imem_rdata,
    output logic [DADDR-1:0] dmem_addr,
    output logic [WIDTH-1:0] dmem_wdata,
    input logic [WIDTH-1:0] dmem_rdata,
    input logic sel_alu0,
    input logic sel_alu1,
    input alu_type_t alu_type,
    input logic sel_ex,
    input logic sel_res,
    input logic sel_rf_wr,
    input logic rf_wr_en,
    input logic sel_pc,
    input cmp_type_t cmp_type,
    output logic cmp_out,
    input logic ecall,
    output logic fin
);

localparam RFADDR = 5;

logic [WIDTH-1:0] pc, next_pc, inc_pc;
logic [WIDTH-1:0] instr;
logic [WIDTH-1:0] imm;
logic [RFADDR-1:0] rs1, rs2, rd;
logic [WIDTH-1:0] rf_rdata1, rf_rdata2, rf_wdata;
logic [WIDTH-1:0] alu_in0, alu_in1, alu_out;
logic [WIDTH-1:0] ex_out;
logic [WIDTH-1:0] result;

bus_stage0 stage0, reg_stage0;
bus_stage1 stage1, reg_stage1;
bus_stage2 stage2, reg_stage2;
bus_stage3 stage3, reg_stage3;

assign stage0 = '{
                instr: instr,
                pc: pc,
                inc_pc: inc_pc
                };

assign stage1 = '{
                rf_wr_en: rf_wr_en,
                rd: rd,
                rf_rdata1: rf_rdata1,
                rf_rdata2: rf_rdata2,
                imm: imm,
                sel_alu0: sel_alu0,
                sel_alu1: sel_alu1,
                alu_type: alu_type,
                cmp_type: cmp_type,
                sel_ex: sel_ex,
                sel_res: sel_res,
                sel_rf_wr: sel_rf_wr,
                sel_pc: sel_pc,
                pc: reg_stage0.pc,
                inc_pc: inc_pc,
                ecall: ecall
                };

assign stage2 = '{
                rf_wr_en: reg_stage1.rf_wr_en,
                rd: reg_stage1.rd,
                rf_rdata2: reg_stage1.rf_rdata2,
                sel_res: reg_stage1.sel_res,
                sel_rf_wr: reg_stage1.sel_rf_wr,
                sel_pc: reg_stage1.sel_pc,
                ex_out: ex_out,
                cmp_out: cmp_out,
                inc_pc: reg_stage1.inc_pc,
                ecall: reg_stage1.ecall
                };

assign stage3 = '{
                rf_wr_en: reg_stage2.rf_wr_en,
                rd: reg_stage2.rd,
                sel_rf_wr: reg_stage2.sel_rf_wr,
                sel_pc: reg_stage2.sel_pc,
                cmp_out: reg_stage2.cmp_out,
                result: result,
                inc_pc: reg_stage2.inc_pc,
                ecall: reg_stage2.ecall
                };

assign inc_pc = pc + 4;
assign imem_addr = pc[IADDR-1:0];
assign instr = imem_rdata;
assign dmem_addr = reg_stage2.ex_out[DADDR-1:0];
assign dmem_wdata = reg_stage2.rf_rdata2;
assign fin = reg_stage3.ecall;

////////// Fetch //////////

flopr #(
    .WIDTH(WIDTH)
) reg_pc (
    .clk(clk),
    .reset_n(reset_n),
    .init(init_pc),
    .in(next_pc),
    .out(pc)
);


////////// Decode //////////

flopr #(
    .WIDTH($bits(stage0))
) reg_decode (
    .clk(clk),
    .reset_n(reset_n),
    .init('d0),
    .in(stage0),
    .out(reg_stage0)
);

decoder #(
    .WIDTH(WIDTH)
) decoder (
    .instr(reg_stage0.instr),
    .op_type(op_type),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .funct3(funct3),
    .funct7(funct7),
    .imm(imm)
);

/// TODO: support pipeline write-back
regfile #(
    .WIDTH(WIDTH),
    .ADDR(RFADDR)
) regfile (
    .clk(clk),
    .reset_n(reset_n),
    .wr_en(reg_stage3.rf_wr_en),
    .rs1(rs1),
    .rs2(rs2),
    .rd(reg_stage3.rd),
    .rdata1(rf_rdata1),
    .rdata2(rf_rdata2),
    .wdata(rf_wdata)
);

////////// Execute //////////

flopr #(
    .WIDTH($bits(stage1))
) reg_execute (
    .clk(clk),
    .reset_n(reset_n),
    .init('d0),
    .in(stage1),
    .out(reg_stage1)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_alu0 (
    .sel(reg_stage1.sel_alu0),
    .in0(reg_stage1.rf_rdata1),
    .in1(reg_stage1.pc),
    .out(alu_in0)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_alu1 (
    .sel(reg_stage1.sel_alu1),
    .in0(reg_stage1.rf_rdata2),
    .in1(reg_stage1.imm),
    .out(alu_in1)
);

alu #(
    .WIDTH(WIDTH)
) alu (
    .alu_type(reg_stage1.alu_type),
    .in0(alu_in0),
    .in1(alu_in1),
    .out(alu_out)
);

cmp #(
    .WIDTH(WIDTH)
) cmp (
    .cmp_type(reg_stage1.cmp_type),
    .in0(reg_stage1.rf_rdata1),
    .in1(reg_stage1.rf_rdata2),
    .out(cmp_out)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_ex (
    .sel(reg_stage1.sel_ex),
    .in0(alu_out),
    .in1(reg_stage1.imm),
    .out(ex_out)
);

////////// Memory //////////

flopr #(
    .WIDTH($bits(stage2))
) reg_memory (
    .clk(clk),
    .reset_n(reset_n),
    .init('d0),
    .in(stage2),
    .out(reg_stage2)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_res (
    .sel(reg_stage2.sel_res),
    .in0(dmem_rdata),
    .in1(reg_stage2.ex_out),
    .out(result)
);

////////// Write Back //////////

flopr #(
    .WIDTH($bits(stage3))
) reg_wback (
    .clk(clk),
    .reset_n(reset_n),
    .init('d0),
    .in(stage3),
    .out(reg_stage3)
);

mux2 #(
    .WIDTH(WIDTH)
) mux2_rf_wr (
    .sel(reg_stage3.sel_rf_wr),
    .in0(reg_stage3.result),
    .in1(reg_stage3.inc_pc),
    .out(rf_wdata)
);

/// TODO: support jump
mux2 #(
    .WIDTH(WIDTH)
) mux2_pc (
    .sel(reg_stage3.sel_pc),
    .in0(inc_pc),
    .in1(reg_stage3.result),
    .out(next_pc)
);

endmodule