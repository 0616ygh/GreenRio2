module tb_top;

`ifndef HEX_DIR
`define HEX_DIR "\"haha.hex\""
`endif

`ifndef WAVE_FILE
`define WAVE_FILE "\"waves.fsdb\""
`endif

parameter DRAM_SIZE = 1 << 29; //18;
parameter DRAM_AXI_DATA_WIDTH = 128;
parameter DRAM_INDEX_NUM = DRAM_SIZE/(DRAM_AXI_DATA_WIDTH/8);
parameter DRAM_INDEX_WIDTH = $clog2(DRAM_INDEX_NUM);
parameter PERIOD = 20;
parameter SIMU_TIME = 10000;

logic                                           clk;
logic                                           rst;
//fetch
logic                                           ft2l1i_if_req_rdy_i;
logic                                           l1i2ft_if_resp_vld_i;
logic [$clog2(IFQ_DEPTH)-1:0]                   l1i2ft_if_resp_if_tag_i;
logic [FETCH_WIDTH-1:0]                         l1i2ft_if_resp_data_i;
logic                                           ft2l1i_if_req_vld_o;
logic [L1I_INDEX_WIDTH-1:0]                     ft2l1i_if_req_index_o;
logic [$clog2(IFQ_DEPTH)-1:0]                   ft2l1i_if_req_if_tag_o;
logic [L1I_OFFSET_WIDTH-1:0]                    ft2l1i_if_req_offset_o;
logic [L1I_TAG_WIDTH-1:0]                       ft2l1i_if_req_vtag_o;
logic                                           itlb2ft_miss_i;
logic                                           itlb2ft_hit_i;
logic                                           ft2itlb_req_vld_o;
logic                                           itlb_fetch_resp_excp_vld_i;
logic [EXCEPTION_CAUSE_WIDTH-1:0]               itlb_fetch_resp_ecause_i;

//decode
logic                                           msip_i;
logic                                           ssip_i;
logic                                           mtip_i;
logic                                           stip_i;
logic                                           eip_i;

//fu
    //fu<->tlb
logic                                           dtlb2fu_lsu_exception_vld_i;
logic [EXCEPTION_CAUSE_WIDTH - 1 : 0]           dtlb2fu_lsu_ecause_i;
logic [PMP_ACCESS_TYPE_WIDTH - 1 : 0]           fu2dtlb_lsu_iss_type_o;
logic                                           dtlb2fu_lsu_rdy_i;
logic                                           dtlb2fu_lsu_vld_i; // should be the lsu_dtlb_iss_vld_o in last cycle
logic                                           dtlb2fu_lsu_hit_i;
logic [PHYSICAL_ADDR_TAG_LEN - 1 : 0]           dtlb2fu_lsu_ptag_i;
// logic [VIRTUAL_ADDR_TAG_LEN - 1 : 0]            dtlb2fu_lsu_vtag_i;
logic                                           fu2dtlb_lsu_iss_vld_o;
logic [VIRTUAL_ADDR_TAG_LEN - 1 : 0]            fu2dtlb_lsu_iss_vtag_o;

    //fu<->l1d cache
logic                                           l1d2fu_lsu_ld_req_rdy_i;
logic                                           fu2l1d_lsu_ld_req_vld_o;
logic  [     ROB_INDEX_WIDTH - 1 : 0]           fu2l1d_lsu_ld_req_rob_index_o;
logic  [    PHY_REG_ADDR_WIDTH - 1 : 0]         fu2l1d_lsu_ld_req_rd_addr_o; // no need
logic  [      LDU_OP_WIDTH - 1 : 0]             fu2l1d_lsu_ld_req_opcode_o;
logic  [       ADDR_INDEX_LEN - 1 : 0]          fu2l1d_lsu_ld_req_index_o; 
logic  [      ADDR_OFFSET_LEN - 1 : 0]          fu2l1d_lsu_ld_req_offset_o;
logic  [     VIRTUAL_ADDR_TAG_LEN -1 : 0]       fu2l1d_lsu_ld_req_vtag_o; 
logic                                           l1d2fu_lsu_st_req_rdy_i;
logic                                           fu2l1d_lsu_st_req_vld_o;
logic                                           fu2l1d_lsu_st_req_is_fence_o;
logic   [     ROB_INDEX_WIDTH - 1 : 0]          fu2l1d_lsu_st_req_rob_index_o;
logic   [    PHY_REG_ADDR_WIDTH - 1 : 0]        fu2l1d_lsu_st_req_rd_addr_o;
logic   [      STU_OP_WIDTH - 1 : 0]            fu2l1d_lsu_st_req_opcode_o;
logic   [       PHYSICAL_ADDR_LEN - 1 : 0]      fu2l1d_lsu_st_req_paddr_o; 
logic   [              XLEN - 1 : 0]            fu2l1d_lsu_st_req_data_o;

