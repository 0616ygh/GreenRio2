module rct_testio (
	mem_if_req_valid,
	mem_if_req_ready,
	mem_if_req,
	mem_if_resp_valid,
	mem_if_resp_ready,
	mem_if_resp,
	ti_clk_i,
	ti_rstn_i,
	ti_mod_i,
	ti_dat_i,
	ti_clk_o,
	ti_clk_oen,
	ti_dat_o,
	ti_dat_oen,
	ti_int_o
);
	parameter DATA_W = 32;
	parameter MASK_W = 4;
	parameter TIO_W = 1;
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
	input wire ti_clk_i;
	input wire ti_rstn_i;
	input wire [1:0] ti_mod_i;
	input wire [TIO_W - 1:0] ti_dat_i;
	output wire ti_clk_o;
	output wire ti_clk_oen;
	output wire [TIO_W - 1:0] ti_dat_o;
	output wire [TIO_W - 1:0] ti_dat_oen;
	output wire ti_int_o;
	localparam TI_IDLE = 4'b0000;
	localparam TI_WR_SEND = 4'b0001;
	localparam TI_WR_RCV_IDLE = 4'b0010;
	localparam TI_WR_RCV_ACK = 4'b0011;
	localparam TI_WR_RCV_PARITY = 4'b0100;
	localparam TI_WR_RCV = 4'b0101;
	localparam TI_RD_SEND = 4'b0110;
	localparam TI_RD_RCV_IDLE = 4'b0111;
	localparam TI_RD_RCV_ACK = 4'b1000;
	localparam TI_RD_RCV = 4'b1001;
	localparam TI_RESP = 4'b1010;
	localparam TI_ACK_ERR = 4'b1011;
	localparam MODE_OUTPUT_WORD = 32'h00000000;
	localparam IDLE_DATA_VALUE = 32'hffffffff;
	localparam MODE_BIT = 2'b00;
	localparam MODE_BYTE = 2'b01;
	localparam MODE_HALF = 2'b10;
	localparam MODE_WORD = 2'b11;
	localparam TI_BIT = 1;
	localparam TI_BYTE = 8;
	localparam TI_HALF = 16;
	localparam TI_WORD = 32;
	reg [50:0] dff_mem_if_resp;
	wire ti_valid;
	wire ti_type;
	wire ti_mem_if_resq_ready;
	wire [MASK_W - 1:0] ti_strb;
	wire [DATA_W - 1:0] ti_addr;
	wire [DATA_W - 1:0] ti_data;
	wire mem_if_cap_rdy;
	reg [3:0] ti_current_state;
	reg [3:0] ti_pre_state;
	reg [3:0] ti_next_state;
	wire is_idle;
	wire is_wr_send;
	wire is_rd_send;
	wire is_rd_rcv;
	wire is_resp;
	wire ti_send_done;
	wire ti_rcv_start;
	wire ti_rcv_ack;
	wire ti_rcv_parity;
	wire ti_rcv_stop;
	wire ti_rcv_done;
	wire is_send_mode;
	wire is_counter_ena;
	wire is_state_changed;
	assign ti_int_o = 1'b0;
	assign mem_if_cap_rdy = mem_if_req_valid && is_idle;
	always @(posedge ti_clk_i)
		if (mem_if_cap_rdy) begin
			dff_mem_if_resp[50-:3] <= mem_if_req[86-:3];
			dff_mem_if_resp[47-:16] <= mem_if_req[83-:16];
		end
	assign ti_mem_if_resq_ready = mem_if_resp_ready;
	assign ti_valid = mem_if_req_valid;
	assign ti_type = mem_if_req[86-:3] == 3'd1;
	assign ti_addr = mem_if_req[67-:32];
	assign ti_data = mem_if_req[31-:rct_cfg_RCT_MEM_DATA_W];
	assign ti_strb = mem_if_req[35-:4];
	assign is_idle = ti_current_state == TI_IDLE;
	assign is_wr_send = ti_current_state == TI_WR_SEND;
	assign is_rd_send = ti_current_state == TI_RD_SEND;
	assign is_rd_rcv = ti_current_state == TI_RD_RCV;
	assign is_resp = ti_current_state == TI_RESP;
	assign is_send_mode = is_wr_send | is_rd_send;
	assign is_counter_ena = is_send_mode | is_rd_rcv;
	wire [5:0] ti_fsm_ctrl_mux;
	wire [5:0] ti_fsm_ctrl_bit;
	// wire [5:0] ti_fsm_ctrl_byte;
	// wire [5:0] ti_fsm_ctrl_half;
	// wire [5:0] ti_fsm_ctrl_word;
	assign ti_rcv_start = ti_fsm_ctrl_mux[5];
	assign ti_rcv_ack = ti_fsm_ctrl_mux[4];
	assign ti_rcv_parity = ti_fsm_ctrl_mux[3];
	assign ti_rcv_stop = ti_fsm_ctrl_mux[2];
	assign ti_rcv_done = ti_fsm_ctrl_mux[1];
	assign ti_send_done = ti_fsm_ctrl_mux[0];
	assign is_state_changed = ti_current_state != ti_pre_state;
	wire [5:0] ti_ctrl;
	wire [5:0] ti_ctrl_bit;
	// wire [5:0] ti_ctrl_byte;
	// wire [5:0] ti_ctrl_half;
	// wire [5:0] ti_ctrl_word;
	assign ti_ctrl = {is_state_changed, is_wr_send, is_rd_send, is_rd_rcv, is_send_mode, is_counter_ena};
	always @(posedge ti_clk_i or negedge ti_rstn_i)
		if (!ti_rstn_i)
			ti_pre_state <= TI_IDLE;
		else
			ti_pre_state <= ti_current_state;
	always @(posedge ti_clk_i or negedge ti_rstn_i)
		if (!ti_rstn_i)
			ti_current_state <= TI_IDLE;
		else
			ti_current_state <= ti_next_state;
	wire [3:0] ti_send_mode;
	assign ti_send_mode = (ti_type ? TI_WR_SEND : TI_RD_SEND);
	always @(*)
		case (ti_current_state)
			TI_IDLE: ti_next_state = (ti_valid ? ti_send_mode : ti_current_state);
			TI_WR_SEND: ti_next_state = (ti_send_done ? TI_WR_RCV_IDLE : ti_current_state);
			TI_WR_RCV_IDLE: ti_next_state = (ti_rcv_start ? TI_WR_RCV_ACK : ti_current_state);
			TI_WR_RCV_ACK: ti_next_state = (ti_rcv_ack ? TI_WR_RCV_PARITY : TI_ACK_ERR);
			TI_WR_RCV_PARITY: ti_next_state = (ti_rcv_parity ? TI_WR_RCV : TI_ACK_ERR);
			TI_WR_RCV: ti_next_state = (ti_rcv_stop ? TI_RESP : ti_current_state);
			TI_RD_SEND: ti_next_state = (ti_send_done ? TI_RD_RCV_IDLE : ti_current_state);
			TI_RD_RCV_IDLE: ti_next_state = (ti_rcv_start ? TI_RD_RCV_ACK : ti_current_state);
			TI_RD_RCV_ACK: ti_next_state = (ti_rcv_ack ? TI_RD_RCV : TI_ACK_ERR);
			TI_RD_RCV: ti_next_state = (ti_rcv_done ? TI_RESP : ti_current_state);
			TI_RESP: ti_next_state = (ti_mem_if_resq_ready ? TI_IDLE : ti_current_state);
			TI_ACK_ERR: ti_next_state = TI_IDLE;
			default: ti_next_state = TI_IDLE;
		endcase
	wire [DATA_W - 1:0] resp_data_mux;
	wire [DATA_W - 1:0] resp_data_bit;
	// wire [DATA_W - 1:0] resp_data_byte;
	// wire [DATA_W - 1:0] resp_data_half;
	// wire [DATA_W - 1:0] resp_data_word;
	wire [TIO_W - 1:0] ti_send_data_mux;
	wire ti_send_data_bit;
	// wire [7:0] ti_send_data_byte;
	// wire [15:0] ti_send_data_half;
	// wire [31:0] ti_send_data_word;
	wire [TIO_W - 1:0] ti_data_oen_mux;
	wire  ti_data_oen_bit;
	// wire [7:0] ti_data_oen_byte;
	// wire [15:0] ti_data_oen_half;
	// wire [31:0] ti_data_oen_word;
	reg [TIO_W - 1:0] rff_ti_send_data;
	reg [TIO_W - 1:0] rff_ti_data_oen;
	wire ti_en_bit;
	// wire ti_en_byte;
	// wire ti_en_half;
	// wire ti_en_word;
	assign ti_en_bit = ti_mod_i == MODE_BIT;
	// assign ti_en_byte = ti_mod_i == MODE_BYTE;
	// assign ti_en_half = ti_mod_i == MODE_HALF;
	// assign ti_en_word = ti_mod_i == MODE_WORD;
	assign ti_ctrl_bit = {6 {ti_en_bit}} & ti_ctrl;
	// assign ti_ctrl_byte = {6 {ti_en_byte}} & ti_ctrl;
	// assign ti_ctrl_half = {6 {ti_en_half}} & ti_ctrl;
	// assign ti_ctrl_word = {6 {ti_en_word}} & ti_ctrl;
	testio_trx #(.TI_W(TI_BIT)) testio_trx_bit_u(
		.req_type(ti_type),
		.req_addr(ti_addr),
		.req_data(ti_data),
		.req_strb(ti_strb),
		.resp_data(resp_data_bit),
		.ti_ctrl(ti_ctrl_bit),
		.ti_clk(ti_clk_i),
		.ti_rstn(ti_rstn_i),
		.ti_din(ti_dat_i),
		.ti_dout(ti_send_data_bit),
		.ti_doen(ti_data_oen_bit),
		.ti_fsm_ctrl(ti_fsm_ctrl_bit)
	);
	// testio_trx #(.TI_W(TI_BYTE)) testio_trx_byte_u(
	// 	.req_type(ti_type),
	// 	.req_addr(ti_addr),
	// 	.req_data(ti_data),
	// 	.req_strb(ti_strb),
	// 	.resp_data(resp_data_byte),
	// 	.ti_ctrl(ti_ctrl_byte),
	// 	.ti_clk(ti_clk_i),
	// 	.ti_rstn(ti_rstn_i),
	// 	.ti_din(ti_dat_i[7:0]),
	// 	.ti_dout(ti_send_data_byte),
	// 	.ti_doen(ti_data_oen_byte),
	// 	.ti_fsm_ctrl(ti_fsm_ctrl_byte)
	// );
	// testio_trx #(.TI_W(TI_HALF)) testio_trx_half_u(
	// 	.req_type(ti_type),
	// 	.req_addr(ti_addr),
	// 	.req_data(ti_data),
	// 	.req_strb(ti_strb),
	// 	.resp_data(resp_data_half),
	// 	.ti_ctrl(ti_ctrl_half),
	// 	.ti_clk(ti_clk_i),
	// 	.ti_rstn(ti_rstn_i),
	// 	.ti_din(ti_dat_i[15:0]),
	// 	.ti_dout(ti_send_data_half),
	// 	.ti_doen(ti_data_oen_half),
	// 	.ti_fsm_ctrl(ti_fsm_ctrl_half)
	// );
	// testio_trx #(.TI_W(TI_WORD)) testio_trx_word_u(
	// 	.req_type(ti_type),
	// 	.req_addr(ti_addr),
	// 	.req_data(ti_data),
	// 	.req_strb(ti_strb),
	// 	.resp_data(resp_data_word),
	// 	.ti_ctrl(ti_ctrl_word),
	// 	.ti_clk(ti_clk_i),
	// 	.ti_rstn(ti_rstn_i),
	// 	.ti_din(ti_dat_i[31:0]),
	// 	.ti_dout(ti_send_data_word),
	// 	.ti_doen(ti_data_oen_word),
	// 	.ti_fsm_ctrl(ti_fsm_ctrl_word)
	// );
	always @(negedge ti_clk_i or negedge ti_rstn_i)
		if (!ti_rstn_i)
			rff_ti_send_data <= 'h0;
		else
			rff_ti_send_data <= ti_send_data_mux;
	always @(negedge ti_clk_i or negedge ti_rstn_i)
		if (!ti_rstn_i)
			rff_ti_data_oen <= 'h0;
		else
			rff_ti_data_oen <= ti_data_oen_mux;
	// assign ti_fsm_ctrl_mux = (ti_mod_i[1] ? (ti_mod_i[0] ? ti_fsm_ctrl_word : ti_fsm_ctrl_half) : (ti_mod_i[0] ? ti_fsm_ctrl_byte : ti_fsm_ctrl_bit));
	// assign ti_send_data_mux = (ti_mod_i[1] ? (ti_mod_i[0] ? ti_send_data_word[31:0] : {2 {ti_send_data_half[15:0]}}) : (ti_mod_i[0] ? {4 {ti_send_data_byte[7:0]}} : {32 {ti_send_data_bit[0]}}));
	// assign ti_data_oen_mux = (ti_mod_i[1] ? (ti_mod_i[0] ? ti_data_oen_word[31:0] : {2 {ti_data_oen_half[15:0]}}) : (ti_mod_i[0] ? {4 {ti_data_oen_byte[7:0]}} : {32 {ti_data_oen_bit[0]}}));
	// assign resp_data_mux = (ti_mod_i[1] ? (ti_mod_i[0] ? resp_data_word : resp_data_half) : (ti_mod_i[0] ? resp_data_byte : resp_data_bit));
	assign ti_fsm_ctrl_mux = ti_fsm_ctrl_bit;
	assign ti_send_data_mux = {{32{ti_send_data_bit}}};
	assign ti_data_oen_mux = {32{ti_data_oen_bit}};
	assign resp_data_mux = resp_data_bit;
	assign ti_clk_oen = MODE_OUTPUT_WORD[0];
	assign ti_clk_o = ti_clk_i;
	assign ti_dat_o = rff_ti_send_data;
	assign ti_dat_oen = rff_ti_data_oen;
	assign mem_if_req_ready = ti_valid && is_idle;
	assign mem_if_resp_valid = is_resp;
	assign mem_if_resp[50-:3] = dff_mem_if_resp[50-:3];
	assign mem_if_resp[47-:16] = dff_mem_if_resp[47-:16];
	assign mem_if_resp[31-:rct_cfg_RCT_MEM_DATA_W] = (mem_if_resp_valid ? resp_data_mux : IDLE_DATA_VALUE);
endmodule
