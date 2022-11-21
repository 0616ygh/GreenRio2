`ifndef __RVH_L1D_PKG_SV__
`define __RVH_L1D_PKG_SV__
`ifdef USE_VERILATOR
`include "rvh_pkg.sv"
`include "uop_encoding_pkg.sv"
`endif //USE_VERILATOR
package rvh_l1d_pkg;
   localparam int unsigned MAJOR_OP_WIDTH = 3;
    
    
    localparam int unsigned MINOR_OP_WIDTH = 5;

    localparam int unsigned ALU_OP_WIDTH = 4;
    localparam int unsigned MUL_OP_WIDTH = 3;
    localparam int unsigned DIV_OP_WIDTH = 3;
    localparam int unsigned BRU_OP_WIDTH = 3;
    
    localparam int unsigned INT_OP_WIDTH = 4;
    
    localparam int unsigned CSR_OP_WIDTH = 4;
    
    localparam int unsigned LDU_OP_WIDTH = 3;
    localparam int unsigned STU_OP_WIDTH = 5;
    localparam int unsigned LSU_OP_WIDTH = STU_OP_WIDTH > LDU_OP_WIDTH ? STU_OP_WIDTH : LDU_OP_WIDTH;    

    typedef enum logic [2:0] {
        NONE,
        IIMM,
        SIMM,
        SBIMM,
        UIMM,
        UJIMM
    } imm_type_t;


    typedef enum logic [MAJOR_OP_WIDTH-1:0] {
        OP_ALU,
        OP_MUL,
        OP_DIV,
        OP_BRU,
        OP_CSR,
        OP_LDU,
        OP_STU,
        OP_FPU
    } major_op_t;

    typedef enum logic [ALU_OP_WIDTH-1:0] {
        ALU_ADD,
        ALU_SUB,
        ALU_SLL,
        ALU_SLT,
        ALU_SLTU,
        ALU_XOR,
        ALU_SRL,
        ALU_SRA,
        ALU_OR,
        ALU_AND,
        // RV64 Only
        ALU_ADDW,
        ALU_SUBW,
        ALU_SLLW,
        ALU_SRLW,
        ALU_SRAW
    } alu_minor_op_t;

    typedef enum logic [MUL_OP_WIDTH-1:0] {
        MUL_MUL,
        MUL_MULH,
        MUL_MULHSU,
        MUL_MULHU,
        // RV64 Only
        MUL_MULW
    } mul_minor_op_t;

    typedef enum logic [DIV_OP_WIDTH-1:0] {
        DIV_DIV,
        DIV_DIVU,
        DIV_REM,
        DIV_REMU,
        // RV64 Only
        DIV_DIVW,
        DIV_DIVUW,
        DIV_REMW,
        DIV_REMUW
    } div_minor_op_t;

    typedef enum logic [BRU_OP_WIDTH-1:0] {
        BRU_JAL,
        BRU_JALR,
        BRU_BEQ,
        BRU_BNE,
        BRU_BLT,
        BRU_BGE,
        BRU_BLTU,
        BRU_BGEU
    } bru_minor_op_t;

    typedef enum logic [CSR_OP_WIDTH-1:0] {
        CSR_CSRRW,
        CSR_CSRRS,
        CSR_CSRRC,
        CSR_CSRR,
        CSR_MRET,
        CSR_SRET,
        CSR_DRET,
        CSR_WFI,
        CSR_FENCEI,
        CSR_SFENCE_VMA
    } csr_minor_op_t;

    typedef enum logic [LDU_OP_WIDTH-1:0] {
        LDU_LB,
        LDU_LH,
        LDU_LW,
        LDU_LBU,
        LDU_LHU,
        LDU_LWU,
        // RV64 Only
        LDU_LD
    } ldu_minor_op_t;

    typedef enum logic [STU_OP_WIDTH-1:0] {
        STU_SB,
        STU_SH,
        STU_SW,
        // RV64 Only
        STU_SD,
        STU_FENCE,
        STU_SFENCE_VMA,
        STU_FENCE_I,

        STU_LRW     ,
        STU_LRD     ,
        STU_SCW     ,
        STU_SCD     ,
        STU_AMOSWAPW,
        STU_AMOSWAPD,
        STU_AMOADDW ,
        STU_AMOADDD ,
        STU_AMOANDW ,
        STU_AMOANDD ,
        STU_AMOORW  ,
        STU_AMOORD  ,
        STU_AMOXORW ,
        STU_AMOXORD ,
        STU_AMOMAXW ,
        STU_AMOMAXD ,
        STU_AMOMAXUW,
        STU_AMOMAXUD,
        STU_AMOMINW ,
        STU_AMOMIND ,
        STU_AMOMINUW,
        STU_AMOMINUD
    } stu_minor_op_t;
    
    /* ------ RCU Configuration ------ */
    localparam int unsigned XLEN = 64;
    localparam int unsigned VADDR_WIDTH = 39; // IMPORT FROM HEHE2
    localparam int unsigned PADDR_WIDTH = 56; // IMPORT FROM HEHE2
    localparam int unsigned BASE_ADDR = 39'h80000000;

    // Fetch & BPU 
    localparam int unsigned FETCH_WIDTH = 128;
    localparam int unsigned PREDS_PER_LINE = 8;
    localparam int unsigned BLKS_FOR_SEL = 8;
    localparam int unsigned BTQ_N_SZ = 32;
    localparam int unsigned IB_BLK_NUM_N = 64;
    localparam int unsigned IB_PC_QUEUE_SIZE_N = 32;
    localparam int unsigned IB_BTQ_IDX_QUEUE_SIZE_N = BTQ_N_SZ;
    localparam int unsigned BR_OFFSET_WIDTH = 20;
    localparam int unsigned IFQ_DEPTH = 8;
    // Decode Width
    localparam int unsigned DECODE_WIDTH = 4;
    // Rename Width
    localparam int unsigned RENAME_WIDTH = 4;
    // Issue 
    localparam int unsigned INT0_IQ_DEPTH = 12;
    localparam int unsigned AGU0_IQ_DEPTH = 12;
    localparam int unsigned SDU0_IQ_DEPTH = 12;
    localparam int unsigned INT1_IQ_DEPTH = 12;
    localparam int unsigned AGU1_IQ_DEPTH = 12;
    localparam int unsigned SDU1_IQ_DEPTH = 12;
    localparam int unsigned COMPLEX_INT0_IQ_DEPTH = 12;
    localparam int unsigned BR0_IQ_DEPTH = 12;
    // Execute
    localparam int unsigned BRU_COUNT = 1;
    localparam int unsigned ALU_COUNT = 3;
    localparam int unsigned MUL_COUNT = 1;
    localparam int unsigned DIV_COUNT = 1;
    localparam int unsigned LSU_ADDR_PIPE_COUNT = 2;
    localparam int unsigned LSU_DATA_PIPE_COUNT = 2;

    localparam int unsigned INT_COMPLETE_WIDTH = 4;
    localparam int unsigned LSU_COMPLETE_WIDTH = LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT;

    // Forwarding Network
    localparam int unsigned INT_CDB_DEPTH = 1;
    localparam int unsigned INT_CDB_BUS_WIDTH = BRU_COUNT + ALU_COUNT + MUL_COUNT + DIV_COUNT + LSU_ADDR_PIPE_COUNT; // 1 + 3 + 1 + 1 + 2 = 8
    localparam int unsigned INT_CDB_ID_WIDTH = 3; // clog2(INT_CDB_BUS_WIDTH)

    localparam int unsigned RETIRE_WIDTH = 4;
    // Dispatch
    localparam int unsigned INT_DISP_QUEUE_DEPTH = 16;
    localparam int unsigned INT_DISP_WIDTH = 4;

    localparam int unsigned LSU_DISP_QUEUE_DEPTH = 16;
    localparam int unsigned LSU_DISP_WIDTH = 2;
    localparam int unsigned LSU_ALLOC_WIDTH = LSU_DISP_WIDTH;
    // ROB
    // localparam int unsigned ROB_SIZE = 128;
    localparam int unsigned ROB_SIZE = 16; //ROB_SIZE
    localparam int unsigned ROB_BLOCK_PER_ENTRY = 1;
    localparam int unsigned ROB_ENTRY_COUNT = ROB_SIZE / ROB_BLOCK_PER_ENTRY;
    localparam int unsigned ROB_CB_WIDTH = INT_COMPLETE_WIDTH + LSU_COMPLETE_WIDTH;
    localparam int unsigned ROB_RE_WIDTH = LSU_ADDR_PIPE_COUNT;
    localparam int unsigned ROB_BR_WIDTH = BRU_COUNT;
    // Physical Register File
    // localparam int unsigned INT_PREG_COUNT = 128;
    localparam int unsigned INT_PREG_COUNT = 48; // IMPORT FROM HEHE2
    localparam int unsigned INT_PRF_ALLOC_PORT_COUNT = RENAME_WIDTH;
    localparam int unsigned INT_PRF_DISP_PORT_COUNT = 2 * (INT_DISP_WIDTH + LSU_DISP_WIDTH);
    localparam int unsigned INT_PRF_WR_PORT_COUNT = 6;
    localparam int unsigned INT_PRF_RD_PORT_COUNT = 6;
    // BTQ
    localparam int unsigned BTQ_ENTRY_COUNT = BTQ_N_SZ;
    // BRQ
    localparam int unsigned BRQ_ENTRY_COUNT = 12;
    // LDQ
    localparam int unsigned LDQ_ENTRY_COUNT = 12;
    localparam int unsigned RAR_QUEUE_ENTRY_COUNT = 32;
    localparam int unsigned RAW_QUEUE_ENTRY_COUNT = 32;
    // STQ
    localparam int unsigned STQ_ENTRY_COUNT = 48;
    // PMP
    localparam int unsigned PMP_ENTRY_COUNT = 8;
    // PTW
    localparam int unsigned PTW_COUNT = 1;
    localparam int unsigned PTW_ID_WIDTH = 1; // PTW_COUNT > 1 ? $clog2(PTW_COUNT) : 1
    // L1D Cache
    localparam int unsigned L1D_SIZE       = 256;// line_size * way_count * set_count = 64 * 4 * 2
    localparam int unsigned L1D_LINE_SIZE  = 64;
    localparam int unsigned L1D_WAY_COUNT  = 4;
    localparam int unsigned L1D_BANK_COUNT = 1;
    localparam int unsigned L1D_SET_COUNT  = L1D_SIZE / (L1D_LINE_SIZE * L1D_WAY_COUNT); // 64
    localparam int unsigned L1D_BANK_SET_COUNT = L1D_SET_COUNT / L1D_BANK_COUNT; // 64
    // L1 DTLB
    localparam int unsigned DTLB_ENTRY_COUNT = 16;
    localparam int unsigned DTLB_MSHR_COUNT  = 4;
    localparam int unsigned DTLB_TRANS_ID_WIDTH = 2;// DTLB_MSHR_COUNT > 1 ? $clog2(DTLB_MSHR_COUNT) : 1;
    localparam int unsigned ITLB_ENTRY_COUNT = 16;
    localparam int unsigned ITLB_TRANS_ID_WIDTH = DTLB_TRANS_ID_WIDTH;
    /* ------------------------------- */

    // L1D Cache 
    localparam int unsigned L1D_OFFSET_WIDTH_CORE = 6;// clog2(L1D_LINE_SIZE);
    localparam int unsigned L1D_BANK_ID_WIDTH_CORE = 1;//clog2(L1D_BANK_COUNT);
    localparam int unsigned L1D_SET_ID_WIDTH_CORE = 1;// clog2(L1D_BANK_SET_COUNT);
    localparam int unsigned L1D_INDEX_WIDTH_CORE = L1D_BANK_ID_WIDTH_CORE + L1D_SET_ID_WIDTH_CORE + L1D_OFFSET_WIDTH_CORE;
    localparam int unsigned L1D_TAG_WIDTH_CORE  = PADDR_WIDTH - (L1D_INDEX_WIDTH_CORE > 12 ? 12 : L1D_INDEX_WIDTH_CORE);


    // PMP Config
    localparam int unsigned PMP_GROUP_COUNT = PMP_ENTRY_COUNT > 8 ? (PMP_ENTRY_COUNT / 8) : 1; // 1
    localparam int unsigned PMP_CFG_TAG_WIDTH = 1; // PMP_GROUP_COUNT > 1 ? clog2(PMP_GROUP_COUNT) : 1;
    localparam int unsigned PMP_ADDR_TAG_WIDTH = 3; // clog2(PMP_ENTRY_COUNT);

    // LSQ
    localparam int unsigned LDQ_TAG_WIDTH = $clog2(LDQ_ENTRY_COUNT);
    localparam int unsigned STQ_TAG_WIDTH = $clog2(STQ_ENTRY_COUNT);
    localparam int unsigned RAW_TAG_WIDTH = $clog2(RAW_QUEUE_ENTRY_COUNT);
    localparam int unsigned RAR_TAG_WIDTH = $clog2(RAR_QUEUE_ENTRY_COUNT);
    localparam
        int unsigned LSQ_TAG_WIDTH = LDQ_TAG_WIDTH > STQ_TAG_WIDTH ? LDQ_TAG_WIDTH : STQ_TAG_WIDTH;
    // BTQ
    localparam int unsigned BTQ_TAG_WIDTH = $clog2(BTQ_ENTRY_COUNT) + 1;
    // BRQ
    localparam int unsigned BRQ_TAG_WIDTH = $clog2(BRQ_ENTRY_COUNT);
    // Physical Register File Config    
    localparam int unsigned INT_PREG_TAG_WIDTH = $clog2(INT_PREG_COUNT);
    localparam int unsigned PREG_TAG_WIDTH = INT_PREG_TAG_WIDTH;
    // ROB
    localparam int unsigned ROB_OFFSET_WIDTH = ROB_BLOCK_PER_ENTRY > 1 ? $clog2(
        ROB_BLOCK_PER_ENTRY
    ) : 1;
    localparam int unsigned ROB_INDEX_WIDTH = 4;// $clog2(ROB_ENTRY_COUNT);
    localparam int unsigned ROB_PTR_WIDTH = 1 + ROB_INDEX_WIDTH;
    // localparam int unsigned ROB_TAG_WIDTH = ROB_PTR_WIDTH + ROB_OFFSET_WIDTH;
    localparam int unsigned ROB_TAG_WIDTH = ROB_INDEX_WIDTH;
    localparam int unsigned ROB_PC_OFFSET_WIDTH = $clog2(FETCH_WIDTH / 8) - 1;
    localparam int unsigned ROB_PC_BASE_WIDTH = VADDR_WIDTH - ROB_PC_OFFSET_WIDTH - 1;


    // INT Encoding
    localparam int unsigned INT_TYPE_WIDTH = 2;
    localparam logic [INT_TYPE_WIDTH-1:0] INT_ALU_TYPE = 0;
    localparam logic [INT_TYPE_WIDTH-1:0] INT_MUL_TYPE = 1;
    localparam logic [INT_TYPE_WIDTH-1:0] INT_DIV_TYPE = 2;
    localparam logic [INT_TYPE_WIDTH-1:0] INT_BRU_TYPE = 3;

    localparam int unsigned LSU_TYPE_WIDTH = 1;
    localparam logic [LSU_TYPE_WIDTH-1:0] LSU_LD_TYPE = 0;
    localparam logic [LSU_TYPE_WIDTH-1:0] LSU_ST_TYPE = 1;

    // AGU IQ TAG
    localparam int unsigned AGU_IQ_TAG_WIDHT = $clog2(AGU0_IQ_DEPTH);
    


    typedef struct packed {logic [VADDR_WIDTH-1:0] pc;} l1ic_req_t;

    typedef struct packed {
        logic                   replay;
        logic [FETCH_WIDTH-1:0] line;
    } l1ic_resp_t;



    localparam int unsigned PRIV_LVL_WIDTH = 2;
    localparam int unsigned PMA_ACCESS_WIDTH = 2;
    localparam int unsigned EXCP_CAUSE_WIDTH = 64;
    localparam int unsigned EXCP_TVAL_WIDTH = 64;
    localparam int unsigned REG_TYPE_WIDTH = 2;
    localparam int unsigned ISA_REG_TAG_WIDTH = 5;
    localparam int unsigned CSR_ADDR_WIDTH = 12;


    localparam int unsigned PTE_LVL_WIDTH = 2;

    typedef enum logic [3:0] {
        ModeOff  = 0,
        ModeSv32 = 1,
        ModeSv39 = 8,
        ModeSv48 = 9,
        ModeSv57 = 10,
        ModeSv64 = 11
    } vm_mode_t;

    typedef enum logic [PTE_LVL_WIDTH-1:0] {
        PAGE_4KB = 0,
        PAGE_1MB = 1,
        PAGE_1GB = 2
    } pte_lvl_t;

    // SATP
    localparam vm_mode_t MODE_SV = ModeSv39;
    localparam MODE_WIDTH = 4;
    localparam ASID_WIDTH = 16;
    localparam PAGE_OFFSET_WIDTH = 12;
    localparam VPN_WIDTH = 27;
    localparam PPN_WIDTH = 48;
    localparam PTE_WIDTH = 64;
    localparam PAGE_LVL_WIDTH = 2;

    typedef enum logic [REG_TYPE_WIDTH-1:0] {
        TYPE_NONE,
        TYPE_INT,
        TYPE_FP,
        TYPE_VEC
    } reg_type_t;

    typedef enum logic [PMA_ACCESS_WIDTH-1:0] {
        PMA_ACCESS_LOAD  = 0,
        PMA_ACCESS_STORE = 1,
        PMA_ACCESS_EXEC  = 2
    } pma_access_t;


    typedef enum logic [PRIV_LVL_WIDTH-1:0] {
        PRIV_M = 2'b11,
        PRIV_S = 2'b01,
        PRIV_U = 2'b00
    } priv_lvl_t;


    // type which holds xlen
    typedef enum logic [1:0] {
        XLEN_32  = 2'b01,
        XLEN_64  = 2'b10,
        XLEN_128 = 2'b11
    } xlen_e;

    typedef enum logic [1:0] {
        Off     = 2'b00,
        Initial = 2'b01,
        Clean   = 2'b10,
        Dirty   = 2'b11
    } xs_t;

    typedef struct packed {
        logic sd;  // signal dirty state - read-only
        logic [62:36] wpri4;  // writes preserved reads ignored
        xlen_e sxl;  // variable supervisor mode xlen - hardwired to zero
        xlen_e uxl;  // variable user mode xlen - hardwired to zero
        logic [8:0] wpri3;  // writes preserved reads ignored
        logic tsr;  // trap sret
        logic tw;  // time wait
        logic tvm;  // trap virtual memory
        logic mxr;  // make executable readable
        logic sum;  // permit supervisor user memory access
        logic mprv;  // modify privilege - privilege level for ld/st
        xs_t xs;  // extension register - hardwired to zero
        xs_t fs;  // floating point extension register
        priv_lvl_t mpp;  // holds the previous privilege mode up to machine
        logic [1:0] wpri2;  // writes preserved reads ignored
        logic spp;  // holds the previous privilege mode up to supervisor
        logic mpie;  // machine interrupts enable bit active prior to trap
        logic wpri1;  // writes preserved reads ignored
        logic spie;  // supervisor interrupts enable bit active prior to trap
        logic upie;  // user interrupts enable bit active prior to trap - hardwired to zero
        logic mie;  // machine interrupts enable
        logic wpri0;  // writes preserved reads ignored
        logic sie;  // supervisor interrupts enable
        logic uie;  // user interrupts enable - hardwired to zero
    } mstatus_t;

    localparam logic [63:0] SSTATUS_UIE  = 'h00000001;
    localparam logic [63:0] SSTATUS_SIE  = 'h00000002;
    localparam logic [63:0] SSTATUS_SPIE = 'h00000020;
    localparam logic [63:0] SSTATUS_SPP  = 'h00000100;
    localparam logic [63:0] SSTATUS_FS   = 'h00006000;
    localparam logic [63:0] SSTATUS_XS   = 'h00018000;
    localparam logic [63:0] SSTATUS_SUM  = 'h00040000;
    localparam logic [63:0] SSTATUS_MXR  = 'h00080000;
    localparam logic [63:0] SSTATUS_UPIE = 'h00000010;
    localparam logic [63:0] SSTATUS_UXL  = 64'h0000000300000000;
    localparam logic [63:0] SSTATUS_SD   = {1'b1, 31'h00000000, 1'b0, 31'h00000000};

    localparam logic [63:0] MSTATUS_UIE  = 'h00000001;
    localparam logic [63:0] MSTATUS_SIE  = 'h00000002;
    localparam logic [63:0] MSTATUS_HIE  = 'h00000004;
    localparam logic [63:0] MSTATUS_MIE  = 'h00000008;
    localparam logic [63:0] MSTATUS_UPIE = 'h00000010;
    localparam logic [63:0] MSTATUS_SPIE = 'h00000020;
    localparam logic [63:0] MSTATUS_HPIE = 'h00000040;
    localparam logic [63:0] MSTATUS_MPIE = 'h00000080;
    localparam logic [63:0] MSTATUS_SPP  = 'h00000100;
    localparam logic [63:0] MSTATUS_HPP  = 'h00000600;
    localparam logic [63:0] MSTATUS_MPP  = 'h00001800;
    localparam logic [63:0] MSTATUS_FS   = 'h00006000;
    localparam logic [63:0] MSTATUS_XS   = 'h00018000;
    localparam logic [63:0] MSTATUS_MPRV = 'h00020000;
    localparam logic [63:0] MSTATUS_SUM  = 'h00040000;
    localparam logic [63:0] MSTATUS_MXR  = 'h00080000;
    localparam logic [63:0] MSTATUS_TVM  = 'h00100000;
    localparam logic [63:0] MSTATUS_TW   = 'h00200000;
    localparam logic [63:0] MSTATUS_TSR  = 'h00400000;
    localparam logic [63:0] MSTATUS_UXL  = {30'h0000000, 1'b1, 1'b1, 32'h00000000};
    localparam logic [63:0] MSTATUS_SXL  = {28'h0000000, 1'b1, 1'b1, 34'h00000000};
    localparam logic [63:0] MSTATUS_SD   = {1'b1, 31'h00000000, 1'b0, 31'h00000000};

    typedef struct packed {
        logic [63:60] mode;
        logic [59:44] asid;
        logic [43:0]  ppn;
    } satp_t;

    localparam int unsigned IRQ_S_SOFT = 1;
    localparam int unsigned IRQ_M_SOFT = 3;
    localparam int unsigned IRQ_S_TIMER = 5;
    localparam int unsigned IRQ_M_TIMER = 7;
    localparam int unsigned IRQ_S_EXT = 9;
    localparam int unsigned IRQ_M_EXT = 11;

    localparam logic [64-1:0] MIP_SSIP = 1 << IRQ_S_SOFT;
    localparam logic [64-1:0] MIP_MSIP = 1 << IRQ_M_SOFT;
    localparam logic [64-1:0] MIP_STIP = 1 << IRQ_S_TIMER;
    localparam logic [64-1:0] MIP_MTIP = 1 << IRQ_M_TIMER;
    localparam logic [64-1:0] MIP_SEIP = 1 << IRQ_S_EXT;
    localparam logic [64-1:0] MIP_MEIP = 1 << IRQ_M_EXT;


    localparam logic [EXCP_CAUSE_WIDTH-1:0] INSTR_ADDR_MISALIGNED = 0;
    localparam logic [EXCP_CAUSE_WIDTH-1:0] INSTR_ACCESS_FAULT =1;  // Illegal access as governed by PMPs and PMAs
    localparam logic [EXCP_CAUSE_WIDTH-1:0] ILLEGAL_INSTR = 2;
    localparam logic [EXCP_CAUSE_WIDTH-1:0] BREAKPOINT = 3;
    localparam logic [EXCP_CAUSE_WIDTH-1:0] LD_ADDR_MISALIGNED = 4;
    localparam logic [EXCP_CAUSE_WIDTH-1:0] LD_ACCESS_FAULT =
        5;  // Illegal access as governed by PMPs and PMAs
    localparam logic [EXCP_CAUSE_WIDTH-1:0] ST_ADDR_MISALIGNED = 6;
    localparam logic [EXCP_CAUSE_WIDTH-1:0] ST_ACCESS_FAULT =
        7;  // Illegal access as governed by PMPs and PMAs
    localparam logic [EXCP_CAUSE_WIDTH-1:0] ENV_CALL_UMODE = 8;  // environment call from user mode
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] ENV_CALL_SMODE = 9;  // environment call from supervisor mode
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] ENV_CALL_MMODE = 11;  // environment call from machine mode
    localparam logic [EXCP_CAUSE_WIDTH-1:0] INSTR_PAGE_FAULT = 12;  // Instruction page fault
    localparam logic [EXCP_CAUSE_WIDTH-1:0] LOAD_PAGE_FAULT = 13;  // Load page fault
    localparam logic [EXCP_CAUSE_WIDTH-1:0] STORE_PAGE_FAULT = 15;  // Store page fault
    // User define
    localparam logic [EXCP_CAUSE_WIDTH-1:0] ORDER_FAILURE = 24;  // ordering failure

    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] S_SW_INTERRUPT = (1 << (64 - 1)) | IRQ_S_SOFT;
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] M_SW_INTERRUPT = (1 << (64 - 1)) | IRQ_M_SOFT;
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] S_TIMER_INTERRUPT = (1 << (64 - 1)) | IRQ_S_TIMER;
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] M_TIMER_INTERRUPT = (1 << (64 - 1)) | IRQ_M_TIMER;
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] S_EXT_INTERRUPT = (1 << (64 - 1)) | IRQ_S_EXT;
    localparam
        logic [EXCP_CAUSE_WIDTH-1:0] M_EXT_INTERRUPT = (1 << (64 - 1)) | IRQ_M_EXT;



    // RV32/64G listings:
    // Quadrant 0
    localparam OpcodeLoad = 7'b0000011;
    localparam OpcodeLoadFp = 7'b0000111;
    localparam OpcodeCustom0 = 7'b0001011;
    localparam OpcodeMiscMem = 7'b0001111;
    localparam OpcodeOpImm = 7'b0010011;
    localparam OpcodeAuipc = 7'b0010111;
    localparam OpcodeOpImm32 = 7'b0011011;
    // Quadrant 1
    localparam OpcodeStore = 7'b0100011;
    localparam OpcodeStoreFp = 7'b0100111;
    localparam OpcodeCustom1 = 7'b0101011;
    localparam OpcodeAmo = 7'b0101111;
    localparam OpcodeOp = 7'b0110011;
    localparam OpcodeLui = 7'b0110111;
    localparam OpcodeOp32 = 7'b0111011;
    // Quadrant 2
    localparam OpcodeMadd = 7'b1000011;
    localparam OpcodeMsub = 7'b1000111;
    localparam OpcodeNmsub = 7'b1001011;
    localparam OpcodeNmadd = 7'b1001111;
    localparam OpcodeOpFp = 7'b1010011;
    localparam OpcodeRsrvd1 = 7'b1010111;
    localparam OpcodeCustom2 = 7'b1011011;
    // Quadrant 3
    localparam OpcodeBranch = 7'b1100011;
    localparam OpcodeJalr = 7'b1100111;
    localparam OpcodeRsrvd2 = 7'b1101011;
    localparam OpcodeJal = 7'b1101111;
    localparam OpcodeSystem = 7'b1110011;
    localparam OpcodeRsrvd3 = 7'b1110111;
    localparam OpcodeCustom3 = 7'b1111011;

    // RV64C/RV32C listings:
    // Quadrant 0
    localparam OpcodeC0 = 2'b00;
    localparam OpcodeC0Addi4spn = 3'b000;
    localparam OpcodeC0Fld = 3'b001;
    localparam OpcodeC0Lw = 3'b010;
    localparam OpcodeC0Ld = 3'b011;
    localparam OpcodeC0Rsrvd = 3'b100;
    localparam OpcodeC0Fsd = 3'b101;
    localparam OpcodeC0Sw = 3'b110;
    localparam OpcodeC0Sd = 3'b111;
    // Quadrant 1
    localparam OpcodeC1 = 2'b01;
    localparam OpcodeC1Addi = 3'b000;
    localparam OpcodeC1Addiw = 3'b001;  //for RV64I only
    localparam OpcodeC1Jal = 3'b001;  //for RV32I only
    localparam OpcodeC1Li = 3'b010;
    localparam OpcodeC1LuiAddi16sp = 3'b011;
    localparam OpcodeC1MiscAlu = 3'b100;
    localparam OpcodeC1J = 3'b101;
    localparam OpcodeC1Beqz = 3'b110;
    localparam OpcodeC1Bnez = 3'b111;
    // Quadrant 2
    localparam OpcodeC2 = 2'b10;
    localparam OpcodeC2Slli = 3'b000;
    localparam OpcodeC2Fldsp = 3'b001;
    localparam OpcodeC2Lwsp = 3'b010;
    localparam OpcodeC2Ldsp = 3'b011;
    localparam OpcodeC2JalrMvAdd = 3'b100;
    localparam OpcodeC2Fsdsp = 3'b101;
    localparam OpcodeC2Swsp = 3'b110;
    localparam OpcodeC2Sdsp = 3'b111;


    /* CSR */
    // Unprivileged Counter/Timers
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_CYCLE = 12'hC00;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_TIME = 12'hC01;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_INSTRET = 12'hC02;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER3 = 12'hC03;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER4 = 12'hC04;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER5 = 12'hC05;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER6 = 12'hC06;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER7 = 12'hC07;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER8 = 12'hC08;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER9 = 12'hC09;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER10 = 12'hC0A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER11 = 12'hC0B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER12 = 12'hC0C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER13 = 12'hC0D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER14 = 12'hC0E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER15 = 12'hC0F;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER16 = 12'hC10;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER17 = 12'hC11;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER18 = 12'hC12;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER19 = 12'hC13;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER20 = 12'hC14;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER21 = 12'hC15;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER22 = 12'hC16;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER23 = 12'hC17;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER24 = 12'hC18;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER25 = 12'hC19;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER26 = 12'hC1A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER27 = 12'hC1B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER28 = 12'hC1C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER29 = 12'hC1D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER30 = 12'hC1E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_HPMCOUNTER31 = 12'hC1F;
    // Machine Information Registers
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MVENDORID = 12'hF11;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MARCHID = 12'hF12;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MIMPID = 12'hF13;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHARTID = 12'hF14;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MCONFIGPTR = 12'hF15;
    // Machine Trap Setup
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MSTATUS = 12'h300;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MISA = 12'h301;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MEDELEG = 12'h302;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MIDELEG = 12'h303;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MIE = 12'h304;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MTVEC = 12'h305;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MCOUNTEREN = 12'h306;
    // Machine Tap Handling 
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MSCRATCH = 12'h340;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MEPC = 12'h341;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MCAUSE = 12'h342;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MTVAL = 12'h343;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MIP = 12'h344;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MTINST = 12'h34A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MTVAL2 = 12'h34B;
    // Machine Configuration
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MENVCFG = 12'h30A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MSECCFG = 12'h747;
    // Machine Memory Protection
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG0 = 12'h3A0;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG2 = 12'h3A2;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG4 = 12'h3A4;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG6 = 12'h3A6;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG8 = 12'h3A8;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG10 = 12'h3AA;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG12 = 12'h3AC;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPCFG14 = 12'h3AE;

    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR0 = 12'h3B0;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR1 = 12'h3B1;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR2 = 12'h3B2;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR3 = 12'h3B3;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR4 = 12'h3B4;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR5 = 12'h3B5;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR6 = 12'h3B6;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR7 = 12'h3B7;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR8 = 12'h3B8;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR9 = 12'h3B9;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR10 = 12'h3BA;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR11 = 12'h3BB;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR12 = 12'h3BC;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR13 = 12'h3BD;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR14 = 12'h3BE;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR15 = 12'h3BF;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR16 = 12'h3C0;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR17 = 12'h3C1;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR18 = 12'h3C2;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR19 = 12'h3C3;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR20 = 12'h3C4;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR21 = 12'h3C5;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR22 = 12'h3C6;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR23 = 12'h3C7;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR24 = 12'h3C8;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR25 = 12'h3C9;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR26 = 12'h3CA;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR27 = 12'h3CB;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR28 = 12'h3CC;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR29 = 12'h3CD;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR30 = 12'h3CE;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR31 = 12'h3CF;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR32 = 12'h3D0;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR33 = 12'h3D1;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR34 = 12'h3D2;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR35 = 12'h3D3;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR36 = 12'h3D4;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR37 = 12'h3D5;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR38 = 12'h3D6;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR39 = 12'h3D7;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR40 = 12'h3D8;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR41 = 12'h3D9;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR42 = 12'h3DA;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR43 = 12'h3DB;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR44 = 12'h3DC;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR45 = 12'h3DD;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR46 = 12'h3DE;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR47 = 12'h3DF;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR48 = 12'h3E0;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR49 = 12'h3E1;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR50 = 12'h3E2;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR51 = 12'h3E3;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR52 = 12'h3E4;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR53 = 12'h3E5;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR54 = 12'h3E6;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR55 = 12'h3E7;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR56 = 12'h3E8;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR57 = 12'h3E9;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR58 = 12'h3EA;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR59 = 12'h3EB;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR60 = 12'h3EC;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR61 = 12'h3ED;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR62 = 12'h3EE;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_PMPADDR63 = 12'h3EF;
    // Machine Counter / Timers
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MCYCLE = 12'hB00;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MINSTRET = 12'hB02;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER3 = 12'hB03;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER4 = 12'hB04;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER5 = 12'hB05;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER6 = 12'hB06;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER7 = 12'hB07;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER8 = 12'hB08;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER9 = 12'hB09;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER10 = 12'hB0A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER11 = 12'hB0B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER12 = 12'hB0C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER13 = 12'hB0D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER14 = 12'hB0E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER15 = 12'hB0F;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER16 = 12'hB10;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER17 = 12'hB11;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER18 = 12'hB12;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER19 = 12'hB13;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER20 = 12'hB14;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER21 = 12'hB15;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER22 = 12'hB16;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER23 = 12'hB17;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER24 = 12'hB18;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER25 = 12'hB19;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER26 = 12'hB1A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER27 = 12'hB1B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER28 = 12'hB1C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER29 = 12'hB1D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER30 = 12'hB1E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMCOUNTER31 = 12'hB1F;
    // Machine Counter Setup
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MCOUNTINHIBIT = 12'h320;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT3 = 12'h323;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT4 = 12'h324;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT5 = 12'h325;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT6 = 12'h326;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT7 = 12'h327;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT8 = 12'h328;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT9 = 12'h329;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT10 = 12'h32A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT11 = 12'h32B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT12 = 12'h32C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT13 = 12'h32D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT14 = 12'h32E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT15 = 12'h32F;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT16 = 12'h330;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT17 = 12'h331;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT18 = 12'h332;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT19 = 12'h333;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT20 = 12'h334;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT21 = 12'h335;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT22 = 12'h336;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT23 = 12'h337;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT24 = 12'h338;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT25 = 12'h339;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT26 = 12'h33A;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT27 = 12'h33B;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT28 = 12'h33C;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT29 = 12'h33D;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT30 = 12'h33E;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_MHPMEVENT31 = 12'h33F;
    // Supervisor Trap Setup
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SSTATUS = 12'h100;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SIE = 12'h104;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_STVEC = 12'h105;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SCOUNTEREN = 12'h106;
    // Supervisor Configuration
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SENVCFG = 12'h10A;
    // Supervisor Trap Handling
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SSCRATCH = 12'h140;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SEPC = 12'h141;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SCAUSE = 12'h142;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_STVAL = 12'h143;
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SIP = 12'h144;
    // Supervisor Protection and Translation
    localparam logic [CSR_ADDR_WIDTH-1:0] CSR_SATP = 12'h180;





