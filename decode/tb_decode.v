module tb_top;

reg clk;
reg rst;
reg [PC_WIDTH-1:0] pc_first_i;
reg [PC_WIDTH-1:0] pc_second_i;
reg [PC_WIDTH-1:0] next_pc_first_i;
reg [PC_WIDTH-1:0] next_pc_second_i;
reg is_rv_first_i;
reg is_rv_second_i;
reg [31:0] instruction_first_i;
reg [31:0] instruction_second_i;
reg exception_first_i;
reg exception_second_i;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_first_i;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_i;
reg fetch_deco_req_valid_first_i;
reg fetch_deco_req_valid_second_i;
reg deco_rob_req_ready_first_i;
reg deco_rob_req_ready_second_i;
reg branch_back_i;
reg global_trapped_i;
reg global_wfi_i;
reg fetch_deco_req_ready_o;
reg uses_rs1_first_o;
reg uses_rs1_second_o;
reg uses_rs2_first_o;
reg uses_rs2_second_o;
reg uses_rd_first_o;
reg uses_rd_second_o;
reg uses_csr_first_o;
reg uses_csr_second_o;
reg [VIRTUAL_ADDR_LEN-1 :0] pc_first_o;
reg [VIRTUAL_ADDR_LEN-1 :0] pc_second_o;
reg [VIRTUAL_ADDR_LEN-1 :0] next_pc_first_o;
reg [VIRTUAL_ADDR_LEN-1 :0] next_pc_second_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rs1_address_first_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rs1_address_second_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rs2_address_first_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rs2_address_second_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rd_address_first_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rd_address_second_o;
reg [CSR_ADDR_LEN-1:0] csr_address_first_o;
reg [CSR_ADDR_LEN-1:0] csr_address_second_o;
reg mret_first_o;
reg mret_second_o;
reg sret_first_o;
reg sret_second_o;
reg wfi_first_o;
reg wfi_second_o;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_first_o;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_o;
reg exception_first_o;
reg exception_second_o;
reg half_first_o;
reg half_second_o;
reg is_fence_first_o;
reg is_fence_second_o;
reg [1:0] fence_op_first_o;
reg [1:0] fence_op_second_o;
reg is_aext_first_o;
reg is_aext_second_o;
reg is_mext_first_o;
reg is_mext_second_o;
reg deco_rob_req_valid_first_o;
reg deco_rob_req_valid_second_o;
reg csr_read_first_o;
reg csr_read_second_o;
reg csr_write_first_o;
reg csr_write_second_o;
reg [31:0] imm_data_first_o;
reg [31:0] imm_data_second_o;
reg [2:0] fu_function_first_o;
reg [2:0] fu_function_second_o;
reg alu_function_modifier_first_o;
reg alu_function_modifier_second_o;
reg [1:0] fu_select_a_first_o;
reg [1:0] fu_select_a_second_o;
reg [1:0] fu_select_b_first_o;
reg [1:0] fu_select_b_second_o;
reg jump_first_o;
reg jump_second_o;
reg branch_first_o;
reg branch_second_o;
reg is_alu_first_o;
reg is_alu_second_o;
reg load_first_o;
reg load_second_o;
reg store_first_o;
reg store_second_o;
reg [LDU_OP_WIDTH-1:0] ldu_op_first_o;
reg [LDU_OP_WIDTH-1:0] ldu_op_second_o;
reg [STU_OP_WIDTH-1:0] stu_op_first_o;
reg [STU_OP_WIDTH-1:0] stu_op_second_o;
reg aq_first_o;
reg aq_second_o;
reg rl_first_o;
reg rl_second_o;

