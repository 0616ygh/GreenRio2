module rvh_l1d_plru (
	clk,
	rstn,
	upd_en_hit,
	upd_set_idx_hit,
	upd_way_idx_hit,
	rd_en_refill,
	rd_idx_refill,
	rd_dat_refill
);
	parameter entry_num = 32;
	parameter entry_idx = $clog2(entry_num);
	parameter way_num = 4;
	parameter way_num_idx = $clog2(way_num);
	input clk;
	input rstn;
	input upd_en_hit;
	input [entry_idx - 1:0] upd_set_idx_hit;
	input [way_num_idx - 1:0] upd_way_idx_hit;
	input rd_en_refill;
	input [entry_idx - 1:0] rd_idx_refill;
	output wire [way_num_idx - 1:0] rd_dat_refill;
	localparam lru_entry_w = way_num - 1;
	wire [(entry_num * lru_entry_w) - 1:0] lru_sta;
	wire [(entry_num * lru_entry_w) - 1:0] lru_sta_nxt;
	wire [entry_num - 1:0] lru_sta_ena;
	wire [lru_entry_w - 1:0] lru_sta_old_hit;
	wire [lru_entry_w - 1:0] lru_sta_old_refill;
	wire [lru_entry_w - 1:0] lru_sta_nxt_hit;
	wire [lru_entry_w - 1:0] lru_sta_nxt_refill;
	genvar ii;
	generate
		for (ii = 0; ii < entry_num; ii = ii + 1) begin : GEN_LRU
			assign lru_sta_nxt[ii * lru_entry_w+:lru_entry_w] = (upd_en_hit ? lru_sta_nxt_hit : lru_sta_nxt_refill);
			assign lru_sta_ena[ii] = (upd_en_hit & (upd_set_idx_hit == ii)) | (rd_en_refill & (rd_idx_refill == ii));
			std_dffre #(.WIDTH(lru_entry_w)) U_PLRU(
				.clk(clk),
				.rstn(rstn),
				.en(lru_sta_ena[ii]),
				.d(lru_sta_nxt[ii * lru_entry_w+:lru_entry_w]),
				.q(lru_sta[ii * lru_entry_w+:lru_entry_w])
			);
		end
	endgenerate
	assign lru_sta_old_hit = lru_sta[upd_set_idx_hit * lru_entry_w+:lru_entry_w];
	assign lru_sta_old_refill = lru_sta[rd_idx_refill * lru_entry_w+:lru_entry_w];
	lru_get_new_line #(
		.NCACHELINE(way_num),
		.LRU_W(lru_entry_w)
	) U_LRU_GET_NEW_LINE(
		.old_lru(lru_sta_old_refill),
		.new_lru(lru_sta_nxt_refill),
		.repl_pos(rd_dat_refill)
	);
	lru_update_on_hit #(
		.NCACHELINE(way_num),
		.LRU_W(lru_entry_w)
	) U_LRU_UPDATE_ON_HIT(
		.old_lru(lru_sta_old_hit),
		.hit_pos(upd_way_idx_hit),
		.new_lru(lru_sta_nxt_hit)
	);
endmodule
