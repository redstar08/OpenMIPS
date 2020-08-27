`include "defines.v"
module div (
    input wire          clk,
    input wire          rst,

    input wire          start,
    input wire          annul,
    input wire          div_signed,
    input wire[31:0]    opdata1,
    input wire[31:0]    opdata2,

    output reg          ready,
    output reg[63:0]    result

);
wire[32:0]  div_temp;
reg[1:0]    state;
reg[5:0]    count;
//dividend的低32位保存的是被除数、中间结果
//第k次迭代结束的时候dividend[k:0]保存的就是当前得到的中间结果
// dividend[31:k+1] 保存的就是被除数中还没有参与运算的数据
// dividend[63:32] 保存的每次迭代的被减数
// 结果保存在div_temp中
reg[64:0]   dividend;
// 除数
reg[31:0]   divisor;
reg[31:0]   op1;
reg[31:0]   op2;
assign div_temp = {1'b0, dividend[63:32]} - {1'b0, divisor};

always @ (posedge clk) begin
    if(rst == `Enable) begin
        state <= `DivFree;
        ready <= `Invalid;
        result <= {`ZeroWord, `ZeroWord};
    end else begin
        case(state)
            // 除法模块空闲 
            `DivFree: begin
                if(start == `Valid && annul == `Invalid) begin
                    if(opdata2 == `ZeroWord) begin
                        // 情况1，除数为0
                        state <= `DivZero;
                    end else begin
                        // 除数不为0
                        state <= `DivOn;
                        count <= 6'b000000;
                        // 确定除数与被除数是否取补码
                        if(div_signed == `Valid && opdata1[31] == 1'b1) begin
                            // 有符号则取补码
                            op1 = (~opdata1) + 1;
                        end else begin
                            op1 = opdata1;
                        end
                        if(div_signed == `Valid && opdata2[31] == 1'b1) begin
                            // 有符号则取补码
                            op2 = (~opdata2) + 1;
                        end else begin
                            op2 = opdata2;
                        end
                        dividend <= {`ZeroWord, `ZeroWord};
                        dividend[32:1] <= op1;
                        divisor <= op2;
                    end
                end else begin
                    // 没有开始除法
                    ready <= `Invalid;
                    result <= {`ZeroWord, `ZeroWord};
                end
            end
            // 除法模块，除数为0
            `DivZero: begin
                dividend <= {`ZeroWord, `ZeroWord};
                state <= `DivEnd;
            end
            // 除法模块，除数运行
            `DivOn: begin
                if(annul == `Invalid) begin
                    // count 不等32则没有计算完
                    if(count != 6'b100000) begin
                        if(div_temp[32] == 1'b1) begin
                            dividend <= {dividend[63:0], 1'b0};
                        end else begin
                            dividend <= {div_temp[31:0], dividend[31:0], 1'b1};
                        end
                        // 计算一次后，计数加1
                        count <= count + 1;
                    end else begin
                        if((div_signed == `Valid) && ((opdata1[31] ^ opdata2[31]) == 1'b1)) begin
                            dividend[31:0] <= ~(dividend[31:0]) + 1;
                        end
                        if((div_signed == `Valid) && ((opdata1[31] ^ dividend[64]) == 1'b1)) begin
                            dividend[64:33] <= ~(dividend[64:33]) + 1;
                        end
                        state <= `DivEnd;
                        count <= 6'b000000;
                    end
                end else begin
                    state <= `DivFree;
                end
            end
            // 除法模块状态，运行结束
            `DivEnd: begin
                ready <= `Valid;
                result <= {dividend[64:33], dividend[31:0]};
                if( start == `Invalid) begin
                    state <= `DivFree;
                    ready <= `Invalid;
                    result <= {`ZeroWord, `ZeroWord};
                end
            end
        endcase
    end
end

endmodule