logic                                           l1d2fu_lsu_ld_replay_vld_i;

logic [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT - 1 : 0]                                  l1d2fu_lsu_wb_vld_i;
logic [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT) * ROB_INDEX_WIDTH - 1 : 0]                l1d2fu_lsu_wb_rob_index_i;
logic                                           l1d2fu_lsu_prf_wb_vld_i;
logic [PHY_REG_ADDR_WIDTH - 1 : 0]              l1d2fu_lsu_prf_wb_rd_addr_i;
logic [XLEN - 1 : 0]                            l1d2fu_lsu_prf_wb_data_i;
logic                                           fu2l1d_lsu_kill_req_o;

`ifdef DPRAM64_2R1W
logic [XLEN/8-1:0] 		                           we,we_real;
logic [XLEN-1:0] 		                           din;
logic [PHYSICAL_ADDR_LEN-1:0]                      waddr;
logic [PHYSICAL_ADDR_LEN-1:0]                      raddr_d;
logic [1:0]                                        re_d;
logic                                              runsigned_d;  
logic  [     ROB_INDEX_WIDTH - 1 : 0]              wrob_index_d;
logic  [    PHY_REG_ADDR_WIDTH - 1 : 0]            wrd_addr_d;     
logic  [     ROB_INDEX_WIDTH - 1 : 0]              rrob_index_d;
logic  [    PHY_REG_ADDR_WIDTH - 1 : 0]            rrd_addr_d;     
`endif // DPRAM64_2R1W
    //fu <-> wb bus
logic                                           fu2wb_lsu_cyc_o;
logic                                           fu2wb_lsu_stb_o;
logic                                           fu2wb_lsu_we_o;
logic [PHYSICAL_ADDR_LEN - 1 : 0]               fu2wb_lsu_adr_o;
logic [WB_DATA_LEN-1:0]                         fu2wb_lsu_dat_o;
logic [WB_DATA_LEN/8-1:0]                       fu2wb_lsu_sel_o;
logic                                           wb2fu_lsu_ack_i;
logic [WB_DATA_LEN -1:0]                        wb2fu_lsu_dat_i;

    //fu <-> pmp
logic                                           fu2pmp_csru_cfg_vld_o;
logic    [PMPCFG_ID_WIDTH-1:0]                  fu2pmp_csru_cfg_addr_o;
logic    [XLEN-1:0]                             fu2pmp_csru_cfg_payload_o;
logic    [XLEN-1:0]                             pmp2fu_csru_cfg_origin_payload_i;
logic                                           fu2pmp_csru_addr_vld_o;
logic    [PMPADDR_ID_WIDTH-1:0]                 fu2pmp_csru_addr_addr_o;
logic    [XLEN-1:0]                             fu2pmp_csru_addr_payload_o;
logic    [XLEN-1:0]                             pmp2fu_csru_addr_origin_payload_i;

// csr_regfile to mmu
logic    [XLEN - 1 : 0]                         satp_o;
logic    [XLEN - 1 : 0]                         mstatus_o;

logic st_vld_1_delay    ;
logic ld_vld_1_delay    ;
logic [ROB_INDEX_WIDTH - 1 : 0] wrob_index_1_delay;
logic [ROB_INDEX_WIDTH - 1 : 0] rrob_index_1_delay;
logic [PHY_REG_ADDR_WIDTH - 1 : 0] rrd_addr_1_delay;

logic st_vld_2_delay    ;
logic ld_vld_2_delay    ;
logic [ROB_INDEX_WIDTH - 1 : 0] wrob_index_2_delay;
logic [ROB_INDEX_WIDTH - 1 : 0] rrob_index_2_delay;
logic [PHY_REG_ADDR_WIDTH - 1 : 0] rrd_addr_2_delay;
logic [XLEN-1:0] dram_rdata_d_2_delay;

logic st_vld_3_delay    ;
logic ld_vld_3_delay    ;
logic [ROB_INDEX_WIDTH - 1 : 0] wrob_index_3_delay;
logic [ROB_INDEX_WIDTH - 1 : 0] rrob_index_3_delay;
logic [PHY_REG_ADDR_WIDTH - 1 : 0] rrd_addr_3_delay;
logic [XLEN-1:0] dram_rdata_d_3_delay;

logic ld_vld_4_delay;
logic [ROB_INDEX_WIDTH - 1 : 0] wrob_index_4_delay;
logic [ROB_INDEX_WIDTH - 1 : 0] rrob_index_4_delay;
logic [PHY_REG_ADDR_WIDTH - 1 : 0] rrd_addr_4_delay  ;

