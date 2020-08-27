`include "defines.v"
module ex_mem(
    input wire               rst,
    input wire               clk,
    input wire[5:0]          stall,   

    // sign from ex
    input wire               ex_we,
    input wire[`RegAddr]     ex_waddr,
    input wire[`DataBus]     ex_wdata,
    // HILO 信号
    input wire               ex_we_hilo,
    input wire[`DataBus]     ex_hi,
    input wire[`DataBus]     ex_lo,

    // 来自EX的输入
    input wire[1:0]          count_i,
    input wire[63:0]         hilo_i,
    // 输出到EX
    output reg[1:0]          count_o,
    output reg[63:0]         hilo_o,

    // sign from ex to mem
    output reg               mem_we,
    output reg[`RegAddr]     mem_waddr,
    output reg[`DataBus]     mem_wdata,
    // HILO sign to mem
    output reg               mem_we_hilo,
    output reg[`DataBus]     mem_hi,
    output reg[`DataBus]     mem_lo
);

always @ (posedge clk) begin
    if(rst == `Enable) begin
        mem_we      <=  `Invalid;
        mem_waddr   <=  `NOPAddr;
        mem_wdata   <=  `ZeroWord;
        mem_we_hilo <=  `Invalid;
        mem_hi      <=  `ZeroWord;
        mem_lo      <=  `ZeroWord;
        count_o     <=  2'b00;
        hilo_o      <=  {`ZeroWord, `ZeroWord};
    end else if(stall[3] == `Stop && stall[4] == `NoStop) begin //EX暂停，MEM继续
        mem_we      <=  `Invalid;
        mem_waddr   <=  `NOPAddr;
        mem_wdata   <=  `ZeroWord;
        mem_we_hilo <=  `Invalid;
        mem_hi      <=  `ZeroWord;
        mem_lo      <=  `ZeroWord;
        count_o     <=  count_i;
        hilo_o      <=  hilo_i;    
    end else if(stall[3] == `NoStop) begin
        mem_we      <=  ex_we;
        mem_waddr   <=  ex_waddr;
        mem_wdata   <=  ex_wdata;
        mem_we_hilo <=  ex_we_hilo;
        mem_hi      <=  ex_hi;
        mem_lo      <=  ex_lo;
        count_o     <=  2'b00;
        hilo_o      <=  {`ZeroWord, `ZeroWord};
    end else begin
        count_o     <=  count_i;
        hilo_o      <=  hilo_i;
    end
end

endmodule