localparam L1D_BANK_LINE_DATA_SIZE = 512; // bits 512

localparam L1D_BANK_SET_NUM = 2; // sets 2
localparam L1D_BANK_WAY_NUM = 4; // 4
localparam L1D_BANK_ID_NUM = 1; // 1

localparam L1D_STB_ENTRY_NUM = 8;

// localparam INDEX_WIDTH = $clog2(L1D_BANK_SET_NUM);
localparam L1D_INDEX_WIDTH  = 1; // clog2(L1D_BANK_SET_NUM*L1D_BANK_ID_NUM);
localparam L1D_OFFSET_WIDTH = 6; //clog2(L1D_BANK_LINE_DATA_SIZE/8);
localparam L1D_BIT_OFFSET_WIDTH = 9;// clog2(L1D_BANK_LINE_DATA_SIZE);
localparam L1D_TAG_WIDTH    = 56-L1D_INDEX_WIDTH-L1D_OFFSET_WIDTH;

localparam L1D_STB_ID_NUM = 4;
localparam L1D_STB_ID_WIDTH = 2;//clog2(L1D_STB_ID_NUM);
localparam L1D_STB_DATA_WIDTH = 512;
localparam L1D_STB_LINE_ADDR_SIZE = 56-L1D_OFFSET_WIDTH;
localparam L1D_OFFSET_BIT_DIFF_STB_SEG = 1; // clog2(L1D_BANK_LINE_DATA_SIZE/L1D_STB_DATA_WIDTH);