wire [XLEN-1:0] dram_wdata     ;
wire [128-1:0] dram_rdata_i     ;
wire [XLEN-1:0] dram_rdata_d     ;
wire [PHYSICAL_ADDR_LEN-1:0] dram_waddr  ;
wire [PHYSICAL_ADDR_LEN-1:0] dram_raddr_i  ;
wire [PHYSICAL_ADDR_LEN-1:0] dram_raddr_d  ;

logic [1:0] re_d_1_delay        ;
logic runsigned_d_1_delay ;
logic [PHYSICAL_ADDR_LEN-1:0] raddr_d_1_delay    ; 

logic [1:0] re_d_2_delay        ;
logic runsigned_d_2_delay ;
logic [PHYSICAL_ADDR_LEN-1:0] raddr_d_2_delay     ;

logic [1:0] re_d_3_delay        ;
logic runsigned_d_3_delay ;
logic [PHYSICAL_ADDR_LEN-1:0] raddr_d_3_delay     ;

logic st_fence_vld_1_delay;
logic st_fence_vld_2_delay;
logic st_fence_vld_3_delay;

always #(PERIOD/2) clk = ~clk; 

import "DPI-C" function void init_cosim();

// simulation lenth
logic mid = 0;
integer co_sim_fd;
integer run_test_fd;
integer co_sim_haha_fd;
int queue[47];
logic signal;
initial begin 
    init_cosim();
    `ifdef HAHA
    co_sim_haha_fd = $fopen("./co_sim_haha.log", "w");
    `endif
    co_sim_fd = $fopen("./co_sim.log", "w");
    run_test_fd = $fopen("./all_test.log", "a+");
    signal = 0;
    clk = 0;
    rst = 1;
    l1d2fu_lsu_wb_vld_i = 0;
    msip_i = 0;
    ssip_i = 0;
    mtip_i = 0;
    stip_i = 0;
    eip_i  = 0;
    #40
    @(negedge clk)
    rst = 0;
    // # 100000;
    // # 1000000;
    #100000000;
    $fdisplay(run_test_fd, "%s simulation terminated", `HEX_DIR);    
    `ifdef HAHA
    $fclose(co_sim_haha_fd);
    `endif
    $fclose(co_sim_fd);
    $fclose(run_test_fd);
    $display ("%s",`HEX_DIR);
    $display ("simulation terminated");
    $finish;
end

logic [PC_WIDTH-1:0] dram_waddr_3_delay, dram_waddr_2_delay, dram_waddr_1_delay;
logic [XLEN-1:0] dram_wdata_3_delay, dram_wdata_2_delay, dram_wdata_1_delay;
logic [XLEN/8-1:0] we_3_delay, we_2_delay, we_1_delay;

logic fromhost;

