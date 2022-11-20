module crg(
    input global_clk,
    input global_rst,
    input wbm_crg_cyc_i,
    input wbm_crg_stb_i,
    input [`WB_AD_WIDTH-1:0] wbm_crg_addr_i,
    input [`WB_DAT_WIDTH-1:0] wbm_crg_wdata_i,
    input [(`WB_DAT_WIDTH/8)-1:0]wbm_crg_sel_i,
    input wbm_crg_we_i,
    output [`WB_DAT_WIDTH-1:0] crg_wbm_rdata_o,
    output crg_wbm_ack_o,
    // hehe, cache, clint, plic
    output domain1_clk_o,
    output domain1_rst_o,
    //uart
    output domain2_clk_o,
    output domain2_rst_o,
    //gpio
    output domain3_clk_o,
    output domain3_rst_o,
    //ebi
    output domain4_clk_o,
    output domain4_rst_o
);

reg domain1_clk_en, domain2_clk_en, domain3_clk_en, domain4_clk_en;
reg clk1_latch, clk2_latch, clk3_latch, clk4_latch;
always @(*) begin  //use latch to remove glitch
    if (!global_clk) begin
    clk1_latch = domain1_clk_en;
    clk2_latch = domain2_clk_en;
    clk3_latch = domain3_clk_en;
    clk4_latch = domain4_clk_en;
    end
end

assign domain1_clk_o = global_clk & clk1_latch;
assign domain2_clk_o = global_clk & clk2_latch;
assign domain3_clk_o = global_clk & clk3_latch;
assign domain4_clk_o = global_clk & clk4_latch;


reg domain1_rst_r, domain2_rst_r, domain3_rst_r, domain4_rst_r;
assign domain1_rst_o = domain1_rst_r;
assign domain2_rst_o = domain2_rst_r;
assign domain3_rst_o = domain3_rst_r;
assign domain4_rst_o = domain4_rst_r;
reg ack_ff;

always @(posedge global_clk or negedge global_rst) begin
    if(!global_rst) begin
    domain1_clk_en <= 'b0;
    domain2_clk_en <= 'b0;
    domain3_clk_en <= 'b0;
    domain4_clk_en <= 'b0;
    domain1_rst_r <= 'b1;
    domain2_rst_r <= 'b1;
    domain3_rst_r <= 'b1;
    domain4_rst_r <= 'b1;
    ack_ff <= 'b0;
    end else begin
        if(wbm_crg_stb_i && wbm_crg_stb_i && wbm_crg_addr_i == 'h200_0400) begin
            ack_ff <= 'b1;
            if(wbm_crg_we_i && !ack_ff) begin
                domain1_rst_r <= wbm_crg_wdata_i[4];
                domain2_rst_r <= wbm_crg_wdata_i[5];
                domain3_rst_r <= wbm_crg_wdata_i[6];
                domain4_rst_r <= wbm_crg_wdata_i[7];
                domain1_clk_en <= wbm_crg_wdata_i[0];
                domain2_clk_en <= wbm_crg_wdata_i[1];
                domain3_clk_en <= wbm_crg_wdata_i[2];
                domain4_clk_en <= wbm_crg_wdata_i[3];
            end
        end else begin
            ack_ff <= 'b0;
        end 
    end
end

assign crg_wbm_ack_o = wbm_crg_cyc_i && ack_ff;
assign crg_wbm_rdata_o = {{24{1'b0}}, domain4_rst_r, domain3_rst_r, domain2_rst_r, domain1_rst_r, domain4_clk_en, domain3_clk_en, domain2_clk_en, domain1_clk_en};
endmodule