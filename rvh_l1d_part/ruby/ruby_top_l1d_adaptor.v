module rubytop_l1d_adaptor (
	clk,
	rst_n,
	top_l1d_req_valid_i,
	top_l1d_req_i,
	top_l1d_req_ready_o,
	top_l1d_resp_valid_o,
	top_l1d_resp_o,
	top_l1d_resp_ready_i,
	ld_l1d_req_valid_o,
	ld_l1d_req_o,
	ld_l1d_req_ready_i,
	ld_l1d_resp_valid_i,
	ld_l1d_resp_i,
	st_l1d_req_valid_o,
	st_l1d_req_o,
	st_l1d_req_ready_i,
	st_l1d_resp_valid_i,
	st_l1d_resp_i,
	l1d_lsu_sleep_valid_i,
	l1d_lsu_sleep_ldq_id_i,
	l1d_lsu_sleep_cache_miss_i,
	l1d_lsu_sleep_mshr_id_i,
	l1d_lsu_sleep_mshr_full_i,
	l1d_lsu_wakeup_cache_refill_valid_i,
	l1d_lsu_wakeup_mshr_id_i,
	l1d_lsu_wakeup_mshr_avail_i
);
	input wire clk;
	input wire rst_n;
	localparam LDQ_PORT_NUM = 2;
	input wire [1:0] top_l1d_req_valid_i;
	localparam rrv64_core_param_pkg_RRV64_INT_PHY_REG_NUM = 64;
	localparam rrv64_core_param_pkg_RRV64_INT_PHY_REG_ADDR_W = 6;
	localparam rrv64_core_param_pkg_RRV64_INT_REG_DATA_W = 64;
	localparam rrv64_core_param_pkg_RRV64_LSU_FIFO_DEPTH = 8;
	localparam rrv64_core_param_pkg_RRV64_LSU_QID_NUM = rrv64_core_param_pkg_RRV64_LSU_FIFO_DEPTH;
	localparam rrv64_core_param_pkg_RRV64_LSU_QID_WIDTH = 3;
	localparam rrv64_core_param_pkg_RRV64_LSU_ID_WIDTH = 6;
	localparam rrv64_core_param_pkg_RRV64_ROB_ENTRY_NUM = 64;
	localparam rrv64_core_param_pkg_RRV64_ROB_ADDR_W = 6;
	localparam rrv64_core_param_pkg_RRV64_L1D_SET_N = 64;
	localparam rrv64_core_param_pkg_RRV64_L1D_SET_IDX_W = 6;
	localparam rrv64_core_param_pkg_RRV64_L1D_TAG_W = 43;
	localparam rrv64_top_param_pkg_RRV64_LINE_OFFSET_W = 6;
	input wire [291:0] top_l1d_req_i;
	output wire [1:0] top_l1d_req_ready_o;
	output wire [1:0] top_l1d_resp_valid_o;
	output wire [177:0] top_l1d_resp_o;
	input wire [1:0] top_l1d_resp_ready_i;
	output wire ld_l1d_req_valid_o;
	output reg [145:0] ld_l1d_req_o;
	input wire ld_l1d_req_ready_i;
	input wire ld_l1d_resp_valid_i;
	input wire [88:0] ld_l1d_resp_i;
	output wire st_l1d_req_valid_o;
	output wire [145:0] st_l1d_req_o;
	input wire st_l1d_req_ready_i;
	input wire st_l1d_resp_valid_i;
	input wire [88:0] st_l1d_resp_i;
	input wire l1d_lsu_sleep_valid_i;
	localparam LDQ_ID_NUM = 32;
	localparam LDQ_ID_NUM_W = 5;
	input wire [4:0] l1d_lsu_sleep_ldq_id_i;
	input wire l1d_lsu_sleep_cache_miss_i;
	localparam rrv64_core_param_pkg_RRV64_L1D_MSHR_D = 4;
	localparam MSHR_ID_NUM_W = 2;
	input wire [1:0] l1d_lsu_sleep_mshr_id_i;
	input wire l1d_lsu_sleep_mshr_full_i;
	input wire l1d_lsu_wakeup_cache_refill_valid_i;
	input wire [1:0] l1d_lsu_wakeup_mshr_id_i;
	input wire l1d_lsu_wakeup_mshr_avail_i;
	genvar ii;
	reg has_state_pending;
	reg has_state_init;
	wire has_state_sent;
	wire has_state_sent_no_change;
	reg has_state_sent_no_ready;
	reg [4:0] ldq_sent_nordy_id;
	reg [4:0] ldq_init_id;
	reg [4:0] ldq_oldest_pending_id;
	localparam LDQ_LD_CNT_W = 32;
	reg [31:0] ld_count_var;
	wire [31:0] ldq_gbl_ld_cnt_d;
	wire [31:0] ldq_gbl_ld_cnt_q;
	localparam LDQ_STATE_W = 3;
	reg [95:0] ldq_state_d;
	wire [95:0] ldq_state_q;
	reg [1023:0] ldq_ld_count_set;
	reg [1023:0] ldq_ld_count_d;
	wire [1023:0] ldq_ld_count_q;
	reg [63:0] ldq_mshr_id_d;
	wire [63:0] ldq_mshr_id_q;
	localparam LDQ_LSU_ID_W = 5;
	reg [159:0] ldq_req_lsu_id_d;
	wire [159:0] ldq_req_lsu_id_q;
	reg [1791:0] ldq_req_addr_d;
	wire [1791:0] ldq_req_addr_q;
	reg [191:0] ldq_req_type_d;
	wire [191:0] ldq_req_type_q;
	reg [31:0] ldq_req_cacheable_d;
	wire [31:0] ldq_req_cacheable_q;
	wire [31:0] ldq_resp_set;
	wire [31:0] ldq_sleep_set;
	wire [31:0] ldq_sent_change_init_set;
	assign st_l1d_req_valid_o = top_l1d_req_valid_i[1];
	assign st_l1d_req_o = top_l1d_req_i[146+:146];
	assign top_l1d_req_ready_o[1] = st_l1d_req_ready_i;
	assign top_l1d_resp_valid_o[1] = st_l1d_resp_valid_i;
	assign top_l1d_resp_o[89+:89] = st_l1d_resp_i;
	assign top_l1d_req_ready_o[0] = has_state_init;
	assign top_l1d_resp_o[0+:89] = ld_l1d_resp_i;
	assign top_l1d_resp_valid_o[0] = ld_l1d_resp_valid_i;
	assign ld_l1d_req_valid_o = (top_l1d_req_valid_i[0] | has_state_pending) | has_state_sent_no_ready;
	always @(*) begin
		ld_l1d_req_o = 1'sb0;
		ld_l1d_req_o[145-:6] = top_l1d_req_i[145-:6];
		ld_l1d_req_o[127-:56] = top_l1d_req_i[127-:56];
		ld_l1d_req_o[133-:6] = top_l1d_req_i[133-:6];
		ld_l1d_req_o[1] = top_l1d_req_i[1];
		if (has_state_pending) begin
			ld_l1d_req_o[145-:6] = ldq_req_lsu_id_q[ldq_oldest_pending_id * 5+:5];
			ld_l1d_req_o[127-:56] = ldq_req_addr_q[ldq_oldest_pending_id * 56+:56];
			ld_l1d_req_o[133-:6] = ldq_req_type_q[ldq_oldest_pending_id * 6+:6];
			ld_l1d_req_o[1] = ldq_req_cacheable_q[ldq_oldest_pending_id];
		end
		if (has_state_sent_no_ready) begin
			ld_l1d_req_o[145-:6] = ldq_req_lsu_id_q[ldq_sent_nordy_id * 5+:5];
			ld_l1d_req_o[127-:56] = ldq_req_addr_q[ldq_sent_nordy_id * 56+:56];
			ld_l1d_req_o[133-:6] = ldq_req_type_q[ldq_sent_nordy_id * 6+:6];
			ld_l1d_req_o[1] = ldq_req_cacheable_q[ldq_sent_nordy_id];
		end
	end
	function automatic [2:0] sv2v_cast_F89C1;
		input reg [2:0] inp;
		sv2v_cast_F89C1 = inp;
	endfunction
	always @(*) begin
		has_state_sent_no_ready = 1'sb0;
		ldq_sent_nordy_id = 1'sb0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < LDQ_ID_NUM; i = i + 1)
				if ((ldq_state_q[i * LDQ_STATE_W+:LDQ_STATE_W] == sv2v_cast_F89C1(3'd3)) && (has_state_sent_no_ready == 1'b0)) begin
					has_state_sent_no_ready = 1'b1;
					ldq_sent_nordy_id = i[4:0];
				end
		end
	end
	always @(*) begin
		has_state_init = 1'sb0;
		ldq_init_id = 1'sb0;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < LDQ_ID_NUM; i = i + 1)
				if ((has_state_init == 1'b0) && (ldq_state_q[i * LDQ_STATE_W+:LDQ_STATE_W] == sv2v_cast_F89C1(3'd0))) begin
					has_state_init = 1'b1;
					ldq_init_id = i[4:0];
				end
		end
	end
	always @(*) begin
		has_state_pending = 1'sb0;
		ldq_oldest_pending_id = 1'sb0;
		ld_count_var = 1'sb0;
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < LDQ_ID_NUM; i = i + 1)
				if (ldq_state_q[i * LDQ_STATE_W+:LDQ_STATE_W] == sv2v_cast_F89C1(3'd1)) begin
					if (ldq_ld_count_q[i * 32+:32] < ld_count_var) begin
						ldq_oldest_pending_id = i[4:0];
						ld_count_var = ldq_ld_count_q[i * 32+:32];
					end
					if (has_state_pending == 1'b0) begin
						has_state_pending = 1'b1;
						ldq_oldest_pending_id = i[4:0];
						ld_count_var = ldq_ld_count_q[i * 32+:32];
					end
				end
		end
	end
	assign ldq_gbl_ld_cnt_d = (ldq_ld_count_set[ldq_init_id * 32+:32] == {32 {1'sb0}} ? ldq_gbl_ld_cnt_q : ldq_ld_count_set[ldq_init_id * 32+:32]);
	std_dffr #(.WIDTH(LDQ_LD_CNT_W)) FF_LDQ_GBL_LD_CNT(
		.clk(clk),
		.rstn(rst_n),
		.d(ldq_gbl_ld_cnt_d),
		.q(ldq_gbl_ld_cnt_q)
	);
	generate
		for (ii = 0; ii < LDQ_ID_NUM; ii = ii + 1) begin : GEN_LDQ_ENTRY
			assign ldq_resp_set[ii] = (ld_l1d_resp_valid_i & (ld_l1d_resp_i[88-:6] == ldq_req_lsu_id_q[ii * 5+:5])) & ~((6'd12 <= ld_l1d_resp_i[76-:6]) & (ld_l1d_resp_i[76-:6] <= 6'd33));
			assign ldq_sleep_set[ii] = l1d_lsu_sleep_valid_i & (l1d_lsu_sleep_ldq_id_i == ldq_req_lsu_id_q[ii * 5+:5]);
			assign ldq_sent_change_init_set[ii] = (ldq_state_q[ii * LDQ_STATE_W+:LDQ_STATE_W] == sv2v_cast_F89C1(3'd2)) & ldq_resp_set[ii];
			always @(*) begin
				ldq_ld_count_set[ii * 32+:32] = 1'sb0;
				ldq_state_d[ii * LDQ_STATE_W+:LDQ_STATE_W] = ldq_state_q[ii * LDQ_STATE_W+:LDQ_STATE_W];
				ldq_ld_count_d[ii * 32+:32] = ldq_ld_count_q[ii * 32+:32];
				ldq_mshr_id_d[ii * 2+:2] = ldq_mshr_id_q[ii * 2+:2];
				ldq_req_addr_d[ii * 56+:56] = ldq_req_addr_q[ii * 56+:56];
				ldq_req_lsu_id_d[ii * 5+:5] = ldq_req_lsu_id_q[ii * 5+:5];
				ldq_req_cacheable_d[ii] = ldq_req_cacheable_q[ii];
				ldq_req_type_d[ii * 6+:6] = ldq_req_type_q[ii * 6+:6];
				if (ldq_state_q[ii * LDQ_STATE_W+:LDQ_STATE_W] == sv2v_cast_F89C1(3'd0)) begin
					if ((ldq_init_id == ii) && top_l1d_req_valid_i[0]) begin
						ldq_state_d[ii * LDQ_STATE_W+:LDQ_STATE_W] = (has_state_pending || has_state_sent_no_ready ? sv2v_cast_F89C1(3'd1) : (ld_l1d_req_ready_i ? sv2v_cast_F89C1(3'd2) : sv2v_cast_F89C1(3'd3)));
						ldq_ld_count_set[ii * 32+:32] = ldq_gbl_ld_cnt_q + 32'sd1;
						ldq_ld_count_d[ii * 32+:32] = ldq_ld_count_set[ii * 32+:32];
						ldq_req_addr_d[ii * 56+:56] = top_l1d_req_i[127-:56];
						ldq_req_lsu_id_d[ii * 5+:5] = top_l1d_req_i[145-:6];
						ldq_req_cacheable_d[ii] = top_l1d_req_i[1];
						ldq_req_type_d[ii * 6+:6] = top_l1d_req_i[133-:6];
					end
				end
				else if (ldq_state_q[ii * LDQ_STATE_W+:LDQ_STATE_W] == sv2v_cast_F89C1(3'd3))
					ldq_state_d[ii * LDQ_STATE_W+:LDQ_STATE_W] = (ld_l1d_req_ready_i ? sv2v_cast_F89C1(3'd2) : sv2v_cast_F89C1(3'd3));
				else if (ldq_state_q[ii * LDQ_STATE_W+:LDQ_STATE_W] == sv2v_cast_F89C1(3'd1)) begin
					if ((ldq_oldest_pending_id == ii) && ~has_state_sent_no_ready)
						ldq_state_d[ii * LDQ_STATE_W+:LDQ_STATE_W] = (ld_l1d_req_ready_i ? sv2v_cast_F89C1(3'd2) : sv2v_cast_F89C1(3'd3));
				end
				else if (ldq_state_q[ii * LDQ_STATE_W+:LDQ_STATE_W] == sv2v_cast_F89C1(3'd2)) begin
					if (ldq_resp_set[ii])
						ldq_state_d[ii * LDQ_STATE_W+:LDQ_STATE_W] = sv2v_cast_F89C1(3'd0);
					else if (ldq_sleep_set[ii])
						if (l1d_lsu_sleep_mshr_full_i)
							ldq_state_d[ii * LDQ_STATE_W+:LDQ_STATE_W] = sv2v_cast_F89C1(3'd5);
						else begin
							ldq_state_d[ii * LDQ_STATE_W+:LDQ_STATE_W] = sv2v_cast_F89C1(3'd4);
							ldq_mshr_id_d[ii * 2+:2] = l1d_lsu_sleep_mshr_id_i;
						end
				end
				else if (ldq_state_q[ii * LDQ_STATE_W+:LDQ_STATE_W] == sv2v_cast_F89C1(3'd4)) begin
					if (l1d_lsu_wakeup_cache_refill_valid_i && (l1d_lsu_wakeup_mshr_id_i == ldq_mshr_id_q[ii * 2+:2]))
						ldq_state_d[ii * LDQ_STATE_W+:LDQ_STATE_W] = sv2v_cast_F89C1(3'd1);
				end
				else if (ldq_state_q[ii * LDQ_STATE_W+:LDQ_STATE_W] == sv2v_cast_F89C1(3'd5))
					if (l1d_lsu_wakeup_mshr_avail_i)
						ldq_state_d[ii * LDQ_STATE_W+:LDQ_STATE_W] = sv2v_cast_F89C1(3'd1);
			end
			std_dffrve #(.WIDTH(LDQ_STATE_W)) FF_LDQ_ENT_STATE(
				.clk(clk),
				.rstn(rst_n),
				.rst_val(sv2v_cast_F89C1(3'd0)),
				.en(1'b1),
				.d(ldq_state_d[ii * LDQ_STATE_W+:LDQ_STATE_W]),
				.q(ldq_state_q[ii * LDQ_STATE_W+:LDQ_STATE_W])
			);
			std_dffr #(.WIDTH(MSHR_ID_NUM_W)) FF_LDQ_ENT_MSHR_ID(
				.clk(clk),
				.rstn(rst_n),
				.d(ldq_mshr_id_d[ii * 2+:2]),
				.q(ldq_mshr_id_q[ii * 2+:2])
			);
			std_dffr #(.WIDTH(LDQ_LD_CNT_W)) FF_LDQ_ENT_LD_CNT(
				.clk(clk),
				.rstn(rst_n),
				.d(ldq_ld_count_d[ii * 32+:32]),
				.q(ldq_ld_count_q[ii * 32+:32])
			);
			std_dffr #(.WIDTH(56)) FF_LDQ_ENT_REQ_ADDR(
				.clk(clk),
				.rstn(rst_n),
				.d(ldq_req_addr_d[ii * 56+:56]),
				.q(ldq_req_addr_q[ii * 56+:56])
			);
			std_dffr #(.WIDTH(LDQ_LSU_ID_W)) FF_LDQ_ENT_REQ_LSU_ID(
				.clk(clk),
				.rstn(rst_n),
				.d(ldq_req_lsu_id_d[ii * 5+:5]),
				.q(ldq_req_lsu_id_q[ii * 5+:5])
			);
			std_dffr #(.WIDTH(1)) FF_LDQ_ENT_REQ_CACHEABLE(
				.clk(clk),
				.rstn(rst_n),
				.d(ldq_req_cacheable_d[ii]),
				.q(ldq_req_cacheable_q[ii])
			);
			std_dffr #(.WIDTH(6)) FF_LDQ_ENT_REQ_TYPE(
				.clk(clk),
				.rstn(rst_n),
				.d(ldq_req_type_d[ii * 6+:6]),
				.q(ldq_req_type_q[ii * 6+:6])
			);
		end
	endgenerate
endmodule
