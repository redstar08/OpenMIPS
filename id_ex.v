`include "defines.v"
module id_ex(
    input wire              rst,
    input wire              clk,
    input wire[5:0]			stall,

    
    // sign from ID
    input wire[`AluOpBus]   id_aluop,
    input wire[`AluSelBus]  id_alusel,
    input wire[`DataBus]    id_reg1,
    input wire[`DataBus]    id_reg2,
    input wire              id_we,
    input wire[`RegAddr]    id_waddr,
    // 跳转和分支指令延时槽
    // 是否为延时槽，要保存的地址
    input wire              id_is_in_slot,
    input wire[`DataBus]    id_link_addr,

    input wire              next_in_slot,
    // 返回输出到ID模块
    output reg              is_in_slot,

    // 输出到EX，是否为延时槽，要保存的地址
    output reg              ex_is_in_slot,
    output reg[`DataBus]    ex_link_addr,

    // sign from ID to EX
    output reg[`AluOpBus]   ex_aluop,
    output reg[`AluSelBus]  ex_alusel,
    output reg[`DataBus]    ex_reg1,
    output reg[`DataBus]    ex_reg2,
    output reg              ex_we,
    output reg[`RegAddr]    ex_waddr
);
always @ (posedge clk) begin
    if(rst == `Enable) begin
        ex_aluop  <=  `ALU_NOP;
        ex_alusel <=  `EXE_NOP;
        ex_reg1   <=  `ZeroWord;
        ex_reg2   <=  `ZeroWord;
        ex_we     <=  `Invalid;
        ex_waddr  <=  `NOPAddr;
        // 控制相关，新增
        is_in_slot      <= `NoInSlot;
        ex_is_in_slot   <= `NoInSlot;
        ex_link_addr    <= `ZeroWord;
    end else if(stall[2] == `Stop && stall[3] == `NoStop) begin //ID暂停，EX继续
        ex_aluop  <=  `ALU_NOP;
        ex_alusel <=  `EXE_NOP;
        ex_reg1   <=  `ZeroWord;
        ex_reg2   <=  `ZeroWord;
        ex_we     <=  `Invalid;
        ex_waddr  <=  `NOPAddr;
        // 控制相关，新增
        is_in_slot      <= `NoInSlot;
        ex_is_in_slot   <= `NoInSlot;
        ex_link_addr    <= `ZeroWord;
    end else if(stall[2] == `NoStop) begin
        ex_aluop  <=  id_aluop;
        ex_alusel <=  id_alusel;
        ex_reg1   <=  id_reg1;
        ex_reg2   <=  id_reg2;
        ex_we     <=  id_we;
        ex_waddr  <=  id_waddr;
        // 控制相关，新增
        is_in_slot      <= next_in_slot;
        ex_is_in_slot   <= id_is_in_slot;
        ex_link_addr    <= id_link_addr;
    end
end

endmodule