dpram64_2r1w #(
    .SIZE(DRAM_SIZE)         , // byte
    .AXI_DATA_WIDTH(DRAM_AXI_DATA_WIDTH)   ,
    .mem_clear(1)          ,
    .mem_simple_seq(0)     ,
    .LSU_DATA_WIDTH(XLEN),
    .LSU_ADDR_WIDTH(PHYSICAL_ADDR_LEN),
    .memfile(`HEX_DIR)          
) dram_u (
    .clk(clk)           ,
    .rst(fromhost)       ,
    .we(we_real)       ,
    .din_d((dram_wdata_3_delay))    ,
    .waddr_d(dram_waddr_3_delay-56'h8000_0000)  ,
    .rsize_d(re_d_3_delay)          ,
    .unsign_d(runsigned_d_3_delay)  ,
    .raddr_i((dram_raddr_i-56'h8000_0000))  ,
    .raddr_d((raddr_d_3_delay-56'h8000_0000))       ,
    .dout_i(dram_rdata_i)   ,
    .dout_d(dram_rdata_d)   
);
assign we_real = (we_3_delay == FENCE_WE) ? 0 : (we_3_delay & {8{st_vld_3_delay}});
//RAM <-> fetch
always @(posedge clk) begin
    l1i2ft_if_resp_vld_i <= ft2l1i_if_req_vld_o & !tb_top.core_u.rcu_u.global_speculate_fault;
    itlb2ft_hit_i <= ft2l1i_if_req_vld_o;
end

assign ft2l1i_if_req_rdy_i = 1;
assign dram_raddr_i = {ft2l1i_if_req_vtag_o, ft2l1i_if_req_index_o};
assign l1i2ft_if_resp_data_i = dram_rdata_i;
assign itlb2ft_miss_i = 0;
assign itlb_fetch_resp_excp_vld_i = 0;
assign itlb_fetch_resp_ecause_i = 0;

//RAM <-> lsu
assign l1d2fu_lsu_ld_req_rdy_i = 1;
assign l1d2fu_lsu_st_req_rdy_i = 1;
assign l1d2fu_lsu_ld_replay_vld_i = 0;
assign dtlb2fu_lsu_exception_vld_i = 0;
assign dtlb2fu_lsu_ecause_i = 0;
assign dtlb2fu_lsu_rdy_i = 1;

// dtlb
always @(posedge clk) begin
        dtlb2fu_lsu_vld_i <= fu2dtlb_lsu_iss_vld_o;
        dtlb2fu_lsu_hit_i <= fu2dtlb_lsu_iss_vld_o;
    if (fu2dtlb_lsu_iss_vld_o) begin
        dtlb2fu_lsu_ptag_i <= {{(PHYSICAL_ADDR_LEN-VIRTUAL_ADDR_LEN){1'b0}}, fu2dtlb_lsu_iss_vtag_o};
    end
end

// dcache
// 1-cycle delay
always @(posedge clk) begin
    if (0) begin
        wrob_index_1_delay      <= 0;
        rrob_index_1_delay      <= 0;
        rrd_addr_1_delay        <= 0;
    end else begin
        wrob_index_1_delay      <= wrob_index_d;
        rrob_index_1_delay      <= rrob_index_d;
        rrd_addr_1_delay        <= rrd_addr_d;
    end
end

//load
always @(posedge clk) begin
    if(tb_top.core_u.rcu_u.global_speculate_fault) begin
        ld_vld_1_delay          <= 0;
        re_d_1_delay            <= 0;
        runsigned_d_1_delay     <= 0;
        raddr_d_1_delay         <= 0;
    end else begin
        ld_vld_1_delay          <= fu2l1d_lsu_ld_req_vld_o;
        re_d_1_delay            <= re_d        ;
        runsigned_d_1_delay     <= runsigned_d ;
        raddr_d_1_delay         <= raddr_d     ;
    end
end
        
//store
always @(posedge clk) begin
    st_fence_vld_1_delay <= (fu2l1d_lsu_st_req_opcode_o == STU_FENCE) & fu2l1d_lsu_st_req_vld_o;
    if (0) begin
        st_vld_1_delay          <= 0 ;
        dram_waddr_1_delay      <= 0 ;
        dram_wdata_1_delay      <= 0 ;
        we_1_delay              <= 0 ;
    end else if (fu2l1d_lsu_st_req_opcode_o != STU_FENCE) begin
        st_vld_1_delay          <= fu2l1d_lsu_st_req_vld_o;
        dram_waddr_1_delay      <= waddr;
        dram_wdata_1_delay      <= din;
        we_1_delay              <= we;
    end
end

// 2-cycle delay
always @(posedge clk) begin
    if (0) begin
        wrob_index_2_delay      <= 0 ;
        rrob_index_2_delay      <= 0 ;
        rrd_addr_2_delay        <= 0 ;
    end else begin
        wrob_index_2_delay      <= wrob_index_1_delay  ;
        rrob_index_2_delay      <= rrob_index_1_delay  ;
        rrd_addr_2_delay        <= rrd_addr_1_delay    ;
    end
end

//load
always @(posedge clk) begin
    if(tb_top.core_u.rcu_u.global_speculate_fault) begin
        ld_vld_2_delay          <= 0 ;
        re_d_2_delay            <= 0;
        runsigned_d_2_delay     <= 0;
        raddr_d_2_delay         <= 0;
    end else begin
        ld_vld_2_delay          <= ld_vld_1_delay      ;
        re_d_2_delay            <= re_d_1_delay        ;
        runsigned_d_2_delay     <= runsigned_d_1_delay ;
        raddr_d_2_delay         <= raddr_d_1_delay     ;
    end
end

// store
always @(posedge clk) begin
    st_fence_vld_2_delay <= st_fence_vld_1_delay;
    if (0) begin
        st_vld_2_delay          <= 0 ;
        dram_waddr_2_delay      <= 0 ;
        dram_wdata_2_delay      <= 0 ;
        we_2_delay              <= 0 ;
    end else begin
        st_vld_2_delay          <= st_vld_1_delay      ;
        dram_waddr_2_delay      <= dram_waddr_1_delay  ;
        dram_wdata_2_delay      <= dram_wdata_1_delay  ;
        we_2_delay              <= we_1_delay          ;
    end
end
// 3-cycle delay
always @(posedge clk) begin
    if (0) begin
        wrob_index_3_delay      <= 0;
        rrob_index_3_delay      <= 0;
        rrd_addr_3_delay        <= 0;
    end else begin
        wrob_index_3_delay      <= wrob_index_2_delay  ;
        rrob_index_3_delay      <= rrob_index_2_delay  ;
        rrd_addr_3_delay        <= rrd_addr_2_delay    ;
    end
end

//load
always @(posedge clk) begin
    if(tb_top.core_u.rcu_u.global_speculate_fault | fu2l1d_lsu_kill_req_o) begin
        ld_vld_3_delay          <= 0;
        re_d_3_delay            <= 0;
        runsigned_d_3_delay     <= 0;
        raddr_d_3_delay         <= 0;
    end else begin
        ld_vld_3_delay          <= ld_vld_2_delay      ;
        re_d_3_delay            <= re_d_2_delay        ;
        runsigned_d_3_delay     <= runsigned_d_2_delay ;
        raddr_d_3_delay         <= raddr_d_2_delay     ;
    end
end

//store
always @(posedge clk) begin
    st_fence_vld_3_delay <= st_fence_vld_2_delay;
    if (fu2l1d_lsu_kill_req_o) begin
        st_vld_3_delay          <= 0;
        dram_waddr_3_delay      <= 0;
        dram_wdata_3_delay      <= 0;
        we_3_delay              <= 0;
    end else begin
        st_vld_3_delay          <= st_vld_2_delay;
        dram_waddr_3_delay      <= dram_waddr_2_delay;
        dram_wdata_3_delay      <= dram_wdata_2_delay;
        we_3_delay              <= we_2_delay;
    end
end

// 4-cycle delay
always @(posedge clk) begin
    if (0) begin
        wrob_index_4_delay      <= 0;
        rrob_index_4_delay      <= 0;
        rrd_addr_4_delay        <= 0;
    end else begin
        wrob_index_4_delay      <= wrob_index_3_delay  ;
        rrob_index_4_delay      <= rrob_index_3_delay  ;
        rrd_addr_4_delay        <= rrd_addr_3_delay    ;
    end
end

//load
always @(posedge clk) begin
    if(tb_top.core_u.rcu_u.global_speculate_fault) begin
        ld_vld_4_delay          <= 0;
    end else begin
        ld_vld_4_delay          <= ld_vld_3_delay      ;
    end
end

// back to lsu
always @(posedge clk) begin
    if (0) begin
        l1d2fu_lsu_wb_rob_index_i <= 0;
        l1d2fu_lsu_wb_vld_i <= 0;
        l1d2fu_lsu_prf_wb_vld_i <= 0;
        l1d2fu_lsu_prf_wb_rd_addr_i <= 0;
        l1d2fu_lsu_prf_wb_data_i <= 0;
    end else begin
        l1d2fu_lsu_wb_vld_i[2] <= st_vld_3_delay | st_fence_vld_3_delay;
        l1d2fu_lsu_wb_vld_i[0] <= ld_vld_4_delay & !tb_top.core_u.rcu_u.global_speculate_fault;
        l1d2fu_lsu_prf_wb_vld_i <= ld_vld_4_delay & !tb_top.core_u.rcu_u.global_speculate_fault;
        if (st_vld_3_delay | st_fence_vld_3_delay) begin
            l1d2fu_lsu_wb_rob_index_i[ROB_INDEX_WIDTH*3 - 1 : ROB_INDEX_WIDTH*2] <= wrob_index_3_delay;
        end else begin
            l1d2fu_lsu_wb_rob_index_i[ROB_INDEX_WIDTH*3 - 1 : ROB_INDEX_WIDTH*2] <= 0;
        end
        if (ld_vld_4_delay) begin
            l1d2fu_lsu_wb_rob_index_i[ROB_INDEX_WIDTH - 1 : 0] <= rrob_index_4_delay;
            l1d2fu_lsu_prf_wb_rd_addr_i <= rrd_addr_4_delay;
            l1d2fu_lsu_prf_wb_data_i <= dram_rdata_d;
        end else begin
            l1d2fu_lsu_wb_rob_index_i[ROB_INDEX_WIDTH - 1 : 0] <= 0;
            l1d2fu_lsu_prf_wb_rd_addr_i <= 0;
            l1d2fu_lsu_prf_wb_data_i <= 0;
        end
    end
end

// pmp
assign pmp2fu_csru_cfg_origin_payload_i = 0;
assign pmp2fu_csru_addr_origin_payload_i = 0;

real inst, cycle, ipc;

// to host
always @(posedge clk) begin
    inst = tb_top.core_u.csr_regfile_u.minstret;
    cycle = tb_top.core_u.csr_regfile_u.mcycle;
    ipc = inst/cycle;
    if(((dram_waddr_3_delay == 56'h80001000) && st_vld_3_delay) || ((dram_waddr_3_delay == 56'h80003000) && st_vld_3_delay)) begin //&& valid
        if (dram_wdata_3_delay == 1) begin
            $display("test pass");
            $fwrite(run_test_fd, "%s test pass", `HEX_DIR);
            $fdisplay(run_test_fd, "  inst = %d, cycle = %d, ipc = %f", tb_top.core_u.csr_regfile_u.minstret, tb_top.core_u.csr_regfile_u.mcycle, ipc);
            $finish;
        end
        else begin
            fromhost = 1;
            $display("to host value is: %x", dram_wdata_3_delay);
            // $fwrite(run_test_fd, "%s test failed", `HEX_DIR);
            // $fdisplay(run_test_fd, "  inst = %d, cycle = %d, ipc = %f", tb_top.core_u.csr_regfile_u.minstret, tb_top.core_u.csr_regfile_u.mcycle, ipc);
            // $finish;
        end
    end else begin
        fromhost = 0;
    end
