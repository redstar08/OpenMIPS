`include "defines.v"
`include "pc.v"
`include "regfile.v"
`include "if_id.v"
`include "id.v"
`include "id_ex.v"
`include "ex.v"
`include "ex_mem.v"
`include "mem.v"
`include "mem_wb.v"

module openmips (
// **************     CPU输入接口       ****************
    input wire              rst,
    input wire              clk,
    // rom
    input wire[`DataBus]    rom_data,

// **************     CPU输出接口       ****************

    // rom
    output reg              rom_ce,
    output reg[`DataBus]    rom_addr
);

// PC连接IF/ID模块的内部引线
wire            ce;
wire[`DataBus]  pc;
// rom_ce连接ce，rom_addr连接pc，通过pc的值去rom取指令
always @(*) begin
    rom_ce = ce;
    rom_addr = pc;
end
wire         id_stall;
wire         ex_stall;
wire[5:0]    stallbus;
// 实例化ctrl
ctrl ctrl0(
    .rst(rst),
    .id_stall(id_stall),
    .ex_stall(ex_stall),
    .stall(stallbus)
);
// 控制相关的内部引线
wire              b_flag;
wire[31:0]        b_addr;
// 实例化pc
pc pc0(
    .rst(rst),
    .stall(stallbus),
    .clk(clk),
    .b_flag(b_flag),
    .b_addr(b_addr),
    .pc(pc),
    .ce(ce)
);

// IF/ID连接ID模块的内部引线
wire[`DataBus]  id_pc;
wire[`DataBus]  id_inst;
// IF/ID实例化
if_id if_id0(
    .clk(clk),
    .rst(rst),
    .stall(stallbus),
    .if_pc(pc),
    .if_inst(rom_data),
    // 输出
    .id_pc(id_pc),
    .id_inst(id_inst)
);

// ID与RegFile连接的内部引线
wire              read1;
wire              read2;
wire[`RegAddr]    raddr1;
wire[`RegAddr]    raddr2;
wire[`DataBus]    rdata1;
wire[`DataBus]    rdata2;
// **************  消除数据相关RAW改动    ****************
// 来自EX阶段的写操作(相隔1条指令的真相关)
wire              ex_we_id;
wire[`RegAddr]    ex_waddr_id;
wire[`DataBus]    ex_wdata_id;
// 来自MEM阶段的写操作(相隔2条指令的真相关)
wire              mem_we_id;
wire[`RegAddr]    mem_waddr_id;
wire[`DataBus]    mem_wdata_id;
// 来自WB阶段的写操作(相隔3条指令的真相关)
// 由于RegFile中已经判断，读的地址是否为WB要写的地址，已经解决
// MEM/WB与RegFile连接的内部引线
wire              wb_we_reg;
wire[`RegAddr]    wb_waddr_reg;
wire[`DataBus]    wb_wdata_reg;

// ID与ID/EX连接的内部引线
wire[`AluOpBus]   id_aluop;
wire[`AluSelBus]  id_alusel;
wire[`DataBus]    id_reg1;
wire[`DataBus]    id_reg2;
wire              id_we;
wire[`RegAddr]    id_waddr;
// 控制相关的内部引线
wire              id_is_in_slot;
wire[31:0]        id_link_addr;
wire              id_next_in_slot;
// 来自ID/EX的输出
wire              id_is_in_slot_i;

// ID实例化
id id0(
    .rst(rst),
    .stall(id_stall),
    .pc(id_pc),
    .inst(id_inst),
    // 消除RAW，来自EX和MEM阶段的输入
    .ex_we(ex_we_id),
    .ex_waddr(ex_waddr_id),
    .ex_wdata(ex_wdata_id),
    .mem_we(mem_we_id),
    .mem_waddr(mem_waddr_id),
    .mem_wdata(mem_wdata_id),
    // RegFile的输入
    .rdata1(rdata1),
    .rdata2(rdata2),
    // 来自ID/EX的输入
    .is_in_slot_i(id_is_in_slot_i),
    // 输出到RegFile
    .read1(read1),
    .read2(read2),
    .raddr1(raddr1),
    .raddr2(raddr2),
    // 输出到PC
    .b_flag(b_flag),
    .b_addr(b_addr),
    // 输出到ID/EX控制相关
    .is_in_slot_o(id_is_in_slot),
    .link_addr(id_link_addr),
    .next_in_slot(id_next_in_slot),

    // 输出到ID/EX
    .aluop(id_aluop),
    .alusel(id_alusel),
    .reg1(id_reg1),
    .reg2(id_reg2),
    .we(id_we),
    .waddr(id_waddr)
);

