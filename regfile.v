`include "defines.v"
module regfile(
    input wire          clk,
    input wire          rst,

    //Write Ports
    input wire              we,     //写使能
    input wire[`RegAddr]    waddr,
    input wire[`DataBus]    wdata,

    // Read Port1
    input wire              read1,
    input wire[`RegAddr]    raddr1,
    output reg[`DataBus]    rdata1,

    // Read Port2
    input wire              read2,
    input wire[`RegAddr]    raddr2,
    output reg[`DataBus]    rdata2
);

// 定义32个32位reg
integer         i;
reg[`DataBus]   regs[0:31];
initial begin
    for(i = 0; i < 32; i = i + 1) begin
        regs[i] = `ZeroWord;
    end
end

// 写端口的操作
always @ (posedge clk) begin
    if(rst == `Disable) begin   //无复位，可写，且编号不为0 ($0恒等于0，不能修改)
        if((we == `Valid) && (waddr != 5'b00000)) begin
            regs[waddr] <= wdata;
        end
    end
end

// 读端口1
always @ (*) begin
    if(rst == `Enable) begin    //置位，清0
        rdata1 <= `ZeroWord;
    end else if(raddr1 == 5'b00000) begin   //读取的是$0 ($0 === 0)
        rdata1 <= `ZeroWord;
    end else if((read1 == `Valid) && (raddr1 == waddr) && (we == `Valid)) begin   //要读的reg，是准备写的reg
        rdata1 <= wdata;
    end else if(read1 == `Valid) begin  //正常读
        rdata1 <= regs[raddr1];
    end else begin      //读端口不能用
        rdata1 <= `ZeroWord;
    end
end

// 读端口2
always @ (*) begin
    if(rst == `Enable) begin    //置位，清0
        rdata2 <= `ZeroWord;
    end else if(raddr2 == 5'b00000) begin   //读取的是$0 ($0 === 0)
        rdata2 <= `ZeroWord;
    end else if((read2 == `Valid) && (raddr2 == waddr) && (we == `Valid)) begin   //要读的reg，是准备写的reg
        rdata2 <= wdata;
    end else if(read2 == `Valid) begin  //正常读
        rdata2 <= regs[raddr2];
    end else begin      //读端口不能用
        rdata2 <= `ZeroWord;
    end
end

endmodule