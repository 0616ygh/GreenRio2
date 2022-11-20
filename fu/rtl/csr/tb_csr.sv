module tb_top;

reg clk;
reg rst;

reg write_enable;

wire [4: 0] cnt_addr;
wire [4: 0] cnt_trap;

reg [CSR_ADDR_LEN - 1: 0] addr_w;
reg [CSR_ADDR_LEN - 1: 0] addr_r;
reg [XLEN - 1: 0] data_write;

reg excp_pending;
reg [EXCEPTION_CAUSE_WIDTH - 1: 0] excp_cause;
reg [PC_WIDTH - 1: 0] excp_pc;

reg mret;
reg sret;

reg [XLEN - 1: 0] data_readed;
reg writeable;
reg readable;
reg read_flag;

reg [PC_WIDTH - 1: 0] ecp_fetch;
reg [1: 0] mode;
reg tsr;

// For MMU
logic [XLEN - 1: 0] mstatus;
logic [XLEN - 1: 0] satp;

//from rcu
// logic [ROB_INDEX_WIDTH-1:0] rob_index_i,
// logic [PHY_REG_ADDR_WIDTH-1:0] prd_addr_i,
logic [2:0] func3;
logic [XLEN-1:0] rs1_data;
logic [IMM_LEN-1:0] imm_data;
logic [CSR_ADDR_LEN-1:0] csr_addr_i;
logic csr_read;
logic csr_write;
    
//hand shake
logic rcu_csr_req_valid_i;

//rcu wrb
logic csr_rcu_resp_valid_o;
logic [ROB_INDEX_WIDTH-1:0] csr_rcu_wrb_rob_index_o;
logic [PHY_REG_ADDR_WIDTH-1:0] csr_rcu_wrb_addr_o;
logic [XLEN-1:0] csr_rcu_wrb_data_o;
logic csr_exception_o;
logic [EXCEPTION_CAUSE_WIDTH-1:0] csr_ecause_o;

//pmp
logic pmp_cfg_vld_o;
logic [PMPCFG_ID_WIDTH-1:0] pmp_cfg_addr_o;
logic [XLEN-1:0] pmp_cfg_payload_o;
logic  [XLEN-1:0] pmp_cfg_origin_payload_i;
logic addr_vld_o;
logic [PMPADDR_ID_WIDTH-1:0] addr_addr_o;
logic [XLEN-1:0] addr_payload_o;
logic  [XLEN-1:0] addr_origin_payload_i;

logic pmpcfg_t;
logic [2:0]pmpcfg_cnt;
logic pmpaddr_t;
logic [5:0]pmpaddr_cnt;

int addresses [24] = '{
    12'h300, 12'h301, 12'h302, 12'h303, 12'h304, 12'h305,
    12'h340, 12'h341, 12'h342, 12'h343, 12'h344,
    12'h100, 12'h104, 12'h105,
    12'h140, 12'h141, 12'h142, 12'h143, 12'h144,
    12'h180,
    12'hf11, 12'hf12, 12'hf13, 12'hf14
};

int traps [20] = '{
    5'b10001, 5'b10011, 5'b10101, 5'b10111, 5'b11001, 5'b11010,
    5'b00000, 5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101, 5'b00110,
    5'b00111, 5'b01000, 5'b01001, 5'b01011, 5'b01100, 5'b01101, 5'b01111
};

int pmpcfgs[8] = '{
    12'h3a0, 12'h3a2, 12'h3a4, 12'h3a6,
    12'h3a8, 12'h3aa, 12'h3ac, 12'h3ae
};

