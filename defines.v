// **************      全局宏定义       ****************
`define Enable          1'b1                //允许
`define Disable         1'b0                //禁止
`define Valid           1'b0                //低电平有效
`define Invalid         1'b1                //高电平无效
`define DataBus         31:0                //数据总线
`define ZeroWord        32'h00000000        //32位0
`define Stop            1'b1                //流水线暂停
`define NoStop          1'b0                //流水线继续
// **************       PC宏定义       ****************
`define pcStep          4'h4             //PC步长

// **************       regfile宏定义       ****************
`define RegAddr         4:0              //reg地址
`define NOPAddr         5'b00000

// **************       rom宏定义       ****************
`define InstMemSize     65536            //2^16=65536 64K个字
`define InstMemSizeLog2 16               //rom的地址线位数

// **************      ALU宏定义       ****************
`define AluOpBus        7:0                 //ALU操作码
`define AluSelBus       2:0                 //ALU操作码分类
//AluOp     alu操作码(相当于OpCode的扩赞)
// 空运算
`define ALU_NOP         8'b00000000
// 逻辑运算
`define ALU_AND         8'b00100100
`define ALU_OR          8'b00100101
`define ALU_XOR         8'b00100110
`define ALU_NOR         8'b00100111
// 移位运算
`define ALU_SLL         8'b00000000
`define ALU_SRL         8'b00000010
`define ALU_SRA         8'b00000011
// 移动指令
`define ALU_MOVZ        8'b00001010           //movz指令的ALU码
`define ALU_MOVN        8'b00001011           //movn指令的ALU码
`define ALU_MFHI        8'b00010000           //mfhi指令的ALU码
`define ALU_MTHI        8'b00010001           //mthi指令的ALU码
`define ALU_MFLO        8'b00010010           //mflo指令的ALU码
`define ALU_MTLO        8'b00010011           //mtlo指令的ALU码
// 算术指令
`define ALU_ADD         8'b00100000           //add指令的ALU码
`define ALU_ADDU        8'b00100001           //addu指令的ALU码
`define ALU_SUB         8'b00100010           //sub指令的ALU码
`define ALU_SUBU        8'b00100011           //subu指令的ALU码
`define ALU_SLT         8'b00101010           //slt指令的ALU码
`define ALU_SLTU        8'b00101011           //sltu指令的ALU码
`define ALU_MULT        8'b00011000           //mult指令的ALU码
`define ALU_MULTU       8'b00011001           //multu指令的ALU码
// SPECIAL2指令 01开头
`define ALU_MUL         8'b01000010           //mul指令的ALU码
`define ALU_CLZ         8'b01100000           //clz指令的ALU码
`define ALU_CLO         8'b01100001           //clo指令的ALU码
// madd、maddu、msub、msubu指令的ALU码
`define ALU_MADD        8'b01000000
`define ALU_MADDU       8'b01000001
`define ALU_MSUB        8'b01000100
`define ALU_MSUBU       8'b01000101
// div、divu指令啊ALU码
`define ALU_DIV         8'b00011010
`define ALU_DIVU        8'b00011011
// 跳转指令
`define ALU_JR          8'b00001000
`define ALU_JALR        8'b00001001
`define ALU_J           8'b10000010           //j指令的ALU码
`define ALU_JAL         8'b10000011           //jal指令的ALU码
// 分支指令
`define ALU_B           8'b00000100           //b指令的ALU码
`define ALU_BEQ         8'b00000100           //beq指令的ALU码
`define ALU_BNE         8'b00000101           //bne指令的ALU码
`define ALU_BGTZ        8'b00000111           //bgtz指令的ALU码
`define ALU_BLEZ        8'b00000110           //blez指令的ALU码
`define ALU_BGEZ        8'b01000111           //bgtz指令的ALU码
`define ALU_BLTZ        8'b01000110           //bltz指令的ALU码
`define ALU_BGEZAL      8'b10000111
`define ALU_BLTZAL      8'b10000110



//AluSel    alu分类码(空运算、逻辑运算、算术运算)
`define EXE_NOP         3'b000              //空运算
`define EXE_LOGIC       3'b001              //逻辑运算
`define EXE_SHIFT       3'b010              //移位运算
`define EXE_MOVE        3'b011              //移动类指令
`define EXE_ARITHMETIC  3'b100              //算术运算指令(非乘法)
`define EXE_MUL         3'b101              //乘法运算指令
`define EXE_JUMP        3'b110              //跳转指令