end

// initial begin
//     $monitor ("test_rd_first = %d", tb_top.core_u.rcu_u.test_rd_first);
// end

// always @(posedge clk) begin 
//     for (int i = 0; i < FRLIST_DEPTH; i = i + 1) begin
//         queue[i] = tb_top.core_u.rcu_u.free_list_u.fifo_queue[i];
//     end
//     for (int i = tb_top.core_u.rcu_u.free_list_u.rd_line; i < {tb_top.core_u.rcu_u.free_list_u.fifo_recount ,tb_top.core_u.rcu_u.free_list_u.wr_line}-1; i = i + 1) begin
//         for (int j = i + 1; j < {tb_top.core_u.rcu_u.free_list_u.fifo_recount ,tb_top.core_u.rcu_u.free_list_u.wr_line}; j = j + 1) begin
//             if(queue[j] == queue[i]) begin
//                 if (queue[j] != 0 && queue[i] != 0) begin
//                     signal <= 1;
//                 end
//             end
//         end
//     end
// end

// int n;
// int queue_free[32 + 48];
// logic error;
// logic [PHY_REG_ADDR_WIDTH-1:0] same_name;
// wire [5:0] max_line = {tb_top.core_u.rcu_u.free_list_u.fifo_recount * 6'h2f} + {tb_top.core_u.rcu_u.free_list_u.wr_line}-1;

