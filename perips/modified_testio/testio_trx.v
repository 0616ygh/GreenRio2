
module testio_trx
#(
    parameter DATA_W = 32,
    parameter MASK_W = 4,
    parameter TI_W   = 1
)
(  
    input       [DATA_W-1:0]           req_addr,
    input       [DATA_W-1:0]           req_data,
    input       [MASK_W-1:0]           req_strb,

    output      [DATA_W-1:0]           resp_data,

    // input                         ti_en,     //enable testio trx from testio mode  
    input       [5:0]                  ti_ctrl,   //control signal from state machine 
    // testio      
    input                              clk,    //Peripheral clock signal
    input                              rst,   //Peripheral async reset signal
    input       [TI_W-1:0]             ti_din,    //Peripheral data in

    output      [TI_W-1:0]             ti_dout,
    output      [TI_W-1:0]             ti_doen,
    output      [5:0]                  ti_fsm_ctrl
);
// FSM is controlled through outside FSM

localparam N_CNT_BITS       = 8;
localparam TI_START_CYCLE   = 1;
localparam TI_TYPE_CYCLE    = 1;  // read or write
localparam TI_PARITY_CYCLE  = 1; 
localparam TI_STOP_CYCLE    = 1; 
localparam TI_ACK_CYCLE     = 1;

localparam TI_ADDR_CYCLE    = DATA_W / TI_W; 
localparam TI_STRB_CYCLE    = (TI_W == 1) ? MASK_W / TI_W : 1; 
localparam TI_DATA_CYCLE    = DATA_W / TI_W; 

localparam TI_HOST_CYC_COM  = TI_START_CYCLE  + TI_TYPE_CYCLE      + TI_PARITY_CYCLE    + TI_STOP_CYCLE - 1'b1;  //为什么要-1？
localparam TI_WR_ACK_CYC    = TI_START_CYCLE  + TI_ACK_CYCLE       + TI_STOP_CYCLE - 1'b1;
localparam TI_RD_ACK_CYC    = TI_PARITY_CYCLE + TI_STOP_CYCLE - 1'b1;

localparam TI_WR_HOST_CYC   = TI_HOST_CYC_COM + TI_ADDR_CYCLE  + TI_STRB_CYCLE  + TI_DATA_CYCLE;

localparam TI_RD_HOST_CYC   = TI_HOST_CYC_COM + TI_ADDR_CYCLE;

localparam TI_RD_TARG_CYC   = TI_RD_ACK_CYC   + TI_DATA_CYCLE;

// max bit width such as 32bit mode
localparam TI_SEND_BUF_W    = TI_WR_HOST_CYC + 1;
localparam TI_RCV_BUF_W     = TI_RD_TARG_CYC + 1;
localparam TI_MASK_W = (TI_W == 1) ? MASK_W : TI_W;

// declare cmd bit
localparam START        = 1'b0; 
localparam STOP         = 1'b1; 
localparam WRITE        = 1'b1; 
localparam READ         = 1'b0; 
localparam ACK_OK       = 1'b0;
localparam ACK_ERR      = 1'b1;
localparam PARITY_OK    = 1'b0; // only for wr ack check
localparam PARITY_ERR   = 1'b1; // only for wr ack check

localparam MODE_INPUT_WORD  = 'hffff_ffff;

localparam MODE_OUTPUT_WORD = 'h0;

localparam IDLE_DATA_VALUE  = 'hffff_ffff;

// send/receive cycle numbers
wire [N_CNT_BITS-1:0] ti_wr_host_cycle;
wire [N_CNT_BITS-1:0] ti_rd_host_cycle;
wire [N_CNT_BITS-1:0] ti_rd_targ_cycle;

// mux ti_cycle_count
wire [N_CNT_BITS-1:0] ti_cycle_count;
reg [N_CNT_BITS-1:0] ti_cycle_counter;

//send/receive data buf
reg [(TI_SEND_BUF_W*TI_W)-1:0] ti_send_buf;

reg [(TI_RCV_BUF_W*TI_W)-1:0] ti_rcv_buf;

wire [MASK_W-1:0] ti_strb;
wire [DATA_W-1:0] ti_addr;
wire [DATA_W-1:0] ti_data;

wire is_wr_send;
wire is_rd_send;
wire is_rd_rcv ;

// control signal
wire is_send_mode;
wire is_counter_ena;

// state change : update cycle counter value
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

