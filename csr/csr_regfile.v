`ifdef VERILATOR
`include "params.vh"
`endif

module csr_regfile (
    input wire clk,
    input wire rst,

    input wire do_rob_commit_first,
    input wire do_rob_commit_second,
    // read / write
    input wire csr_w_i, // write enable
    input wire [CSR_ADDR_LEN - 1: 0] csr_addr_w_i, // write address
    input wire [CSR_ADDR_LEN - 1: 0] csr_addr_r_i, // read address
    input wire [XLEN - 1: 0] csr_data_w_i, // write data

    // exception
    input wire excp_pending_i,
    input wire [EXCEPTION_CAUSE_WIDTH - 1: 0] excp_cause_i,
    input wire [PC_WIDTH - 1: 0] excp_pc_i,

    // xRET inst
    input wire m_ret_i,
    input wire s_ret_i,

    // to csru
    output reg [XLEN - 1: 0] csr_data_r_o,
    output reg readable_o,
    output reg writeable_o,

    // to fetch
    output reg [PC_WIDTH - 1: 0] excp_pc_o,

    // to decode
    output reg [1: 0] current_mode_o,
    output wire tsr_o,
    output wire tvm_o,
    output wire tw_o,

    // to mmu
    output wire [XLEN - 1: 0] mstatus_o,
    output wire [XLEN - 1: 0] satp_o,

    // to exception ctrl
    output interrupt_o
);

`ifndef DEBUGING
reg [1: 0] misa_mxl = 2'b10; // MXL = 64
reg [1: 0] next_mode;

reg [XLEN-1:0] mcycle;
reg [XLEN-1:0] minstret;

// Extensions: Z, Y, X, W, V, U, T, S, R, Q, R, O, N, M, L, K, J, I, H, G, F, E, D, C, B, A
reg [25: 0] misa_ext = 26'b00000101000001000100000101;

/** fields in xstatus regs */
reg status_sie;
reg status_mie;
reg status_spie;
reg status_mpie;
reg status_spp;
reg [1: 0] status_mpp;

reg [1: 0] status_vs = 2'b00; // no V extension
reg [1: 0] status_fs = 2'b00; // no F extension
reg [1: 0] status_xs = 2'b00; // no additional user extensions
reg status_sd = 1'b0; // FS, VS, XS are all read-only zero

reg status_mprv; // enable translation when set
reg status_sum; // Enable access to U-Mode memory in S-Mode
reg status_mxr; // enable loads from readable & exe-able;

reg status_tvm; // TVM=0 to permit SFENCE & satp operation in S-Mode
reg status_tw; // TW=0 to permit WFI in any lower priv mode
reg status_tsr;

reg [1: 0] status_uxl = 2'b10; // XL = 64
reg [1: 0] status_sxl = 2'b10; // XL = 64
reg status_sbe = 1'b0; // little endian memory access
reg status_mbe = 1'b0; // little endian memory access
reg status_ube = 1'b0; // little endian memory access

/** fields in mie/sie regs */
reg meie;
reg seie;
reg mtie;
reg stie;
reg ssie;

/** fields in mip/sip regs */
reg m_ext_int;
reg s_ext_int;
reg m_timer_int;
reg s_timer_int;
reg m_soft_int;
reg s_soft_int;
reg s_soft_int_ex;
reg s_timer_int_ex;
reg s_ext_int_ex;

wire interrupt_ex = status_mie & ((seie & s_ext_int_ex) | (stie & s_timer_int_ex) | (ssie & s_soft_int_ex));

reg [EXCEPTION_CAUSE_WIDTH-1:0] dff_ecause;
reg dff_interrupt;
reg dff_excp_pending;

reg mcause_interrupt;
reg [EXCEPTION_CAUSE_WIDTH - 2: 0] mcause_code;

reg scause_interrupt;
reg [EXCEPTION_CAUSE_WIDTH - 2: 0] scause_code;