// always @(posedge clk) begin
//     for (int i = 0; i < 32 + 48 -1; i = i + 1) begin
//         queue_free[i] = 0;
//     end
//     n = 0;
//     error = 0;
//     for (int i = 0; i < 32; i = i + 1) begin
//         queue_free[i] = tb_top.core_u.rcu_u.rename_reg[i];
//     end
//     n = 32;
//     for (int i = tb_top.core_u.rcu_u.free_list_u.rd_line; i <= max_line; i = i + 1) begin
//         if (i >= 47) begin
//             queue_free[n] = tb_top.core_u.rcu_u.free_list_u.fifo_queue[i - 47];
//         end else begin
//             queue_free[n] = tb_top.core_u.rcu_u.free_list_u.fifo_queue[i];
//         end
//         n = n + 1;
//     end
//     for (int i = 0; i < 32 + 48 - 1; i = i + 1) begin
//         for (int j = i + 1; j < 32 + 48; j = j + 1) begin
//             if (queue_free[i] == queue_free[j]) begin
//                 if (queue_free[i] != 0) begin
//                     error = 1;
//                     same_name = queue_free[i];
//                 end
//             end
//         end
//     end
// end


always @(posedge clk) begin
    if (tb_top.core_u.rcu_u.do_rob_commit_first) begin
        $fdisplay (co_sim_fd, "-----");
        $fdisplay (co_sim_fd, "0x%0x", (tb_top.core_u.rcu_u.test_pc_first));
        // $fwrite (co_sim_fd, "p%0x, ", tb_top.core_u.rcu_u.test_prd_first);
        if (tb_top.core_u.rcu_u.test_rd_first != 0) begin
            $fwrite (co_sim_fd, "x%0d <- 0x%x\n", tb_top.core_u.rcu_u.test_rd_first, tb_top.core_u.rcu_u.test_rdata_first);
        end
    end
    if (tb_top.core_u.rcu_u.do_rob_commit_second) begin
        $fdisplay (co_sim_fd, "-----");
        $fdisplay (co_sim_fd, "0x%0x",(tb_top.core_u.rcu_u.test_pc_second));
        // $fwrite (co_sim_fd, "p%0x, ", tb_top.core_u.rcu_u.test_prd_second);
        if (tb_top.core_u.rcu_u.test_rd_second != 0) begin
            $fwrite (co_sim_fd, "x%0d <- 0x%x\n", tb_top.core_u.rcu_u.test_rd_second, tb_top.core_u.rcu_u.test_rdata_second);
        end
    end
