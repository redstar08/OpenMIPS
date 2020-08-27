`include "defines.v"
module ex(
    input wire               rst,
    output reg  			 stall,
    // 获得ID/EX来的数据
    input wire[`AluOpBus]    aluop,
    input wire[`AluSelBus]   alusel,
    input wire[`DataBus]     reg1,
    input wire[`DataBus]     reg2,
    // 写reg控制
    input wire               we_i,
    input wire[`RegAddr]     waddr_i,

    // 来自HILO的输入
    input wire[`DataBus]     hi_i,
    input wire[`DataBus]     lo_i,
    // 来自MEM的HILO输入，消除RAW
    input wire               mem_we_hilo,
    input wire[`DataBus]     mem_hi,
    input wire[`DataBus]     mem_lo,
    // 来自WB的HILO输入，消除RAW
    input wire               wb_we_hilo,
    input wire[`DataBus]     wb_hi,
    input wire[`DataBus]     wb_lo,
    // 来自EX/MEM的输入
    input wire[1:0]          count_i,
    input wire[63:0]         hilo_i,

    // 来自DIV的输入
    input wire               div_ready,
    input wire[63:0]         div_result,

    // 来自控制相关的输入
    // 是否延迟槽指令，要保存的返回地址
    input wire               is_in_slot,
    input wire[`DataBus]     link_addr,

    // 输出到EX/MEM
    output reg[1:0]          count_o,
    output reg[63:0]         hilo_o,

    // 输出到DIV
    output reg               div_start,
    output reg               div_signed,
    output reg[`DataBus]     div_opdata1,
    output reg[`DataBus]     div_opdata2,



    // 输出HILO
    output reg               we_hilo,
    output reg[`DataBus]     hi_o,
    output reg[`DataBus]     lo_o,

    // 执行的结果
    output reg               we_o,
    output reg[`RegAddr]     waddr_o,
    output reg[`DataBus]     wdata_o
);
// 保存逻辑运算的结果
reg [`DataBus] logicout;
// 保存移位运算的结果
reg [`DataBus] shiftout;
// 保存移动指令的结果
reg [`DataBus] moveout;
// 保存hilo寄存器的最新值
reg [`DataBus] hi;
reg [`DataBus] lo;
//保存算术运算的结果
reg[`DataBus]   arithmeticout;
reg[63:0]       mulcout;            //保存乘法运算结果
// MADD、MADDU、MSUB、MSUBU运算 
reg             stall_for_div;
reg             stall_for_madd;     //暂停流水线
reg[63:0]       hilotemp;           //保存加了rs*rt结果

// 算术指令中间过程
wire[`DataBus]  reg2_mux;           //reg2_mux为reg2参与运算的真实值
wire[`DataBus]  result_sum;         //加减法结果
wire            overflow;           //保存溢出的情况
wire            reg1_eq_reg2;       //计算(reg1 == reg2)
wire            reg1_lt_reg2;       //计算(reg1 < reg2)
wire[`DataBus]  reg1_n;             //reg1取反