reg [XLEN - 1: 0] mtvec;
reg [XLEN - 1: 0] stvec;
reg [XLEN - 1: 0] mscratch;
reg [XLEN - 1: 0] sscratch;
reg [PC_WIDTH - 1: 0] mepc;
reg [PC_WIDTH - 1: 0] sepc;
reg [XLEN - 1: 0] mtval;
reg [XLEN - 1: 0] stval;

reg [15: 0] medeleg; // only 16 bits for 16 exceptions
reg [11: 0] mideleg; // only 12 bits for 12 interrupts

reg [XLEN - 1: 0] satp;

wire [XLEN - 1: 0] misa;
wire [XLEN - 1: 0] mcause;
wire [XLEN - 1: 0] mstatus;
wire [XLEN - 1: 0] mip;
wire [XLEN - 1: 0] mip_ex;
wire [XLEN - 1: 0] mie;
wire [XLEN - 1: 0] medeleg_w;
wire [XLEN - 1: 0] mideleg_w;

wire [XLEN - 1: 0] scause;
wire [XLEN - 1: 0] sstatus;
wire [XLEN - 1: 0] sip;
wire [XLEN - 1: 0] sip_ex;
wire [XLEN - 1: 0] sie;

reg [XLEN - 1: 0] tvec_out;

assign tsr_o = status_tsr;
assign tvm_o = status_tvm;
assign tw_o = status_tw;
assign mstatus_o = mstatus;
assign satp_o = satp;

always @(*)
begin: validata_address
    casez (csr_addr_r_i)
        12'hc00, 12'hc01:
        begin // cycle, time
            readable_o = 1;
            writeable_o = 0;
        end
        12'hc02:
        begin // instret
            readable_o = 1;
            writeable_o = 0;
        end
        12'hc03, 12'hc04, 12'hc05, 12'hc06, 12'hc07,
        12'hc08, 12'hc09, 12'hc0a, 12'hc0b, 12'hc0c,
        12'hc0d, 12'hc0e, 12'hc0f, 12'hc1? :
        begin // hpmcounterX
            readable_o = 1;
            writeable_o = 0;
        end
        12'h100, 12'h104, 12'h105, 12'h106:
        begin
            // Supervisor Trap Setup (sstatus, sie, stvec, scounteren)
            readable_o = 1;
            writeable_o = 1;
        end
        12'h10A:
        begin
            // Supervisor Configure (senvcfg)
            readable_o = 1;
            writeable_o = 1;
        end
        12'h140, 12'h141, 12'h142, 12'h143, 12'h144:
        begin
            // Supervisor Trap Handling (sscratch, sepc, scause, stval, sip)
            readable_o = 1;
            writeable_o = 1;
        end
        12'h180:
        begin // Supervisor Protection and Translation (satp)
            readable_o = 1;
            writeable_o = 1;
        end
        12'h5a8:
        begin // scontext, Debug Mode
            readable_o = 1;
            writeable_o = 1;
        end
        12'hf11, 12'hf12, 12'hf13, 12'hf14, 12'hf15:
        begin // mvendorid, marchid, mimpid, mhartid, mconfigptr
            readable_o = 1;
            writeable_o = 0;
        end
        12'h300, 12'h301, 12'h302, 12'h303, 12'h304, 12'h305, 12'h306:
        begin
            // mstatus, misa, medeleg, mideleg, mie, mtvec, mcounteren
            readable_o = 1;
            writeable_o = 1;
        end
        12'h340, 12'h341, 12'h342, 12'h343, 12'h344, 12'h34A, 12'h34B:
        begin
            // mscratch, mepc, mcause, mtval, mip, mtinst, mtval2
            readable_o = 1;
            writeable_o = 1;
        end
        12'h30A:
        begin // menvcfg
            readable_o = 1;
            writeable_o = 1;
        end
        12'h747:
        begin // mseccfg
            readable_o = 1;
            writeable_o = 1;
        end
        12'h3A0, 12'h3A2, 12'h3A4, 12'h3A6,
        12'h3A8,12'h3AA, 12'h3AC, 12'h3AE:
        begin
            // pmpcfg0, 2, ..., 14
            readable_o = 1;
            writeable_o = 1;
        end
        12'h3B? , 12'h3C? , 12'h3D? , 12'h3E? :
        begin
            // pmpaddr0 ... pmpaddr63
            readable_o = 1;
            writeable_o = 1;
        end
        12'h7a0, 12'h7a1, 12'h7a2, 12'h7a3, 12'h7a8:
        begin // Debug, Trace: tselect, tdata*, mcontext
            readable_o = 1;
            writeable_o = 1;
        end
        12'h7b0, 12'h7b1, 12'h7b2, 12'h7b3:
        begin // Debug: dcsr, dpc, dstratch*
            readable_o = 1;
            writeable_o = 1;
        end
        12'hb00, 12'hb01:
        begin // mcycle, mtime
            readable_o = 1;
            writeable_o = 1;
        end
        12'hb02:
        begin // minstret
            readable_o = 1;
            writeable_o = 1;
        end
        12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07,
        12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c,
        12'hb0d, 12'hb0e, 12'hb0f, 12'hb1? :
        begin // mhpmcounterX
            readable_o = 1;
            writeable_o = 1;
        end
        12'h320,  // mcountinhibit
        12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 
        12'h328, 12'h329, 12'h32A, 12'h32B,
        12'h32C, 12'h32D, 12'h32E, 12'h32F, 12'h33? :
        begin // mhpmeventX
            readable_o = 1;
            writeable_o = 1;
        end
        default:
        begin
            readable_o = 0;
            writeable_o = 0;
        end
    endcase
