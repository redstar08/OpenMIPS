`include "defines.v"
module id(
    input wire               rst,
    output reg  			 stall,

    // sign from if_id to id
    input wire[`DataBus]     pc,
    input wire[`DataBus]     inst,

// **************  消除数据相关RAW改动    ****************
    // 来自EX阶段的写操作(相隔1条指令的真相关)
    input wire               ex_we,
    input wire[`RegAddr]     ex_waddr,
    input wire[`DataBus]     ex_wdata,
    // 来自MEM阶段的写操作(相隔2条指令的真相关)
    input wire               mem_we,
    input wire[`RegAddr]     mem_waddr,
    input wire[`DataBus]     mem_wdata,
    // 来自WB阶段的写操作(相隔3条指令的真相关)
    // 由于RegFile中已经判断，读的地址是否为WB要写的地址，已经解决
    // 控制冒险
    input wire               is_in_slot_i,

    // 输出到ID/EX解决控制相关
    output reg               next_in_slot,
    // 输出到PC
    output reg               b_flag,
    output reg[31:0]         b_addr,
    // 输出到ID/EX 
    output reg               is_in_slot_o,
    output reg[31:0]         link_addr,   

    // 输出read控制信号和addr到Regfile
    output reg               read1,
    output reg               read2,
    output reg[`RegAddr]     raddr1,
    output reg[`RegAddr]     raddr2,

    // 拿到reg1和reg2的值，作为输入
    input wire[`DataBus]     rdata1,
    input wire[`DataBus]     rdata2,

    // 将数据输出到执行阶段
    output reg[`AluOpBus]    aluop,
    output reg[`AluSelBus]   alusel,
    output reg[`DataBus]     reg1,
    output reg[`DataBus]     reg2,
    // 写reg控制
    output reg               we,
    output reg[`RegAddr]     waddr
);

// **************      指令分类       ****************
// R类
wire[5:0] opcode   =  inst[31:26];
wire[4:0] rs       =  inst[25:21];
wire[4:0] rt       =  inst[20:16];
wire[4:0] rd       =  inst[15:11];
wire[4:0] shamt    =  inst[10:6];
wire[5:0] func     =  inst[5:0];
// I类
wire[15:0] imm     =  inst[15:0];
// J类
wire[25:0] address =  inst[25:0];

