module rvh_l1d_bank_input_arb (
	ls_pipe_l1d_ld_req_vld_i,
	ls_pipe_l1d_ld_req_io_i,
	ls_pipe_l1d_ld_req_rob_tag_i,
	ls_pipe_l1d_ld_req_prd_i,
	ls_pipe_l1d_ld_req_opcode_i,
	ls_pipe_l1d_ld_req_idx_i,
	ls_pipe_l1d_ld_req_offset_i,
	ls_pipe_l1d_ld_req_vtag_i,
	stb_l1d_ld_req_rdy_i,
	ls_pipe_l1d_ld_req_rdy_o,
	ls_pipe_l1d_ld_req_hit_bank_id_o,
	ls_pipe_l1d_dtlb_resp_vld_i,
	ls_pipe_l1d_dtlb_resp_ppn_i,
	ls_pipe_l1d_dtlb_resp_excp_vld_i,
	ls_pipe_l1d_dtlb_resp_hit_i,
	ls_pipe_l1d_dtlb_resp_miss_i,
	ls_pipe_l1d_st_req_vld_i,
	ls_pipe_l1d_st_req_io_i,
	ls_pipe_l1d_st_req_rob_tag_i,
	ls_pipe_l1d_st_req_prd_i,
	ls_pipe_l1d_st_req_opcode_i,
	ls_pipe_l1d_st_req_paddr_i,
	ls_pipe_l1d_st_req_data_i,
	ls_pipe_l1d_st_req_rdy_o,
	l1d_bank_ld_req_vld_o,
	l1d_bank_ld_req_rob_tag_o,
	l1d_bank_ld_req_prd_o,
	l1d_bank_ld_req_opcode_o,
	l1d_bank_ld_req_idx_o,
	l1d_bank_ld_req_offset_o,
	l1d_bank_ld_req_vtag_o,
	l1d_bank_stb_ld_req_rdy_o,
	l1d_bank_ld_req_rdy_i,
	dtlb_l1d_resp_vld_o,
	dtlb_l1d_resp_excp_vld_o,
	dtlb_l1d_resp_hit_o,
	dtlb_l1d_resp_ppn_o,
	dtlb_l1d_resp_rdy_i,
	l1d_bank_st_req_vld_o,
	l1d_bank_st_req_io_region_o,
	l1d_bank_st_req_rob_tag_o,
	l1d_bank_st_req_prd_o,
	l1d_bank_st_req_opcode_o,
	l1d_bank_st_req_paddr_o,
	l1d_bank_st_req_data_o,
	l1d_bank_st_req_data_byte_mask_o,
	l1d_bank_st_req_rdy_i,
	clk,
	rst
);
	localparam [31:0] rvh_pkg_LSU_ADDR_PIPE_COUNT = 2;
	parameter [31:0] N_ARB_LD_IN_PORT = rvh_pkg_LSU_ADDR_PIPE_COUNT;
	parameter [31:0] N_ARB_ST_IN_PORT = 1;
	parameter [31:0] N_ARB_ST_IN_PORT_W = (N_ARB_ST_IN_PORT > 1 ? $clog2(N_ARB_ST_IN_PORT) : 1);
	input wire [N_ARB_LD_IN_PORT - 1:0] ls_pipe_l1d_ld_req_vld_i;
	input wire [N_ARB_LD_IN_PORT - 1:0] ls_pipe_l1d_ld_req_io_i;
	localparam [31:0] rvh_pkg_ROB_BLOCK_PER_ENTRY = 1;
	localparam [31:0] rvh_pkg_ROB_SIZE = 16;
	localparam [31:0] rvh_pkg_ROB_ENTRY_COUNT = rvh_pkg_ROB_SIZE / rvh_pkg_ROB_BLOCK_PER_ENTRY;
	localparam [31:0] rvh_pkg_ROB_INDEX_WIDTH = $clog2(rvh_pkg_ROB_ENTRY_COUNT);
	localparam [31:0] rvh_pkg_ROB_TAG_WIDTH = rvh_pkg_ROB_INDEX_WIDTH;
	input wire [(N_ARB_LD_IN_PORT * rvh_pkg_ROB_TAG_WIDTH) - 1:0] ls_pipe_l1d_ld_req_rob_tag_i;
	localparam [31:0] rvh_pkg_INT_PREG_COUNT = 48;
	localparam [31:0] rvh_pkg_INT_PREG_TAG_WIDTH = 6;
	localparam [31:0] rvh_pkg_PREG_TAG_WIDTH = rvh_pkg_INT_PREG_TAG_WIDTH;
	input wire [(N_ARB_LD_IN_PORT * rvh_pkg_PREG_TAG_WIDTH) - 1:0] ls_pipe_l1d_ld_req_prd_i;
	localparam [31:0] uop_encoding_pkg_LDU_OP_WIDTH = 3;
	input wire [(N_ARB_LD_IN_PORT * uop_encoding_pkg_LDU_OP_WIDTH) - 1:0] ls_pipe_l1d_ld_req_opcode_i;
	localparam [31:0] rvh_pkg_L1D_BANK_COUNT = 1;
	localparam rvh_l1d_pkg_L1D_BANK_ID_NUM = rvh_pkg_L1D_BANK_COUNT;
	localparam [31:0] rvh_pkg_L1D_LINE_SIZE = 64;
	localparam [31:0] rvh_pkg_L1D_SIZE = 16384;
	localparam [31:0] rvh_pkg_L1D_WAY_COUNT = 4;
	localparam [31:0] rvh_pkg_L1D_SET_COUNT = rvh_pkg_L1D_SIZE / (rvh_pkg_L1D_LINE_SIZE * rvh_pkg_L1D_WAY_COUNT);
	localparam [31:0] rvh_pkg_L1D_BANK_SET_COUNT = rvh_pkg_L1D_SET_COUNT / rvh_pkg_L1D_BANK_COUNT;
	localparam rvh_l1d_pkg_L1D_BANK_SET_NUM = rvh_pkg_L1D_BANK_SET_COUNT;
	localparam rvh_l1d_pkg_L1D_INDEX_WIDTH = $clog2(rvh_l1d_pkg_L1D_BANK_SET_NUM * 32'd1);
	input wire [(N_ARB_LD_IN_PORT * rvh_l1d_pkg_L1D_INDEX_WIDTH) - 1:0] ls_pipe_l1d_ld_req_idx_i;
	localparam rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE = 512;
	localparam rvh_l1d_pkg_L1D_OFFSET_WIDTH = 6;
	input wire [(N_ARB_LD_IN_PORT * rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1:0] ls_pipe_l1d_ld_req_offset_i;
	localparam [31:0] rvh_pkg_PADDR_WIDTH = 56;
	localparam rvh_l1d_pkg_L1D_TAG_WIDTH = (rvh_pkg_PADDR_WIDTH - rvh_l1d_pkg_L1D_INDEX_WIDTH) - rvh_l1d_pkg_L1D_OFFSET_WIDTH;
	input wire [(N_ARB_LD_IN_PORT * rvh_l1d_pkg_L1D_TAG_WIDTH) - 1:0] ls_pipe_l1d_ld_req_vtag_i;
	input wire [N_ARB_LD_IN_PORT - 1:0] stb_l1d_ld_req_rdy_i;
	output reg [N_ARB_LD_IN_PORT - 1:0] ls_pipe_l1d_ld_req_rdy_o;
	localparam rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH = 0;
	output reg [-1:0] ls_pipe_l1d_ld_req_hit_bank_id_o;
	input wire [N_ARB_LD_IN_PORT - 1:0] ls_pipe_l1d_dtlb_resp_vld_i;
	localparam riscv_pkg_PAGE_OFFSET_WIDTH = 12;
	localparam riscv_pkg_PPN_WIDTH = 44;
	input wire [(N_ARB_LD_IN_PORT * riscv_pkg_PPN_WIDTH) - 1:0] ls_pipe_l1d_dtlb_resp_ppn_i;
	input wire [N_ARB_LD_IN_PORT - 1:0] ls_pipe_l1d_dtlb_resp_excp_vld_i;
	input wire [N_ARB_LD_IN_PORT - 1:0] ls_pipe_l1d_dtlb_resp_hit_i;
	input wire [N_ARB_LD_IN_PORT - 1:0] ls_pipe_l1d_dtlb_resp_miss_i;
	input wire [N_ARB_ST_IN_PORT - 1:0] ls_pipe_l1d_st_req_vld_i;
	input wire [N_ARB_ST_IN_PORT - 1:0] ls_pipe_l1d_st_req_io_i;
	input wire [(N_ARB_ST_IN_PORT * rvh_pkg_ROB_TAG_WIDTH) - 1:0] ls_pipe_l1d_st_req_rob_tag_i;
	input wire [(N_ARB_ST_IN_PORT * rvh_pkg_PREG_TAG_WIDTH) - 1:0] ls_pipe_l1d_st_req_prd_i;
	localparam [31:0] uop_encoding_pkg_STU_OP_WIDTH = 5;
	input wire [(N_ARB_ST_IN_PORT * uop_encoding_pkg_STU_OP_WIDTH) - 1:0] ls_pipe_l1d_st_req_opcode_i;
	input wire [(N_ARB_ST_IN_PORT * rvh_pkg_PADDR_WIDTH) - 1:0] ls_pipe_l1d_st_req_paddr_i;
	localparam [31:0] rvh_pkg_XLEN = 64;
	input wire [(N_ARB_ST_IN_PORT * rvh_pkg_XLEN) - 1:0] ls_pipe_l1d_st_req_data_i;
	output reg [N_ARB_ST_IN_PORT - 1:0] ls_pipe_l1d_st_req_rdy_o;
	output reg [0:0] l1d_bank_ld_req_vld_o;
	output reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * rvh_pkg_ROB_TAG_WIDTH) - 1:0] l1d_bank_ld_req_rob_tag_o;
	output reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * rvh_pkg_PREG_TAG_WIDTH) - 1:0] l1d_bank_ld_req_prd_o;
	output reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * uop_encoding_pkg_LDU_OP_WIDTH) - 1:0] l1d_bank_ld_req_opcode_o;
	localparam rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH = $clog2(rvh_l1d_pkg_L1D_BANK_SET_NUM);
	output reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) - 1:0] l1d_bank_ld_req_idx_o;
	localparam rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH = rvh_l1d_pkg_L1D_OFFSET_WIDTH;
	output reg [5:0] l1d_bank_ld_req_offset_o;
	localparam rvh_l1d_pkg_L1D_BANK_TAG_WIDTH = rvh_l1d_pkg_L1D_TAG_WIDTH;
	output reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * rvh_l1d_pkg_L1D_BANK_TAG_WIDTH) - 1:0] l1d_bank_ld_req_vtag_o;
	output reg [0:0] l1d_bank_stb_ld_req_rdy_o;
	input wire [0:0] l1d_bank_ld_req_rdy_i;
	output reg [0:0] dtlb_l1d_resp_vld_o;
	output reg [0:0] dtlb_l1d_resp_excp_vld_o;
	output reg [0:0] dtlb_l1d_resp_hit_o;
	output reg [43:0] dtlb_l1d_resp_ppn_o;
	input wire [0:0] dtlb_l1d_resp_rdy_i;
	output reg [0:0] l1d_bank_st_req_vld_o;
	output reg [0:0] l1d_bank_st_req_io_region_o;
	output reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * rvh_pkg_ROB_TAG_WIDTH) - 1:0] l1d_bank_st_req_rob_tag_o;
	output reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * rvh_pkg_PREG_TAG_WIDTH) - 1:0] l1d_bank_st_req_prd_o;
	output reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * uop_encoding_pkg_STU_OP_WIDTH) - 1:0] l1d_bank_st_req_opcode_o;
	output reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * rvh_pkg_PADDR_WIDTH) - 1:0] l1d_bank_st_req_paddr_o;
	localparam rvh_l1d_pkg_L1D_STB_DATA_WIDTH = 512;
	output reg [511:0] l1d_bank_st_req_data_o;
	output reg [63:0] l1d_bank_st_req_data_byte_mask_o;
	input wire [0:0] l1d_bank_st_req_rdy_i;
	input clk;
	input rst;
	genvar i;
	genvar j;
	reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) - 1:0] ls_pipe_l1d_input_arb_ld_req_vld;
	reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) - 1:0] ls_pipe_l1d_input_arb_ld_req_io;
	reg [((rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) * rvh_pkg_ROB_TAG_WIDTH) - 1:0] ls_pipe_l1d_input_arb_ld_req_rob_tag;
	reg [((rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) * rvh_pkg_PREG_TAG_WIDTH) - 1:0] ls_pipe_l1d_input_arb_ld_req_prd;
	reg [((rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) * 3) - 1:0] ls_pipe_l1d_input_arb_ld_req_opcode;
	reg [((rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) * rvh_l1d_pkg_L1D_INDEX_WIDTH) - 1:0] ls_pipe_l1d_input_arb_ld_req_idx;
	reg [((rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) * 6) - 1:0] ls_pipe_l1d_input_arb_ld_req_offset;
	reg [((rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) * rvh_l1d_pkg_L1D_TAG_WIDTH) - 1:0] ls_pipe_l1d_input_arb_ld_req_vtag;
	reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) - 1:0] stb_l1d_input_arb_ld_req_rdy;
	wire [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) - 1:0] ls_pipe_l1d_input_arb_ld_req_rdy;
	reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_ST_IN_PORT) - 1:0] ls_pipe_l1d_input_arb_st_req_vld;
	reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_ST_IN_PORT) - 1:0] ls_pipe_l1d_input_arb_st_req_io;
	reg [((rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_ST_IN_PORT) * rvh_pkg_ROB_TAG_WIDTH) - 1:0] ls_pipe_l1d_input_arb_st_req_rob_tag;
	reg [((rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_ST_IN_PORT) * rvh_pkg_PREG_TAG_WIDTH) - 1:0] ls_pipe_l1d_input_arb_st_req_prd;
	reg [((rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_ST_IN_PORT) * 5) - 1:0] ls_pipe_l1d_input_arb_st_req_opcode;
	reg [((rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_ST_IN_PORT) * 56) - 1:0] ls_pipe_l1d_input_arb_st_req_paddr;
	reg [((rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_ST_IN_PORT) * 64) - 1:0] ls_pipe_l1d_input_arb_st_req_data;
	wire [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_ST_IN_PORT) - 1:0] ls_pipe_l1d_input_arb_st_req_rdy;
	wire [-1:0] ld_req_bank_id;
	reg [-1:0] ld_req_bank_id_ff;
	wire [N_ARB_LD_IN_PORT - 1:0] lsu_pipe_ld_req_hsk;
	wire [-1:0] st_req_bank_id;
	wire [-1:0] st_req_bank_id_ff;
	generate
		for (i = 0; i < N_ARB_LD_IN_PORT; i = i + 1) begin : genblk1
			assign ld_req_bank_id[0+:rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH] = ls_pipe_l1d_ld_req_idx_i[(i * rvh_l1d_pkg_L1D_INDEX_WIDTH) + (rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH - 1)-:rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH];
			assign lsu_pipe_ld_req_hsk[i] = ls_pipe_l1d_ld_req_vld_i[i] & ls_pipe_l1d_ld_req_rdy_o[i];
		end
		for (i = 0; i < N_ARB_ST_IN_PORT; i = i + 1) begin : genblk2
			assign st_req_bank_id[0+:rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH] = ls_pipe_l1d_st_req_paddr_i[(i * rvh_pkg_PADDR_WIDTH) + 6-:2];
		end
	endgenerate
	always @(posedge clk or negedge rst)
		if (~rst)
			ld_req_bank_id_ff <= 1'sb0;
		else begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < N_ARB_LD_IN_PORT; i = i + 1)
				if (lsu_pipe_ld_req_hsk[i])
					ld_req_bank_id_ff[0+:rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH] <= ld_req_bank_id[0+:rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH];
		end
	always @(*) begin : lsu_ld_req_to_cache_bank_router
		ls_pipe_l1d_input_arb_ld_req_vld = 1'sb0;
		ls_pipe_l1d_input_arb_ld_req_io = 1'sb0;
		ls_pipe_l1d_input_arb_ld_req_rob_tag = 1'sb0;
		ls_pipe_l1d_input_arb_ld_req_prd = 1'sb0;
		ls_pipe_l1d_input_arb_ld_req_opcode = 1'sb0;
		ls_pipe_l1d_input_arb_ld_req_idx = 1'sb0;
		ls_pipe_l1d_input_arb_ld_req_offset = 1'sb0;
		ls_pipe_l1d_input_arb_ld_req_vtag = 1'sb0;
		stb_l1d_input_arb_ld_req_rdy = 1'sb0;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1)
				begin : sv2v_autoblock_3
					reg signed [31:0] j;
					for (j = 0; j < N_ARB_LD_IN_PORT; j = j + 1)
						if (ld_req_bank_id[0+:rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH] == i[rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH - 1:0]) begin
							ls_pipe_l1d_input_arb_ld_req_vld[(i * N_ARB_LD_IN_PORT) + j] = ls_pipe_l1d_ld_req_vld_i[j];
							ls_pipe_l1d_input_arb_ld_req_io[(i * N_ARB_LD_IN_PORT) + j] = ls_pipe_l1d_ld_req_io_i[j];
							ls_pipe_l1d_input_arb_ld_req_rob_tag[((i * N_ARB_LD_IN_PORT) + j) * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH] = ls_pipe_l1d_ld_req_rob_tag_i[j * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH];
							ls_pipe_l1d_input_arb_ld_req_prd[((i * N_ARB_LD_IN_PORT) + j) * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH] = ls_pipe_l1d_ld_req_prd_i[j * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH];
							ls_pipe_l1d_input_arb_ld_req_opcode[((i * N_ARB_LD_IN_PORT) + j) * 3+:3] = ls_pipe_l1d_ld_req_opcode_i[j * uop_encoding_pkg_LDU_OP_WIDTH+:uop_encoding_pkg_LDU_OP_WIDTH];
							ls_pipe_l1d_input_arb_ld_req_idx[((i * N_ARB_LD_IN_PORT) + j) * rvh_l1d_pkg_L1D_INDEX_WIDTH+:rvh_l1d_pkg_L1D_INDEX_WIDTH] = ls_pipe_l1d_ld_req_idx_i[j * rvh_l1d_pkg_L1D_INDEX_WIDTH+:rvh_l1d_pkg_L1D_INDEX_WIDTH];
							ls_pipe_l1d_input_arb_ld_req_offset[((i * N_ARB_LD_IN_PORT) + j) * 6+:6] = ls_pipe_l1d_ld_req_offset_i[j * rvh_l1d_pkg_L1D_OFFSET_WIDTH+:rvh_l1d_pkg_L1D_OFFSET_WIDTH];
							ls_pipe_l1d_input_arb_ld_req_vtag[((i * N_ARB_LD_IN_PORT) + j) * rvh_l1d_pkg_L1D_TAG_WIDTH+:rvh_l1d_pkg_L1D_TAG_WIDTH] = ls_pipe_l1d_ld_req_vtag_i[j * rvh_l1d_pkg_L1D_TAG_WIDTH+:rvh_l1d_pkg_L1D_TAG_WIDTH];
							stb_l1d_input_arb_ld_req_rdy[(i * N_ARB_LD_IN_PORT) + j] = stb_l1d_ld_req_rdy_i[j];
						end
				end
		end
	end
	always @(*) begin : lsu_st_req_to_cache_bank_router
		ls_pipe_l1d_input_arb_st_req_vld = 1'sb0;
		ls_pipe_l1d_input_arb_st_req_io = 1'sb0;
		ls_pipe_l1d_input_arb_st_req_rob_tag = 1'sb0;
		ls_pipe_l1d_input_arb_st_req_prd = 1'sb0;
		ls_pipe_l1d_input_arb_st_req_opcode = 1'sb0;
		ls_pipe_l1d_input_arb_st_req_paddr = 1'sb0;
		ls_pipe_l1d_input_arb_st_req_data = 1'sb0;
		begin : sv2v_autoblock_4
			reg signed [31:0] i;
			for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1)
				begin : sv2v_autoblock_5
					reg signed [31:0] j;
					for (j = 0; j < N_ARB_ST_IN_PORT; j = j + 1)
						if (st_req_bank_id[0+:rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH] == i[rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH - 1:0]) begin
							ls_pipe_l1d_input_arb_st_req_vld[(i * N_ARB_ST_IN_PORT) + j] = ls_pipe_l1d_st_req_vld_i[j];
							ls_pipe_l1d_input_arb_st_req_io[(i * N_ARB_ST_IN_PORT) + j] = ls_pipe_l1d_st_req_io_i[j];
							ls_pipe_l1d_input_arb_st_req_rob_tag[((i * N_ARB_ST_IN_PORT) + j) * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH] = ls_pipe_l1d_st_req_rob_tag_i[j * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH];
							ls_pipe_l1d_input_arb_st_req_prd[((i * N_ARB_ST_IN_PORT) + j) * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH] = ls_pipe_l1d_st_req_prd_i[j * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH];
							ls_pipe_l1d_input_arb_st_req_opcode[((i * N_ARB_ST_IN_PORT) + j) * 5+:5] = ls_pipe_l1d_st_req_opcode_i[j * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH];
							ls_pipe_l1d_input_arb_st_req_paddr[((i * N_ARB_ST_IN_PORT) + j) * 56+:56] = ls_pipe_l1d_st_req_paddr_i[j * rvh_pkg_PADDR_WIDTH+:rvh_pkg_PADDR_WIDTH];
							ls_pipe_l1d_input_arb_st_req_data[((i * N_ARB_ST_IN_PORT) + j) * 64+:64] = ls_pipe_l1d_st_req_data_i[j * rvh_pkg_XLEN+:rvh_pkg_XLEN];
						end
				end
		end
	end
	wire [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) - 1:0] l1d_bank_ld_req_grt;
	wire [(rvh_l1d_pkg_L1D_BANK_ID_NUM * $clog2(N_ARB_LD_IN_PORT)) - 1:0] l1d_bank_ld_req_grt_idx;
	wire [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) - 1:0] l1d_bank_ld_req_hsk;
	reg [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_LD_IN_PORT) - 1:0] l1d_bank_ld_req_hsk_ff;
	generate
		for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1) begin : genblk3
			one_hot_rr_arb #(.N_INPUT(N_ARB_LD_IN_PORT)) ld_req_input_rr_arb_u(
				.req_i(ls_pipe_l1d_input_arb_ld_req_vld[i * N_ARB_LD_IN_PORT+:N_ARB_LD_IN_PORT]),
				.update_i(|ls_pipe_l1d_input_arb_ld_req_vld[i * N_ARB_LD_IN_PORT+:N_ARB_LD_IN_PORT]),
				.grt_o(l1d_bank_ld_req_grt[i * N_ARB_LD_IN_PORT+:N_ARB_LD_IN_PORT]),
				.grt_idx_o(l1d_bank_ld_req_grt_idx[i * $clog2(N_ARB_LD_IN_PORT)+:$clog2(N_ARB_LD_IN_PORT)]),
				.rstn(rst),
				.clk(clk)
			);
		end
		for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1) begin : genblk4
			assign l1d_bank_ld_req_hsk[i * N_ARB_LD_IN_PORT+:N_ARB_LD_IN_PORT] = l1d_bank_ld_req_grt[i * N_ARB_LD_IN_PORT+:N_ARB_LD_IN_PORT] & {N_ARB_LD_IN_PORT {l1d_bank_ld_req_rdy_i[i]}};
		end
	endgenerate
	always @(posedge clk or negedge rst)
		if (~rst)
			l1d_bank_ld_req_hsk_ff <= 1'sb0;
		else
			l1d_bank_ld_req_hsk_ff <= l1d_bank_ld_req_hsk;
	always @(*) begin
		ls_pipe_l1d_ld_req_rdy_o = 1'sb0;
		ls_pipe_l1d_ld_req_hit_bank_id_o = 1'sb0;
		begin : sv2v_autoblock_6
			reg signed [31:0] i;
			for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1)
				begin : sv2v_autoblock_7
					reg signed [31:0] j;
					for (j = 0; j < N_ARB_LD_IN_PORT; j = j + 1)
						if (l1d_bank_ld_req_grt[(i * N_ARB_LD_IN_PORT) + j]) begin
							ls_pipe_l1d_ld_req_rdy_o[j] = l1d_bank_ld_req_rdy_i[i];
							ls_pipe_l1d_ld_req_hit_bank_id_o[0+:rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH] = i[rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH - 1:0];
						end
				end
		end
	end
	wire [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_ST_IN_PORT) - 1:0] l1d_bank_st_req_grt;
	wire [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_ST_IN_PORT_W) - 1:0] l1d_bank_st_req_grt_idx;
	wire [(rvh_l1d_pkg_L1D_BANK_ID_NUM * N_ARB_ST_IN_PORT) - 1:0] l1d_bank_st_req_hsk;
	generate
		if (N_ARB_ST_IN_PORT > 1) begin : gen_st_req_input_rr_arb_more_than_1_port
			for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1) begin : gen_st_req_input_rr_arb
				one_hot_rr_arb #(.N_INPUT(N_ARB_ST_IN_PORT)) st_req_input_rr_arb_u(
					.req_i(ls_pipe_l1d_input_arb_st_req_vld[i * N_ARB_ST_IN_PORT+:N_ARB_ST_IN_PORT]),
					.update_i(|ls_pipe_l1d_input_arb_st_req_vld[i * N_ARB_ST_IN_PORT+:N_ARB_ST_IN_PORT]),
					.grt_o(l1d_bank_st_req_grt[i * N_ARB_ST_IN_PORT+:N_ARB_ST_IN_PORT]),
					.grt_idx_o(l1d_bank_st_req_grt_idx[i * N_ARB_ST_IN_PORT_W+:N_ARB_ST_IN_PORT_W]),
					.rstn(rst),
					.clk(clk)
				);
			end
		end
		else begin : gen_st_req_input_rr_arb_only_one_port
			for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1) begin : gen_st_req_input_rr_arb
				assign l1d_bank_st_req_grt[i * N_ARB_ST_IN_PORT+:N_ARB_ST_IN_PORT] = 1'b1;
				assign l1d_bank_st_req_grt_idx[i * N_ARB_ST_IN_PORT_W+:N_ARB_ST_IN_PORT_W] = 1'b0;
			end
		end
		for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1) begin : genblk6
			assign l1d_bank_st_req_hsk[i * N_ARB_ST_IN_PORT+:N_ARB_ST_IN_PORT] = l1d_bank_st_req_grt[i * N_ARB_ST_IN_PORT+:N_ARB_ST_IN_PORT] & {N_ARB_ST_IN_PORT {l1d_bank_st_req_rdy_i[i]}};
		end
	endgenerate
	always @(*) begin
		ls_pipe_l1d_st_req_rdy_o = 1'sb0;
		begin : sv2v_autoblock_8
			reg signed [31:0] i;
			for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1)
				begin : sv2v_autoblock_9
					reg signed [31:0] j;
					for (j = 0; j < N_ARB_ST_IN_PORT; j = j + 1)
						if (l1d_bank_st_req_grt[(i * N_ARB_ST_IN_PORT) + j])
							ls_pipe_l1d_st_req_rdy_o[j] = l1d_bank_st_req_rdy_i[i];
				end
		end
	end
	wire [511:0] ls_pipe_l1d_st_req_data_transed;
	wire [63:0] ls_pipe_l1d_st_req_data_byte_mask_transed;
	generate
		for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1) begin : genblk7
			rrv2rvh_ruby_stmask_trans rrv2rvh_ruby_stmask_trans_st_req_u(
				.st_dat_i(ls_pipe_l1d_input_arb_st_req_data[((i * N_ARB_ST_IN_PORT) + l1d_bank_st_req_grt_idx[i * N_ARB_ST_IN_PORT_W+:N_ARB_ST_IN_PORT_W]) * 64+:64]),
				.st_offset_i(ls_pipe_l1d_input_arb_st_req_paddr[(((i * N_ARB_ST_IN_PORT) + l1d_bank_st_req_grt_idx[i * N_ARB_ST_IN_PORT_W+:N_ARB_ST_IN_PORT_W]) * 56) + 5-:6]),
				.st_opcode_i(ls_pipe_l1d_input_arb_st_req_opcode[((i * N_ARB_ST_IN_PORT) + l1d_bank_st_req_grt_idx[i * N_ARB_ST_IN_PORT_W+:N_ARB_ST_IN_PORT_W]) * 5+:5]),
				.ls_pipe_l1d_st_req_data_o(ls_pipe_l1d_st_req_data_transed[i * 512+:512]),
				.ls_pipe_l1d_st_req_data_byte_mask_o(ls_pipe_l1d_st_req_data_byte_mask_transed[i * 64+:64])
			);
		end
	endgenerate
	always @(*) begin : sv2v_autoblock_10
		reg signed [31:0] i;
		for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1)
			begin
				l1d_bank_ld_req_vld_o[i] = ls_pipe_l1d_input_arb_ld_req_vld[(i * N_ARB_LD_IN_PORT) + l1d_bank_ld_req_grt_idx[i * $clog2(N_ARB_LD_IN_PORT)+:$clog2(N_ARB_LD_IN_PORT)]];
				l1d_bank_ld_req_rob_tag_o[i * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH] = ls_pipe_l1d_input_arb_ld_req_rob_tag[((i * N_ARB_LD_IN_PORT) + l1d_bank_ld_req_grt_idx[i * $clog2(N_ARB_LD_IN_PORT)+:$clog2(N_ARB_LD_IN_PORT)]) * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH];
				l1d_bank_ld_req_prd_o[i * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH] = ls_pipe_l1d_input_arb_ld_req_prd[((i * N_ARB_LD_IN_PORT) + l1d_bank_ld_req_grt_idx[i * $clog2(N_ARB_LD_IN_PORT)+:$clog2(N_ARB_LD_IN_PORT)]) * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH];
				l1d_bank_ld_req_opcode_o[i * uop_encoding_pkg_LDU_OP_WIDTH+:uop_encoding_pkg_LDU_OP_WIDTH] = ls_pipe_l1d_input_arb_ld_req_opcode[((i * N_ARB_LD_IN_PORT) + l1d_bank_ld_req_grt_idx[i * $clog2(N_ARB_LD_IN_PORT)+:$clog2(N_ARB_LD_IN_PORT)]) * 3+:3];
				l1d_bank_ld_req_idx_o[i * rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH+:rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH] = ls_pipe_l1d_input_arb_ld_req_idx[(((i * N_ARB_LD_IN_PORT) + l1d_bank_ld_req_grt_idx[i * $clog2(N_ARB_LD_IN_PORT)+:$clog2(N_ARB_LD_IN_PORT)]) * rvh_l1d_pkg_L1D_INDEX_WIDTH) + (rvh_l1d_pkg_L1D_INDEX_WIDTH - 1)-:rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH];
				l1d_bank_ld_req_offset_o[i * rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH+:rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH] = ls_pipe_l1d_input_arb_ld_req_offset[(((i * N_ARB_LD_IN_PORT) + l1d_bank_ld_req_grt_idx[i * $clog2(N_ARB_LD_IN_PORT)+:$clog2(N_ARB_LD_IN_PORT)]) * 6) + 5-:6];
				l1d_bank_ld_req_vtag_o[i * rvh_l1d_pkg_L1D_BANK_TAG_WIDTH+:rvh_l1d_pkg_L1D_BANK_TAG_WIDTH] = ls_pipe_l1d_input_arb_ld_req_vtag[(((i * N_ARB_LD_IN_PORT) + l1d_bank_ld_req_grt_idx[i * $clog2(N_ARB_LD_IN_PORT)+:$clog2(N_ARB_LD_IN_PORT)]) * rvh_l1d_pkg_L1D_TAG_WIDTH) + (rvh_l1d_pkg_L1D_BANK_TAG_WIDTH - 1)-:rvh_l1d_pkg_L1D_BANK_TAG_WIDTH];
				l1d_bank_stb_ld_req_rdy_o[i] = stb_l1d_input_arb_ld_req_rdy[(i * N_ARB_LD_IN_PORT) + l1d_bank_ld_req_grt_idx[i * $clog2(N_ARB_LD_IN_PORT)+:$clog2(N_ARB_LD_IN_PORT)]];
				l1d_bank_st_req_vld_o[i] = ls_pipe_l1d_input_arb_st_req_vld[(i * N_ARB_ST_IN_PORT) + l1d_bank_st_req_grt_idx[i * N_ARB_ST_IN_PORT_W+:N_ARB_ST_IN_PORT_W]];
				l1d_bank_st_req_io_region_o[i] = 1'b0;
				l1d_bank_st_req_rob_tag_o[i * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH] = ls_pipe_l1d_input_arb_st_req_rob_tag[((i * N_ARB_ST_IN_PORT) + l1d_bank_st_req_grt_idx[i * N_ARB_ST_IN_PORT_W+:N_ARB_ST_IN_PORT_W]) * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH];
				l1d_bank_st_req_prd_o[i * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH] = ls_pipe_l1d_input_arb_st_req_prd[((i * N_ARB_ST_IN_PORT) + l1d_bank_st_req_grt_idx[i * N_ARB_ST_IN_PORT_W+:N_ARB_ST_IN_PORT_W]) * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH];
				l1d_bank_st_req_opcode_o[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] = ls_pipe_l1d_input_arb_st_req_opcode[((i * N_ARB_ST_IN_PORT) + l1d_bank_st_req_grt_idx[i * N_ARB_ST_IN_PORT_W+:N_ARB_ST_IN_PORT_W]) * 5+:5];
				l1d_bank_st_req_paddr_o[i * rvh_pkg_PADDR_WIDTH+:rvh_pkg_PADDR_WIDTH] = ls_pipe_l1d_input_arb_st_req_paddr[((i * N_ARB_ST_IN_PORT) + l1d_bank_st_req_grt_idx[i * N_ARB_ST_IN_PORT_W+:N_ARB_ST_IN_PORT_W]) * 56+:56];
				l1d_bank_st_req_data_o[i * 512+:512] = ls_pipe_l1d_st_req_data_transed[i * 512+:512];
				l1d_bank_st_req_data_byte_mask_o[i * 64+:64] = ls_pipe_l1d_st_req_data_byte_mask_transed[i * 64+:64];
			end
	end
	always @(*) begin
		dtlb_l1d_resp_vld_o = 1'sb0;
		dtlb_l1d_resp_excp_vld_o = 1'sb0;
		dtlb_l1d_resp_hit_o = 1'sb0;
		dtlb_l1d_resp_ppn_o = 1'sb0;
		begin : sv2v_autoblock_11
			reg signed [31:0] i;
			for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1)
				begin : sv2v_autoblock_12
					reg signed [31:0] j;
					for (j = 0; j < N_ARB_LD_IN_PORT; j = j + 1)
						if ((ld_req_bank_id_ff[0+:rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH] == i[rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH - 1:0]) & l1d_bank_ld_req_hsk_ff[(i * N_ARB_LD_IN_PORT) + j]) begin
							dtlb_l1d_resp_vld_o[i] = ls_pipe_l1d_dtlb_resp_vld_i[j];
							dtlb_l1d_resp_excp_vld_o[i] = ls_pipe_l1d_dtlb_resp_excp_vld_i[j];
							dtlb_l1d_resp_hit_o[i] = ls_pipe_l1d_dtlb_resp_hit_i[j];
							dtlb_l1d_resp_ppn_o[i * riscv_pkg_PPN_WIDTH+:riscv_pkg_PPN_WIDTH] = ls_pipe_l1d_dtlb_resp_ppn_i[j * riscv_pkg_PPN_WIDTH+:riscv_pkg_PPN_WIDTH];
						end
				end
		end
	end
endmodule