localparam L1D_BANK_SET_INDEX_WIDTH = 1;// $clog2(L1D_BANK_SET_NUM);
localparam L1D_BANK_ID_INDEX_WIDTH  = 0;// $clog2(L1D_BANK_ID_NUM);
localparam L1D_BANK_OFFSET_WIDTH  = L1D_OFFSET_WIDTH;
localparam L1D_BANK_TAG_WIDTH     = L1D_TAG_WIDTH;
localparam L1D_BANK_WAY_INDEX_WIDTH = 2; //$clog2(L1D_BANK_WAY_NUM);

localparam L1D_BANK_LINE_ADDR_SIZE = 56-L1D_OFFSET_WIDTH-L1D_BANK_ID_INDEX_WIDTH;
localparam L1D_BANK_PADDR_TAG_WIDTH = 56-L1D_BANK_SET_INDEX_WIDTH-L1D_BANK_ID_INDEX_WIDTH-L1D_BANK_OFFSET_WIDTH;
localparam L1D_BANK_TAG_RAM_WORD_WIDTH = L1D_BANK_PADDR_TAG_WIDTH; 


// s_axi_awsize    width(byte)
// 3'b000          1
// 3'b001          2
// 3'b010          4
// 3'b011          8
// 3'b100          16
// 3'b101          32
// 3'b110          64
// 3'b111          128
localparam MEM_DATA_WIDTH = 64;
localparam BURST_SIZE = L1D_BANK_LINE_DATA_SIZE/MEM_DATA_WIDTH;//8
localparam AXI_SIZE = 3; //$clog2(MEM_DATA_WIDTH/8);
localparam N_MSHR = 2; // num of MSHR
localparam N_MSHR_W = 1;//$clog2(N_MSHR);
// localparam PPN_WIDTH = 44;
localparam N_EWRQ = N_MSHR;
localparam N_MLFB = N_MSHR;


