module rvh_l1d_bank_axi_arb (
	l1d_bank_axi_arb_arvalid,
	l1d_bank_axi_arb_arready,
	l1d_bank_axi_arb_ar,
	l1d_bank_axi_arb_awvalid,
	l1d_bank_axi_arb_awready,
	l1d_bank_axi_arb_aw,
	l1d_bank_axi_arb_wvalid,
	l1d_bank_axi_arb_wready,
	l1d_bank_axi_arb_w,
	l1d_bank_axi_arb_bvalid,
	l1d_bank_axi_arb_bready,
	l1d_bank_axi_arb_b,
	l1d_bank_axi_arb_rvalid,
	l1d_bank_axi_arb_rready,
	l1d_bank_axi_arb_r,
	axi_arb_l2_arvalid,
	axi_arb_l2_arready,
	axi_arb_l2_ar,
	axi_arb_l2_awvalid,
	axi_arb_l2_awready,
	axi_arb_l2_aw,
	axi_arb_l2_wvalid,
	axi_arb_l2_wready,
	axi_arb_l2_w,
	axi_arb_l2_bvalid,
	axi_arb_l2_bready,
	axi_arb_l2_b,
	axi_arb_l2_rvalid,
	axi_arb_l2_rready,
	axi_arb_l2_r,
	clk,
	rst
);
	localparam [31:0] rvh_pkg_L1D_BANK_COUNT = 1;
	localparam rvh_l1d_pkg_L1D_BANK_ID_NUM = rvh_pkg_L1D_BANK_COUNT;
	parameter INPUT_PORT_NUM = rvh_l1d_pkg_L1D_BANK_ID_NUM;
	parameter INPUT_PORT_NUM_INDEX_WIDTH = $clog2(INPUT_PORT_NUM);
	parameter RESP_PORT_SELECT_BID_LSB = 0;
	input wire [INPUT_PORT_NUM - 1:0] l1d_bank_axi_arb_arvalid;
	output reg [INPUT_PORT_NUM - 1:0] l1d_bank_axi_arb_arready;
	localparam rvh_l1d_pkg_MEMNOC_TID_MASTERID_SIZE = 4;
	localparam rvh_l1d_pkg_MEMNOC_TID_TID_SIZE = 4;
	localparam [31:0] rvh_pkg_PADDR_WIDTH = 56;
	input wire [(INPUT_PORT_NUM * 77) - 1:0] l1d_bank_axi_arb_ar;
	input wire [INPUT_PORT_NUM - 1:0] l1d_bank_axi_arb_awvalid;
	output reg [INPUT_PORT_NUM - 1:0] l1d_bank_axi_arb_awready;
	input wire [(INPUT_PORT_NUM * 77) - 1:0] l1d_bank_axi_arb_aw;
	input wire [INPUT_PORT_NUM - 1:0] l1d_bank_axi_arb_wvalid;
	output reg [INPUT_PORT_NUM - 1:0] l1d_bank_axi_arb_wready;
	localparam rvh_l1d_pkg_MEM_DATA_WIDTH = 64;
	input wire [(INPUT_PORT_NUM * 73) - 1:0] l1d_bank_axi_arb_w;
	output reg [INPUT_PORT_NUM - 1:0] l1d_bank_axi_arb_bvalid;
	input wire [INPUT_PORT_NUM - 1:0] l1d_bank_axi_arb_bready;
	output wire [(INPUT_PORT_NUM * 10) - 1:0] l1d_bank_axi_arb_b;
	output reg [INPUT_PORT_NUM - 1:0] l1d_bank_axi_arb_rvalid;
	input wire [INPUT_PORT_NUM - 1:0] l1d_bank_axi_arb_rready;
	output wire [(INPUT_PORT_NUM * 78) - 1:0] l1d_bank_axi_arb_r;
	output reg axi_arb_l2_arvalid;
	input wire axi_arb_l2_arready;
	output wire [76:0] axi_arb_l2_ar;
	output reg axi_arb_l2_awvalid;
	input wire axi_arb_l2_awready;
	output wire [76:0] axi_arb_l2_aw;
	output reg axi_arb_l2_wvalid;
	input wire axi_arb_l2_wready;
	output wire [72:0] axi_arb_l2_w;
	input wire axi_arb_l2_bvalid;
	output reg axi_arb_l2_bready;
	input wire [9:0] axi_arb_l2_b;
	input wire axi_arb_l2_rvalid;
	output reg axi_arb_l2_rready;
	input wire [77:0] axi_arb_l2_r;
	input wire clk;
	input wire rst;
	genvar i;
	wire [INPUT_PORT_NUM - 1:0] ar_grt;
	wire [INPUT_PORT_NUM - 1:0] aw_grt;
	wire [INPUT_PORT_NUM - 1:0] w_grt;
	wire [INPUT_PORT_NUM_INDEX_WIDTH - 1:0] ar_grt_idx;
	wire [INPUT_PORT_NUM_INDEX_WIDTH - 1:0] aw_grt_idx;
	wire [INPUT_PORT_NUM_INDEX_WIDTH - 1:0] w_grt_idx;
	one_hot_rr_arb #(.N_INPUT(INPUT_PORT_NUM)) ar_rr_arb_u(
		.req_i(l1d_bank_axi_arb_arvalid),
		.update_i(|l1d_bank_axi_arb_arvalid),
		.grt_o(ar_grt),
		.grt_idx_o(ar_grt_idx),
		.rstn(rst),
		.clk(clk)
	);
	reg axi_arb_w_fsm_d;
	wire axi_arb_w_fsm_q;
	reg axi_arb_w_fsm_d_ena;
	wire axi_arb_l2_w_hsk;
	reg [INPUT_PORT_NUM - 1:0] w_grt_d;
	wire [INPUT_PORT_NUM - 1:0] w_grt_q;
	wire [INPUT_PORT_NUM - 1:0] w_grt_chosen;
	reg w_grt_d_ena;
	reg [INPUT_PORT_NUM_INDEX_WIDTH - 1:0] w_grt_idx_d;
	wire [INPUT_PORT_NUM_INDEX_WIDTH - 1:0] w_grt_idx_q;
	wire [INPUT_PORT_NUM_INDEX_WIDTH - 1:0] w_grt_idx_chosen;
	reg w_grt_idx_d_ena;
	reg axi_arb_w_fsm_in_transmit;
	reg axi_arb_w_rr_update_en;
	assign axi_arb_l2_w_hsk = axi_arb_l2_wvalid & axi_arb_l2_wready;
	always @(*) begin
		axi_arb_w_fsm_d = axi_arb_w_fsm_q;
		axi_arb_w_fsm_d_ena = 1'b0;
		w_grt_d = w_grt_q;
		w_grt_d_ena = 1'b0;
		w_grt_idx_d = w_grt_idx_q;
		w_grt_idx_d_ena = 1'b0;
		axi_arb_w_fsm_in_transmit = 1'b0;
		axi_arb_w_rr_update_en = 1'b0;
		case (axi_arb_w_fsm_q)
			1'd0: begin
				if (axi_arb_l2_wvalid) begin
					w_grt_d = w_grt;
					w_grt_d_ena = 1'b1;
					w_grt_idx_d = w_grt_idx;
					w_grt_idx_d_ena = 1'b1;
				end
				if (axi_arb_l2_w_hsk) begin
					axi_arb_w_fsm_d = 1'd1;
					axi_arb_w_fsm_d_ena = 1'b1;
				end
			end
			1'd1: begin
				axi_arb_w_fsm_in_transmit = 1'b1;
				if (axi_arb_l2_w_hsk & axi_arb_l2_w[8]) begin
					axi_arb_w_fsm_d = 1'd0;
					axi_arb_w_fsm_d_ena = 1'b1;
					axi_arb_w_rr_update_en = 1'b1;
				end
			end
			default: begin
				axi_arb_w_fsm_d = 1'd0;
				w_grt_d = w_grt;
				w_grt_d_ena = 1'b1;
				w_grt_idx_d = w_grt_idx;
				w_grt_idx_d_ena = 1'b1;
			end
		endcase
	end
	assign w_grt_chosen = (axi_arb_w_fsm_in_transmit ? w_grt_q : w_grt);
	assign w_grt_idx_chosen = (axi_arb_w_fsm_in_transmit ? w_grt_idx_q : w_grt_idx);
	std_dffrve #(.WIDTH(1)) U_L1D_AXI_ARB_W_FSM_STATE_REG(
		.clk(clk),
		.rstn(rst),
		.rst_val(1'd0),
		.en(axi_arb_w_fsm_d_ena),
		.d(axi_arb_w_fsm_d),
		.q(axi_arb_w_fsm_q)
	);
	std_dffre #(.WIDTH(INPUT_PORT_NUM)) U_L1D_AXI_ARB_W_GRT_REG(
		.clk(clk),
		.rstn(rst),
		.en(w_grt_d_ena),
		.d(w_grt_d),
		.q(w_grt_q)
	);
	std_dffre #(.WIDTH(INPUT_PORT_NUM_INDEX_WIDTH)) U_L1D_AXI_ARB_W_GRT_IDX_REG(
		.clk(clk),
		.rstn(rst),
		.en(w_grt_idx_d_ena),
		.d(w_grt_idx_d),
		.q(w_grt_idx_q)
	);
	one_hot_rr_arb #(.N_INPUT(INPUT_PORT_NUM)) w_rr_arb_u(
		.req_i(l1d_bank_axi_arb_wvalid),
		.update_i(axi_arb_w_rr_update_en),
		.grt_o(w_grt),
		.grt_idx_o(w_grt_idx),
		.rstn(rst),
		.clk(clk)
	);
	always @(*) begin : ar_control_signal
		l1d_bank_axi_arb_arready = 1'sb0;
		axi_arb_l2_arvalid = 1'sb0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < INPUT_PORT_NUM; i = i + 1)
				if (ar_grt[i]) begin
					l1d_bank_axi_arb_arready[i] = axi_arb_l2_arready;
					axi_arb_l2_arvalid = l1d_bank_axi_arb_arvalid[i];
				end
		end
	end
	always @(*) begin : aw_control_signal
		l1d_bank_axi_arb_awready = 1'sb0;
		axi_arb_l2_awvalid = 1'sb0;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < INPUT_PORT_NUM; i = i + 1)
				if (w_grt_chosen[i]) begin
					l1d_bank_axi_arb_awready[i] = axi_arb_l2_awready;
					axi_arb_l2_awvalid = l1d_bank_axi_arb_awvalid[i];
				end
		end
	end
	always @(*) begin : w_control_signal
		l1d_bank_axi_arb_wready = 1'sb0;
		axi_arb_l2_wvalid = 1'sb0;
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < INPUT_PORT_NUM; i = i + 1)
				if (w_grt_chosen[i]) begin
					l1d_bank_axi_arb_wready[i] = axi_arb_l2_wready;
					axi_arb_l2_wvalid = l1d_bank_axi_arb_wvalid[i];
				end
		end
	end
	always @(*) begin : r_control_signal
		axi_arb_l2_rready = 1'sb0;
		l1d_bank_axi_arb_rvalid = 1'sb0;
		begin : sv2v_autoblock_4
			reg signed [31:0] i;
			for (i = 0; i < INPUT_PORT_NUM; i = i + 1)
				if (axi_arb_l2_r[74 + RESP_PORT_SELECT_BID_LSB+:INPUT_PORT_NUM_INDEX_WIDTH] == i[INPUT_PORT_NUM_INDEX_WIDTH - 1:0]) begin
					axi_arb_l2_rready = l1d_bank_axi_arb_rready[i];
					l1d_bank_axi_arb_rvalid[i] = axi_arb_l2_rvalid;
				end
		end
	end
	always @(*) begin : b_control_signal
		axi_arb_l2_bready = 1'sb0;
		l1d_bank_axi_arb_bvalid = 1'sb0;
		begin : sv2v_autoblock_5
			reg signed [31:0] i;
			for (i = 0; i < INPUT_PORT_NUM; i = i + 1)
				if (axi_arb_l2_b[6 + RESP_PORT_SELECT_BID_LSB+:INPUT_PORT_NUM_INDEX_WIDTH] == i[INPUT_PORT_NUM_INDEX_WIDTH - 1:0]) begin
					axi_arb_l2_bready = l1d_bank_axi_arb_bready[i];
					l1d_bank_axi_arb_bvalid[i] = axi_arb_l2_bvalid;
				end
		end
	end
	assign axi_arb_l2_ar = l1d_bank_axi_arb_ar[ar_grt_idx * 77+:77];
	assign axi_arb_l2_aw = l1d_bank_axi_arb_aw[w_grt_idx_chosen * 77+:77];
	assign axi_arb_l2_w = l1d_bank_axi_arb_w[w_grt_idx_chosen * 73+:73];
	generate
		for (i = 0; i < INPUT_PORT_NUM; i = i + 1) begin : genblk1
			assign l1d_bank_axi_arb_b[i * 10+:10] = axi_arb_l2_b;
			assign l1d_bank_axi_arb_r[i * 78+:78] = axi_arb_l2_r;
		end
	endgenerate
endmodule