initial begin
    clk = 0;
    rst = 1;
    pc_first_i = 0;
    pc_second_i = 0;
    next_pc_first_i = 0;
    next_pc_second_i = 0;
    is_rv_first_i = 0;
    is_rv_second_i = 0;
    instruction_first_i = 0;
    instruction_second_i = 0;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 0;
    fetch_deco_req_valid_second_i = 0;
    deco_rob_req_ready_first_i = 0;
    deco_rob_req_ready_second_i = 0;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // from rv64ui-p-add
    // 800001c4:	ffff8137          	lui	sp,0xffff8
    // 800001c8:	00208733          	add	a4,ra,sp
    rst = 0;
    pc_first_i = 32'h800001c4;
    pc_second_i = 32'h800001c8;
    next_pc_first_i = 32'h800001c8;
    next_pc_second_i = 32'h800001cc;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'hffff8137;
    instruction_second_i = 32'h00208733;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 80000200:	fff3839b          	addiw	t2,t2,-1
    // 80000204:	00f39393          	slli	t2,t2,0xf
    pc_first_i = 32'h80000200;
    pc_second_i = 32'h80000204;
    next_pc_first_i = 32'h80000204;
    next_pc_second_i = 32'h80000208;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'hfff3839b;
    instruction_second_i = 32'h00f39393;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 80000208:	00700193          	li	gp,7
    // 8000020c:	46771063          	bne	a4,t2,8000066c <fail>
    pc_first_i = 32'h80000208;
    pc_second_i = 32'h8000020c;
    next_pc_first_i = 32'h8000020c;
    next_pc_second_i = 32'h80000210;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'h00700193;
    instruction_second_i = 32'h46771063;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 8000066c:	0ff0000f          	fence
    // 80000670:	00018063          	beqz	gp,80000670 <fail+0x4>
    pc_first_i = 32'h8000066c;
    pc_second_i = 32'h80000670;
    next_pc_first_i = 32'h80000670;
    next_pc_second_i = 32'h80000674;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'h0ff0000f;
    instruction_second_i = 32'h00018063;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // from aha-mont64
    // 8000003e:	62f9                	lui	t0,0x1e
    // 80000040:	3002a073          	csrs	mstatus,t0
    pc_first_i = 32'h8000003e;
    pc_second_i = 32'h80000040;
    next_pc_first_i = 32'h80000040;
    next_pc_second_i = 32'h80000044;
    is_rv_first_i = 0;
    is_rv_second_i = 1;
    instruction_first_i = 32'h000062f9;
    instruction_second_i = 32'h3002a073;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 80000044:	4285                	li	t0,1
    // 80000046:	02fe                	slli	t0,t0,0x1f
    pc_first_i = 32'h80000044;
    pc_second_i = 32'h80000046;
    next_pc_first_i = 32'h80000046;
    next_pc_second_i = 32'h80000048;
    is_rv_first_i = 0;
    is_rv_second_i = 0;
    instruction_first_i = 32'h00004285;
    instruction_second_i = 32'h000002fe;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 80000052:	faa2a923          	sw	a0,-78(t0) # 80001000 <tohost>
    // 80000056:	bfdd                	j	8000004c <_start+0x4c>
    pc_first_i = 32'h80000052;
    pc_second_i = 32'h80000056;
    next_pc_first_i = 32'h80000056;
    next_pc_second_i = 32'h80000058;
    is_rv_first_i = 1;
    is_rv_second_i = 0;
    instruction_first_i = 32'hfaa2a923;
    instruction_second_i = 32'h0000bfdd;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 80001050:	a001be83          	ld	t4,-1536(gp) # 80001e60 <in_a>
    // 80001054:	03ce8fb3          	mul	t6,t4,t3
    pc_first_i = 32'h80001050;
    pc_second_i = 32'h80001054;
    next_pc_first_i = 32'h80001054;
    next_pc_second_i = 32'h80001058;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'ha001be83;
    instruction_second_i = 32'h03ce8fb3;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 80001120:	e416                	sd	t0,8(sp)
    // 80001122:	6702                	ld	a4,0(sp)
    pc_first_i = 32'h80001120;
    pc_second_i = 32'h80001122;
    next_pc_first_i = 32'h80001122;
    next_pc_second_i = 32'h80001124;
    is_rv_first_i = 0;
    is_rv_second_i = 0;
    instruction_first_i = 32'h0000e416;
    instruction_second_i = 32'h00006702;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 80001a64:	9d19                	subw	a0,a0,a4
    // 80001a66:	8082                	ret
    pc_first_i = 32'h80001a64;
    pc_second_i = 32'h80001a66;
    next_pc_first_i = 32'h80001a66;
    next_pc_second_i = 32'h80001a68;
    is_rv_first_i = 0;
    is_rv_second_i = 0;
    instruction_first_i = 32'h00009d19;
    instruction_second_i = 32'h00008082;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 80001512:	12e7ec63          	bltu	a5,a4,8000164a <vprintfmt+0x276>
    // 80001516:	02e7d7b3          	divu	a5,a5,a4
    pc_first_i = 32'h80001512;
    pc_second_i = 32'h80001516;
    next_pc_first_i = 32'h80001516;
    next_pc_second_i = 32'h8000151a;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'h12e7ec63;
    instruction_second_i = 32'h02e7d7b3;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 8000151e:	2c05                	addiw	s8,s8,1
    // 80001520:	02e7f9b3          	remu	s3,a5,a4
    pc_first_i = 32'h8000151e;
    pc_second_i = 32'h80001520;
    next_pc_first_i = 32'h80001520;
    next_pc_second_i = 32'h80001524;
    is_rv_first_i = 0;
    is_rv_second_i = 1;
    instruction_first_i = 32'h00002c05;
    instruction_second_i = 32'h02e7f9b3;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 8000109a:	f1ed                	bnez	a1,8000107c <benchmark_body+0x34>
    // 8000109c:	02d6b733          	mulhu	a4,a3,a3
    pc_first_i = 32'h8000109a;
    pc_second_i = 32'h8000109c;
    next_pc_first_i = 32'h8000109c;
    next_pc_second_i = 32'h800010a0;
    is_rv_first_i = 0;
    is_rv_second_i = 1;
    instruction_first_i = 32'h0000f1ed;
    instruction_second_i = 32'h02d6b733;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // RV64A
    // 80001ac4:	0f50000f          	fence	iorw,ow
    // 80001ac8:	4516202f          	amoor.w.aq	zero,a7,(a2)
    pc_first_i = 32'h80001ac4;
    pc_second_i = 32'h80001ac8;
    next_pc_first_i = 32'h80001ac8;
    next_pc_second_i = 32'h80001acc;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'h0f50000f;
    instruction_second_i = 32'h4516202f;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 80000060:	0805252f          	amoswap.w	a0,zero,(a0)
    // 80000064:	00157593          	andi	a1,a0,1
    pc_first_i = 32'h80000060;
    pc_second_i = 32'h80000064;
    next_pc_first_i = 32'h80000064;
    next_pc_second_i = 32'h80000068;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'h0805252f;
    instruction_second_i = 32'h00157593;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 800074b0:	100736af          	lr.d	a3,(a4)
    // 800074b4:	00c69763          	bne	a3,a2,800074c2 <switch_mm+0x266>
    pc_first_i = 32'h800074b0;
    pc_second_i = 32'h800074b4;
    next_pc_first_i = 32'h800074b4;
    next_pc_second_i = 32'h800074b8;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'h100736af;
    instruction_second_i = 32'h00c69763;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 800074b8:	1af735af          	sc.d.rl	a1,a5,(a4)
    // 800074bc:	f9f5                	bnez	a1,800074b0 <switch_mm+0x254>
    pc_first_i = 32'h800074b8;
    pc_second_i = 32'h800074bc;
    next_pc_first_i = 32'h800074bc;
    next_pc_second_i = 32'h800074be;
    is_rv_first_i = 1;
    is_rv_second_i = 0;
    instruction_first_i = 32'h1af735af;
    instruction_second_i = 32'h0000f9f5;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 800075be:	0f57b62f          	amoswap.d.aqrl	a2,s5,(a5)
    // 800075c2:	00a08f97          	auipc	t6,0xa08
    pc_first_i = 32'h800075be;
    pc_second_i = 32'h800075c2;
    next_pc_first_i = 32'h800075c2;
    next_pc_second_i = 32'h800075c6;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'h0f57b62f;
    instruction_second_i = 32'h00a08f97;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 8000ac3a:	00871733          	sll	a4,a4,s0
    // 8000ac3e:	40e7b02f          	amoor.d	zero,a4,(a5)
    pc_first_i = 32'h8000ac3a;
    pc_second_i = 32'h8000ac3e;
    next_pc_first_i = 32'h8000ac3e;
    next_pc_second_i = 32'h8000ac42;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'h00871733;
    instruction_second_i = 32'h40e7b02f;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // fence
    // 800072e2:	18079073          	csrw	satp,a5
    // 800072e6:	12000073          	sfence.vma
    pc_first_i = 32'h800072e2;
    pc_second_i = 32'h800072e6;
    next_pc_first_i = 32'h800072e6;
    next_pc_second_i = 32'h800072ea;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'h18079073;
    instruction_second_i = 32'h12000073;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #100
    // 80007306:	0330000f          	fence	rw,rw
    // 8000730a:	0000100f          	fence.i
    pc_first_i = 32'h80007306;
    pc_second_i = 32'h8000730a;
    next_pc_first_i = 32'h8000730a;
    next_pc_second_i = 32'h8000730e;
    is_rv_first_i = 1;
    is_rv_second_i = 1;
    instruction_first_i = 32'h0330000f;
    instruction_second_i = 32'h0000100f;
    exception_first_i = 0;
    exception_second_i = 0;
    ecause_first_i = 0;
    ecause_second_i = 0;
    fetch_deco_req_valid_first_i = 1;
    fetch_deco_req_valid_second_i = 1;
    deco_rob_req_ready_first_i = 1;
    deco_rob_req_ready_second_i = 1;
    branch_back_i = 0;
    global_trapped_i = 0;
    global_wfi_i = 0;
    #2000
    $finish;