// ************    算术运算相关变量的值     *************
// 加减法运算，减法或者有符号比较，用reg2的补码运算
// 默认是无符号运算，有符号则减法为加补码，无符号减法也是加补码
assign reg2_mux = ((aluop == `ALU_SUB) || (aluop == `ALU_SUBU) || (aluop == `ALU_SLT)) ? (~reg2)+1 : reg2;
assign result_sum = reg1 + reg2_mux;
// 有符号运算，计算加减运算是否溢出，正+正=负 || 负+负=正
assign overflow = (!reg1[31] && !reg2_mux[31] && result_sum[31])
                || (reg1[31] && reg2_mux[31] && !result_sum[31]);
// 计算slt、slti指令，有符号 负<正 || 正-正=负 || 负-负=负，无符号直接比
assign reg1_lt_reg2 = (aluop == `ALU_SLT) ? (reg1[31] && !reg2[31])
                    ||(!reg1[31] && !reg2[31] && result_sum[31])
                    ||(reg1[31] && reg2[31] && result_sum[31])
                    :(reg1 < reg2);
// clz、clo指令
assign reg1_n = ~reg1;
// ************    得到HILO的最新值，消除数据相关     *************
always @ (*) begin
    if(rst == `Enable) begin
        {hi, lo} <= {`ZeroWord, `ZeroWord};
    end else if(mem_we_hilo == `Valid) begin
        {hi, lo} <= {mem_hi, mem_lo};
    end else if(wb_we_hilo == `Valid) begin
        {hi, lo} <= {wb_hi, wb_lo};
    end else begin
        {hi, lo} <= {hi_i, lo_i};
    end
end


// ************    根据aluop操作码，进行相应的操作     *************
// 非乘法算术运算
always @ (*) begin
    if(rst == `Enable) begin
        arithmeticout <= `ZeroWord;
    end else begin
        case(aluop)
            `ALU_ADD, `ALU_ADDU: begin  //加法运算
                arithmeticout <= result_sum;
            end
            `ALU_SUB, `ALU_SUBU: begin    //减法运算
                arithmeticout <= result_sum;
            end
            `ALU_SLT, `ALU_SLTU: begin    //减法运算
                arithmeticout <= reg1_lt_reg2;
            end
            `ALU_CLZ: begin
                arithmeticout <= reg1[31] ? 0  : reg1[30] ? 1  : reg1[29] ? 2  : reg1[28] ? 3 :
                                 reg1[27] ? 4  : reg1[26] ? 5  : reg1[25] ? 6  : reg1[24] ? 7 :
                                 reg1[23] ? 8  : reg1[22] ? 9  : reg1[21] ? 10 : reg1[20] ? 11 :
                                 reg1[19] ? 12 : reg1[18] ? 13 : reg1[17] ? 14 : reg1[16] ? 15 :
                                 reg1[15] ? 16 : reg1[14] ? 17 : reg1[13] ? 18 : reg1[12] ? 19 :
                                 reg1[11] ? 20 : reg1[10] ? 21 : reg1[9]  ? 22 : reg1[8]  ? 23 :
                                 reg1[7]  ? 24 : reg1[6]  ? 25 : reg1[5]  ? 26 : reg1[4]  ? 27 :
                                 reg1[3]  ? 28 : reg1[2]  ? 29 : reg1[1]  ? 30 : reg1[0]  ? 31 : 32;
            end
            `ALU_CLO: begin
                arithmeticout <= reg1_n[31] ? 0  : reg1_n[30] ? 1  : reg1_n[29] ? 2  : reg1_n[28] ? 3 :
                                 reg1_n[27] ? 4  : reg1_n[26] ? 5  : reg1_n[25] ? 6  : reg1_n[24] ? 7 :
                                 reg1_n[23] ? 8  : reg1_n[22] ? 9  : reg1_n[21] ? 10 : reg1_n[20] ? 11 :
                                 reg1_n[19] ? 12 : reg1_n[18] ? 13 : reg1_n[17] ? 14 : reg1_n[16] ? 15 :
                                 reg1_n[15] ? 16 : reg1_n[14] ? 17 : reg1_n[13] ? 18 : reg1_n[12] ? 19 :
                                 reg1_n[11] ? 20 : reg1_n[10] ? 21 : reg1_n[9]  ? 22 : reg1_n[8]  ? 23 :
                                 reg1_n[7]  ? 24 : reg1_n[6]  ? 25 : reg1_n[5]  ? 26 : reg1_n[4]  ? 27 :
                                 reg1_n[3]  ? 28 : reg1_n[2]  ? 29 : reg1_n[1]  ? 30 : reg1_n[0]  ? 31 : 32;
            end
            default:begin
                arithmeticout <= `ZeroWord;
            end
        endcase
    end
end
// 乘法运算
always @ (*) begin
    if(rst == `Enable) begin
        mulcout <= {`ZeroWord, `ZeroWord};
    end else begin
        case(aluop)
        // 有符号乘法
        `ALU_MUL, `ALU_MULT, `ALU_MADD, `ALU_MSUB: begin
            mulcout <= $signed(reg1) * $signed(reg2);
        end
        // 无符号乘法
        `ALU_MULTU, `ALU_MADDU, `ALU_MSUBU: begin
            mulcout <= reg1 * reg2;
        end
        endcase
    end
end
// MADD、MADDU、MSUB、MSUBU运算
// DIV DIVU运算暂停流水线
always @ (*) begin
    stall = stall_for_madd || stall_for_div;
end

always @ (*) begin
    if(rst == `Enable) begin
        count_o <= 2'b00;
        hilo_o <= {`ZeroWord, `ZeroWord};
        stall_for_madd <=`NoStop;
    end else begin
        case(aluop)
            // 乘累加
            `ALU_MADD, `ALU_MADDU: begin
                if(count_i == 2'b00) begin          //执行madd、maddu第一个周期
                    count_o <= 2'b01;
                    // 当前rs*rt的值
                    hilo_o <= mulcout;
                    stall_for_madd <=`Stop;
                end else if(count_i == 2'b01) begin //执行madd、maddu第二个周期
                    count_o <= 2'b10;
                    hilo_o <= {`ZeroWord, `ZeroWord};
                    stall_for_madd <=`NoStop;
                    // 保存累加的结果，当前hi,lo的值 + 上一个周期rs*rt的值
                    hilotemp <= {hi, lo} + hilo_i;
                end
            end
            `ALU_MSUB, `ALU_MSUBU: begin
                if(count_i == 2'b00) begin          //执行madd、maddu第一个周期
                    count_o <= 2'b01;
                    // 当前rs*rt的值
                    hilo_o <= mulcout;
                    stall_for_madd <=`Stop;
                end else if(count_i == 2'b01) begin //执行madd、maddu第二个周期
                    count_o <= 2'b10;
                    hilo_o <= {`ZeroWord, `ZeroWord};
                    stall_for_madd <=`NoStop;
                    // 保存累减的结果，当前hi,lo的值 - 上一个周期rs*rt的值
                    hilotemp <= {hi, lo} + (~hilo_i+1);
                end
            end
            default: begin
                count_o <= 2'b00;
                hilo_o <= {`ZeroWord, `ZeroWord};
                stall_for_madd <=`NoStop;
            end
        endcase
    end
end

// 进行逻辑运算
always @ (*) begin
    if(rst == `Enable) begin
        logicout <= `ZeroWord;
    end else begin
        case(aluop)
            `ALU_OR: begin  //逻辑或运算
                logicout <= reg1 | reg2;
            end
            `ALU_AND: begin
                logicout <= reg1 & reg2;
            end
            `ALU_XOR: begin
                logicout <= reg1 ^ reg2;
            end
            `ALU_NOR: begin
                logicout <= ~(reg1 | reg2);
            end
            default:begin
                logicout <= `ZeroWord;
            end
        endcase
    end
end
// 移位运算
always @ (*) begin
    if(rst == `Enable) begin
        shiftout <= `ZeroWord;
    end else begin
        case(aluop)
            `ALU_SLL: begin  //移位运算
                shiftout <= reg2 << reg1[4:0];
            end
            `ALU_SRL: begin
                shiftout <= reg2 >> reg1[4:0];
            end
            `ALU_SRA: begin
                shiftout <= ($signed(reg2)) >>> reg1[4:0];
            end
            default:begin
                shiftout <= `ZeroWord;
            end
        endcase
    end
end


// ************    MOVZ、MOVN、MFHI、MFLO指令     *************
always @ (*) begin
    if(rst == `Enable) begin
        moveout <= `ZeroWord;
    end else begin
        moveout <= `ZeroWord;
        case(aluop)
            // moveout最终将作为wdata写入寄存器
            `ALU_MOVZ: begin
                moveout <= reg1;
            end
            `ALU_MOVN: begin
                moveout <= reg1;
            end
            `ALU_MFHI: begin
                moveout <= hi;
            end
            `ALU_MFLO: begin
                moveout <= lo;
            end
            default:begin
            end
        endcase
    end
end
// ************    MTHI、MTLO指令     *************
always @ (*) begin
    if(rst == `Enable) begin
        we_hilo <= `Invalid;
        hi_o    <= `ZeroWord;
        lo_o    <= `ZeroWord;
    end else begin
        case(aluop)
            // mult、multu计算更新HILO
            `ALU_MULT, `ALU_MULTU: begin
                we_hilo <= `Valid;
                hi_o    <= mulcout[63:32];
                lo_o    <= mulcout[31:0];
            end
            // 写HI则LO保持不变，写LO则HI保持不变
            `ALU_MTHI: begin
                we_hilo <= `Valid;
                hi_o    <= reg1;
                lo_o    <= lo;
            end
            `ALU_MTLO: begin
                we_hilo <= `Valid;
                hi_o    <= hi;
                lo_o    <= reg1;
            end
            `ALU_MADD, `ALU_MADDU, `ALU_MSUB, `ALU_MSUBU: begin
                we_hilo <= `Valid;
                hi_o    <= hilotemp[63:32];
                lo_o    <= hilotemp[31:0];
            end
            `ALU_DIV, `ALU_DIVU: begin
                we_hilo <= `Valid;
                hi_o    <= div_result[63:32];
                lo_o    <= div_result[31:0];
            end
            default:begin
                we_hilo <= `Invalid;
                hi_o    <= `ZeroWord;
                lo_o    <= `ZeroWord;
            end
        endcase
    end
end
// *******  输出DIV模块控制信息，获取DIV模块给出的结果   *********
always @ (*) begin
    if(rst == `Enable) begin
        stall_for_div <= `NoStop;
        div_start <= `Invalid;
        div_opdata1 <= `ZeroWord;
        div_opdata2 <= `ZeroWord;
        div_signed <= `Invalid;
    end else begin
        stall_for_div <= `NoStop;
        div_start <= `Invalid;
        div_opdata1 <= `ZeroWord;
        div_opdata2 <= `ZeroWord;
        div_signed <= `Invalid;
        case (aluop)
            `ALU_DIV: begin
                if(div_ready == `Invalid) begin
                    // 除法的结果没有运算完，开始除法运算
                    div_start <= `Valid;
                    div_opdata1 <= reg1;
                    div_opdata2 <= reg2;
                    div_signed <= `Valid;
                    stall_for_div <= `Stop;
                end else if(div_ready == `Valid) begin
                    // 除法结果准备好，运算完毕
                    div_start <= `Invalid;
                    div_opdata1 <= reg1;
                    div_opdata2 <= reg2;
                    div_signed <= `Valid;
                    stall_for_div <= `NoStop;
                end else begin
                    // 其他情况复位
                    stall_for_div <= `NoStop;
                    div_start <= `Invalid;
                    div_opdata1 <= `ZeroWord;
                    div_opdata2 <= `ZeroWord;
                    div_signed <= `Invalid;
                end
            end
            `ALU_DIVU: begin
                if(div_ready == `Invalid) begin
                    // 除法的结果没有运算完，开始除法运算
                    div_start <= `Valid;
                    div_opdata1 <= reg1;
                    div_opdata2 <= reg2;
                    div_signed <= `Invalid;
                    stall_for_div <= `Stop;
                end else if(div_ready == `Valid) begin
                    // 除法结果准备好，运算完毕
                    div_start <= `Invalid;
                    div_opdata1 <= reg1;
                    div_opdata2 <= reg2;
                    div_signed <= `Invalid;
                    stall_for_div <= `NoStop;
                end else begin
                    // 其他情况复位
                    stall_for_div <= `NoStop;
                    div_start <= `Invalid;
                    div_opdata1 <= `ZeroWord;
                    div_opdata2 <= `ZeroWord;
                    div_signed <= `Invalid;
                end
            end
            default: begin
            end
        endcase
    end
    
end



// ************    根据aluop操作码，选择结果输出     *************
always @ (*) begin
    waddr_o <= waddr_i;
    // 如果add、addi、sub、subi等有符号运算发生溢出，不写结果
    if((overflow == 1'b1) && ((aluop == `ALU_ADD) || (aluop == `ALU_SUB))) begin
        we_o <= `Invalid;
    end else begin
        we_o <= we_i;
    end
    // 根据操作类型，选择结果
    case (alusel)
        `EXE_LOGIC: begin
            wdata_o <= logicout;
        end
        `EXE_SHIFT: begin
            wdata_o <= shiftout;
        end
        `EXE_MOVE: begin
            wdata_o <= moveout;
        end
        `EXE_ARITHMETIC: begin
            wdata_o <= arithmeticout;
        end
        `EXE_MUL: begin
            wdata_o <= mulcout[31:0];
        end
        `EXE_JUMP: begin
            wdata_o <= link_addr;
        end
        default: begin
            wdata_o <= `ZeroWord;
        end
    endcase
end

endmodule