localparam MEMNOC_TID_MASTERID_SIZE  = 4;
localparam MEMNOC_TID_TID_SIZE       = 4;

`ifdef RUBY
// localparam RRV64_LSU_ID_WIDTH = LDQ_TAG_WIDTH + 2;
// parameter RT_TRANS_ID_NUM_W   = $clog2(RT_TRANS_ID_NUM);
localparam RRV64_LSU_ID_WIDTH = $clog2(32) + $clog2(LSU_ADDR_PIPE_COUNT);
`endif

  typedef logic [N_MSHR_W-1:0]   mshr_id_t;

  typedef enum logic [1:0] {
    INVALID,
    SHARED,
    EXCLUSIVE,
    MODIFIED
  } rrv64_mesi_type_e;

  typedef struct packed {
    logic [MEMNOC_TID_MASTERID_SIZE-1:0] bid; // cache bank id, the highest used for distinguish i$/d$
    logic [MEMNOC_TID_TID_SIZE-1:0] tid;      // mshr id in ar and r
  } mem_tid_t;
  typedef enum logic[1:0] {
    AXI_RESP_OKAY = 2'b00,
    AXI_RESP_EXOKAY = 2'b01,
    AXI_RESP_SLVERR = 2'b10,
    AXI_RESP_DECERR = 2'b11
  } axi4_resp_t;

  typedef struct packed {
    mem_tid_t awid;
    logic [56-1:0]  awaddr;
    logic [7 : 0] awlen;
    
    logic [2 : 0] awsize; // TODO: 
    logic [1 : 0] awburst; // TODO:
    
} cache_mem_if_aw_t;

  typedef struct packed {
    logic [MEM_DATA_WIDTH-1:0]  wdata;
    logic wlast;
    mem_tid_t wid;
} cache_mem_if_w_t;

  typedef struct packed {
    mem_tid_t arid;
    logic [7  : 0] arlen;
    
    logic [2 : 0] arsize; // TODO: 
    logic [1 : 0] arburst; // TODO:
    
    logic [56-1:0]  araddr;
  } cache_mem_if_ar_t;

  // typedef struct packed {
  //   mem_tid_t rid;
  //   logic [MEM_DATA_WIDTH-1:0]  rdata;
  //   axi4_resp_t rresp;
  //   logic rlast;
  // } cache_mem_if_r_t;

  typedef struct packed {
    mem_tid_t                        rid;
    logic [MEM_DATA_WIDTH-1:0]       dat;
    logic                            err;
    rrv64_mesi_type_e                mesi_sta;
    // logic [RRV64_SCU_SST_IDX_W-1:0]  sst_idx;
    axi4_resp_t rresp; // TODO: 
    logic rlast;  // TODO: 
  //    logic                            l2_hit;
  } cache_mem_if_r_t;

  typedef struct packed {
    mem_tid_t bid;
    axi4_resp_t bresp;
  } cache_mem_if_b_t;

  // ace5 snoop channels
    // snoop addr
  typedef struct packed {
    // mem_tid_t acid;
    logic [L1D_STB_LINE_ADDR_SIZE-1:0]  acaddr;
    logic [3:0]              acsoop;
    logic [2:0]              acprot;
  } cache_mem_if_ac_t;

    // snoop resp
  typedef struct packed {
    logic WasUnique;
    logic IsShared;
    logic PassDirty;
    logic Error; // for ECC, not used
    logic DataTransfer;
  } cr_crresp_t;

  typedef struct packed {
    // mem_tid_t crid;
    cr_crresp_t crresp;
  } cache_mem_if_cr_t;

    // snoop data
  typedef struct packed {
    // mem_tid_t cdid;
    logic [L1D_BANK_LINE_DATA_SIZE-1:0] cddata;
    logic                               cdlast;
  } cache_mem_if_cd_t;





  typedef enum logic [2:0] {
    AMOSWAP,
    AMOADD,
    AMOAND,
    AMOOR,
    AMOXOR,
    AMOMAX,
    AMOMIN
  } l1d_amo_type_e;

  typedef struct packed {
    logic          is_ld;
    logic          is_ptw_ld;
    logic          is_st;
    logic          is_amo;
    logic          amo_u;
    l1d_amo_type_e amo_type;
    logic          is_lr;
    logic          is_sc;
    logic          op_b;
    logic          op_hw;
    logic          op_w;
    logic          op_dw;
    logic          ld_u;
  } rrv64_l1d_req_type_dec_t;