int pmpaddrs[64] = '{
    12'h3b0, 12'h3b1, 12'h3b2, 12'h3b3, 12'h3b4, 12'h3b5, 12'h3b6, 12'h3b7,
    12'h3b8, 12'h3b9, 12'h3ba, 12'h3bb, 12'h3bc, 12'h3bd, 12'h3be, 12'h3bf,
    12'h3c0, 12'h3c1, 12'h3c2, 12'h3c3, 12'h3c4, 12'h3c5, 12'h3c6, 12'h3c7,
    12'h3c8, 12'h3c9, 12'h3ca, 12'h3cb, 12'h3cc, 12'h3cd, 12'h3ce, 12'h3cf,
    12'h3d0, 12'h3d1, 12'h3d2, 12'h3d3, 12'h3d4, 12'h3d5, 12'h3d6, 12'h3d7,
    12'h3d8, 12'h3d9, 12'h3da, 12'h3db, 12'h3dc, 12'h3dd, 12'h3de, 12'h3df,
    12'h3e0, 12'h3e1, 12'h3e2, 12'h3e3, 12'h3e4, 12'h3e5, 12'h3e6, 12'h3e7,
    12'h3e8, 12'h3e9, 12'h3ea, 12'h3eb, 12'h3ec, 12'h3ed, 12'h3ee, 12'h3ef
};