end

`ifdef HAHA
always @(posedge clk) begin
    if (tb_top.core_u.rcu_u.do_rob_commit_first & !tb_top.core_u.rcu_u.dff_cmt_miss_delay) begin
        $fdisplay (co_sim_haha_fd, "-----");
        $fdisplay (co_sim_haha_fd, "0x%0x", (tb_top.core_u.rcu_u.test_pc_first));
        // $fwrite (co_sim_haha_fd, "p%0x, ", tb_top.core_u.rcu_u.test_prd_first);
        if (tb_top.core_u.rcu_u.test_rd_first != 0) begin
            $fwrite (co_sim_haha_fd, "x%0d <- 0x%x\n", tb_top.core_u.rcu_u.test_rd_first, tb_top.core_u.rcu_u.test_rdata_first);
        end
    end
    if (tb_top.core_u.rcu_u.do_rob_commit_second & !tb_top.core_u.rcu_u.dff_cmt_miss_delay) begin
        $fdisplay (co_sim_haha_fd, "-----");
        $fdisplay (co_sim_haha_fd, "0x%0x",(tb_top.core_u.rcu_u.test_pc_second));
        // $fwrite (co_sim_haha_fd, "p%0x, ", tb_top.core_u.rcu_u.test_prd_second);
        if (tb_top.core_u.rcu_u.test_rd_second != 0) begin
            $fwrite (co_sim_haha_fd, "x%0d <- 0x%x\n", tb_top.core_u.rcu_u.test_rd_second, tb_top.core_u.rcu_u.test_rdata_second);
        end
    end
end
`endif

