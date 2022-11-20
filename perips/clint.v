`include "perips_cfg.vh"

module clint(
    `ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
    `endif
    input clk,
    input rst,
    output clint_core_mtmr_irq_o,
    output clint_core_stmr_irq_o,
    output 	clint_core_msoft_irq_o,
    output 	clint_core_ssoft_irq_o,
    input wbm_clint_cyc_i,
    input wbm_clint_stb_i,
    input [`WB_AD_WIDTH-1:0] wbm_clint_addr_i,
    input [`WB_DAT_WIDTH-1:0] wbm_clint_wdata_i,
    input [(`WB_DAT_WIDTH/8)-1:0]wbm_clint_sel_i,
    input wbm_clint_we_i,
    output [`WB_DAT_WIDTH-1:0] clint_wbm_rdata_o,
    output clint_wbm_ack_o
);
reg [63:0] mtime;
reg [63:0] next_mtime;
reg [63:0] stime;
reg [63:0] next_stime;
reg msip;
reg ssip;
reg next_msip;
reg next_ssip;
reg [63:0] mtimecmp;
reg [63:0] next_mtimecmp;
reg [63:0] stimecmp;
reg [63:0] next_stimecmp;
reg ack_ff;
reg next_ack_ff;
reg [`WB_DAT_WIDTH-1:0] rdata;

always @(posedge clk) begin
    if(rst) begin
        mtime <= 64'b0;
        mtimecmp <= 32'h0000_ffff; //default situation: not trigger interrupt
        msip <= 64'b0;
        stime <= 64'b0;
        stimecmp <= 32'h0000_ffff;
        ssip <= 64'b0;
        ack_ff <= 1'b0;
    end
    else begin
        mtime <= next_mtime;
        mtimecmp <= next_mtimecmp;
        msip <= next_msip;
        stime <= next_stime;
        stimecmp <= next_stimecmp;
        ssip <= next_ssip;
        ack_ff <= next_ack_ff;
    end
end

assign clint_wbm_rdata_o = rdata;

always @(*) begin
    next_msip = msip;
    next_mtime = mtime + 'b1;
    next_mtimecmp = mtimecmp;
    next_ssip = ssip;
    next_stime = stime + 'b1;
    next_stimecmp = stimecmp;
    next_ack_ff = 'b0;
    rdata = 'b0;
    if(wbm_clint_stb_i && wbm_clint_cyc_i && !ack_ff) begin
        if(wbm_clint_we_i) begin
            case(wbm_clint_addr_i)
                `MTIMECMP_ADDR:begin
                    next_mtimecmp = {mtimecmp[63:32], wbm_clint_wdata_i};
                    next_ack_ff = 1'b1;
                end
                `MTIMECMP_ADDR+32'd4:begin
                    next_mtimecmp = {wbm_clint_wdata_i, mtimecmp[31:0]};
                    next_ack_ff = 1'b1;
                end
                `MSIP_ADDR:begin
                    next_msip = wbm_clint_wdata_i[0];
                    next_ack_ff = 1'b1;
                end
                `MTIME_ADDR:begin
                    next_mtime = {mtime[63:32], wbm_clint_wdata_i};
                    next_ack_ff = 1'b1;
                end
                `MTIME_ADDR+32'd4:begin
                    next_mtime = {wbm_clint_wdata_i, mtime[31:0]};
                    next_ack_ff = 1'b1;
                end
                `STIMECMP_ADDR:begin
                    next_stimecmp = {stimecmp[63:32], wbm_clint_wdata_i};
                    next_ack_ff = 1'b1;
                end
                `STIMECMP_ADDR+32'd4:begin
                    next_stimecmp = {wbm_clint_wdata_i, stimecmp[31:0]};
                    next_ack_ff = 1'b1;
                end
                `SSIP_ADDR:begin
                    next_ssip = wbm_clint_wdata_i[0];
                    next_ack_ff = 1'b1;
                end
                `STIME_ADDR:begin
                    next_stime = {stime[63:32], wbm_clint_wdata_i};
                    next_ack_ff = 1'b1;
                end
                `STIME_ADDR+32'd4:begin
                    next_stime = {wbm_clint_wdata_i, stime[31:0]};
                    next_ack_ff = 1'b1;
                end
                default: begin
                end
            endcase
        end else begin
            case(wbm_clint_addr_i)
                `MTIMECMP_ADDR:begin
                    rdata = mtimecmp[31:0];
                    next_ack_ff = 1'b1;
                end
                `MTIMECMP_ADDR+32'd4:begin
                    rdata = mtimecmp[63:32];
                    next_ack_ff = 1'b1;
                end
                `MSIP_ADDR:begin
                    rdata = {{31{1'b0}}, msip};
                    next_ack_ff = 1'b1;
                end
                `MTIME_ADDR:begin
                    rdata = mtime[31:0];
                    next_ack_ff = 1'b1;
                end
                `MTIME_ADDR+32'd4:begin
                    rdata = mtime[63:32];
                    next_ack_ff = 1'b1;
                end
                `STIMECMP_ADDR:begin
                    rdata = stimecmp[31:0];
                    next_ack_ff = 1'b1;
                end
                `STIMECMP_ADDR+32'd4:begin
                    rdata = stimecmp[63:32];
                    next_ack_ff = 1'b1;
                end
                `SSIP_ADDR:begin
                    rdata = {{31{1'b0}}, ssip};
                    next_ack_ff = 1'b1;
                end
                `STIME_ADDR:begin
                    rdata = stime[31:0];
                    next_ack_ff = 1'b1;
                end
                `STIME_ADDR+32'd4:begin
                    rdata = stime[63:32];
                    next_ack_ff = 1'b1;
                end
                default: begin
                end
            endcase
        end
    end
end


assign clint_core_msoft_irq_o = msip;
assign clint_core_mtmr_irq_o = (mtime >= mtimecmp);
assign clint_core_ssoft_irq_o = ssip;
assign clint_core_stmr_irq_o = (stime >= stimecmp);
assign clint_wbm_ack_o = wbm_clint_cyc_i & ack_ff;

endmodule

