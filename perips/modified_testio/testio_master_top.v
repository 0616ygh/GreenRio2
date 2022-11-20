// it's a master
module testio_master_top #(
    parameter BUS_WIDTH    = 32,
    parameter BUS_MASK     = 4,
    parameter TESTIO_WIDTH = 1
) (
    //clk and rstn
    input      clk,
    input      rst,          
    //axi
    input      wbm_testio_cyc_i,
    input      wbm_testio_stb_i,
    output     testio_wbm_ack_o,
    input      wbm_testio_we_i,
    input [BUS_WIDTH-1:0]  wbm_testio_addr_i,
    input [BUS_WIDTH-1:0]  wbm_testio_wdata_i,
    output [31:0] wbm_testio_rdata_o,
    input [TESTIO_WIDTH-1:0] ti_i,
    output [TESTIO_WIDTH-1:0] ti_o,
    output [TESTIO_WIDTH-1:0] ti_oen  // 0的时候为输出
);
//ti_o 的 bit_0 进行start等
localparam TI_IDLE         = 4'b0000;
localparam TI_WR_SEND      = 4'b0001;
localparam TI_WR_RCV_IDLE  = 4'b0010;
localparam TI_WR_RCV_ACK   = 4'b0011;
localparam TI_WR_RCV_PARITY= 4'b0100;
localparam TI_WR_RCV       = 4'b0101;
localparam TI_RD_SEND      = 4'b0110;
localparam TI_RD_RCV_IDLE  = 4'b0111;
localparam TI_RD_RCV_ACK   = 4'b1000;
localparam TI_RD_RCV       = 4'b1001;
localparam TI_RESP         = 4'b1010;
localparam TI_ACK_ERR      = 4'b1011;

localparam MODE_OUTPUT_WORD = 32'h0;
localparam IDLE_DATA_VALUE  = 32'hffff_ffff;

reg [3:0] ti_current_state;
reg [3:0] ti_pre_state;
reg [3:0] ti_next_state;

// generate control signal
wire is_idle        = ti_current_state == TI_IDLE       ;
wire is_wr_send     = ti_current_state == TI_WR_SEND    ;
wire is_rd_send     = ti_current_state == TI_RD_SEND    ;
wire is_rd_rcv      = ti_current_state == TI_RD_RCV     ;
wire is_send_mode    = is_wr_send | is_rd_send;
wire is_counter_ena  = is_send_mode | is_rd_rcv;

assign testio_wbm_ack_o = (ti_current_state == TI_RESP) && wbm_testio_cyc_i;   // TODO: 要一直保持不变直到cyc拉低

//state transfer
always @(posedge clk) begin
    if(rst) begin
        ti_pre_state <= TI_IDLE;
        ti_current_state <= TI_IDLE;
    end else begin
        ti_pre_state <= ti_current_state;
        ti_current_state <= ti_next_state; 
    end
end

// 1: write 0: read
wire [3:0] ti_send_mode = wbm_testio_we_i ? TI_WR_SEND : TI_RD_SEND;

wire [5:0] ti_fsm_ctrl;
wire ti_rcv_start   = ti_fsm_ctrl[5];
wire ti_rcv_ack     = ti_fsm_ctrl[4];
wire ti_rcv_parity  = ti_fsm_ctrl[3];
wire ti_rcv_stop    = ti_fsm_ctrl[2];
// rcv data 
wire ti_rcv_done    = ti_fsm_ctrl[1];
// send data 
wire ti_send_done   = ti_fsm_ctrl[0];
wire is_state_changed  = (ti_current_state != ti_pre_state);

wire [5:0] ti_ctrl = {is_state_changed, is_wr_send, is_rd_send, is_rd_rcv, is_send_mode, is_counter_ena};

