`include "defines.v"
module rom(
    input wire              ce,
    // 输入地址(pc的值)
    input wire[`DataBus]    addr,  
    // 输出指令(inst的值)
    output reg[`DataBus]    inst
);
    // 定义32为的数据65536个(64K个字)
    reg[`DataBus] inst_mem[0:`InstMemSize-1];
    // 使用inst_rom.data中的数据初始化inst_mem
    initial $readmemh ("test.data", inst_mem);

    always @ (*) begin
        if(ce == `Invalid) begin
            inst <= `ZeroWord;
        end else begin
            // OpenMIPS按字节寻址，将32位数据取出，地址为4的倍数，向右移动2位
            inst <= inst_mem[addr[`InstMemSizeLog2+1:2]];
        end
    end

endmodule