typedef struct packed {
    rrv64_mesi_type_e [L1D_BANK_WAY_NUM-1:0] mesi_sta;
} rrv64_l1d_lst_t;

typedef struct packed {
  // stage 1
  logic [     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_req_rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_req_prd;
  // logic [      LDU_OP_WIDTH-1:0] ls_pipe_l1d_req_opcode;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_req_lsu_tag;
`endif

  logic [L1D_BANK_SET_INDEX_WIDTH-1:0] ls_pipe_l1d_req_idx;
  logic [L1D_BANK_OFFSET_WIDTH-1:0   ] ls_pipe_l1d_req_offset;
  logic [L1D_BANK_TAG_WIDTH-1:0      ] ls_pipe_l1d_req_vtag; // for ld gen ptag when idx+offset<12
  
  logic [ L1D_BANK_PADDR_TAG_WIDTH-1:0 ] ls_pipe_l1d_st_req_tag; // for st: st paddr tag; for ptw: ptw ld paddr tag
  logic [       L1D_STB_DATA_WIDTH-1:0 ] ls_pipe_l1d_st_req_dat;
  logic [     L1D_STB_DATA_WIDTH/8-1:0 ] ls_pipe_l1d_st_req_dat_byte_mask;
  
  rrv64_l1d_lst_t                    lst_dat; // mesi, cover valid & dirty bit
  // logic                              is_lsu_ld_req;
  rrv64_l1d_req_type_dec_t           req_type_dec;
  
  logic                              is_evict;
  logic [L1D_BANK_WAY_NUM-1:0]       evict_way_idx;

  logic                              sc_rt_check_succ; // sc
} l1d_pipe_s1_t;

typedef struct packed {
  // stage 2
//  logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_PADDR_TAG_WIDTH-1:0]               tram_rdat;
//  logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM-1:0]  dram_rdat;
//  logic [L1D_BANK_WAY_NUM-1:0]                                    vram_rdat;
  logic [     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_req_rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_req_prd;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_req_lsu_tag;
`endif

  logic                                     tag_compare_hit;
  logic [L1D_BANK_WAY_NUM-1:0]              tag_compare_hit_per_way;
  // logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]      tag_compare_hit_way_idx;
  logic                                     ld_tlb_hit;
  logic [L1D_BANK_LINE_DATA_SIZE-1:0]       line_data;  // 1. for ld req: lsu_ld_hit_dat; 2. for st req: ls_pipe_l1d_st_req_dat; 3. for amo req: 
  logic [XLEN-1:0]                          amo_st_data; // for amo rs2 data

  rrv64_l1d_req_type_dec_t           req_type_dec;
  logic                              is_evict;

  // logic [       56-1:0 ]           ls_pipe_l1d_ld_req_paddr;
  logic [       L1D_BANK_PADDR_TAG_WIDTH-1:0] ls_pipe_l1d_req_tag;
  logic [L1D_BANK_SET_INDEX_WIDTH-1:0    ] ls_pipe_l1d_req_idx;
  logic [       L1D_BANK_OFFSET_WIDTH-1:0   ] ls_pipe_l1d_req_offset;

  // logic [       L1D_STB_DATA_WIDTH-1:0 ] ls_pipe_l1d_st_req_dat;
  logic [     L1D_STB_DATA_WIDTH/8-1:0 ] ls_pipe_l1d_st_req_dat_byte_mask;

  // rrv64_mesi_type_e                     lst_mesi_sta;

  // snoop
  rrv64_l1d_lst_t                   lst_dat; // mesi, cover valid & dirty bit

  logic                             sc_rt_check_succ; // sc
} l1d_pipe_s2_t;

typedef struct packed {
  // stage 1
  l1d_pipe_s1_t s1;
  // stage 2
  l1d_pipe_s2_t s2;
} l1d_pipe_reg_t;

// fencei flush fsm
typedef enum logic [2:0] {
  FLUSH_IDLE,
  FLUSH_PENDING,
  FLUSH_READ_LST,                 // read lst and judge whether need to read data ram
  FLUSH_READ_DATA_RAM_WRITE_LST,  // read data ram if needed, write lst if needed
  FLUSH_ENQUEUE_EVICT_QUEUE,      // put the dirty data into evict queue if needed
  FLUSH_WAIT_EVICT_QUEUE_CLEAN,   // wait for evict queue clear
  FLUSH_FINISH
} l1d_bank_fencei_flush_state_t;

typedef enum logic [2:0] {
  FENCEI_IDLE,
  FENCEI_WAITING_FOR_STB_HSK,
  FENCEI_WAITING_FOR_STB_DONE,
  FENCEI_REQ_TO_BANK,
  FENCEI_WAITING_FOR_BANK_GRANT,
  FENCEI_FINISH
} l1d_fencei_state_t;

// ------------------------------
// store buffer
// st req pipe
typedef struct packed {
    logic [          ROB_TAG_WIDTH-1:0] rob_tag;
    logic [         PREG_TAG_WIDTH-1:0] prd;
    logic [           STU_OP_WIDTH-1:0] opcode;
    logic [ L1D_STB_LINE_ADDR_SIZE-1:0] line_paddr;
    logic [     L1D_STB_DATA_WIDTH-1:0] line_data;
    logic [   L1D_STB_DATA_WIDTH/8-1:0] write_byte_mask;
`ifdef RUBY
    logic [     RRV64_LSU_ID_WIDTH-1:0] lsu_tag;
`endif
    // sc
    logic                               sc_rt_check_succ;
    logic [       L1D_OFFSET_WIDTH-1:0] amo_offset; // offset used for amo & lr
  } stb_entry_t;

typedef struct packed {
  // stage 1
  logic [     ROB_TAG_WIDTH-1:0]  rob_tag;
  logic [    PREG_TAG_WIDTH-1:0]  prd;
  logic [      STU_OP_WIDTH-1:0]  opcode;
  logic [       56-1:0]  paddr;
  logic [              XLEN-1:0]  data;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH-1:0]  lsu_tag;
`endif
  
  logic                           stb_hit;
  logic [L1D_STB_ENTRY_NUM-1:0]   stb_hit_entry_mask; // equals to N_STB
  
  // ===== TODO: here only work for 2 input ports ======
  logic                           hit_the_same_cache_line;
  // ===================================================

  // sc
  logic                           sc_rt_check_succ;
} l1d_stb_st_pipe_s1_t;

typedef struct packed {
  // stage 1
  l1d_stb_st_pipe_s1_t s1;
} l1d_stb_st_pipe_reg_t;

// ld req pipe
typedef struct packed {
  // stage 1
  logic [     ROB_TAG_WIDTH-1:0] rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] prd;
  logic [      LDU_OP_WIDTH-1:0] opcode;
  logic                          is_ptw_ld;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif

  logic [L1D_TAG_WIDTH-1:0    ] vtag; // for ld gen ptag when idx+offset<12 // for ptw, it is ptag
  logic [L1D_INDEX_WIDTH-1:0  ] index;
  logic [L1D_OFFSET_WIDTH-1:0 ] offset;
} l1d_stb_ld_pipe_s1_t;

typedef struct packed {
  // stage 2
  logic [     ROB_TAG_WIDTH-1:0] rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] prd;
  logic [      LDU_OP_WIDTH-1:0] opcode;
  logic                          is_ptw_ld;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif
  logic [L1D_OFFSET_WIDTH-1:0 ] offset;

  logic                         stb_hit;
  logic [L1D_STB_ENTRY_NUM-1:0] stb_hit_per_entry; // equals to N_STB
} l1d_stb_ld_pipe_s2_t;

typedef struct packed {
  // stage 1
  l1d_stb_ld_pipe_s1_t s1;
  // stage 2
  l1d_stb_ld_pipe_s2_t s2;
} l1d_stb_ld_pipe_reg_t;

// eviction fsm
typedef enum logic [1:0] {
  IDLE,
  IN_AGE_EVICT,     // stb full; 
  SELECTED_EVICT,   // load partial hit; coherence snoop hit;
  FLUSH             // stb flush (evict all);
} l1d_stb_evict_state_t;

  //------------------------------------------------------
  // MSHR definition
  typedef enum logic [2:0] {
    MSHR_WAIT_WRITE_BACK,
    MSHR_WRITE_BACK,
    MSHR_WAIT_ALLOCATE
  } mshr_state_t;

  typedef struct packed {
    // logic                 valid;

//    tid_t                 tid; // transaction id to the cpu side
    logic [ROB_TAG_WIDTH-1:0]  rob_tag;
    logic [PREG_TAG_WIDTH-1:0] prd;
`ifdef RUBY
    logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif
    
    logic                       rw; // read or write miss
    logic                       flush;
    logic                       no_write_alloc;
    logic [L1D_BANK_PADDR_TAG_WIDTH-1:0]  new_tag; // read addr 
    logic [L1D_BANK_SET_INDEX_WIDTH-1:0]  bank_index; // bank index (index - bank_id)
    logic [L1D_BANK_OFFSET_WIDTH-1:0]     offset;
    
    logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] way_id; // way id // TODO: store after mshr read tag
    logic [L1D_STB_DATA_WIDTH-1:0]      data; // data to write (for write miss)
    logic [L1D_STB_DATA_WIDTH/8-1:0 ]   data_byte_mask;
    rrv64_l1d_req_type_dec_t    req_type_dec;