always @(*) begin
    if(rst) begin
        ti_next_state = TI_IDLE;
    end else begin
        case(ti_current_state)
            TI_IDLE        : begin
                ti_next_state = wbm_testio_cyc_i ? ti_send_mode : ti_current_state;
            end
            TI_WR_SEND     : begin
                ti_next_state = ti_send_done ? TI_WR_RCV_IDLE : ti_current_state;
            end
            TI_WR_RCV_IDLE : begin
                ti_next_state = ti_rcv_start ? TI_WR_RCV_ACK  : ti_current_state;
            end
            TI_WR_RCV_ACK  : begin
                ti_next_state = ti_rcv_ack   ? TI_WR_RCV_PARITY: TI_ACK_ERR;
            end
            TI_WR_RCV_PARITY: begin
                ti_next_state = ti_rcv_parity? TI_WR_RCV      : TI_ACK_ERR;
            end
            TI_WR_RCV      : begin
                ti_next_state = ti_rcv_stop  ? TI_RESP        : ti_current_state;
            end
            TI_RD_SEND     : begin
                ti_next_state = ti_send_done ? TI_RD_RCV_IDLE : ti_current_state;
            end 
            TI_RD_RCV_IDLE : begin 
                ti_next_state = ti_rcv_start ? TI_RD_RCV_ACK  : ti_current_state;
            end
            TI_RD_RCV_ACK  : begin
                ti_next_state = ti_rcv_ack   ? TI_RD_RCV      : TI_ACK_ERR;
            end
            TI_RD_RCV      : begin
                ti_next_state = ti_rcv_done  ? TI_RESP        : ti_current_state;
            end
            TI_RESP        : begin
                ti_next_state = (!wbm_testio_cyc_i)  ? TI_IDLE  : ti_current_state;  //cyc 拉低后回到idle
            end
            TI_ACK_ERR     : begin
                ti_next_state = TI_IDLE;
            end
            default        : ti_next_state = TI_IDLE;
        endcase
    end
end

wire [31:0] resp_data_from_trx;
wire [TESTIO_WIDTH-1:0] ti_send_oen;
wire [TESTIO_WIDTH-1:0] ti_send_data;

generate 
    if (TESTIO_WIDTH == 1) begin: trx_u1
        testio_trx #(
            .TI_W(1) 
        ) testio_trx_bit_u
        (
            .req_addr         (wbm_testio_addr_i),
            .req_data         (wbm_testio_wdata_i),
            .req_strb         (4'hf),
            .resp_data        (resp_data_from_trx),
        
            .ti_ctrl          (ti_ctrl),   //control signal from state machine
            // testio          
            .clk           (clk),     //Peripheral clock signal
            .rst          (rst),    //Peripheral async reset signal
            .ti_din           (ti_i),   //Peripheral data in

            .ti_dout          (ti_send_data),
            .ti_doen          (ti_send_oen),
            .ti_fsm_ctrl      (ti_fsm_ctrl)
        );
    end
    else if(TESTIO_WIDTH == 16) begin: trx_u16
        testio_trx #(
            .TI_W(16) 
        ) testio_trx_halfword_u
        (
            .req_addr         (wbm_testio_addr_i),
            .req_data         (wbm_testio_wdata_i),
            .req_strb         (4'hf),
            .resp_data        (resp_data_from_trx),
        
            .ti_ctrl          (ti_ctrl),   //control signal from state machine
            // testio          
            .clk           (clk),     //Peripheral clock signal
            .rst          (rst),    //Peripheral async reset signal
            .ti_din           (ti_i),   //Peripheral data in

            .ti_dout          (ti_send_data),
            .ti_doen          (ti_send_oen),
            .ti_fsm_ctrl      (ti_fsm_ctrl)
        );
    end
endgenerate

reg [TESTIO_WIDTH-1:0] rff_ti_data_oen;
reg [TESTIO_WIDTH-1:0] rff_ti_send_data;

always @(negedge clk) begin
    if(rst) begin
        rff_ti_send_data <= 'h0;
        rff_ti_data_oen <= {TESTIO_WIDTH{1'b1}};  //默认接收数据
    end else begin
        rff_ti_data_oen <= ti_send_oen;
        rff_ti_send_data <= ti_send_data;
    end
end

assign ti_o     = rff_ti_send_data;
assign ti_oen   = rff_ti_data_oen;
assign wbm_testio_rdata_o  = resp_data_from_trx;

endmodule