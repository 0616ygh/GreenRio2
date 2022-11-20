module testio_trx (
	req_type,
	req_addr,
	req_data,
	req_strb,
	resp_data,
	resp_data_err,
	ti_ctrl,
	ti_clk,
	ti_rstn,
	ti_din,
	ti_dout,
	ti_doen,
	ti_fsm_ctrl
);
	parameter DATA_W = 32;
	parameter MASK_W = 4;
	parameter TI_W = 1;
	input wire req_type;
	input wire [DATA_W - 1:0] req_addr;
	input wire [DATA_W - 1:0] req_data;
	input wire [MASK_W - 1:0] req_strb;
	output wire [DATA_W - 1:0] resp_data;
	output wire resp_data_err;
	input wire [5:0] ti_ctrl;
	input wire ti_clk;
	input wire ti_rstn;
	input wire [TI_W - 1:0] ti_din;
	output wire [TI_W - 1:0] ti_dout;
	output wire [TI_W - 1:0] ti_doen;
	output wire [5:0] ti_fsm_ctrl;
	localparam N_CNT_BITS = 8;
	localparam TI_START_CYCLE = 1;
	localparam TI_TYPE_CYCLE = 1;
	localparam TI_PARITY_CYCLE = 1;
	localparam TI_STOP_CYCLE = 1;
	localparam TI_ACK_CYCLE = 1;
	localparam TI_ADDR_CYCLE = DATA_W / TI_W;
	localparam TI_STRB_CYCLE = (TI_W == 1 ? MASK_W / TI_W : 1);
	localparam TI_DATA_CYCLE = DATA_W / TI_W;
	localparam TI_HOST_CYC_COM = 3;
	localparam TI_WR_ACK_CYC = 2;
	localparam TI_RD_ACK_CYC = 1;
	localparam TI_WR_HOST_CYC = ((TI_HOST_CYC_COM + TI_ADDR_CYCLE) + TI_STRB_CYCLE) + TI_DATA_CYCLE;
	localparam TI_RD_HOST_CYC = TI_HOST_CYC_COM + TI_ADDR_CYCLE;
	localparam TI_RD_TARG_CYC = TI_RD_ACK_CYC + TI_DATA_CYCLE;
	localparam TI_SEND_BUF_W = TI_WR_HOST_CYC + 1;
	localparam TI_RCV_BUF_W = TI_RD_TARG_CYC + 1;
	localparam TI_MASK_W = (TI_W == 1 ? MASK_W : TI_W);
	localparam [0:0] START = 1'b0;
	localparam [0:0] STOP = 1'b1;
	localparam [0:0] WRITE = 1'b1;
	localparam [0:0] READ = 1'b0;
	localparam [0:0] ACK_OK = 1'b0;
	localparam [0:0] ACK_ERR = 1'b1;
	localparam [0:0] PARITY_OK = 1'b0;
	localparam [0:0] PARITY_ERR = 1'b1;
	localparam MODE_INPUT_WORD = 'hffffffff;
	localparam MODE_OUTPUT_WORD = 'h0;
	localparam IDLE_DATA_VALUE = 'hffffffff;
	wire [7:0] ti_wr_host_cycle;
	wire [7:0] ti_rd_host_cycle;
	wire [7:0] ti_rd_targ_cycle;
	wire [(TI_SEND_BUF_W * TI_W) - 1:0] ti_wr_send_data_mux;
	wire [7:0] ti_cycle_count;
	reg [7:0] ti_cycle_counter;
	reg [(TI_SEND_BUF_W * TI_W) - 1:0] ti_send_buf;
	reg [TI_W - 1:0] ti_data_parity;
	reg [(TI_RCV_BUF_W * TI_W) - 1:0] ti_rcv_buf;
	reg [TI_W - 1:0] ti_rcv_data_parity;
	wire [MASK_W - 1:0] ti_strb;
	wire [DATA_W - 1:0] ti_addr;
	wire [DATA_W - 1:0] ti_data;
	wire is_wr_send;
	wire is_rd_send;
	wire is_rd_rcv;
	wire is_send_mode;
	wire is_counter_ena;
	wire is_state_changed;
	wire is_counter_reload;
	wire is_cycle_count_eq_zero;
	wire is_cycle_count_eq_one;
	wire ti_send_done;
	wire ti_rcv_start;
	wire ti_rcv_ack;
	wire ti_rcv_parity;
	wire ti_rcv_stop;
	wire ti_rcv_done;
	assign is_cycle_count_eq_zero = ti_cycle_counter == 8'h00;
	assign is_cycle_count_eq_one = ti_cycle_counter == 8'h01;
	assign ti_rcv_start = ti_din[0] == START;
	assign ti_rcv_ack = ti_din[0] == ACK_OK;
	assign ti_rcv_parity = ti_din == {TI_W {PARITY_OK}};
	assign ti_rcv_stop = ti_din[0] == STOP;
	assign ti_rcv_done = is_cycle_count_eq_zero;
	assign ti_send_done = is_cycle_count_eq_zero;
	assign ti_addr = req_addr;
	assign ti_data = req_data;
	assign ti_strb = req_strb;
	assign ti_fsm_ctrl[5] = ti_rcv_start;
	assign ti_fsm_ctrl[4] = ti_rcv_ack;
	assign ti_fsm_ctrl[3] = ti_rcv_parity;
	assign ti_fsm_ctrl[2] = ti_rcv_stop;
	assign ti_fsm_ctrl[1] = ti_rcv_done;
	assign ti_fsm_ctrl[0] = ti_send_done;
	wire [(TI_SEND_BUF_W * TI_W) - 1:0] ti_wr_send_data;
	wire [(TI_SEND_BUF_W * TI_W) - 1:0] ti_rd_send_data;
	wire [TI_W - 1:0] ti_wr_send_parity_w;
	wire [TI_W - 1:0] ti_start_w;
	wire [TI_W - 1:0] ti_write_w;
	wire [TI_W - 1:0] ti_read_w;
	wire [TI_W - 1:0] ti_stop_w;
	wire [DATA_W - 1:0] ti_addr_w;
	wire [DATA_W - 1:0] ti_data_w;
	wire [TI_MASK_W - 1:0] ti_strb_w;
	assign ti_start_w = {TI_W {START}};
	assign ti_write_w = {TI_W {WRITE}};
	assign ti_read_w = {TI_W {READ}};
	assign ti_stop_w = {TI_W {STOP}};
	assign ti_addr_w = ti_addr;
	assign ti_data_w = ti_data;
	// assign ti_strb_w = {{TI_MASK_W - MASK_W {1'b0}}, ti_strb};
	assign ti_strb_w = ti_strb;
	assign ti_wr_send_parity_w = {TI_W {PARITY_OK}};
	assign ti_wr_send_data = {ti_start_w, ti_write_w, ti_addr_w, ti_strb_w, ti_data_w, ti_wr_send_parity_w, ti_stop_w};
	assign ti_rd_send_data = {ti_start_w, ti_read_w, ti_addr_w, ti_wr_send_parity_w, ti_stop_w, {(TI_STRB_CYCLE + TI_DATA_CYCLE) * TI_W {1'b1}}};
	assign ti_wr_host_cycle = TI_WR_HOST_CYC[7:0];
	assign ti_rd_host_cycle = TI_RD_HOST_CYC[7:0];
	assign ti_rd_targ_cycle = TI_RD_TARG_CYC[7:0];
	assign ti_wr_send_data_mux = (is_wr_send ? ti_wr_send_data : ti_rd_send_data);
	assign is_state_changed = ti_ctrl[5];
	assign is_wr_send = ti_ctrl[4];
	assign is_rd_send = ti_ctrl[3];
	assign is_rd_rcv = ti_ctrl[2];
	assign is_send_mode = ti_ctrl[1];
	assign is_counter_ena = ti_ctrl[0];
	assign is_counter_reload = is_state_changed;
	assign ti_cycle_count = (is_wr_send ? ti_wr_host_cycle : (is_rd_send ? ti_rd_host_cycle : (is_rd_rcv ? ti_rd_targ_cycle : 8'hff)));
	always @(posedge ti_clk or negedge ti_rstn)
		if (!ti_rstn)
			ti_cycle_counter <= 8'hff;
		else if (is_counter_reload)
			ti_cycle_counter <= ti_cycle_count;
		else if (is_counter_ena)
			ti_cycle_counter <= ti_cycle_counter - 1'b1;
	wire [TI_W - 1:0] rff_ti_rcv_data;
	wire [TI_W - 1:0] rff_ti_data_parity;
	std_dffr #(.WIDTH(TI_W)) ti_rcv_data_u(
		.clk(ti_clk),
		.rstn(~ti_rstn),
		.d(ti_din),
		.q(rff_ti_rcv_data)
	);
	always @(negedge ti_clk or negedge ti_rstn)
		if (!ti_rstn)
			ti_send_buf <= 'h0;
		else if (is_state_changed) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < TI_SEND_BUF_W; i = i + 1)
				if (is_send_mode)
					ti_send_buf[i * TI_W+:TI_W] <= ti_wr_send_data_mux[((TI_SEND_BUF_W - 1) - i) * TI_W+:TI_W];
		end
		else if (is_send_mode)
			ti_send_buf <= {1'b0, ti_send_buf[TI_W * (((TI_SEND_BUF_W - 1) >= 1 ? TI_SEND_BUF_W - 1 : ((TI_SEND_BUF_W - 1) + ((TI_SEND_BUF_W - 1) >= 1 ? TI_SEND_BUF_W - 1 : 3 - TI_SEND_BUF_W)) - 1) - (((TI_SEND_BUF_W - 1) >= 1 ? TI_SEND_BUF_W - 1 : 3 - TI_SEND_BUF_W) - 1))+:TI_W * ((TI_SEND_BUF_W - 1) >= 1 ? TI_SEND_BUF_W - 1 : 3 - TI_SEND_BUF_W)]};
	always @(negedge ti_clk or negedge ti_rstn)
		if (!ti_rstn)
			ti_data_parity <= 'h0;
		else if (is_state_changed)
			ti_data_parity <= 'h0;
		else if (is_send_mode)
			ti_data_parity <= ti_data_parity ^ ti_send_buf[0+:TI_W];
	always @(posedge ti_clk or negedge ti_rstn)
		if (!ti_rstn)
			ti_rcv_buf <= 'h0;
		else if (is_state_changed)
			ti_rcv_buf <= ti_rcv_buf;
		else if (is_rd_rcv)
			ti_rcv_buf <= {ti_rcv_buf[TI_W * (((TI_RCV_BUF_W - 2) >= 0 ? TI_RCV_BUF_W - 2 : ((TI_RCV_BUF_W - 2) + ((TI_RCV_BUF_W - 2) >= 0 ? TI_RCV_BUF_W - 1 : 3 - TI_RCV_BUF_W)) - 1) - (((TI_RCV_BUF_W - 2) >= 0 ? TI_RCV_BUF_W - 1 : 3 - TI_RCV_BUF_W) - 1))+:TI_W * ((TI_RCV_BUF_W - 2) >= 0 ? TI_RCV_BUF_W - 1 : 3 - TI_RCV_BUF_W)], rff_ti_rcv_data};
	always @(posedge ti_clk or negedge ti_rstn)
		if (!ti_rstn)
			ti_rcv_data_parity <= 'h0;
		else if (is_state_changed)
			ti_rcv_data_parity <= 'h0;
		else if (is_rd_rcv)
			ti_rcv_data_parity <= ti_rcv_data_parity ^ rff_ti_rcv_data;
	wire [TI_W - 1:0] rff_ti_rcv_data_parity;
	std_dffre #(.WIDTH(TI_W)) ti_rcv_data_parity_u(
		.clk(ti_clk),
		.rstn(~ti_rstn),
		.en(is_cycle_count_eq_one),
		.d(ti_rcv_data_parity),
		.q(rff_ti_rcv_data_parity)
	);
	reg [TI_W - 1:0] ti_data_oen;
	always @(negedge ti_clk or negedge ti_rstn)
		if (!ti_rstn)
			ti_data_oen <= MODE_INPUT_WORD[TI_W - 1:0];
		else
			ti_data_oen <= (is_send_mode && ~ti_send_done ? MODE_OUTPUT_WORD[TI_W - 1:0] : MODE_INPUT_WORD[TI_W - 1:0]);
	wire [TI_W - 1:0] ti_send_data;
	assign ti_send_data = (is_send_mode && ~is_state_changed ? (is_cycle_count_eq_one ? ti_data_parity : ti_send_buf[0+:TI_W]) : IDLE_DATA_VALUE[TI_W - 1:0]);
	assign ti_dout = ti_send_data;
	assign ti_doen = ti_data_oen;
	assign resp_data = ti_rcv_buf[TI_W * ((((DATA_W / TI_W) + 1) >= 2 ? (DATA_W / TI_W) + 1 : (((DATA_W / TI_W) + 1) + (((DATA_W / TI_W) + 1) >= 2 ? (DATA_W / TI_W) + 0 : 3 - ((DATA_W / TI_W) + 1))) - 1) - ((((DATA_W / TI_W) + 1) >= 2 ? (DATA_W / TI_W) + 0 : 3 - ((DATA_W / TI_W) + 1)) - 1))+:TI_W * (((DATA_W / TI_W) + 1) >= 2 ? (DATA_W / TI_W) + 0 : 3 - ((DATA_W / TI_W) + 1))];
	assign resp_data_err = ~(rff_ti_rcv_data_parity == ti_rcv_buf[TI_W+:TI_W]) && ~is_rd_rcv;
endmodule