//    cpu_byte_mask_t       byte_mask; // data read/write mask

    // snoop
    rrv64_mesi_type_e             old_lst_state;

    // amo
    logic [XLEN-1:0]              amo_st_data;
  } mshr_t;

  typedef struct packed {
    // axi bus status
    logic                   waddr;
    logic                   wdata;
  } mshr_mem_state_t;

  // wdata pipeline registers
  // typedef struct packed {
  //   // bank_index_t                            waddr;
  //   // mshr_id_t                               wid;
  //   //logic                                   flush;
  //   logic                                   wvalid;
  //   //logic                                   wlast;
  //   //logic [$clog2(N_WAY)-1:0]               way_id;
  // } wdata_pipe_t;

  typedef struct packed {
    // cache data write pipeline
    logic                                   wvalid;
    // wdata_pipe_t                            wdata_pipe;
    logic [$clog2(BURST_SIZE)-1:0]          wdata_offset;
    //mshr_mem_state_t [N_MSHR-1:0]           mem_state;
    //mem_offset_t rdata_offset;

    // data output pipeline
  //  cpu_resp_t  rdata_pipe;
    // logic       rdata_pipe_valid;
  } mem_fsm_reg_t;

  typedef struct packed {
    mshr_id_t id;
    logic     rw;
    logic     no_write_alloc;
    logic     flush;
    logic     valid;
  } mshr_req_t; // request interface pipeline registers


