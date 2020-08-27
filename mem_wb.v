`include "defines.v"
module mem_wb(
    input wire              rst,
    input wire              clk,
    input wire[5:0]          stall,   

    // sign from ex
    input wire              mem_we,
    input wire[`RegAddr]    mem_waddr,
    input wire[`DataBus]    mem_wdata,
    input wire              mem_we_hilo,
    input wire[`DataBus]    mem_hi,
    input wire[`DataBus]    mem_lo,
    // sign from ex to mem
    output reg              wb_we,
    output reg[`RegAddr]    wb_waddr,
    output reg[`DataBus]    wb_wdata,
    output reg              wb_we_hilo,
    output reg[`DataBus]    wb_hi,
    output reg[`DataBus]    wb_lo
);

always @ (posedge clk) begin
    if(rst == `Enable) begin
        wb_we      <=  `Invalid;
        wb_waddr   <=  `NOPAddr;
        wb_wdata   <=  `ZeroWord;
        wb_we_hilo <=  `Invalid;
        wb_hi      <=  `ZeroWord;
        wb_lo      <=  `ZeroWord;
    end else if(stall[4] == `Stop && stall[5] == `NoStop) begin  //MEM暂停，WB继续
        wb_we      <=  `Invalid;
        wb_waddr   <=  `NOPAddr;
        wb_wdata   <=  `ZeroWord;
        wb_we_hilo <=  `Invalid;
        wb_hi      <=  `ZeroWord;
        wb_lo      <=  `ZeroWord;
    end else if(stall[4] == `NoStop) begin
        wb_we      <=  mem_we;
        wb_waddr   <=  mem_waddr;
        wb_wdata   <=  mem_wdata;
        wb_we_hilo <=  mem_we_hilo;
        wb_hi      <=  mem_hi;
        wb_lo      <=  mem_lo;
    end
end

endmodule