// 保存扩展为32位之后的imm
reg[`DataBus] immediate;
// 指令是否有效
reg instable;

// 跳转指令
// 保存当前PC之后的两条指令的地址
wire[31:0]      pc_plus_4;
wire[31:0]      pc_plus_8;
// imm << 2 然后扩展为32位
wire[31:0]      address_32;

assign pc_plus_4  = pc + 4;
assign pc_plus_8  = pc + 8;
assign address_32 = {{14{inst[15]}}, imm, 2'b00};

// **************      指令译码       ****************
always @ (*) begin
    if(rst == `Enable) begin
        aluop     <=  `ALU_NOP;      // 空操作
        alusel    <=  `EXE_NOP;
        we        <=  `Invalid;         // 不可写
        waddr     <=  `NOPAddr;
        read1     <=  `Invalid;      // 不可读
        read2     <=  `Invalid;
        raddr1    <=  `NOPAddr;
        raddr2    <=  `NOPAddr;
        immediate <=  `ZeroWord; // immediate清0
        instable  <=  `Enable;    // 指令无效
        // 跳转指令相关信号
        b_flag    <= `Invalid;
        b_addr    <= `ZeroWord;
        link_addr <= `ZeroWord;
        next_in_slot <= `NoInSlot;
        
    end else begin
        // 初始化，默认的配置
        aluop     <=  `ALU_NOP;      // 空操作
        alusel    <=  `EXE_NOP;
        we        <=  `Invalid;         // 不可写
        // 默认写rd
        waddr     <=  rd;
        read1     <=  `Invalid;      // 不可读
        read2     <=  `Invalid;
        raddr1    <=  rs;
        raddr2    <=  rt;
        immediate <=  `ZeroWord; // immediate清0
        instable  <=  `Disable;
        // 跳转指令相关信号
        b_flag    <= `Invalid;
        b_addr    <= `ZeroWord;
        link_addr <= `ZeroWord;
        next_in_slot <= `NoInSlot;
        // 根据指令码确定信号
        case(opcode)
            `OP_SPECIAL:   begin
                case(shamt)
                    // 无shamt
                    5'b00000:   begin
                        case(func)
                            // 逻辑运算指令
                            `FUNC_AND: begin
                                // 需要写回，默认写回rd
                                we <= `Valid;
                                // 运算类型
                                aluop <= `ALU_AND;
                                alusel <= `EXE_LOGIC;
                                // rs和rt都需要读
                                read1 <= `Valid;
                                read2 <= `Valid;
                                // 指令有效
                                instable <= `Enable;
                            end
                            `FUNC_OR: begin
                                we <= `Valid;
                                aluop <= `ALU_OR;
                                alusel <= `EXE_LOGIC;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_XOR: begin
                                we <= `Valid;
                                aluop <= `ALU_XOR;
                                alusel <= `EXE_LOGIC;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_NOR: begin
                                we <= `Valid;
                                aluop <= `ALU_NOR;
                                alusel <= `EXE_LOGIC;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            // 移位运算指令
                            `FUNC_SLLV: begin
                                // 要写回，默认写回rd = rt << rs
                                we <= `Valid;
                                // 运算类型
                                aluop <= `ALU_SLL;
                                alusel <= `EXE_SHIFT;
                                // 需要读rs rt
                                read1 <= `Valid;
                                read2 <= `Valid;
                                // 指令有效
                                instable <= `Enable;
                            end
                            `FUNC_SRLV: begin
                                we <= `Valid;
                                aluop <= `ALU_SRL;
                                alusel <= `EXE_SHIFT;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_SRAV: begin
                                we <= `Valid;
                                aluop <= `ALU_SRA;
                                alusel <= `EXE_SHIFT;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            // 移动类指令
                            `FUNC_MOVZ: begin
                                aluop <= `ALU_MOVZ;
                                alusel <= `EXE_MOVE;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                                // 判断rt(reg2)是否为0，为0则写
                                if(reg2 == `ZeroWord) begin
                                    we <= `Valid;
                                end else begin
                                    we <= `Invalid;
                                end
                            end
                            `FUNC_MOVN: begin
                                aluop <= `ALU_MOVN;
                                alusel <= `EXE_MOVE;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                                // 判断rt(reg2)是否不为0，不为0则写
                                if(reg2 != `ZeroWord) begin
                                    we <= `Valid;
                                end else begin
                                    we <= `Invalid;
                                end
                            end
                            `FUNC_MFHI: begin
                                // 需要写reg, rd <- HI
                                we <= `Valid;
                                aluop <= `ALU_MFHI;
                                alusel <= `EXE_MOVE;
                                // 不需要读reg
                                read1 <= `Invalid;
                                read2 <= `Invalid;
                                instable <= `Enable;
                            end
                            `FUNC_MFLO: begin
                                // 需要写reg, rd <- LO
                                we <= `Valid;
                                aluop <= `ALU_MFLO;
                                alusel <= `EXE_MOVE;
                                // 不需要读reg
                                read1 <= `Invalid;
                                read2 <= `Invalid;
                                instable <= `Enable;
                            end
                            `FUNC_MTHI: begin
                                // 不需要写reg, LO <- rs
                                we <= `Invalid;
                                aluop <= `ALU_MTHI;
                                // 需要读rs
                                read1 <= `Valid;
                                read2 <= `Invalid;
                                instable <= `Enable;
                            end
                            `FUNC_MTLO: begin
                                // 不需要写reg, LO <- rs
                                we <= `Invalid;
                                aluop <= `ALU_MTLO;
                                // 需要读rs
                                read1 <= `Valid;
                                read2 <= `Invalid;
                                instable <= `Enable;
                            end
                            // 算术运算指令
                            `FUNC_ADD: begin
                                // 需要写reg, rd <- rs + rt
                                we <= `Valid;
                                aluop <= `ALU_ADD;
                                alusel <= `EXE_ARITHMETIC;
                                // 需要读rs rt
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_ADDU: begin
                                we <= `Valid;
                                aluop <= `ALU_ADDU;
                                alusel <= `EXE_ARITHMETIC;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_SUB: begin
                                we <= `Valid;
                                aluop <= `ALU_SUB;
                                alusel <= `EXE_ARITHMETIC;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_SUBU: begin
                                we <= `Valid;
                                aluop <= `ALU_SUBU;
                                alusel <= `EXE_ARITHMETIC;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_SLT: begin
                                we <= `Valid;
                                aluop <= `ALU_SLT;
                                alusel <= `EXE_ARITHMETIC;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_SLTU: begin
                                we <= `Valid;
                                aluop <= `ALU_SLTU;
                                alusel <= `EXE_ARITHMETIC;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_MULT: begin
                                // 乘法不需要写reg，{hi,lo} = rs*rt
                                we <= `Invalid;
                                aluop <= `ALU_MULT;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_MULTU: begin
                                // 乘法不需要写reg，{hi,lo} = rs*rt
                                we <= `Invalid;
                                aluop <= `ALU_MULTU;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_DIV: begin
                                // 除法不需要写reg，{hi,lo} = rs / rt
                                we <= `Invalid;
                                aluop <= `ALU_DIV;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            `FUNC_DIVU: begin
                                // 除法不需要写reg，{hi,lo} = rs / rt
                                we <= `Invalid;
                                aluop <= `ALU_DIVU;
                                read1 <= `Valid;
                                read2 <= `Valid;
                                instable <= `Enable;
                            end
                            // 跳转指令
                            `FUNC_JR: begin
                                // 跳转指令不需要写reg
                                we <= `Invalid;
                                aluop <= `ALU_JR;
                                alusel <= `EXE_JUMP;
                                // 需要读取rs值，跳转
                                read1 <= `Valid;
                                read2 <= `Invalid;
                                instable <= `Enable;
                                // 不需要保存返回的地址
                                link_addr <= `ZeroWord;
                                b_flag <= `Valid;
                                b_addr <= reg1;
                                next_in_slot <= `InSlot;
                            end
                            `FUNC_JALR: begin
                                // jalr跳转指令，需要写reg
                                we <= `Valid;
                                aluop <= `ALU_JALR;
                                alusel <= `EXE_JUMP;
                                // 需要读取rs值，跳转
                                read1 <= `Valid;
                                read2 <= `Invalid;
                                instable <= `Enable;
                                // 需要保存返回的地址
                                waddr <= rd;
                                // 要保存的返回地址为pc_plus_8
                                link_addr <= pc_plus_8;
                                b_flag <= `Valid;
                                b_addr <= reg1;
                                next_in_slot <= `InSlot;
                            end
                            default:begin
                                // 其余情况，当做NOP处理
                            end
                        // 结束case(func)
                        endcase
                    end
                    // 有shamt值
                    default:    begin
                        // shamt != 5'b00000 并且 rs == 5'b00000
                        // opcode和rs都为0，sll srl sra等指令均满足
                        if(rs == 5'b00000) begin
                            case(func)
                                `FUNC_SLL:  begin
                                    // 要写回，默认写回rd = rt << shamt
                                    we <= `Valid;
                                    aluop <= `ALU_SLL;
                                    alusel <= `EXE_SHIFT;
                                    read1 <= `Invalid;
                                    read2 <= `Valid;
                                    immediate[4:0] <= shamt;
                                    instable <= `Enable;
                                end
                                `FUNC_SRL:  begin
                                    we <= `Valid;
                                    aluop <= `ALU_SRL;
                                    alusel <= `EXE_SHIFT;
                                    read1 <= `Invalid;
                                    read2 <= `Valid;
                                    immediate[4:0] <= shamt;
                                    instable <= `Enable;
                                end
                                `FUNC_SRA:  begin
                                    we <= `Valid;
                                    aluop <= `ALU_SRA;
                                    alusel <= `EXE_SHIFT;
                                    read1 <= `Invalid;
                                    read2 <= `Valid;
                                    immediate[4:0] <= shamt;
                                    instable <= `Enable;
                                end
                                default:begin
                                    // 其他情况当NOP处理
                                end
                            // 结束case(func)
                            endcase
                        // end if
                        end
                    // end default
                    end
                // 结束case(shamt)
                endcase
            end
            // 特殊2类指令
            `OP_SPECIAL2: begin
                case (func)
                    `FUNC_MUL: begin
                        // 需要写rd，rd <- rs*rt
                        we <= `Valid;
                        aluop <= `ALU_MUL;
                        alusel <= `EXE_MUL;
                        read1 <= `Valid;
                        read2 <= `Valid;
                        instable <= `Enable;    
                    end
                    `FUNC_CLZ: begin
                        we <= `Valid;
                        aluop <= `ALU_CLZ;
                        alusel <= `EXE_ARITHMETIC;
                        read1 <= `Valid;
                        read2 <= `Invalid;
                        instable <= `Enable;    
                    end
                    `FUNC_CLO: begin
                        we <= `Valid;
                        aluop <= `ALU_CLO;
                        alusel <= `EXE_ARITHMETIC;
                        read1 <= `Valid;
                        read2 <= `Invalid;
                        instable <= `Enable;    
                    end
                    // madd、maddu、msub、msubu指令
                    `FUNC_MADD: begin
                        we <= `Invalid;
                        aluop <= `ALU_MADD;
                        alusel <= `EXE_MUL;
                        read1 <= `Valid;
                        read2 <= `Valid;
                        instable <= `Enable;    
                    end
                    `FUNC_MADDU: begin
                        we <= `Invalid;
                        aluop <= `ALU_MADDU;
                        alusel <= `EXE_MUL;
                        read1 <= `Valid;
                        read2 <= `Valid;
                        instable <= `Enable;    
                    end
                    `FUNC_MSUB: begin
                        we <= `Invalid;
                        aluop <= `ALU_MSUB;
                        alusel <= `EXE_MUL;
                        read1 <= `Valid;
                        read2 <= `Valid;
                        instable <= `Enable;    
                    end
                    `FUNC_MSUBU: begin
                        we <= `Invalid;
                        aluop <= `ALU_MSUBU;
                        alusel <= `EXE_MUL;
                        read1 <= `Valid;
                        read2 <= `Valid;
                        instable <= `Enable;    
                    end
                    default: begin
                    end
                // end case (func)
                endcase
            // end OP_SPECIAL2
            end
            `OP_ORI:   begin
                // ori需要写回，we有效
                we <= `Valid;
                // aluop是逻辑或运算
                aluop <= `ALU_OR;
                // alusel类型是逻辑运算类型
                alusel <= `EXE_LOGIC;
                // 需要读reg1，不需要读reg2
                read1 <= `Valid;
                read2 <= `Invalid;
                // 需要立即数
                immediate <= {16'h0, imm};
                // 要写rt寄存器
                waddr <= rt;
                // ori指令有效
                instable <= `Enable;
            end
            `OP_ANDI:   begin
                we <= `Valid;
                aluop <= `ALU_AND;
                alusel <= `EXE_LOGIC;
                read1 <= `Valid;
                read2 <= `Invalid;
                immediate <= {16'h0, imm};
                waddr <= rt;
                instable <= `Enable;
            end
            `OP_XORI:   begin
                we <= `Valid;
                aluop <= `ALU_XOR;
                alusel <= `EXE_LOGIC;
                read1 <= `Valid;
                read2 <= `Invalid;
                immediate <= {16'h0, imm};
                waddr <= rt;
                instable <= `Enable;
            end
            `OP_LUI:   begin
                we <= `Valid;
                // 将imm扩展成高16位的32位数之后，与$0直接作或运算，相当于rt <= {imm, 16'h0};
                aluop <= `ALU_OR;
                alusel <= `EXE_LOGIC;
                read1 <= `Valid;
                read2 <= `Invalid;
                immediate <= {imm, 16'h0};
                waddr <= rt;
                instable <= `Enable;
            end
            `OP_ADDI:   begin
                // 需要写rt，rt <- rs + imm
                we <= `Valid;
                aluop <= `ALU_ADD;
                alusel <= `EXE_ARITHMETIC;
                read1 <= `Valid;
                read2 <= `Invalid;
                immediate <= {16'h0, imm};
                waddr <= rt;
                instable <= `Enable;
            end
            `OP_ADDIU:   begin
                // 需要写rt，rt <- rs + imm
                we <= `Valid;
                aluop <= `ALU_ADDU;
                alusel <= `EXE_ARITHMETIC;
                read1 <= `Valid;
                read2 <= `Invalid;
                // 保留符号
                immediate <= {{16{imm[15]}}, imm};
                waddr <= rt;
                instable <= `Enable;
            end
            `OP_SLTI:   begin
                // 需要写rt，rt <- (rs < immediate)
                we <= `Valid;
                aluop <= `ALU_SLT;
                alusel <= `EXE_ARITHMETIC;
                read1 <= `Valid;
                read2 <= `Invalid;
                immediate <= {`ZeroWord, imm};
                waddr <= rt;
                instable <= `Enable;
            end
            `OP_SLTIU:   begin
                // 需要写rt，rt <- (rs < immediate)
                we <= `Valid;
                aluop <= `ALU_SLTU;
                alusel <= `EXE_ARITHMETIC;
                read1 <= `Valid;
                read2 <= `Invalid;
                // 保留符号
                immediate <= {{16{imm[15]}}, imm};
                waddr <= rt;
                instable <= `Enable;
            end
            // 跳转指令
            `OP_J:   begin
                we <= `Invalid;
                aluop <= `ALU_J;
                alusel <= `EXE_JUMP;
                read1 <= `Invalid;
                read2 <= `Invalid;
                instable <= `Enable;
                // 不需要保存返回地址
                link_addr <= `ZeroWord;
                b_flag <= `Valid;
                b_addr <= {pc_plus_4[31:28], address, 2'b00};
                next_in_slot <= `InSlot;
            end
            `OP_JAL:   begin
                // 需要写$31
                we <= `Valid;
                aluop <= `ALU_JAL;
                alusel <= `EXE_JUMP;
                read1 <= `Invalid;
                read2 <= `Invalid;
                instable <= `Enable;
                waddr  <= 5'b11111;
                // 需要保存返回地址
                link_addr <= pc_plus_8;
                b_flag <= `Valid;
                b_addr <= {pc_plus_4[31:28], address, 2'b00};
                next_in_slot <= `InSlot;
            end
            `OP_BEQ:   begin
                we <= `Invalid;
                aluop <= `ALU_BEQ;
                alusel <= `EXE_JUMP;
                read1 <= `Valid;
                read2 <= `Valid;
                instable <= `Enable;
                if (reg1 == reg2) begin
                    b_flag <= `Valid;
                    b_addr <= pc_plus_4 + address_32;
                    next_in_slot <= `InSlot;
                end
            end
            `OP_BNE:   begin
                we <= `Invalid;
                aluop <= `ALU_BNE;
                alusel <= `EXE_JUMP;
                read1 <= `Valid;
                read2 <= `Valid;
                instable <= `Enable;
                if (reg1 != reg2) begin
                    b_flag <= `Valid;
                    b_addr <= pc_plus_4 + address_32;
                    next_in_slot <= `InSlot;
                end
            end
            `OP_BGTZ:   begin
                we <= `Invalid;
                aluop <= `ALU_BGTZ;
                alusel <= `EXE_JUMP;
                read1 <= `Valid;
                read2 <= `Invalid;
                instable <= `Enable;
                // >0
                if ((reg1[31] == 1'b0) && (reg1 != `ZeroWord)) begin
                    b_flag <= `Valid;
                    b_addr <= pc_plus_4 + address_32;
                    next_in_slot <= `InSlot;
                end
            end
            `OP_BLEZ:   begin
                we <= `Invalid;
                aluop <= `ALU_BLEZ;
                alusel <= `EXE_JUMP;
                read1 <= `Valid;
                read2 <= `Invalid;
                instable <= `Enable;
                // <=0
                if ((reg1[31] == 1'b1) || (reg1 == `ZeroWord)) begin
                    b_flag <= `Valid;
                    b_addr <= pc_plus_4 + address_32;
                    next_in_slot <= `InSlot;
                end
            end
            `OP_REGIMM:   begin
                case (rt)
                    `RT_BGEZ: begin
                        we <= `Invalid;
                        aluop <= `ALU_BGEZ;
                        alusel <= `EXE_JUMP;
                        read1 <= `Valid;
                        read2 <= `Invalid;
                        instable <= `Enable;
                        // >=0
                        if (reg1[31] == 1'b0) begin
                            b_flag <= `Valid;
                            b_addr <= pc_plus_4 + address_32;
                            next_in_slot <= `InSlot;
                        end
                    end
                    `RT_BLTZ: begin
                        we <= `Invalid;
                        aluop <= `ALU_BLTZ;
                        alusel <= `EXE_JUMP;
                        read1 <= `Valid;
                        read2 <= `Invalid;
                        instable <= `Enable;
                        // <0
                        if (reg1[31] == 1'b1) begin
                            b_flag <= `Valid;
                            b_addr <= pc_plus_4 + address_32;
                            next_in_slot <= `InSlot;
                        end
                    end
                    `RT_BGEZAL: begin
                        // AL所以需要保存返回地址
                        we <= `Valid;
                        aluop <= `ALU_BGEZAL;
                        alusel <= `EXE_JUMP;
                        read1 <= `Valid;
                        read2 <= `Invalid;
                        instable <= `Enable;
                        // >0
                        waddr <= 5'b11111;
                        link_addr <= pc_plus_8;
                        if (reg1[31] == 1'b0) begin
                            b_flag <= `Valid;
                            b_addr <= pc_plus_4 + address_32;
                            next_in_slot <= `InSlot;
                        end
                    end
                    `RT_BLTZAL: begin
                        // AL所以需要保存返回地址
                        we <= `Valid;
                        aluop <= `ALU_BLTZAL;
                        alusel <= `EXE_JUMP;
                        read1 <= `Valid;
                        read2 <= `Invalid;
                        instable <= `Enable;
                        // <0
                        waddr <= 5'b11111;
                        link_addr <= pc_plus_8;
                        if (reg1[31] == 1'b1) begin
                            b_flag <= `Valid;
                            b_addr <= pc_plus_4 + address_32;
                            next_in_slot <= `InSlot;
                        end
                    end
                    default: begin
                    end
                // 结束case(rt)
                endcase
            end
            default:begin
            end
        // 结束case(opcode)    
        endcase
    end
end

// 输出变量is_in_slot_o，表示当前指令是否为延时指令
always @ (*) begin
    if (rst == `Enable) begin
        is_in_slot_o <= `NoInSlot;
    end else begin
        is_in_slot_o <= is_in_slot_i;
    end
end


// **************     确定源操作数1      ****************
always @ (*) begin
    if(rst == `Enable) begin
        reg1 <= `ZeroWord;
    end else if((read1 == `Valid) && (ex_we == `Valid) && (ex_waddr == raddr1)) begin
        // 消除RAW相关，要读的reg是EX阶段要写的reg，直接赋值(EX -> ID)
        reg1 <= ex_wdata;
    end else if((read1 == `Valid) && (mem_we == `Valid) && (mem_waddr == raddr1)) begin
        // 消除RAW相关，要读的reg是MEM阶段要写的reg，直接赋值(MEM -> ID)
        reg1 <= mem_wdata;
    end else if(read1 == `Valid) begin      //读有效，其他情况
        reg1 <= rdata1;
    end else if(read1 == `Invalid) begin    //读无效，给出imm
        reg1 <= immediate;
    end else begin
        reg1 <= `ZeroWord;
    end
end

// **************     确定源操作数2      ****************
always @ (*) begin
    if(rst == `Enable) begin
        reg2 <= `ZeroWord;
    end else if((read2 == `Valid) && (ex_we == `Valid) && (ex_waddr == raddr2)) begin
        // 消除RAW相关，要读的reg是EX阶段要写的reg，直接赋值(EX -> ID)
        reg2 <= ex_wdata;
    end else if((read2 == `Valid) && (mem_we == `Valid) && (mem_waddr == raddr2)) begin
        // 消除RAW相关，要读的reg是MEM阶段要写的reg，直接赋值(MEM -> ID)
        reg2 <= mem_wdata;
    end else if(read2 == `Valid) begin      //读有效
        reg2 <= rdata2;
    end else if(read2 == `Invalid) begin    //读无效，给出imm
        reg2 <= immediate;
    end else begin
        reg2 <= `ZeroWord;
    end
end

endmodule