initial begin
    clk = 0;
    rst = 1;
    read_flag = 0;
    // #40
    // // Try to write 64bit 1, test field defination
    // write_enable = 1;
    // rst = 0;
    // #1000
    // @(posedge clk)
    // write_enable = 0;
    // read_flag = 1;
    // @(posedge clk)
    // read_flag = 0;
    // #2000
    // rst = 1;
    #40
    /**
     * rst = 0;
     * @(negedge clk)
     * write_enable = 1;
     * addr = 12'h300;
     * data = 36'b1010_0000_0000_0000_0000_0001_1000_0000_1010;
     * @(negedge clk)
     * write_enable = 0;
     * @(negedge clk)
     * write_enable = 1;
     * addr = 12'h304;
     * data = 12'b1010_1010_0010;
     * @(negedge clk)
     * write_enable = 0;
     * trap_en = 1;
     * excp_pending = 1;
     * excp_cause = 5'b11011;
     * @(negedge clk)
     * trap_en = 0;
     * excp_pending = 0;
     * @(negedge clk)
     * mret = 1;
     * @(negedge clk)
     * mret = 0;
     * #1000
     */
    rst = 0;
    @(negedge clk)
    rcu_csr_req_valid_i = 1;
    csr_addr_i = 12'h180; // try SATP
    rs1_data = 64'b1000_1111_0000_1111_0000_1111_0000_1111_0000_1111_0000_1111_0000_1111_0000_1111;
    func3 = 3'b001; // CSRRW
    csr_read = 1;
    csr_write = 1;
    @(negedge clk)
    rcu_csr_req_valid_i = 0;
    csr_read = 0;
    csr_write = 0;
    @(negedge clk)
    rcu_csr_req_valid_i = 1;
    csr_addr_i = 12'h300; // set mpp in mstatus
    rs1_data = 64'b1_0000_0000_0000; // set MPP = S
    func3 = 3'b011; // CSRRC
    csr_read = 1;
    csr_write = 1;
    @(negedge clk)
    rcu_csr_req_valid_i = 0;
    csr_read = 0;
    csr_write = 0;
    @(negedge clk)
    rcu_csr_req_valid_i = 1;
    csr_addr_i = 12'h300; // set mie in mstatus
    rs1_data = 64'b1000_1000; // set MIE = 1
    func3 = 3'b010; // CSRRS
    csr_read = 1;
    csr_write = 1;
    @(negedge clk)
    rcu_csr_req_valid_i = 0;
    csr_read = 0;
    csr_write = 0;
    @(negedge clk)
    rcu_csr_req_valid_i = 1;
    csr_addr_i = 12'h341; // set mepc
    rs1_data = 32'b1011_0101_0011_1010_0101_0001_1110_0100;
    func3 = 3'b010; // CSRRS
    csr_read = 1;
    csr_write = 1;
    @(negedge clk)
    rcu_csr_req_valid_i = 0;
    csr_read = 0;
    csr_write = 0;
    @(negedge clk)
    mret = 1;
    @(negedge clk)
    mret = 0;
    @(negedge clk)
    rcu_csr_req_valid_i = 1;
    csr_addr_i = 12'h141; // set sepc
    imm_data = 5'b10101;
    func3 = 3'b110; // CSRRSI
    csr_read = 1;
    csr_write = 1;
    @(negedge clk)
    rcu_csr_req_valid_i = 0;
    csr_read = 0;
    csr_write = 0;
    @(negedge clk)
    rcu_csr_req_valid_i = 1;
    csr_addr_i = 12'h100; // set spp in sstatus
    rs1_data = 64'b1_0000_0000; // set SPP = U
    func3 = 3'b011; // CSRRC
    csr_read = 1;
    csr_write = 1;
    @(negedge clk)
    rcu_csr_req_valid_i = 0;
    csr_read = 0;
    csr_write = 0;
    sret = 1;
    @(negedge clk)
    sret = 0;
    @(negedge clk)
    excp_pending = 1;
    excp_cause = 5'b10101;
    excp_pc = 32'b1011_0101_0011_1010_0101_0001_1110_0101;
    @(negedge clk)
    excp_pending = 0;
    #200
    @(negedge clk)
    mret = 1;
    @(negedge clk)
    mret = 0;
    @(negedge clk)
    rcu_csr_req_valid_i = 1;
    csr_addr_i = 12'h303; // set mideleg
    rs1_data = 12'b0010_0010_0000; // set Supervisor Timer/External Interrupt deleg to S mode
    func3 = 3'b010; // CSRRS
    csr_read = 1;
    csr_write = 1;
    @(negedge clk)
    rcu_csr_req_valid_i = 0;
    csr_read = 0;
    csr_write = 0;
    @(negedge clk)
    rcu_csr_req_valid_i = 1;
    csr_addr_i = 12'h100; // set SIE
    rs1_data = 64'b10_0010; // set SIE & SPIE = 1
    func3 = 3'b010; // CSRRS
    csr_read = 1;
    csr_write = 1;
    @(negedge clk)
    rcu_csr_req_valid_i = 0;
    csr_read = 0;
    csr_write = 0;
    @(negedge clk)
    excp_pending = 1;
    excp_cause = 5'b10101;
    excp_pc = 32'b1011_0101_0011_1010_0101_0001_1010_0101;
    @(negedge clk)
    excp_pending = 0;
    #200
    @(negedge clk)
    sret = 1;
    @(negedge clk)
    sret = 0;
    @(negedge clk)
    rcu_csr_req_valid_i = 1;
    func3 = 3'b010; // CSRRS
    csr_addr_i = 12'h3a6;
    csr_read = 1;
    csr_write = 0;
    pmp_cfg_origin_payload_i = 64'h0123_4567_89ab_cdef;
    addr_origin_payload_i = 64'hcdef_89ab_4567_0123;
    @(negedge clk)
    pmpaddr_t = 0;
    pmpcfg_t = 1;
    #2000
    @(negedge clk)
    pmpcfg_t = 0;
    pmpaddr_t = 1;
    #2000
    $finish;
end

always #10 clk = ~clk;

always @(posedge clk) begin
    if (rst) begin
        excp_pending <= 0;
        excp_cause <= 0;
        excp_pc <= 0;
        mret <= 0;
        sret <= 0;
        pmpcfg_t = 0;
        pmpaddr_t = 0;
    end else begin
        if (pmpcfg_t) begin
            csr_addr_i = pmpcfgs[pmpcfg_cnt];
            rcu_csr_req_valid_i = !rcu_csr_req_valid_i;
        end
        else if (pmpaddr_t) begin
            csr_addr_i = pmpaddrs[pmpaddr_cnt];
            rcu_csr_req_valid_i = !rcu_csr_req_valid_i;
        end
    end
end

