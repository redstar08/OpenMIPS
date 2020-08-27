`include "defines.v"
module hi_lo(
    input wire              clk,
    input wire              rst,

    //Write Ports
    input wire              we,     //写使能
    input wire[`DataBus]    whi,
    input wire[`DataBus]    wlo,

    // Read Ports                   //无需使能，直接输出HI LO信号
    output reg[`DataBus]    rhi,
    output reg[`DataBus]    rlo
);

reg[`DataBus]   hi;
reg[`DataBus]   lo;
// 初始化hi和lo
initial begin
    hi = `ZeroWord;
    lo = `ZeroWord;
end

// 写端口的操作
always @ (posedge clk) begin
    if(rst == `Disable) begin   //无复位，可写
        if(we == `Valid) begin
            hi <= whi;
            lo <= wlo;
        end
    end
end

always @ (*) begin
    if(rst == `Enable) begin    //置位，清0
        rhi <= `ZeroWord;
        rlo <= `ZeroWord;
    end else begin
        rhi <= hi;
        rlo <= lo;
    end
end

endmodule