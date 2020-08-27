	.org 0x0
	.set noat
	.set noreorder			#不进行指令调度
	.set nomacro
	.global __start
__start:
	# 注意，MIPS编译时，会将rs和rt的二进制位置互换，写法上是rt,rs，指令码是opcode rs rt(写入rt)
	# 用ori指令作为开始标志
	# start code
	# ori $0, $0, 0x0000
	# 3400 0000
	# 此处开始书写代码
	.org 0x0000
	ori $0, $0, 0x0000
	
	# 真正的代码
	ori $3, $0, 0x8000 		# [1] $3 = 0x00008000
	sll $3, 16				# [2] $3左移16位，$3 = 0x80000000
	ori	$1, $0, 0x0001		# [3] $1 = 0x1
	b 	s1					# [4] 转移到s1处
	ori $1, $0, 0x0002		# [5] $1 = 0x2,延迟槽指令
b1:
	ori	$1, $0, 0x1111
	ori $1, $0, 0x1100
 
	.org 0x20
s1 :
	ori	$1, $0, 0x0004		# [6] $1 = 0x4
	movz $2, $1, $0 		# [7] $2 = $1 = 0x4
	bal s2					# [8] 转移到s2处，同时设置$31为0x30
	srlv $3, $3, $1			# [9] $3右移 $1 = 0x4 位,$3 = 0x08000000，延迟槽指令
	ori	$1, $0, 0x1100		# 地址为0x30，保存在$31中
	ori	$1, $0, 0x1111
	bne $1, $0, s3
	nop
	ori	$1, $0, 0x1100
	ori $1, $0, 0x1111

	.org 0x50
s2:
	ori	$1, $0,  0x0003		# [10] $1 = 0x3
	beq	$3, $3,  s3			# [11] $3等于$3，发生转移，目的地址是s3
	or  $1, $31, $0			# [12] $1 = 0x30,延迟槽指令
	ori	$1, $0,  0x1111
	ori $1, $0,  0x1100
b2:
	addi $2, $1, 0x0015 	# [16] $2 = $1(0x6) + 0x15 = 0x1b
	ori	$1, $0, 0x2			# [17] $1 = 0x2,
	mul $4, $1, $2 			# [18] $4 = $1(0x6) * $2(0x1b)
	ori $1, $1, 0xffff
	sll $1, $1, 16
	addi $1, $1, 0xffe3
	bgtz $2, s4				# [19] 此时$1为0x8，大于0，所以转移至标号s4处
	addi $1, $1, 0x1000
	
	.org 0x90
s3:
	ori $1, $0, 0x0005		# [13] $1 = 0x5
	bgez $1, b2				# [14] 此时$1为0x5 大于0,转移至前面的b2处
	ori $1, $0, 0x0006		# [15] $1 = 0x6，延迟槽指令
	ori	$1, $0, 0x1111 
	ori $1, $0, 0x1100
	nop 

s4:
	ori $2, $0, 0xffff      # [20]  $2 = 0x0000ffff
	sll $2, $2, 16			# $2 = 0xffff0000
	ori $2, $2, 0xfff1 		# $2 = -15 (0xfffffff1)
	ori $3, $0, 0x11 		# $3 = 17  (0x00000011)
	div  $0, $2, $3			# hi = 0xfffffff1
							# lo = 0x0					
	divu $0, $2, $3			# hi = 0x00000003
							# lo = 0x0f0f0f0e						
	div  $0, $3, $2			# hi = 0x02
							# lo = 0xffffffff
							# 
next0:
	j next0 # [21] 指令运行结束，等待退出
	nop


	# end code
	# 3400 0000 3400 0000
	ori $0, $0, 0x0000
	ori $0, $0, 0x0000
