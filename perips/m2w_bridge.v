module rct_m2w_bridge (
	clk_i,
	rstn_i,
	mem_if_req_valid,
	mem_if_req_ready,
	mem_if_req,
	mem_if_resp_valid,
	mem_if_resp_ready,
	mem_if_resp,
	wb_stb_o,
	wb_addr_o,
	wb_we_o,
	wb_data_o,
	wb_sel_o,
	wb_cyc_o,
	wb_ack_i,
	wb_err_i,
	wb_data_i
);
	parameter BUS_WIDTH = 32;
	parameter BUS_MASK = 4;
	input clk_i;
	input rstn_i;
	input wire mem_if_req_valid;
	output wire mem_if_req_ready;
	localparam rct_cfg_RCT_MEM_ADDR_W = 32;
	localparam rct_cfg_RCT_MEM_DATA_W = 32;
	localparam rct_cfg_RCT_MEM_MASK_W = 4;
	localparam rct_cfg_CPUNOC_TID_RID_SIZE = 4;
	localparam rct_cfg_CPUNOC_TID_SRCID_SIZE = 4;
	localparam rct_cfg_CPUNOC_TID_TID_SIZE = 8;
	input wire [86:0] mem_if_req;
	output wire mem_if_resp_valid;
	input wire mem_if_resp_ready;
	output wire [50:0] mem_if_resp;
	output wire wb_stb_o;
	output wire [BUS_WIDTH - 1:0] wb_addr_o;
	output wire wb_we_o;
	output wire [BUS_WIDTH - 1:0] wb_data_o;
	output wire [BUS_MASK - 1:0] wb_sel_o;
	output wire wb_cyc_o;
	input wb_ack_i;
	input wb_err_i;
	input [BUS_WIDTH - 1:0] wb_data_i;
	localparam WB_IDLE = 2'b00;
	localparam WB_START = 2'b01;
	localparam WB_END = 2'b10;
	wire clk;
	wire rstn;
	reg memif_req_ready;
	reg memif_resp_valid;
	reg [BUS_WIDTH - 1:0] memif_resp_data;
	reg [2:0] memif_resp_type;
	reg [15:0] memif_resp_tid;
	reg wb_valid;
	reg wb_stb;
	reg wb_cyc;
	reg wb_we;
	reg [BUS_WIDTH - 1:0] wb_addr;
	reg [BUS_WIDTH - 1:0] wb_data;
	reg [BUS_MASK - 1:0] wb_mask;
	reg [15:0] wb_tid;
	wire [1:0] wb_current_state;
	reg [1:0] wb_next_state;
	wire is_idle;
	wire is_wb_start;
	wire is_wb_end;
	wire is_wb_ack;
	wire is_resp_ready;
	wire memif_we;
	assign memif_we = mem_if_req[86-:3] == 3'd1;
	assign is_idle = wb_current_state == WB_IDLE;
	assign is_wb_start = wb_current_state == WB_START;
	assign is_wb_end = wb_current_state == WB_END;
	std_dffr #(.WIDTH(2)) wb_state_u(
		.clk(clk_i),
		.rstn(~rstn_i),
		.d(wb_next_state),
		.q(wb_current_state)
	);
	assign is_wb_ack = wb_valid && wb_ack_i;
	assign is_resp_ready = mem_if_resp_ready;
	always @(*)
		case (1'b1)
			is_idle: wb_next_state = (mem_if_req_valid ? WB_START : wb_current_state);
			is_wb_start: wb_next_state = (is_wb_ack ? WB_END : wb_current_state);
			is_wb_end: wb_next_state = (is_resp_ready ? WB_IDLE : wb_current_state);
			default: wb_next_state = WB_IDLE;
		endcase
	always @(posedge clk_i or negedge rstn_i)
		if (!rstn_i) begin
			wb_valid <= 0;
			wb_stb <= 0;
			wb_cyc <= 0;
			wb_we <= 0;
			wb_tid <= 0;
			wb_addr <= 0;
			wb_data <= 0;
			wb_mask <= 0;
			memif_resp_valid <= 0;
		end
		else
			case (1'b1)
				is_idle:
					if (mem_if_req_valid) begin
						wb_valid <= 1'b1;
						wb_stb <= 1'b1;
						wb_cyc <= 1'b1;
						wb_we <= memif_we;
						wb_tid <= mem_if_req[83-:16];
						wb_addr <= mem_if_req[67-:32];
						wb_data <= mem_if_req[31-:rct_cfg_RCT_MEM_DATA_W];
						wb_mask <= mem_if_req[35-:4];
						memif_req_ready <= 1'b1;
					end
					else begin
						wb_valid <= 1'b0;
						wb_stb <= 1'b0;
						wb_cyc <= 1'b0;
						wb_we <= 1'b0;
						memif_req_ready <= 1'b0;
					end
				is_wb_start: begin
					memif_req_ready <= 1'b0;
					if (wb_ack_i) begin
						wb_stb <= 1'b0;
						wb_cyc <= 1'b0;
						wb_we <= 1'b0;
						memif_resp_valid <= 1'b1;
						memif_resp_type <= (wb_we ? 3'd1 : 3'd0);
						memif_resp_tid <= wb_tid;
						memif_resp_data <= wb_data_i;
					end
				end
				is_wb_end:
					if (mem_if_resp_ready)
						memif_resp_valid <= 1'b0;
			endcase
	assign mem_if_req_ready = memif_req_ready;
	assign mem_if_resp_valid = memif_resp_valid;
	assign mem_if_resp[50-:3] = memif_resp_type;
	assign mem_if_resp[47-:16] = memif_resp_tid;
	assign mem_if_resp[31-:rct_cfg_RCT_MEM_DATA_W] = memif_resp_data;
	assign wb_cyc_o = wb_cyc;
	assign wb_stb_o = wb_stb;
	assign wb_we_o = wb_we;
	assign wb_addr_o = wb_addr;
	assign wb_data_o = wb_data;
	assign wb_sel_o = wb_mask;
endmodule