core_top core_u(
    .clk(clk),
    .rst(rst),
    .ft2l1i_if_req_rdy_i(ft2l1i_if_req_rdy_i),
    .l1i2ft_if_resp_vld_i(l1i2ft_if_resp_vld_i),
    .l1i2ft_if_resp_if_tag_i(l1i2ft_if_resp_if_tag_i),
    .l1i2ft_if_resp_data_i(l1i2ft_if_resp_data_i),
    .ft2l1i_if_req_vld_o(ft2l1i_if_req_vld_o),
    .ft2l1i_if_req_index_o(ft2l1i_if_req_index_o),
    .ft2l1i_if_req_if_tag_o(ft2l1i_if_req_if_tag_o),
    .ft2l1i_if_req_offset_o(ft2l1i_if_req_offset_o),
    .ft2l1i_if_req_vtag_o(ft2l1i_if_req_vtag_o),
    .itlb2ft_miss_i(itlb2ft_miss_i),
    .itlb2ft_hit_i(itlb2ft_hit_i),
    .ft2itlb_req_vld_o(ft2itlb_req_vld_o),
    .itlb_fetch_resp_excp_vld_i(itlb_fetch_resp_excp_vld_i),
    .itlb_fetch_resp_ecause_i(itlb_fetch_resp_ecause_i),
    .msip_i(msip_i),
    .ssip_i(ssip_i),
    .mtip_i(mtip_i),
    .stip_i(stip_i),
    .eip_i(eip_i),
    .dtlb2fu_lsu_exception_vld_i(dtlb2fu_lsu_exception_vld_i),
    .dtlb2fu_lsu_ecause_i(dtlb2fu_lsu_ecause_i),
    .fu2dtlb_lsu_iss_type_o(fu2dtlb_lsu_iss_type_o),
    .dtlb2fu_lsu_rdy_i(dtlb2fu_lsu_rdy_i),
    .dtlb2fu_lsu_vld_i(dtlb2fu_lsu_vld_i),
    .dtlb2fu_lsu_hit_i(dtlb2fu_lsu_hit_i),
    .dtlb2fu_lsu_ptag_i(dtlb2fu_lsu_ptag_i),
    // .dtlb2fu_lsu_vtag_i(dtlb2fu_lsu_vtag_i),
    .fu2dtlb_lsu_iss_vld_o(fu2dtlb_lsu_iss_vld_o),
    .fu2dtlb_lsu_iss_vtag_o(fu2dtlb_lsu_iss_vtag_o),
    .l1d2fu_lsu_ld_req_rdy_i(l1d2fu_lsu_ld_req_rdy_i),
    .fu2l1d_lsu_ld_req_vld_o(fu2l1d_lsu_ld_req_vld_o),
    .fu2l1d_lsu_ld_req_rob_index_o(fu2l1d_lsu_ld_req_rob_index_o),
    .fu2l1d_lsu_ld_req_rd_addr_o(fu2l1d_lsu_ld_req_rd_addr_o),
    .fu2l1d_lsu_ld_req_opcode_o(fu2l1d_lsu_ld_req_opcode_o),
    .fu2l1d_lsu_ld_req_index_o(fu2l1d_lsu_ld_req_index_o), 
    .fu2l1d_lsu_ld_req_offset_o(fu2l1d_lsu_ld_req_offset_o),
    .fu2l1d_lsu_ld_req_vtag_o(fu2l1d_lsu_ld_req_vtag_o), 
    .l1d2fu_lsu_st_req_rdy_i(l1d2fu_lsu_st_req_rdy_i),
    .fu2l1d_lsu_st_req_vld_o(fu2l1d_lsu_st_req_vld_o),
    .fu2l1d_lsu_st_req_is_fence_o(fu2l1d_lsu_st_req_is_fence_o),
    .fu2l1d_lsu_st_req_rob_index_o(fu2l1d_lsu_st_req_rob_index_o),
    .fu2l1d_lsu_st_req_rd_addr_o(fu2l1d_lsu_st_req_rd_addr_o),
    .fu2l1d_lsu_st_req_opcode_o(fu2l1d_lsu_st_req_opcode_o),
    .fu2l1d_lsu_st_req_paddr_o(fu2l1d_lsu_st_req_paddr_o), 
    .fu2l1d_lsu_st_req_data_o(fu2l1d_lsu_st_req_data_o),
    .l1d2fu_lsu_ld_replay_vld_i(l1d2fu_lsu_ld_replay_vld_i),
    .l1d2fu_lsu_wb_vld_i(l1d2fu_lsu_wb_vld_i),
    .l1d2fu_lsu_wb_rob_index_i(l1d2fu_lsu_wb_rob_index_i),
    .l1d2fu_lsu_prf_wb_vld_i(l1d2fu_lsu_prf_wb_vld_i),
    .l1d2fu_lsu_prf_wb_rd_addr_i(l1d2fu_lsu_prf_wb_rd_addr_i),
    .l1d2fu_lsu_prf_wb_data_i(l1d2fu_lsu_prf_wb_data_i),
    .fu2l1d_lsu_kill_req_o(fu2l1d_lsu_kill_req_o),
    `ifdef DPRAM64_2R1W
    .we(we),
    .din(din),
    .waddr(waddr),
    .raddr_d(raddr_d),
    .re_d(re_d),
    .runsigned_d(runsigned_d),  
    .wrob_index_d(wrob_index_d),
    .wrd_addr_d(wrd_addr_d),    
    .rrob_index_d(rrob_index_d),
    .rrd_addr_d(rrd_addr_d),    
    `endif // DPRAM64_2R1W
    .fu2wb_lsu_cyc_o(fu2wb_lsu_cyc_o),
    .fu2wb_lsu_stb_o(fu2wb_lsu_stb_o),
    .fu2wb_lsu_we_o(fu2wb_lsu_we_o),
    .fu2wb_lsu_adr_o(fu2wb_lsu_adr_o),
    .fu2wb_lsu_dat_o(fu2wb_lsu_dat_o),
    .fu2wb_lsu_sel_o(fu2wb_lsu_sel_o),
    .wb2fu_lsu_ack_i(wb2fu_lsu_ack_i),
    .wb2fu_lsu_dat_i(wb2fu_lsu_dat_i),
    .fu2pmp_csru_cfg_vld_o(fu2pmp_csru_cfg_vld_o),
    .fu2pmp_csru_cfg_addr_o(fu2pmp_csru_cfg_addr_o),
    .fu2pmp_csru_cfg_payload_o(fu2pmp_csru_cfg_payload_o),
    .pmp2fu_csru_cfg_origin_payload_i(pmp2fu_csru_cfg_origin_payload_i),
    .fu2pmp_csru_addr_vld_o(fu2pmp_csru_addr_vld_o),
    .fu2pmp_csru_addr_addr_o(fu2pmp_csru_addr_addr_o),
    .fu2pmp_csru_addr_payload_o(fu2pmp_csru_addr_payload_o),
    .pmp2fu_csru_addr_origin_payload_i(pmp2fu_csru_addr_origin_payload_i),
    .satp_o(satp_o),
    .mstatus_o(mstatus_o)
);

// wave log
initial begin
    int dumpon = 0;
    string log;
    string wav;
    $value$plusargs("dumpon=%d",dumpon);
    if ($value$plusargs("sim_log=%s",log)) begin
        $display("wave_log= %s",log);
    end
    wav = {`WAVE_FILE};
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

endmodule
