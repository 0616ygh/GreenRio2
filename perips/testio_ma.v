module rct_testio_ma (
	rstn_i,
	test_intr,
	test_clk,
	test_din,
	test_dout,
	test_doen,
	mem_if_req_valid,
	mem_if_req_ready,
	mem_if_req,
	mem_if_resp_valid,
	mem_if_resp_ready,
	mem_if_resp
);
	input wire rstn_i;
	output wire test_intr;
	input wire test_clk;
	input wire test_din;
	output reg test_dout;
	output reg test_doen;
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
	assign test_intr = 1'b0;
	localparam signed [31:0] N_CNT_BITS = 7;
	localparam [6:0] N_CMD_BITS = 1;
	localparam [6:0] N_ADDR_BITS = 32;
	localparam [6:0] N_STRB_BITS = 4;
	localparam [6:0] N_DATA_BITS = 32;
	localparam [6:0] N_PRTY_BITS = 1;
	localparam [6:0] N_ACK_BITS = 1;
	localparam [6:0] N_CMDBUF_BITS = (((N_CMD_BITS + N_ADDR_BITS) + N_DATA_BITS) + N_STRB_BITS) + N_PRTY_BITS;
	localparam [N_CMD_BITS - 1:0] CMD_RD = 0;
	localparam [N_CMD_BITS - 1:0] CMD_WR = 1;
	localparam [0:0] START = 0;
	localparam [0:0] STOP = 1;
	localparam [N_ACK_BITS - 1:0] ACK_OK = {N_ACK_BITS {1'b0}};
	localparam [N_ACK_BITS - 1:0] ACK_ERR = {N_ACK_BITS {1'b1}};
	wire [N_DATA_BITS - 1:0] resp_data;
	reg [2:0] rff_cdcst;
	reg [2:0] next_cdcst;
	wire test_rstn;
	assign test_rstn = rstn_i;
	reg dff_test_din;
	always @(posedge test_clk) dff_test_din <= test_din;
	wire test_din_en;
	reg dff_test_din_en;
	wire test_din_neg;
	reg [6:0] rff_cmd_idx_max;
	reg [6:0] rff_cmd_idx;
	assign test_din_en = |rff_cmd_idx;
	assign test_din_neg = (dff_test_din == 1'b1) && (test_din == 1'b0);
	always @(posedge test_clk or negedge test_rstn)
		if (test_rstn == 1'b0)
			dff_test_din_en <= 1'd0;
		else
			dff_test_din_en <= test_din_en;
	wire [N_CMD_BITS - 1:0] cmd;
	always @(*)
		if (cmd == CMD_WR)
			rff_cmd_idx_max = (((1 + N_ADDR_BITS) + N_STRB_BITS) + N_DATA_BITS) + N_PRTY_BITS;
		else if (cmd == CMD_RD)
			rff_cmd_idx_max = (1 + N_ADDR_BITS) + N_PRTY_BITS;
		else
			rff_cmd_idx_max = {N_CNT_BITS {1'b1}};
	always @(posedge test_clk or negedge test_rstn)
		if (test_rstn == 1'b0)
			rff_cmd_idx <= {N_CNT_BITS {1'b0}};
		else if (rff_cmd_idx >= rff_cmd_idx_max)
			rff_cmd_idx <= {N_CNT_BITS {1'b0}};
		else if (test_din_en)
			rff_cmd_idx <= rff_cmd_idx + 1'b1;
		else if (test_doen && test_din_neg)
			rff_cmd_idx <= rff_cmd_idx + 1'b1;
		else
			rff_cmd_idx <= {N_CNT_BITS {1'b0}};
	reg [N_CMDBUF_BITS:1] dff_cmdbuf;
	always @(posedge test_clk)
		if (test_din_en)
			dff_cmdbuf[rff_cmd_idx] <= test_din;
	wire [N_ADDR_BITS - 1:0] addr;
	wire [N_STRB_BITS - 1:0] wstrb;
	wire [N_DATA_BITS - 1:0] wdata;
	wire [N_PRTY_BITS - 1:0] prty;
	genvar i;
	generate
		for (i = 0; i < N_CMD_BITS; i = i + 1) begin : CMD_REORDER_GEN
			assign cmd[i] = dff_cmdbuf[N_CMD_BITS - i];
		end
		for (i = 0; i < N_ADDR_BITS; i = i + 1) begin : ADDR_REORDER_GEN
			assign addr[i] = dff_cmdbuf[(N_CMD_BITS + N_ADDR_BITS) - i];
		end
		for (i = 0; i < N_STRB_BITS; i = i + 1) begin : STRB_REORDER_GEN
			assign wstrb[i] = dff_cmdbuf[((N_CMD_BITS + N_ADDR_BITS) + N_STRB_BITS) - i];
		end
		for (i = 0; i < N_DATA_BITS; i = i + 1) begin : WDATA_REORDER_GEN
			assign wdata[i] = dff_cmdbuf[(((N_CMD_BITS + N_ADDR_BITS) + N_STRB_BITS) + N_DATA_BITS) - i];
		end
	endgenerate
	function automatic [6:0] sv2v_cast_70A79;
		input reg [6:0] inp;
		sv2v_cast_70A79 = inp;
	endfunction
	function automatic [sv2v_cast_70A79(1) - 1:0] sv2v_cast_45798;
		input reg [sv2v_cast_70A79(1) - 1:0] inp;
		sv2v_cast_45798 = inp;
	endfunction
	generate
		for (i = 0; i < N_PRTY_BITS; i = i + 1) begin : PRTY_REORDER_GEN
			assign prty[i] = (cmd == sv2v_cast_45798(1) ? dff_cmdbuf[((((N_CMD_BITS + N_ADDR_BITS) + N_STRB_BITS) + N_DATA_BITS) + N_PRTY_BITS) - i] : dff_cmdbuf[((N_CMD_BITS + N_ADDR_BITS) + N_PRTY_BITS) - i]);
		end
	endgenerate
	wire prty_wreq_exp;
	wire prty_rreq_exp;
	reg [N_ACK_BITS - 1:0] ack;
	assign prty_wreq_exp = ^{CMD_WR, addr, wstrb, wdata};
	assign prty_rreq_exp = ^{CMD_RD, addr};
	always @(posedge test_clk)
		if (cmd == CMD_WR)
			ack <= (prty == prty_wreq_exp ? ACK_OK : ACK_ERR);
		else if (cmd == CMD_RD)
			ack <= (prty == prty_rreq_exp ? ACK_OK : ACK_ERR);
		else
			ack <= ack;
	wire [N_PRTY_BITS - 1:0] rprty;
	wire [N_PRTY_BITS - 1:0] wprty;
	assign rprty = ^{ack, resp_data};
	assign wprty = ^{ack};
	reg [(((1 + N_ACK_BITS) + N_DATA_BITS) + N_PRTY_BITS) + 0:0] dff_payload;
	reg [6:0] rff_payload_idx;
	reg rff_payload_in_progress;
	always @(posedge test_clk)
		if (cmd == CMD_RD) begin
			if (mem_if_resp_valid & mem_if_resp_ready)
				dff_payload <= {START, ack, resp_data, rprty, STOP};
			else
				dff_payload <= dff_payload;
		end
		else if (cmd == CMD_WR) begin
			if ((rff_cdcst == 3'd5) && (mem_if_resp_valid == 1'b1))
				dff_payload <= {START, ack, wprty, STOP, 32'hffffffff};
			else
				dff_payload <= dff_payload;
		end
		else
			dff_payload <= dff_payload;
	always @(posedge test_clk or negedge test_rstn)
		if (test_rstn == 1'b0)
			rff_payload_idx <= {N_CNT_BITS {1'b0}};
		else
			case (cmd)
				CMD_RD:
					if (mem_if_resp_valid & mem_if_resp_ready)
						rff_payload_idx <= {N_CNT_BITS {1'b0}};
					else if (rff_payload_in_progress)
						rff_payload_idx <= rff_payload_idx + 1'b1;
				CMD_WR:
					if ((rff_cdcst == 3'd5) && (mem_if_resp_valid == 1'b1))
						rff_payload_idx <= {N_CNT_BITS {1'b0}};
					else if (rff_payload_in_progress)
						rff_payload_idx <= rff_payload_idx + 1'b1;
			endcase
	always @(posedge test_clk or negedge test_rstn)
		if (test_rstn == 1'b0)
			rff_payload_in_progress <= 1'b0;
		else
			case (cmd)
				CMD_RD:
					if (mem_if_resp_valid & mem_if_resp_ready)
						rff_payload_in_progress <= 1'b1;
					else if (rff_payload_idx == ((((1 + N_ACK_BITS) + N_DATA_BITS) + N_PRTY_BITS) + 0))
						rff_payload_in_progress <= 1'b0;
				CMD_WR:
					if ((rff_cdcst == 3'd5) && (mem_if_resp_valid == 1'b1))
						rff_payload_in_progress <= 1'b1;
					else if (rff_payload_idx == (((1 + N_ACK_BITS) + N_PRTY_BITS) + 0))
						rff_payload_in_progress <= 1'b0;
			endcase
	always @(posedge test_clk or negedge test_rstn)
		if (test_rstn == 1'b0)
			rff_cdcst <= 3'd0;
		else
			rff_cdcst <= next_cdcst;
	always @(*) begin
		next_cdcst = rff_cdcst;
		case (rff_cdcst)
			3'd0:
				if (dff_test_din_en && !test_din_en)
					next_cdcst = 3'd1;
			3'd1:
				case (cmd)
					CMD_RD: next_cdcst = 3'd2;
					CMD_WR: next_cdcst = 3'd4;
					default: next_cdcst = 3'd0;
				endcase
			3'd2:
				if (mem_if_req_ready)
					next_cdcst = 3'd3;
			3'd3:
				if (mem_if_resp_valid)
					next_cdcst = 3'd0;
			3'd4:
				if (mem_if_req_ready)
					next_cdcst = 3'd5;
			3'd5:
				if (mem_if_resp_valid)
					next_cdcst = 3'd0;
		endcase
	end
	always @(*) begin
		test_doen = 1'b1;
		test_dout = 1'b1;
		if (rff_payload_in_progress == 1'b1) begin
			test_doen = 1'b0;
			test_dout = dff_payload[((((1 + N_ACK_BITS) + N_DATA_BITS) + N_PRTY_BITS) + 0) - rff_payload_idx];
		end
	end
	assign mem_if_req_valid = (rff_cdcst == 3'd4) | (rff_cdcst == 3'd2);
	assign mem_if_req[86-:3] = (cmd ? 3'd1 : 3'd0);
	assign mem_if_req[83-:16] = 16'h0;
	assign mem_if_req[67-:32] = addr[31:0];
	assign mem_if_req[35-:4] = wstrb[3:0];
	assign mem_if_req[31-:rct_cfg_RCT_MEM_DATA_W] = wdata[31:0];
	assign mem_if_resp_ready = (rff_cdcst == 3'd5) | (rff_cdcst == 3'd3);
	// assign resp_data = {{(N_DATA_BITS - rct_cfg_RCT_MEM_DATA_W){1'b0}}, mem_if_resp[31-:rct_cfg_RCT_MEM_DATA_W]};
	assign resp_data = mem_if_resp[31:0];
endmodule