counter#(
    .CNT_SIZE(24),
    .CNT_SIZE_WIDTH(5)
) address_cnt_u (
    .clk(clk),
    .rst(rst | read_flag),
    .cnt_add_flag_i(1'b1),
    .cnt_rst_vector_i (5'b00000),
    .cnt_o(cnt_addr),
    .cnt_end_o()
);

counter#(
    .CNT_SIZE(20),
    .CNT_SIZE_WIDTH(5)
) trap_cnt_u (
    .clk(clk),
    .rst(rst),
    .cnt_add_flag_i(!excp_pending),
    .cnt_rst_vector_i(5'b00000),
    .cnt_o(cnt_trap),
    .cnt_end_o()
);

counter#(
    .CNT_SIZE(8),
    .CNT_SIZE_WIDTH(3)
) pmpcfg_cnt_u (
    .clk(clk),
    .rst(rst),
    .cnt_add_flag_i(pmpcfg_t),
    .cnt_rst_vector_i(3'b000),
    .cnt_o(pmpcfg_cnt),
    .cnt_end_o()
);

counter#(
    .CNT_SIZE(64),
    .CNT_SIZE_WIDTH(6)
) pmpaddr_cnt_u (
    .clk(clk),
    .rst(rst),
    .cnt_add_flag_i(pmpaddr_t),
    .cnt_rst_vector_i(6'b000000),
    .cnt_o(pmpaddr_cnt),
    .cnt_end_o()
);

csr_regfile csr_regfile(
    .clk(clk),
    .rst(rst),
    .csr_w_i(write_enable),
    .csr_addr_w_i(addr_w),
    .csr_addr_r_i(addr_r),
    .csr_data_w_i(data_write),
    .excp_pending_i(excp_pending),
    .excp_cause_i(excp_cause),
    .excp_pc_i(excp_pc),
    .m_ret_i(mret),
    .s_ret_i(sret),
    .csr_data_r_o(data_readed),
    .readable_o(readable),
    .writeable_o(writeable),
    .excp_pc_o(ecp_fetch),
    .current_mode_o(mode),
    .tsr_o(tsr),
    .mstatus_o(mstatus),
    .satp_o(satp)
);

csr csr_u(
    .clk(clk),
    .rst(rst),

    .rob_index_i(0),
    .prd_addr_i(0),
    .func3_i(func3),
    .prs1_data_i(rs1_data),
    .imm_i(imm_data),
    .csr_addr_i(csr_addr_i),
    .csr_do_read_i(csr_read),
    .csr_do_write_i(csr_write),

    .rcu_csr_req_valid_i(rcu_csr_req_valid_i),

    .csr_raddr_o(addr_r),
    .csr_rdata_i(data_readed),
    .csr_readable_i(readable),
    .csr_writable_i(writeable),

    .csr_waddr_o(addr_w),
    .do_csr_write_o(write_enable),
    .csr_wrdata_o(data_write),

    .csr_rcu_resp_valid_o(),
    .csr_rcu_wrb_rob_index_o(),
    .csr_rcu_wrb_addr_o(),
    .csr_rcu_wrb_data_o(),
    .csr_exception_o(csr_exception_o),
    .csr_ecause_o(csr_ecause_o),

    .pmp_cfg_vld_o(pmp_cfg_vld_o),
    .pmp_cfg_addr_o(pmp_cfg_addr_o),
    .pmp_cfg_payload_o(pmp_cfg_payload_o),
    .pmp_cfg_origin_payload_i(pmp_cfg_origin_payload_i),
    .pmp_addr_vld_o(addr_vld_o),
    .pmp_addr_addr_o(addr_addr_o),
    .pmp_addr_payload_o(addr_payload_o),
    .pmp_addr_origin_payload_i(addr_origin_payload_i)
);

initial begin
    int dumpon = 0;
    string log;
    string wav;
    $value$plusargs("dumpon=%d",dumpon);
    if ($value$plusargs("sim_log=%s",log)) begin
        $display("wave_log= %s",log);
    end
    wav = {log,"/waves.fsdb"};
    $display("wave_log= %s",wav);
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