// RegFile实例化
regfile regfile0(
    .clk(clk),
    .rst(rst),
    // 来自ID的输入
    .read1(read1),
    .read2(read2),
    .raddr1(raddr1),
    .raddr2(raddr2),
    // 来自MEM/WB的输入
    .we(wb_we_reg),
    .waddr(wb_waddr_reg),
    .wdata(wb_wdata_reg),
    // 输出到ID
    .rdata1(rdata1),
    .rdata2(rdata2)
);
// ID/EX连接EX的内部引线
wire[`AluOpBus]   ex_aluop;
wire[`AluSelBus]  ex_alusel;
wire[`DataBus]    ex_reg1;
wire[`DataBus]    ex_reg2;
wire              ex_we;
wire[`RegAddr]    ex_waddr;
// 控制相关的内部引线
wire              ex_is_in_slot;
wire[31:0]        ex_link_addr;

// ID/EX实例化
id_ex id_ex0(
    .rst(rst),
    .clk(clk),
    .stall(stallbus),
    // 来自ID的输入
    .id_aluop(id_aluop),
    .id_alusel(id_alusel),
    .id_reg1(id_reg1),
    .id_reg2(id_reg2),
    .id_we(id_we),
    .id_waddr(id_waddr),
    .id_is_in_slot(id_is_in_slot),
    .id_link_addr(id_link_addr),
    .next_in_slot(id_next_in_slot),

    // 控制相关输出到EX
    .ex_is_in_slot(ex_is_in_slot),
    .ex_link_addr(ex_link_addr),
    .is_in_slot(id_is_in_slot_i),

    // 输出到EX
    .ex_aluop(ex_aluop),
    .ex_alusel(ex_alusel),
    .ex_reg1(ex_reg1),
    .ex_reg2(ex_reg2),
    .ex_we(ex_we),
    .ex_waddr(ex_waddr)
);

// EX连接EX/MEM的内部引线
wire              ex_we_o;
wire[`RegAddr]    ex_waddr_o;
wire[`DataBus]    ex_wdata_o;
wire              ex_we_hilo;
wire[`DataBus]    ex_hi_o;
wire[`DataBus]    ex_lo_o;
// EX -> ID,消除RAW
assign ex_we_id    = ex_we_o;
assign ex_waddr_id = ex_waddr_o;
assign ex_wdata_id = ex_wdata_o;
// HILO -> EX
wire[`DataBus]    hi_to_ex;
wire[`DataBus]    lo_to_ex;
// MEM -> EX & WB -> EX，消除RAW
wire              mem_we_hilo_ex;
wire[`DataBus]    mem_hi_ex;
wire[`DataBus]    mem_lo_ex;
wire              wb_we_hilo_ex;
wire[`DataBus]    wb_hi_ex;
wire[`DataBus]    wb_lo_ex;

// madd、maddu、msub、msubu指令
wire[1:0]       ex_count_mem;
wire[63:0]      ex_hilo_mem;
wire[1:0]       mem_count_ex;
wire[63:0]      mem_hilo_ex;

// DIV DIVU指令
wire            div_start;
wire            div_signed;
wire[31:0]      div_opdata1;
wire[31:0]      div_opdata2;
wire            div_ready;
wire[63:0]      div_result;


// EX实例化
ex ex0(
    .rst(rst),
    .stall(ex_stall),
    // 来自ID/EX的输入
    .aluop(ex_aluop),
    .alusel(ex_alusel),
    .reg1(ex_reg1),
    .reg2(ex_reg2),
    .we_i(ex_we),
    .waddr_i(ex_waddr),
    .is_in_slot(ex_is_in_slot),
    .link_addr(ex_link_addr),
    // 来自HILO的输入
    .hi_i(hi_to_ex),
    .lo_i(lo_to_ex),
    // 来自MEM的输入
    .mem_we_hilo(mem_we_hilo_ex),
    .mem_hi(mem_hi_ex),
    .mem_lo(mem_lo_ex),
    // 来自WB的输入
    .wb_we_hilo(wb_we_hilo_ex),
    .wb_hi(wb_hi_ex),
    .wb_lo(wb_lo_ex),
    // 来自EX/MEM的输入
    .count_i(mem_count_ex),
    .hilo_i(mem_hilo_ex),

    // 来自DIV的输入
    .div_ready(div_ready),
    .div_result(div_result),
    // 输出到DIV
    .div_start(div_start),
    .div_signed(div_signed),
    .div_opdata1(div_opdata1),
    .div_opdata2(div_opdata2),

    // 输出到EX/MEM
    .count_o(ex_count_mem),
    .hilo_o(ex_hilo_mem),
    .we_o(ex_we_o),
    .waddr_o(ex_waddr_o),
    .wdata_o(ex_wdata_o),
    .we_hilo(ex_we_hilo),
    .hi_o(ex_hi_o),
    .lo_o(ex_lo_o)
);

// EX/MEM和MEM相连的内部引线
wire              mem_we;
wire[`RegAddr]    mem_waddr;
wire[`DataBus]    mem_wdata;
wire              mem_we_hilo;
wire[`DataBus]    mem_hi;
wire[`DataBus]    mem_lo;
// EX/MEM实例化
ex_mem ex_mem0(
    .rst(rst),
    .clk(clk),
    .stall(stallbus),
    // 来自EX的输入
    .ex_we(ex_we_o),
    .ex_waddr(ex_waddr_o),
    .ex_wdata(ex_wdata_o),
    .ex_we_hilo(ex_we_hilo),
    .ex_hi(ex_hi_o),
    .ex_lo(ex_lo_o),
    // 来自E的输入
    .count_i(ex_count_mem),
    .hilo_i(ex_hilo_mem),
    // 输出到EX
    .count_o(mem_count_ex),
    .hilo_o(mem_hilo_ex),

    // 输出到MEM
    .mem_we(mem_we),
    .mem_waddr(mem_waddr),
    .mem_wdata(mem_wdata),
    .mem_we_hilo(mem_we_hilo),
    .mem_hi(mem_hi),
    .mem_lo(mem_lo)

);

// MEM连接MEM/WB的内部引线
wire              mem_we_o;
wire[`RegAddr]    mem_waddr_o;
wire[`DataBus]    mem_wdata_o;
wire              mem_we_hilo_o;
wire[`DataBus]    mem_hi_o;
wire[`DataBus]    mem_lo_o;

// MEM -> ID，消除RAW相关
assign mem_we_id    = mem_we_o;
assign mem_waddr_id = mem_waddr_o;
assign mem_wdata_id = mem_wdata_o;
// MEM -> EX消除RAW
assign mem_we_hilo_ex = mem_we_hilo_o;
assign mem_hi_ex      = mem_hi_o;
assign mem_lo_ex      = mem_lo_o;

// 实例化MEM
mem mem0(
    .rst(rst),
    // 来自EX/MEM的输入
    .we_i(mem_we),
    .waddr_i(mem_waddr),
    .wdata_i(mem_wdata),
    .we_hilo_i(mem_we_hilo),
    .hi_i(mem_hi),
    .lo_i(mem_lo),
    // 输出到MEM/WB
    .we_o(mem_we_o),
    .waddr_o(mem_waddr_o),
    .wdata_o(mem_wdata_o),
    .we_hilo_o(mem_we_hilo_o),
    .hi_o(mem_hi_o),
    .lo_o(mem_lo_o)
);

// MEM/WB连接HILO的内部引线
wire              wb_we_hilo;
wire[`DataBus]    wb_hi;
wire[`DataBus]    wb_lo;
// WB -> EX消除RAW
assign wb_we_hilo_ex = wb_we_hilo;
assign wb_hi_ex      = wb_hi;
assign wb_lo_ex      = wb_lo;

// 实例化MEM/WB
mem_wb mem_wb0(
    .rst(rst),
    .clk(clk),
    .stall(stallbus),
    // 来自MEM的输入
    .mem_we(mem_we_o),
    .mem_waddr(mem_waddr_o),
    .mem_wdata(mem_wdata_o),
    .mem_we_hilo(mem_we_hilo_o),
    .mem_hi(mem_hi_o),
    .mem_lo(mem_lo_o),
    // 输出到RegFile
    .wb_we(wb_we_reg),
    .wb_waddr(wb_waddr_reg),
    .wb_wdata(wb_wdata_reg),
    .wb_we_hilo(wb_we_hilo),
    .wb_hi(wb_hi),
    .wb_lo(wb_lo)

);

// 实例化HILO
hi_lo hi_lo0(
    .clk(clk),
    .rst(rst),
    // 写HILO
    .we(wb_we_hilo),
    .whi(wb_hi),
    .wlo(wb_lo),
    // 输出HILO
    .rhi(hi_to_ex),
    .rlo(lo_to_ex)
);

// 实例化DIV模块
div div0(
    .clk(clk),
    .rst(rst),
    .annul(`Invalid),
    // 来自EX模块的输入
    .start(div_start),
    .div_signed(div_signed),
    .opdata1(div_opdata1),
    .opdata2(div_opdata2),
    // 输出到EX模块
    .ready(div_ready),
    .result(div_result)
);

endmodule