// check ti_cycle_counter
assign is_cycle_count_eq_zero = (ti_cycle_counter == 8'h0);
assign is_cycle_count_eq_one  = (ti_cycle_counter == 8'h1);

// always check ti_din for ti_rcv_start and ti_rcv_ack
assign ti_rcv_start   = (ti_din[0]    == START);
assign ti_rcv_ack     = (ti_din[0]    == ACK_OK);
assign ti_rcv_parity  = 1'b1;   //  no error here
assign ti_rcv_stop    = (ti_din[0]    == STOP);
// rcv data done
assign ti_rcv_done    = is_cycle_count_eq_zero;
// send data done
assign ti_send_done   = is_cycle_count_eq_zero;

// prepere req data
assign ti_addr  = req_addr;
assign ti_data  = req_data;
assign ti_strb  = req_strb;

assign ti_fsm_ctrl[5] = ti_rcv_start;
assign ti_fsm_ctrl[4] = ti_rcv_ack;
assign ti_fsm_ctrl[3] = ti_rcv_parity;
assign ti_fsm_ctrl[2] = ti_rcv_stop;
assign ti_fsm_ctrl[1] = ti_rcv_done;
assign ti_fsm_ctrl[0] = ti_send_done;

// data width handle
wire [(TI_SEND_BUF_W*TI_W)-1:0] ti_wr_send_data;
wire [(TI_SEND_BUF_W*TI_W)-1:0] ti_rd_send_data;

wire [TI_W-1:0]      ti_wr_send_parity_w;
wire [TI_W-1:0]      ti_start_w, ti_write_w, ti_read_w, ti_stop_w;
wire [DATA_W-1:0]    ti_addr_w;
wire [DATA_W-1:0]    ti_data_w;
wire [TI_MASK_W-1:0] ti_strb_w;

assign ti_start_w = {TI_W{START}};
assign ti_write_w = {TI_W{WRITE}};
assign ti_read_w  = {TI_W{READ}};
assign ti_stop_w  = {TI_W{STOP}};
assign ti_addr_w  = ti_addr;
assign ti_data_w  = ti_data;
assign ti_strb_w  = {{(TI_MASK_W-MASK_W){1'b0}},ti_strb};
assign ti_wr_send_parity_w = {TI_W{PARITY_OK}};
assign ti_wr_send_data    = {ti_start_w, ti_write_w, ti_addr_w, ti_strb_w, ti_data_w, {TI_W{1'b1}}, ti_stop_w};
assign ti_rd_send_data    = {ti_start_w, ti_read_w, ti_addr_w, {TI_W{1'b1}}, ti_stop_w, {((TI_STRB_CYCLE+TI_DATA_CYCLE)*TI_W){1'b1}}};   //后面是为了填满buffer, 其实在发出stop时就已经停止

assign ti_wr_host_cycle = TI_WR_HOST_CYC[N_CNT_BITS-1:0];
assign ti_rd_host_cycle = TI_RD_HOST_CYC[N_CNT_BITS-1:0];
assign ti_rd_targ_cycle = TI_RD_TARG_CYC[N_CNT_BITS-1:0];

wire [(TI_SEND_BUF_W*TI_W)-1:0] ti_wr_send_data_mux  = is_wr_send ? ti_wr_send_data : ti_rd_send_data;

// control signal
assign is_state_changed = ti_ctrl[5];
assign is_wr_send       = ti_ctrl[4];
assign is_rd_send       = ti_ctrl[3];
assign is_rd_rcv        = ti_ctrl[2];
assign is_send_mode     = ti_ctrl[1];
assign is_counter_ena   = ti_ctrl[0];

assign is_counter_reload = is_state_changed;

// mux ti_cycle_count
assign ti_cycle_count    = is_wr_send ? ti_wr_host_cycle
                         : is_rd_send ? ti_rd_host_cycle
                         : is_rd_rcv  ? ti_rd_targ_cycle
                         : 8'hff;

// cycle counter
always @(posedge clk) begin
    if(rst) begin
        ti_cycle_counter <= 8'hff;
    end else if(is_counter_reload) begin //begin
        ti_cycle_counter <= ti_cycle_count;
    end else if(is_counter_ena) begin
        ti_cycle_counter <= ti_cycle_counter - 1'b1;
    end
end
//counter = n denotes that in next cycle rising edge the receiver will read bit-n data, so in this cycle's falling edge the data bit-n need to be sent(change to bit-n in this moment)

wire [TI_W-1:0] rff_ti_rcv_data;
std_dffr #(TI_W) ti_rcv_data_u (
    .clk(clk), 
    .rstn(rst), 
    .d(ti_din), 
    .q(rff_ti_rcv_data)
);  //同步

//shift send_buf
always @(negedge clk) begin
    if(rst) begin
        ti_send_buf  <= 'h0;
    end else if(is_state_changed) begin
        ti_send_buf <= ti_wr_send_data_mux;
    end else if(is_send_mode) begin
        ti_send_buf  <= {{ti_send_buf[TI_SEND_BUF_W*TI_W -1 -TI_W: 0]}, {TI_W{1'b0}}}; //ti_send_buf <= ti_send_buf >> TI_W
    end
end

//shift rcv_buf
always @(posedge clk) begin
    if(rst) begin
        ti_rcv_buf           <= 'h0;
    end else if(is_state_changed) begin
        ti_rcv_buf           <= ti_rcv_buf;
    end else if(is_rd_rcv) begin
        ti_rcv_buf           <= {ti_rcv_buf[TI_RCV_BUF_W*TI_W-TI_W-1:0], rff_ti_rcv_data};
    end
end

//------------------------
// configure ti_data_oen
// send mdoe : output
// otherwise : input
//------------------------
reg [TI_W-1:0] ti_data_oen;
always @(negedge clk) begin
    if(rst) begin  // 默认是接收（signal为high）
        ti_data_oen <= MODE_INPUT_WORD[TI_W-1:0];
    end else begin
        ti_data_oen <= (is_send_mode && ~ti_send_done) ? MODE_OUTPUT_WORD[TI_W-1:0] : MODE_INPUT_WORD[TI_W-1:0];
    end   //send done 标志此周期已经是最后一个数据，接下来
end

wire [TI_W-1:0] ti_send_data;

// send data
assign ti_send_data = (is_send_mode && ~is_state_changed) ? (is_cycle_count_eq_one ? {TI_W{1'b1}} : ti_send_buf[TI_SEND_BUF_W*TI_W-1 -: TI_W]) : IDLE_DATA_VALUE[TI_W-1:0];
// 每次发送最高的TI_W位
assign ti_dout   = ti_send_data;
assign ti_doen   = ti_data_oen;

// calc resp data
assign resp_data = ti_rcv_buf[2*TI_W +: DATA_W]; //parity/stop不算data 而是用于计算err等...
endmodule

// `default_nettype wire