// ************    OpCode指令码宏定义     *************
`define OP_NOP          6'b000000           //nop的指令码
`define OP_ANDI         6'b001100           //andi的指令码
`define OP_ORI          6'b001101           //ori的指令码
`define OP_XORI         6'b001110           //xori的指令码
`define OP_LUI          6'b001111           //lui的指令码
// 算术运算指令
`define OP_ADDI         6'b001000           //addi的指令码
`define OP_ADDIU        6'b001001           //addiu的指令码
`define OP_SLTI         6'b001010           //slti的指令码
`define OP_SLTIU        6'b001011           //sltiu的指令码
// 跳转指令
`define OP_J            6'b000010           //j指令的指令码
`define OP_JAL          6'b000011           //jal指令的指令码
// 分支指令
`define OP_B            6'b000100           //b指令的指令码
`define OP_BEQ          6'b000100           //beq指令的指令码
`define OP_BNE          6'b000101           //bne指令的指令码
`define OP_BLEZ         6'b000110           //blez指令的指令码
`define OP_BGTZ         6'b000111           //bgtz指令的指令码


// SPECIAL特殊功能指令的功能码
`define OP_SPECIAL      6'b000000           //special类指令的指令码
`define OP_SPECIAL2     6'b011100           //special2类指令的指令码
`define OP_REGIMM       6'b000001           //regimm类指令的指令码

`define RT_BLTZ         5'b00000            //bltz指令的区分码
`define RT_BGEZ         5'b00001            //bgez指令的区分码
`define RT_BLTZAL       5'b10000            //bltzal指令的区分码
`define RT_BGEZAL       5'b10001            //bgezal指令的区分码
`define RT_BAL          5'b10001            //bal指令的区分码


// 移位运算功能码
`define FUNC_SLL        6'b000000           //sll类指令的功能码
`define FUNC_SRL        6'b000010           //srl类指令的功能码
`define FUNC_SRA        6'b000011           //sra类指令的功能码
`define FUNC_SLLV       6'b000100           //sllv类指令的功能码
`define FUNC_SRLV       6'b000110           //srlv类指令的功能码
`define FUNC_SRAV       6'b000111           //srav类指令的功能码

// 逻辑运算功能码
`define FUNC_AND        6'b100100           //and指令的功能码
`define FUNC_OR         6'b100101           //or指令的功能码
`define FUNC_XOR        6'b100110           //xor指令的功能码
`define FUNC_NOR        6'b100111           //nor指令的功能码

// 移动指令功能码
`define FUNC_MOVZ       6'b001010           //movz指令的功能码
`define FUNC_MOVN       6'b001011           //movn指令的功能码
`define FUNC_MFHI       6'b010000           //mfhi指令的功能码
`define FUNC_MTHI       6'b010001           //mthi指令的功能码
`define FUNC_MFLO       6'b010010           //mflo指令的功能码
`define FUNC_MTLO       6'b010011           //mtlo指令的功能码

// 算术指令功能码
`define FUNC_ADD        6'b100000           //add指令的功能码
`define FUNC_ADDU       6'b100001           //addu指令的功能码
`define FUNC_SUB        6'b100010           //sub指令的功能码
`define FUNC_SUBU       6'b100011           //subu指令的功能码
`define FUNC_SLT        6'b101010           //slt指令的功能码
`define FUNC_SLTU       6'b101011           //sltu指令的功能码
`define FUNC_MULT       6'b011000           //mult指令的功能码
`define FUNC_MULTU      6'b011001           //multu指令的功能码

// OP_SPECIAL2的功能码
`define FUNC_MUL        6'b000010           //mul指令的功能码
`define FUNC_CLZ        6'b100000           //clz指令的功能码
`define FUNC_CLO        6'b100001           //clo指令的功能码
// madd、maddu、msub、msubu指令的功能码
`define FUNC_MADD       6'b000000
`define FUNC_MADDU      6'b000001
`define FUNC_MSUB       6'b000100
`define FUNC_MSUBU      6'b000101
// div、divu指令啊ALU码
`define FUNC_DIV        6'b011010
`define FUNC_DIVU       6'b011011
// 定义除法状态
`define DivFree         2'b00
`define DivZero         2'b01
`define DivOn           2'b10
`define DivEnd          2'b11

// 跳转指令
`define FUNC_JR         6'b001000
`define FUNC_JALR       6'b001001
// 延迟槽宏定义
`define InSlot          1'b1
`define NoInSlot        1'b0