// ------ mlfb ------// 
  typedef struct packed {
    logic [L1D_BANK_SET_INDEX_WIDTH-1:0] set_idx;
    logic [L1D_BANK_WAY_NUM-1:0] way_idx;
} rrv64_l1d_evict_req_t;

  typedef struct packed {
    logic [L1D_BANK_PADDR_TAG_WIDTH-1:0]      tag;
    logic [L1D_BANK_LINE_DATA_SIZE-1:0]    dat;
    logic [L1D_BANK_SET_INDEX_WIDTH-1:0]  set_idx;
    logic [L1D_BANK_WAY_NUM-1:0]  way_idx;
    rrv64_mesi_type_e                mesi_sta;
    logic                            is_lr;
    logic                            is_ld;

    logic [L1D_BANK_OFFSET_WIDTH-1:0]         offset;
    logic [ROB_TAG_WIDTH-1:0]         rob_tag;
    logic [PREG_TAG_WIDTH-1:0]        prd;
`ifdef RUBY
    logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif
    rrv64_l1d_req_type_dec_t        req_type_dec;
    logic                             ld_no_resp;

    // amo
    logic [XLEN-1:0]              amo_st_data;
  } rrv64_l1d_refill_req_t;





typedef struct packed {
    logic                             valid;
    logic [N_MSHR_W -1:0]       mshr_idx;
    logic                             err;
    rrv64_mesi_type_e                 mesi_sta;

    logic [56-1:0]           paddr;
    logic [ROB_TAG_WIDTH-1:0]         rob_tag;
    logic [PREG_TAG_WIDTH-1:0]        prd;
`ifdef RUBY
    logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif

    logic                             peek_done;
    logic                             check_done;
    logic                             evict_done;
    logic                             refill_done;
//    logic                             stb_dat_done;
    logic  [L1D_BANK_LINE_DATA_SIZE -1:0]   line_dat;
    logic  [L1D_STB_DATA_WIDTH-1:0]       st_dat;
    logic  [L1D_STB_DATA_WIDTH/8-1:0 ]    st_dat_byte_mask;
//    logic                             is_st;
    rrv64_l1d_req_type_dec_t           req_type_dec;
//    logic  [RRV64_L1D_DATA_ECC_W* RRV64_L1D_WAY_N -1:0] dat_ecc_ckbit;
//    logic  [RRV64_L1D_TAG_ECC_W -1:0] tag_ecc_ckbit;
    logic  [L1D_BANK_WAY_NUM -1:0] avail_way_idx;
    logic  [L1D_BANK_WAY_NUM -1:0] victim_way_idx;
    logic                             victim_set_full;
    logic                             victim_way_clean;
//    logic  [RRV64_SCU_SST_IDX_W -1:0] sst_idx;
//    logic                             stb_alloc;
//    logic                             l2_hit;

    logic                             ld_no_resp;
    // amo
    logic [XLEN-1:0]              amo_st_data;
} rrv64_l1d_mlfb_head_buf_t;

