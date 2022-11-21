`ifdef VERILATOR
`include "params.vh"
`endif
module tb_top(
    input clk,
    input rst
);

parameter DRAM_SIZE = 1 << 29; //18;
parameter DRAM_AXI_DATA_WIDTH = 128;
parameter DRAM_INDEX_NUM = DRAM_SIZE/(DRAM_AXI_DATA_WIDTH/8);
parameter DRAM_INDEX_WIDTH = $clog2(DRAM_INDEX_NUM);
parameter PERIOD = 20;
parameter SIMU_TIME = 10000;

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
logic                          itlb2ic_if_resp_vld_o          ;
logic [         PPN_WIDTH-1:0] itlb2icache_ic_ptag_o          ;
logic                          itlb2ft_resp_excp_vld_o        ;
logic                          itlb_translate_resp_miss_o     ;
logic                          itlb_translate_resp_hit_o      ;

logic  [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_vld_o          ;
logic  [LSU_ADDR_PIPE_COUNT-1:0][         PPN_WIDTH-1:0] dtlb2dcache_lsu_ptag_o         ;
logic  [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_exception_vld_o;
logic  [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_miss_o         ;
logic  [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_hit_o          ;

logic                                               mmu2cache_ptw_walk_req_vld_o ;
logic  [PTW_ID_WIDTH-1:0]                           mmu2cache_ptw_walk_req_id_o  ;
logic  [PADDR_WIDTH-1:0]                            mmu2cache_ptw_walk_req_addr_o;
logic                                               mmu2cache_ptw_walk_req_rdy_i ;

logic                                               mmu2cache_ptw_walk_resp_vld_i;
logic [PTE_WIDTH-1:0]                               mmu2cache_ptw_walk_resp_pte_i;
logic                                               mmu2cache_ptw_walk_resp_rdy_o;

// remain for unuse
logic                                           dtlb2fu_lsu_vld_i; // should be the lsu_dtlb_iss_vld_o in last cycle
logic                                           dtlb2fu_lsu_hit_i;
logic [PHYSICAL_ADDR_TAG_LEN - 1 : 0]           dtlb2fu_lsu_ptag_i;

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

logic                                           lsu_l1d_fencei_flush_vld_o;
logic                                           l1d_lsu_fencei_flush_grant_i;

logic                                           lsu_l1i_fencei_flush_vld_o;
logic                                           l1i_lsu_fencei_flush_grant_i;

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

always @(posedge clk) begin
    if (rst) begin
        msip_i = 0;
        ssip_i = 0;
        mtip_i = 0;
        stip_i = 0;
        eip_i  = 0;
        l1d2fu_lsu_ld_replay_vld_i = 0;
        l1d2fu_lsu_st_req_rdy_i = 1;
        l1d2fu_lsu_ld_req_rdy_i = 1;
        l1d_lsu_fencei_flush_grant_i = 0;
        l1i_lsu_fencei_flush_grant_i = 0;
    end
end

logic [PC_WIDTH-1:0] dram_waddr_3_delay, dram_waddr_2_delay, dram_waddr_1_delay;
logic [XLEN-1:0] dram_wdata_3_delay, dram_wdata_2_delay, dram_wdata_1_delay;
logic [XLEN/8-1:0] we_3_delay, we_2_delay, we_1_delay;

logic fromhost;

logic ft2l1i_if_req_vld_1_delay;
logic [$clog2(IFQ_DEPTH)-1:0] ft2l1i_if_req_if_tag_1_delay;

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
    ft2l1i_if_req_vld_1_delay <= ft2l1i_if_req_vld_o & !tb_top.core_u.rcu_u.global_speculate_fault;
end
always @(posedge clk) begin
    l1i2ft_if_resp_vld_i <= ft2l1i_if_req_vld_1_delay & itlb2ic_if_resp_vld_o & !tb_top.core_u.rcu_u.global_speculate_fault;
    itlb2ft_hit_i <= ft2l1i_if_req_vld_1_delay;
end
assign ft2l1i_if_req_rdy_i = 1;
assign dram_raddr_i = {itlb2icache_ic_ptag_o, ft2l1i_if_req_index_o};
assign l1i2ft_if_resp_data_i = dram_rdata_i;
assign itlb2ft_miss_i = 0;
assign itlb_fetch_resp_excp_vld_i = 0;
assign itlb_fetch_resp_ecause_i = 0;

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
    if (rst) begin
        l1d2fu_lsu_wb_vld_i <= 0;
    end else if (0) begin
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

real inst, cycle, ipc;
logic haha;

always @(posedge clk) begin
    inst = tb_top.core_u.csr_regfile_u.minstret;
    cycle = tb_top.core_u.csr_regfile_u.mcycle;
    ipc = inst/cycle;
    if(rst) begin
        haha = 0;
    end

    if(((dram_waddr_3_delay == 56'h80001000) && st_vld_3_delay) || ((dram_waddr_3_delay == 56'h80003000) && st_vld_3_delay)) begin //&& valid
        if (dram_wdata_3_delay == 1) begin
            $display("test pass");
            $display("%s test pass", `HEX_DIR);
            $display("inst = %d, cycle = %d, ipc = %f", inst, cycle, ipc);
            haha = 1;
            $finish;
        end
        else begin
            fromhost = 1;
            $display("to host value is: %x", dram_wdata_3_delay);
            // $display("%s test failed", `HEX_DIR);
            $display("inst = %d, cycle = %d, ipc = %f", inst, cycle, ipc);
            // $finish;
        end
    end else begin
        fromhost = 0;
    end

    if (haha) begin
        $finish;
    end