end

always #10 clk = ~clk;

decode decode_u(
    .clk(clk),
    .rst(rst),
    .pc_first_i(pc_first_i),
    .pc_second_i(pc_second_i),
    .next_pc_first_i(next_pc_first_i),
    .next_pc_second_i(next_pc_second_i),
    .is_rv_first_i(is_rv_first_i),
    .is_rv_second_i(is_rv_second_i),
    .instruction_first_i(instruction_first_i),
    .instruction_second_i(instruction_second_i),
    .exception_first_i(exception_first_i),
    .exception_second_i(exception_second_i),
    .ecause_first_i(ecause_first_i),
    .ecause_second_i(ecause_second_i),
    .fetch_deco_req_valid_first_i(fetch_deco_req_valid_first_i),
    .fetch_deco_req_valid_second_i(fetch_deco_req_valid_second_i),
    .deco_rob_req_ready_first_i(deco_rob_req_ready_first_i),
    .deco_rob_req_ready_second_i(deco_rob_req_ready_second_i),
    .branch_back_i(branch_back_i),
    .global_trapped_i(global_trapped_i),
    .global_wfi_i(global_wfi_i),
    .fetch_deco_req_ready_o(fetch_deco_req_ready_o), 
    .uses_rs1_first_o(uses_rs1_first_o),
    .uses_rs1_second_o(uses_rs1_second_o),
    .uses_rs2_first_o(uses_rs2_first_o),
    .uses_rs2_second_o(uses_rs2_second_o),
    .uses_rd_first_o(uses_rd_first_o),
    .uses_rd_second_o(uses_rd_second_o),
    .uses_csr_first_o(uses_csr_first_o),
    .uses_csr_second_o(uses_csr_second_o),
    .pc_first_o(pc_first_o),
    .pc_second_o(pc_second_o),
    .next_pc_first_o(next_pc_first_o),
    .next_pc_second_o(next_pc_second_o),
    .rs1_address_first_o(rs1_address_first_o),
    .rs1_address_second_o(rs1_address_second_o),
    .rs2_address_first_o(rs2_address_first_o),
    .rs2_address_second_o(rs2_address_second_o),
    .rd_address_first_o(rd_address_first_o),
    .rd_address_second_o(rd_address_second_o),
    .csr_address_first_o(csr_address_first_o),
    .csr_address_second_o(csr_address_second_o),
    .mret_first_o(mret_first_o),
    .mret_second_o(mret_second_o),
    .sret_first_o(sret_first_o),
    .sret_second_o(sret_second_o),
    .wfi_first_o(wfi_first_o),
    .wfi_second_o(wfi_second_o),
    .ecause_first_o(ecause_first_o),
    .ecause_second_o(ecause_second_o),
    .exception_first_o(exception_first_o),
    .exception_second_o(exception_second_o),
    .half_first_o(half_first_o),
    .half_second_o(half_second_o),
    .is_fence_first_o(is_fence_first_o),
    .is_fence_second_o(is_fence_second_o),
    .fence_op_first_o(fence_op_first_o),
    .fence_op_second_o(fence_op_second_o),
    .is_aext_first_o(is_aext_first_o),
    .is_aext_second_o(is_aext_second_o),
    .is_mext_first_o(is_mext_first_o),
    .is_mext_second_o(is_mext_second_o),
    .deco_rob_req_valid_first_o(deco_rob_req_valid_first_o),
    .deco_rob_req_valid_second_o(deco_rob_req_valid_second_o),
    .csr_read_first_o(csr_read_first_o),
    .csr_read_second_o(csr_read_second_o),
    .csr_write_first_o(csr_write_first_o),
    .csr_write_second_o(csr_write_second_o),
    .imm_data_first_o(imm_data_first_o),
    .imm_data_second_o(imm_data_second_o),
    .fu_function_first_o(fu_function_first_o),
    .fu_function_second_o(fu_function_second_o),
    .alu_function_modifier_first_o(alu_function_modifier_first_o),
    .alu_function_modifier_second_o(alu_function_modifier_second_o),
    .fu_select_a_first_o(fu_select_a_first_o),
    .fu_select_a_second_o(fu_select_a_second_o),
    .fu_select_b_first_o(fu_select_b_first_o),
    .fu_select_b_second_o(fu_select_b_second_o),
    .jump_first_o(jump_first_o),
    .jump_second_o(jump_second_o),
    .branch_first_o(branch_first_o),
    .branch_second_o(branch_second_o),
    .is_alu_first_o(is_alu_first_o),
    .is_alu_second_o(is_alu_second_o),
    .load_first_o(load_first_o),
    .load_second_o(load_second_o),
    .store_first_o(store_first_o),
    .store_second_o(store_second_o),
    .ldu_op_first_o(ldu_op_first_o),
    .ldu_op_second_o(ldu_op_second_o),
    .stu_op_first_o(stu_op_first_o),
    .stu_op_second_o(stu_op_second_o),
    .aq_first_o(aq_first_o),
    .aq_second_o(aq_second_o),
    .rl_first_o(rl_first_o),
    .rl_second_o(rl_second_o)
);

initial begin
    int dumpon = 0;
    string log;
    string wav;
    $value$plusargs("dumpon=%d",dumpon);
    if ($value$plusargs("sim_log=%s",log)) begin
        $display("!!!!!!!!!!wave_log= %s",log);
    end
    wav = {log,"/waves.fsdb"};
    $display("!!!!!!wave_log= %s",wav);
    if(dumpon > 0) begin
      $fsdbDumpfile(wav);
      $fsdbDumpvars(0,tb_top);
      $fsdbDumpvars("+struct");
      $fsdbDumpvars("+mda");
      $fsdbDumpvars("+all");
      $fsdbDumpon;
    end
end

endmodule : tb_top