typedef struct packed {
  logic [N_MSHR_W-1:0]             mshr_idx;
  logic                            err;
  rrv64_mesi_type_e                mesi_sta;
  // logic [RRV64_SCU_SST_IDX_W-1:0]  sst_idx;
//  logic                            l2_hit;
} rrv64_l1d_mlfb_t;

typedef struct packed {
  logic [PTW_ID_WIDTH-1:0]       id;
  logic [56-1:0 ]       paddr;
} ptw_req_buffer_t;


// ------ snp ctrl ------//
typedef enum logic [3:0] {
  ReadShared          = 4'b0000,
  ReadClean           = 4'b0001,
  ReadNotSharedDirty  = 4'b0010, // need support
  ReadUnique          = 4'b0111, // need support
  CleanShared         = 4'b1000,
  CleanInvalid        = 4'b1001, // need support
  MakeInvalid         = 4'b1101,
  DVM_Complete        = 4'b1110,
  DVM_Message         = 4'b1111
} ace_acsoop_type_e;

typedef struct packed {
  logic [L1D_STB_LINE_ADDR_SIZE-1:0]   snp_line_addr;
  logic                     snp_leave_invalid;
  logic                     snp_leave_sharedclean;
  logic                     snp_return_clean_data;
  logic                     snp_return_dirty_data;
} snp_req_buf_t;

typedef struct packed {
  snp_req_buf_t   snp_req;

  logic           s1_conflict_check_done;
  // logic         s1_dataless_resp_i; // SnpResp_I

  logic           s2_read_tag_lst_done;
  rrv64_l1d_lst_t s2_lst_dat; // line state per way, read from lst

  logic           s3_rd_data_wr_lst_done;
  logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  s3_tag_compare_match_id;
  logic           s3_data_resp;  // resp with data
  logic           s3_resp_inv;   // SnpResp_I
  logic           s3_resp_sc;    // SnpResp_SC
  logic           s3_resp_pd;    // pass dirty
  logic           s3_was_unique;

  logic           s4_snp_resp_done;
  logic           cr_hsk_done;
  logic           cd_hsk_done;
  logic [L1D_BANK_LINE_DATA_SIZE-1:0] cd_data_hold; // if cd channel not hsk immediately, buffer the data
  } snp_req_head_buf_t;

typedef struct packed {
  logic                                            s1_st_req_tag_hit;      // s0_1
  logic                                            s1_valid;               // s0_2 pipeline s1 vld
  logic                                            s2_valid;               // s0_2 pipeline s2 vld
  l1d_pipe_reg_t                                   cur;                    // s0_2 pipeline
  logic  [L1D_BANK_PADDR_TAG_WIDTH-1:0]            s1_tag_used_to_compare; // s0_2 pipeline for vipt s1 ptag
  logic  [N_MSHR-1:0]                              mshr_bank_valid;        // s0_2 mshr vld
  logic  [N_MSHR-1:0]                              mshr_bank_sent;         // s0_2 mshr sent
  mshr_t [N_MSHR-1:0]                              mshr_bank;              // s0_2 mshr
  logic  [N_EWRQ-1:0]                              ewrq_vld;               // s0_2 ewrq
  logic  [N_EWRQ-1:0][L1D_BANK_LINE_ADDR_SIZE-1:0] ewrq_addr;              // s0_2 addr
} snp_l1d_bank_snp_s0_t;

typedef struct packed {
  rrv64_l1d_lst_t               lst_dat; // line state per way, read from lst
} snp_l1d_bank_snp_s1_t;

typedef struct packed {
  logic [L1D_BANK_WAY_NUM-1:0]  tag_compare_result_per_way;
} snp_l1d_bank_snp_s2_t;

endpackage
`endif // __RVH_L1D_PKG_SV__