end

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

    .msip_i(msip_i),
    .ssip_i(ssip_i),
    .mtip_i(mtip_i),
    .stip_i(stip_i),
    .eip_i(eip_i),
    
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

    .lsu_l1d_fencei_flush_vld_o(lsu_l1d_fencei_flush_vld_o),
    .l1d_lsu_fencei_flush_grant_i(l1d_lsu_fencei_flush_grant_i),

    .lsu_l1i_fencei_flush_vld_o(lsu_l1i_fencei_flush_vld_o),
    .l1i_lsu_fencei_flush_grant_i(l1i_lsu_fencei_flush_grant_i),

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

    .itlb2ic_if_resp_vld_o(itlb2ic_if_resp_vld_o),
    .itlb2icache_ic_ptag_o(itlb2icache_ic_ptag_o),
    .itlb2ft_resp_excp_vld_o(itlb2ft_resp_excp_vld_o),
    .itlb_translate_resp_miss_o(itlb_translate_resp_miss_o),
    .itlb_translate_resp_hit_o(itlb_translate_resp_hit_o),

    .dtlb2dcache_lsu_vld_o(dtlb2dcache_lsu_vld_o),
    .dtlb2dcache_lsu_ptag_o(dtlb2dcache_lsu_ptag_o),
    .dtlb2dcache_lsu_exception_vld_o(dtlb2dcache_lsu_exception_vld_o),
    .dtlb2dcache_lsu_miss_o(dtlb2dcache_lsu_miss_o),
    .dtlb2dcache_lsu_hit_o(dtlb2dcache_lsu_hit_o),
         
    .mmu2cache_ptw_walk_req_vld_o(mmu2cache_ptw_walk_req_vld_o),
    .mmu2cache_ptw_walk_req_id_o(mmu2cache_ptw_walk_req_id_o),
    .mmu2cache_ptw_walk_req_addr_o(mmu2cache_ptw_walk_req_addr_o),
    .mmu2cache_ptw_walk_req_rdy_i(mmu2cache_ptw_walk_req_rdy_i),
    .mmu2cache_ptw_walk_resp_vld_i(mmu2cache_ptw_walk_resp_vld_i),
    .mmu2cache_ptw_walk_resp_pte_i(mmu2cache_ptw_walk_resp_pte_i),
    .mmu2cache_ptw_walk_resp_rdy_o(mmu2cache_ptw_walk_resp_rdy_o)
);

// wave log


endmodule
