module top
(
    input clk,
    input reset_n
);

localparam WIDTH = 32;
localparam IADDR = 5;
localparam DADDR = 5;

logic [IADDR-1:0] imem_addr;
logic [WIDTH-1:0] imem_rdata;
logic [DADDR-1:0] dmem_addr;
logic [WIDTH-1:0] dmem_wdata;
logic dmem_wr_en;
logic [WIDTH-1:0] dmem_rdata;
logic [WIDTH-1:0] init_pc = 0;

riscv #(
    .WIDTH(WIDTH),
    .IADDR(IADDR),
    .DADDR(DADDR)
) riscv (
    .clk(clk),
    .reset_n(reset_n),
    .init_pc(init_pc),
    .imem_addr(imem_addr),
    .imem_rdata(imem_rdata),
    .dmem_addr(dmem_addr),
    .dmem_wdata(dmem_wdata),
    .dmem_wr_en(dmem_wr_en),
    .dmem_rdata(dmem_rdata)
);

memory #(
    .WIDTH(WIDTH),
    .ADDR(IADDR)
) imem (
    .clk(clk),
    .wr_en(1'b0),
    .addr(imem_addr),
    .rdata(imem_rdata),
    .wdata()
);

memory #(
    .WIDTH(WIDTH),
    .ADDR(DADDR)
) dmem (
    .clk(clk),
    .wr_en(dmem_wr_en),
    .addr(imem_addr),
    .rdata(imem_rdata),
    .wdata(dmem_wdata)
);


endmodule