module rct_w2m_bridge (
	clk_i,
	rstn_i,
	wb_stb_i,
	wb_addr_i,
	wb_we_i,
	wb_data_i,
	wb_sel_i,
	wb_cyc_i,
	wb_ack_o,
	wb_err_o,
	wb_data_o,
	mem_if_req_valid,
	mem_if_req_ready,
	mem_if_req,
	mem_if_resp_valid,
	mem_if_resp_ready,
	mem_if_resp
);
	parameter BUS_WIDTH = 32;
	parameter BUS_MASK = 4;
	input clk_i;
	input rstn_i;
	input wb_stb_i;
	input [BUS_WIDTH - 1:0] wb_addr_i;
	input wb_we_i;
	input [BUS_WIDTH - 1:0] wb_data_i;
	input [BUS_MASK - 1:0] wb_sel_i;
	input wb_cyc_i;
	output wire wb_ack_o;
	output wire wb_err_o;
	output wire [BUS_WIDTH - 1:0] wb_data_o;
	output wire mem_if_req_valid;
	input wire mem_if_req_ready;
	localparam rct_cfg_RCT_MEM_ADDR_W = 32;
	localparam rct_cfg_RCT_MEM_DATA_W = 32;
	localparam rct_cfg_RCT_MEM_MASK_W = 4;
	localparam rct_cfg_CPUNOC_TID_RID_SIZE = 4;
	localparam rct_cfg_CPUNOC_TID_SRCID_SIZE = 4;
	localparam rct_cfg_CPUNOC_TID_TID_SIZE = 8;
	output wire [86:0] mem_if_req;
	input wire mem_if_resp_valid;
	output wire mem_if_resp_ready;
	input wire [50:0] mem_if_resp;
	localparam MEM_IF_IDLE = 2'b00;
	localparam MEM_IF_REQ = 2'b01;
	localparam MEM_IF_RESP = 2'b10;
	wire wb_valid;
	wire mem_if_ready;
	wire rff_mem_if_ready;
	wire [1:0] wb_current_state;
	reg [1:0] wb_next_state;
	wire is_idle;
	wire is_req;
	wire is_resp;
	wire is_req_ready;
	wire is_resp_ready;
	assign wb_err_o = 1'b0;
	assign is_idle = wb_current_state == MEM_IF_IDLE;
	assign is_req = wb_current_state == MEM_IF_REQ;
	assign is_resp = wb_current_state == MEM_IF_RESP;
	assign wb_valid = wb_cyc_i && wb_stb_i;
	assign is_req_ready = wb_valid && mem_if_req_ready;
	assign is_resp_ready = wb_valid && mem_if_resp_valid;
	std_dffr #(.WIDTH(2)) wb_state_u(
		.clk(clk_i),
		.rstn(~rstn_i),
		.d(wb_next_state),
		.q(wb_current_state)
	);
	always @(*)
		case (1'b1)
			is_idle: wb_next_state = (wb_valid ? MEM_IF_REQ : wb_current_state);
			is_req: wb_next_state = (is_req_ready ? MEM_IF_RESP : wb_current_state);
			is_resp: wb_next_state = (is_resp_ready ? MEM_IF_IDLE : wb_current_state);
			default: wb_next_state = MEM_IF_IDLE;
		endcase
	assign mem_if_req_valid = is_req;
	assign mem_if_req[86-:3] = (wb_we_i ? 3'd1 : 3'd0);
	assign mem_if_req[83-:16] = 16'h0;
	assign mem_if_req[67-:32] = wb_addr_i;
	assign mem_if_req[31-:rct_cfg_RCT_MEM_DATA_W] = wb_data_i;
	assign mem_if_req[35-:4] = wb_sel_i;
	assign mem_if_resp_ready = is_resp;
	assign wb_ack_o = is_resp_ready;
	assign wb_data_o = mem_if_resp[31-:rct_cfg_RCT_MEM_DATA_W];
endmodule