end

//! assign value to csr_data as output according to csr_address_r
always @(*)
begin: assign_csr_output
    case (csr_addr_r_i)
        12'h301: // misa
            csr_data_r_o = misa;
        12'hf11: // mvendorid, unimplemented
            csr_data_r_o = 0;
        12'hf12: // marchid, unimplemented
            csr_data_r_o = 0;
        12'hf13: // mimpid, unimplemented
            csr_data_r_o = 0;
        12'hf14: // mhartid, fixed0
            csr_data_r_o = {XLEN{1'b0}};
        12'h300: // mstatus
            csr_data_r_o = mstatus;
        12'h302: // medeleg
            csr_data_r_o = medeleg_w;
        12'h303: // mideleg
            csr_data_r_o = mideleg_w;
        12'h304: // mie
            csr_data_r_o = mie;
        12'h305: // mtvec
            csr_data_r_o = mtvec;
        12'h340: // mscratch
            csr_data_r_o = mscratch;
        12'h341: // mepc
            csr_data_r_o = {mepc[PC_WIDTH - 1: 1], 1'b0};
        12'h342: // mcause
            csr_data_r_o = mcause;
        12'h343: // mtval
            csr_data_r_o = mtval;
        12'h344: // mip
            csr_data_r_o = mip | mip_ex;
        12'h100: // sstatus
            csr_data_r_o = sstatus;
        12'h104: // sie
            csr_data_r_o = sie;
        12'h105: // stvec
            csr_data_r_o = {stvec, 2'b00};
        12'h140: // sscratch
            csr_data_r_o = sscratch;
        12'h141: // sepc
            csr_data_r_o = {sepc[PC_WIDTH - 1: 1], 1'b0};
        12'h142: // scause
            csr_data_r_o = scause;
        12'h143: // stval
            csr_data_r_o = stval;
        12'h144: // sip
            csr_data_r_o = sip | sip_ex;
        12'h180: // satp
            csr_data_r_o = satp;
        12'hb00: // mcycle
            csr_data_r_o = mcycle;
        12'hb02: // minstret
            csr_data_r_o = minstret;
        12'hc00: // cycle
            csr_data_r_o = mcycle;
        default:
            csr_data_r_o = 0;
    endcase
end

assign misa = {misa_mxl,{(XLEN - 28){1'b0}},misa_ext};

assign mstatus = {
    status_sd,
    {25{1'b0}},
    status_mbe,
    status_sbe,
    status_sxl,
    status_uxl,
    {9{1'b0}},
    status_tsr,
    status_tw,
    status_tvm,
    status_mxr,
    status_sum,
    status_mprv,
    status_xs,
    status_fs,
    status_mpp,
    status_vs,
    status_spp,
    status_mpie,
    status_ube,
    status_spie,
    1'b0,
    status_mie,
    1'b0,
    status_sie,
    1'b0
};

assign mip = {
    {52{1'b0}},
    m_ext_int,
    1'b0,
    s_ext_int,
    1'b0,
    m_timer_int,
    1'b0,
    s_timer_int,
    1'b0,
    1'b0, // msip is ro 0 for single-hart
    1'b0,
    s_soft_int,
    1'b0
};

assign mip_ex = {
    {52{1'b0}},
    1'b0,
    1'b0,
    s_soft_int_ex,
    1'b0,
    1'b0,
    1'b0,
    s_timer_int_ex,
    1'b0,
    1'b0, // msip is ro 0 for single-hart
    1'b0,
    s_soft_int_ex,
    1'b0
};

assign mie = {
    {52{1'b0}},
    meie,
    1'b0,
    seie,
    1'b0,
    mtie,
    1'b0,
    stie,
    1'b0,
    1'b0, // msie is ro 0 for single-hart
    1'b0,
    ssie,
    1'b0
};

assign mcause = {
    mcause_interrupt,
    {(64 - EXCEPTION_CAUSE_WIDTH){1'b0}},
    mcause_code
};

assign medeleg_w = {
    {48{1'b0}},
    medeleg
};

assign mideleg_w = {
    {54{1'b0}},
    mideleg
};

assign sstatus = {
    status_sd,
    {29{1'b0}},
    status_uxl,
    {12{12'b0}},
    status_mxr,
    status_sum,
    1'b0,
    status_xs,
    status_fs,
    {2{1'b0}},
    status_vs,
    status_spp,
    1'b0,
    status_ube,
    status_spie,
    {3{1'b0}},
    status_sie,
    1'b0
};

assign sip = {
    {54{1'b0}},
    s_ext_int,
    3'b000,
    s_timer_int,
    3'b000,
    s_soft_int,
    1'b0
};

assign sip_ex = {
    {54{1'b0}},
    s_soft_int_ex,
    3'b000,
    s_timer_int_ex,
    3'b000,
    s_soft_int_ex,
    1'b0
};

assign sie = {
    {54{1'b0}},
    seie,
    3'b000,
    stie,
    3'b000,
    ssie,
    1'b0
};

assign scause = {
    scause_interrupt,
    {(64 - EXCEPTION_CAUSE_WIDTH){1'b0}},
    scause_code
};

//! update inner signals of CSR Register file; if reset, current_mode_o = 3 (Machine Mode)
always @(posedge clk)
begin: update_inner_signals
    if (rst)
    begin
        current_mode_o <= 2'b11;
        status_sie <= 0;
        status_mie <= 0;
        status_spie <= 0;
        status_mpie <= 0;
        status_spp <= 0;
        status_mpp <= 2'b11;
        status_sum <= 0;
        status_mxr <= 0;
        status_tvm <= 0;
        status_tw  <= 0;
        status_mprv <= 0;
        status_tsr <= 0;
        mtvec <= 0;
        mscratch <= 0;
        mepc <= 0;
        mtval <= 0;
        meie <= 0;
        seie <= 0;
        mtie <= 0;
        stie <= 0;
        ssie <= 0;
        m_soft_int <= 0;
        m_timer_int <= 0;
        m_ext_int <= 0;
        s_soft_int <= 0;
        s_timer_int <= 0;
        s_ext_int <= 0;
        s_soft_int_ex  <= 0;
        s_timer_int_ex <= 0;
        s_ext_int_ex   <= 0;
        mcause_interrupt <= 0;
        mcause_code <= 0;
        scause_interrupt <= 0;
        scause_code <= 0;
        medeleg <= 0;
        mideleg <= 0;
        sscratch <= 0;
        stvec <= 0;
        sepc <= 0;
        satp <= 0;
    end
    else
    begin
        current_mode_o <= next_mode;
        if (!excp_pending_i)
        begin
            if (csr_w_i)
            begin
                case (csr_addr_w_i)
                    12'h300: // mstatus
                    begin
                        status_sie  <= csr_data_w_i[1];
                        status_mie  <= csr_data_w_i[3];
                        status_spie <= csr_data_w_i[5];
                        status_mpie <= csr_data_w_i[7];
                        status_spp  <= csr_data_w_i[8];
                        status_mpp  <= csr_data_w_i[12: 11];
                        status_mprv <= csr_data_w_i[17];
                        status_sum  <= csr_data_w_i[18];
                        status_mxr  <= csr_data_w_i[19];
                        status_tvm  <= csr_data_w_i[20];
                        status_tw   <= csr_data_w_i[21];
                        status_tsr  <= csr_data_w_i[22];
                    end
                    12'h305: // mtvec
                        mtvec <= csr_data_w_i;
                    12'h304: // mie
                    begin
                        ssie <= csr_data_w_i[1];
                        stie <= csr_data_w_i[5];
                        mtie <= csr_data_w_i[7];
                        seie <= csr_data_w_i[9];
                        meie <= csr_data_w_i[11];
                    end
                    12'h340: // mscratch
                        mscratch <= csr_data_w_i;
                    12'h341: // mepc
                        mepc <= {csr_data_w_i[PC_WIDTH - 1: 1], 1'b0};
                    12'h342: // mcause
                    begin
                        mcause_code <= csr_data_w_i[EXCEPTION_CAUSE_WIDTH - 2: 0];
                        mcause_interrupt <= csr_data_w_i[XLEN - 1];
                    end
                    12'h343: // mtval
                        mtval <= csr_data_w_i;
                    12'h344: // mip
                    begin
                        s_soft_int_ex  <= csr_data_w_i[1];
                        s_timer_int_ex <= csr_data_w_i[5];
                        s_ext_int_ex   <= csr_data_w_i[9];
                    end
                    12'h302: // medeleg
                        medeleg <= csr_data_w_i[15: 0];
                    12'h303: // mideleg
                        mideleg <= csr_data_w_i[11: 0];
                    12'h100: // sstatus
                    begin
                        status_mxr  <= csr_data_w_i[19];
                        status_sum <= csr_data_w_i[18];
                        status_spp <= csr_data_w_i[8];
                        status_spie <= csr_data_w_i[5];
                        status_sie <= csr_data_w_i[1];
                    end
                    12'h105: // stvec
                        stvec <= csr_data_w_i[XLEN - 1: 2];
                    12'h141: // sepc
                        sepc <= {csr_data_w_i[XLEN - 1: 1], 1'b0};
                    12'h142: // scause
                    begin
                        scause_code <= csr_data_w_i[EXCEPTION_CAUSE_WIDTH - 2: 0];
                        scause_interrupt <= csr_data_w_i[XLEN - 1];
                    end
                    12'h143: // stval
                        stval <= csr_data_w_i;
                    12'h104: // sie
                    begin
                        ssie <= csr_data_w_i[1];
                        stie <= csr_data_w_i[5];
                        seie <= csr_data_w_i[9];
                    end
                    12'h140: // sscratch
                        sscratch <= csr_data_w_i;
                    12'h042: // scause
                    begin
                        mcause_code <= csr_data_w_i[EXCEPTION_CAUSE_WIDTH - 2: 0];
                        mcause_interrupt <= csr_data_w_i[XLEN - 1];
                    end
                    12'h180: // satp
                        satp <= csr_data_w_i[XLEN - 1: 0];
                endcase
            end else if (m_ret_i)
            begin
                status_mie <= status_mpie;
                status_mpie <= 1;
                status_mpp <= 2'b00;
                m_soft_int <= 0;
                m_timer_int <= 0;
                m_ext_int <= 0;
                s_soft_int <= 0;
                s_timer_int <= 0;
                s_ext_int <= 0;
                s_soft_int_ex  <= 0;
                s_timer_int_ex <= 0;
                s_ext_int_ex   <= 0;
            end else if (s_ret_i)
            begin
                status_sie <= status_spie;
                status_spie <= 1;
                status_spp <= 0;
                m_soft_int <= 0;
                m_timer_int <= 0;
                m_ext_int <= 0;
                s_soft_int <= 0;
                s_timer_int <= 0;
                s_ext_int <= 0;
                s_soft_int_ex  <= 0;
                s_timer_int_ex <= 0;
                s_ext_int_ex   <= 0;
            end
        end
        if (excp_pending_i & excp_cause_i[EXCEPTION_CAUSE_WIDTH-1]) begin
            m_soft_int  <= excp_cause_i == 5'b10011;
            m_timer_int <= excp_cause_i == 5'b10111;
            m_ext_int   <= excp_cause_i == 5'b11011;
            s_soft_int  <= excp_cause_i == 5'b10001;
            s_timer_int <= excp_cause_i == 5'b10101;
            s_ext_int   <= excp_cause_i == 5'b11001; // will never happen
        end
        if (interrupt_ex | ((excp_pending_i & (status_mie | ~excp_cause_i[EXCEPTION_CAUSE_WIDTH-1]) && (next_mode == 2'b11)) && !m_ret_i)) begin
            mepc <= {excp_pc_i[PC_WIDTH - 1: 1], 1'b0};
            status_mie <= 0;
            status_mpie <= status_mie;
            status_mpp <= current_mode_o;
            mcause_interrupt <= interrupt_ex ? 1'b0 : excp_cause_i[EXCEPTION_CAUSE_WIDTH - 1];
            mcause_code <= interrupt_ex ? dff_ecause : excp_cause_i[EXCEPTION_CAUSE_WIDTH - 2: 0];
            if (!excp_cause_i[EXCEPTION_CAUSE_WIDTH - 1])
                case (excp_cause_i[EXCEPTION_CAUSE_WIDTH - 2: 0])
                    4'b0000:
                        mtval <= 0;
                    4'b0010:
                        mtval <= 0;
                    default:
                        mtval <= 0;
                endcase
            else
                mtval <= 0;
        end 
        else if ((excp_pending_i & (status_sie | ~excp_cause_i[EXCEPTION_CAUSE_WIDTH-1]) && (next_mode == 2'b01)) && !s_ret_i) begin
            sepc <= {excp_pc_i[PC_WIDTH - 1: 1], 1'b0}; //if instr is c extension, [PC_WIDTH - 1:1]
            status_sie <= 0;
            status_spie <= status_sie;
            status_spp <= current_mode_o[0];
            scause_interrupt <= excp_cause_i[EXCEPTION_CAUSE_WIDTH - 1];
            scause_code <= excp_cause_i[EXCEPTION_CAUSE_WIDTH - 2: 0];
            if (!excp_cause_i[EXCEPTION_CAUSE_WIDTH - 1])
                case (excp_cause_i[EXCEPTION_CAUSE_WIDTH - 2: 0])
                    4'b0000:
                        stval <= 0;
                    4'b0010:
                        stval <= 0;
                    default:
                        stval <= 0;
                endcase
            else
                stval <= 0;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        dff_interrupt <= 0;
    end else begin
        dff_interrupt <= status_mie & ((seie & s_ext_int_ex) | (stie & s_timer_int_ex) | (ssie & s_soft_int_ex));
    end
end

always @(*) begin
    if (interrupt_ex) begin
        if (s_soft_int) begin
            dff_ecause = INTERRUPT_SOFTWARE_SUPERVISOR;
        end else if (s_timer_int) begin
            dff_ecause = INTERRUPT_TIMER_SUPERVISOR;
        end else if (s_ext_int) begin
            dff_ecause = 5'h19;
        end
    end else begin
        dff_ecause = 0;
    end
end

assign interrupt_o = dff_interrupt;
//! assign values to output ports
always @(*) begin: assign_output_ports
    next_mode = current_mode_o;
    if (excp_pending_i) begin
        if (excp_cause_i[EXCEPTION_CAUSE_WIDTH - 1]) // Determine if interrupt
        begin
        if (mideleg[excp_cause_i[EXCEPTION_CAUSE_WIDTH - 2: 0]])
            next_mode = 2'b01;
        else
            next_mode = 2'b11;
        end
        else
        begin
            if (medeleg[excp_cause_i[EXCEPTION_CAUSE_WIDTH - 2: 0]])
                next_mode = 2'b01;
            else
                next_mode = 2'b11;
        end
    end else if (m_ret_i)
        next_mode = status_mpp;
    else if (s_ret_i)
        next_mode = {1'b0, status_spp};
    else if ((status_mie & (|(mie & mip)))) begin // only permitted in m mode
        next_mode = 2'b11;
    end else
        next_mode = current_mode_o;
end

always @(*)
begin: init_tvec
    if (next_mode == 2'b11) begin
        if (dff_interrupt | (status_mie & |(mie & mip)) | excp_pending_i & excp_cause_i[EXCEPTION_CAUSE_WIDTH-1] & mtvec[0]) begin
            tvec_out = {mtvec[XLEN-1:2], 2'b00} + {57'b0,excp_cause_i[EXCEPTION_CAUSE_WIDTH-2:0],3'b100};
        end else begin
            tvec_out = {mtvec[XLEN-1:2], 2'b00};
        end
    end else if (next_mode == 2'b01) begin
        if ((status_sie & |(sie & sip)) | excp_pending_i & excp_cause_i[EXCEPTION_CAUSE_WIDTH-1] & stvec[0]) begin
            tvec_out = {stvec[XLEN-1:2], 2'b00} + {57'b0,excp_cause_i[EXCEPTION_CAUSE_WIDTH-2:0],3'b100};
        end else begin
            tvec_out = {stvec[XLEN-1:2], 2'b00};
        end
    end
end

always @(*)
begin: trap_return
    case ({m_ret_i & !excp_pending_i, s_ret_i & !excp_pending_i})
        2'b00:
            excp_pc_o = tvec_out;
        2'b10:
            excp_pc_o = mepc;
        2'b01:
            excp_pc_o = sepc;
        default:
            excp_pc_o = tvec_out;
    endcase
end


// mcycle
always @(posedge clk) begin
    if (rst) begin
        mcycle <= 0;
    end else if (csr_addr_w_i == 12'hB00 & csr_w_i) begin
        mcycle <= csr_data_w_i;
    end else begin
        mcycle <= mcycle + 1;
    end
end

// minstret
always @(posedge clk) begin
    if (rst) begin
        minstret <= 0;
    end else if (do_rob_commit_first & do_rob_commit_second) begin
        minstret <= minstret + 2;
    end else if (do_rob_commit_first | do_rob_commit_first) begin
        minstret <= minstret + 1;
    end else begin
        minstret <= minstret;
    end
end

`endif
endmodule
