// it's a master
module outer_ebi #(
    parameter DATA_WIDTH  = 64,
    parameter PADDR_WIDTH = 32,
    parameter CACHELINE_LENGTH = 512,
    parameter EBI_WIDTH = 16
) (
    //clk and rstn
    input      clk,
    input      rst,          
    
    //cache
    //AR
    input                           l2_req_if_arready_i,
    output                          l2_req_if_arvalid_o,
    output   [PADDR_WIDTH-1:0]      araddr_o,
    output   [3:0]                  arsnoop_o,
    
    // AW   
    input                           l2_req_if_awready_i,
    output                          l2_req_if_awvalid_o,
    output   [PADDR_WIDTH-1:0]      awaddr_o,
    output   [1:0]                  awmesi_o,
    
    // W    
    input                           l2_req_if_wready_i,
    output                          l2_req_if_wvalid_o,
    output   [DATA_WIDTH-1:0]       wdata_o,
    
    // R    
    input                           l2_resp_if_rvalid_i,
    output                          l2_resp_if_rready_o,
    input  [DATA_WIDTH-1:0]         rdata_i,
    input  [1:0]                    mesi_sta_i,
    
    // SNOOP REQ    
    output                          l2_req_if_snready_o,
    input                           l2_req_if_snvalid_i,
    input  [PADDR_WIDTH-1:0]        sn_req_addr,
    input  [3:0]                    sn_req_snoop,
    
    // SNOOP RESP   
    input                           l2_resp_if_snready_i,
    output                          l2_resp_if_snvalid_o,
    output                          sn_resp_has_data,
    output   [DATA_WIDTH-1:0]       sn_resp_dat,
    output                          ack,  // = ~sn_resp_has_data
    
    
    // connected GPIO   
    input   [EBI_WIDTH-1:0]         ebi_i,
    output  [EBI_WIDTH-1:0]         ebi_o,
    output  [EBI_WIDTH-1:0]         ebi_oen,  // 0的时候为输出,默认为1
    
    // master/slave switch  
    input                           bus_switch_i,
    output     reg                  bus_switch_o,
    output     reg                  bus_switch_oen  //slave输出,master监听
);
//oen对gpio并起不到控制作用,它的作用是为了方便debug以及在fpga上实现三态门

// state transition
localparam OPCODE_WIDTH = 4;
localparam IDLE         = 4'h0;
localparam SEND_SNP_REQ      = 4'h1;
localparam WAIT_SNP_RESP       = 4'h2;
localparam RECV_SNP_RESP       = 4'h3;
localparam READ_SNP_RESP       = 4'h4;
localparam RECV_WR       = 4'h5;
localparam CHECK_OPCODE    = 4'h6;
localparam FORWARD_RREQ   = 4'h7;

localparam WAIT_R_CONTENT             = 4'h8;
localparam R_RESP    = 4'h9;
localparam FORWARD_WREQ        = 4'ha;
localparam FORWARD_W_CONTENT        = 4'hb;
localparam RESP_ACK    = 4'hc;


//opcode
localparam host_DR = 4'd0;
localparam host_DW1 = 4'd1;
localparam host_DW2 = 4'd2;
localparam slave_SNP_RESP1 = 4'd3;
localparam slave_SNP_RESP2 = 4'd4;
localparam host_IDLE = 4'd5;
localparam host_SNP_REQ = 4'd6;
localparam slave_RD_RESP = 4'd7;
localparam slave_IDLE = 4'd8;
localparam slave_ACK = 4'hf;

reg [3:0] trx_current_state;
reg [3:0] trx_next_state;
reg [3:0] trx_pre_state;

wire trx_send_done;
wire trx_rcv_done;
wire trx_rcv_start;
//---------------------------- BUS_OCCUPY FSM ---------------------------
// BUS_CCUPY state
localparam RELEASE_BUS = 1'b0;
localparam ACCQUIRE_BUS = 1'b1;

reg current_bus_occupy; // 1: bus_master 0: bus_slave
reg next_bus_occupy;
reg next_bus_switch_o;
reg next_bus_switch_oen;
reg asking;
reg next_asking;
reg release_signal;
reg next_release_signal;

always@(*) begin
    next_bus_occupy = current_bus_occupy;
    next_bus_switch_oen = bus_switch_oen;
    next_bus_switch_o = bus_switch_o;
    next_asking = asking;
    next_release_signal = release_signal;
    if (current_bus_occupy == RELEASE_BUS) begin
        if (asking) begin
            next_bus_switch_oen = 1'b1; // asking拉高后的第一个cycle 已经将请求发出, bus_swtich_oen拉高为下下拍
            if(bus_switch_oen && bus_switch_i) begin  //一直等待直到允许切换
                next_bus_occupy = ACCQUIRE_BUS;
                next_asking = 1'b0;
                next_bus_switch_o = 1'b0;
                next_bus_switch_oen = 1'b1; //成为master要开始监听
            end
        end else begin
            if (l2_req_if_snvalid_i) begin 
                next_bus_switch_o = 1'b1;
                next_asking = 1'b1;
            end
        end
    end else begin  //ACCQUIRE_BUS
        if (release_signal) begin // 上个cycle告诉了另一侧ebi将bus释放了,将ebi_switch据为己有
            next_bus_switch_o = 1'b0;
            next_bus_switch_oen = 1'b0;  //成为slave开始准备输出
            next_release_signal = 1'b0;
            next_bus_occupy = RELEASE_BUS;
        end else begin
            if (bus_switch_i && (trx_current_state == IDLE) && (!l2_req_if_snvalid_i)) begin  //加上valid条件是因为idle时ready为高,下一拍即将进行transcation处理
                next_bus_switch_oen = 1'b0;
                next_bus_switch_o = 1'b1;
                next_release_signal = 1'b1; 
            end
        end
    end
end

always @(posedge clk) begin
    if (rst) begin   // To avoid deadlock, initially the inner_occupy should be accquire, outer_occupy should be release
        current_bus_occupy <= RELEASE_BUS;
        asking <= 1'b0;
        bus_switch_o <= 1'b0;
        bus_switch_oen <= 1'b0;
        release_signal <= 1'b0;
    end else begin
        current_bus_occupy <= next_bus_occupy;
        bus_switch_o <= next_bus_switch_o;
        bus_switch_oen <= next_bus_switch_oen;
        asking <= next_asking;
        release_signal <= next_release_signal;
    end
end

//----------------write data control---------------------------
reg [3:0] write_counter; // used for write `direct write data`
wire w_complete;
always @(posedge clk) begin
    if(rst) begin
        write_counter <= 'b0;
    end else begin
        if(l2_req_if_wvalid_o && l2_req_if_wready_i && (!w_complete)) begin
            write_counter <= write_counter + 1;
        end else if(w_complete) begin
            write_counter <= 'b0;
        end
    end
end

assign w_complete = l2_req_if_wvalid_o && l2_req_if_wready_i && (write_counter == (CACHELINE_LENGTH/DATA_WIDTH - 1));

// -----------------------R_BUFFER FSM----------------------
localparam R_BUFFER_LENGTH = EBI_WIDTH + CACHELINE_LENGTH + EBI_WIDTH  + EBI_WIDTH; // start + opcode + data +mesi_sta
reg r_buffer_valid;
reg [R_BUFFER_LENGTH-1:0] r_buffer;
reg [4:0] r_buf_fill_count;
localparam R_FILL = CACHELINE_LENGTH / DATA_WIDTH;

// buffer 是从低向高发
always @(posedge clk) begin
    if(rst) begin
        r_buffer_valid <= 1'b0;
        r_buffer <= 'b0;
        r_buf_fill_count <= 'b0;
    end else begin
        if(l2_resp_if_rvalid_i && l2_resp_if_rready_o) begin
            if (r_buf_fill_count == R_FILL- 2) begin
                r_buffer_valid <= 1'b1;
            end 
            if (r_buf_fill_count < R_FILL) begin
                r_buffer[0 +: 2*EBI_WIDTH] <= {{(EBI_WIDTH-OPCODE_WIDTH){1'b0}}, slave_RD_RESP, {EBI_WIDTH{1'b0}}};
                r_buffer[2*EBI_WIDTH + CACHELINE_LENGTH +: EBI_WIDTH] <= {{(EBI_WIDTH - 2){1'b0}}, mesi_sta_i};
                r_buffer[2*EBI_WIDTH + r_buf_fill_count * DATA_WIDTH +: DATA_WIDTH] <= rdata_i;
                r_buf_fill_count <= r_buf_fill_count + 1;
            end
        end else if ((trx_pre_state ==  WAIT_R_CONTENT) && (trx_current_state == R_RESP)) begin 
            r_buffer_valid <= 1'b0;
        end
    end
end

// -----------------------SNP BUFFER FSM----------------------
localparam SNOOP_BUFFER_LENGTH = EBI_WIDTH + PADDR_WIDTH + EBI_WIDTH + EBI_WIDTH;
reg [SNOOP_BUFFER_LENGTH-1:0] snp_buffer;
reg snp_buffer_valid;
always @(posedge clk) begin
    if(rst) begin
        snp_buffer <= 'b0;
        snp_buffer_valid <= 1'b0;
    end else begin
        if(l2_req_if_snvalid_i && l2_req_if_snready_o) begin
            snp_buffer <= {{(EBI_WIDTH-4){1'b0}}, sn_req_snoop, sn_req_addr, {(EBI_WIDTH-OPCODE_WIDTH){1'b0}}, host_SNP_REQ, {EBI_WIDTH{1'b0}}};  //地址先发低位后发高位
            snp_buffer_valid <= 1'b1;
        end else if((trx_pre_state == SEND_SNP_REQ) && (trx_current_state == WAIT_SNP_RESP)) begin
            snp_buffer_valid <= 1'b0;
        end//resp
    end
end


//--------------------------------- TRX FSM --------------------------------
wire req_is_read;
wire w_has_data;
wire snp_resp_done;

always @(*) begin
    trx_next_state = trx_current_state;
    if (current_bus_occupy) begin  // ebi as master to snp_req
        case(trx_current_state)
            IDLE: begin
                trx_next_state = snp_buffer_valid ? SEND_SNP_REQ : trx_current_state;
            end
            SEND_SNP_REQ: begin
                trx_next_state = trx_send_done ? WAIT_SNP_RESP  : trx_current_state;   
            end
            WAIT_SNP_RESP: begin
                trx_next_state = trx_rcv_start ? RECV_SNP_RESP : trx_current_state;
            end
            RECV_SNP_RESP: begin
                trx_next_state = trx_rcv_done ? READ_SNP_RESP  : trx_current_state;   
            end
            READ_SNP_RESP: begin
                trx_next_state = snp_resp_done  ? IDLE    : trx_current_state;   
            end
        endcase
    end else begin  // ebi as slave to response read/write
        case(trx_current_state)
            IDLE: begin
                trx_next_state = trx_rcv_start ? RECV_WR : trx_current_state;
            end
            RECV_WR: begin
                trx_next_state = trx_rcv_done ? CHECK_OPCODE  : trx_current_state;
            end
            CHECK_OPCODE: begin
                trx_next_state = req_is_read ? FORWARD_RREQ : FORWARD_WREQ;
            end

            FORWARD_RREQ: begin
                trx_next_state =  (l2_req_if_arready_i && l2_req_if_arvalid_o) ? WAIT_R_CONTENT : trx_current_state;  
            end 
            WAIT_R_CONTENT: begin   
                trx_next_state = r_buffer_valid ? R_RESP : trx_current_state;
            end  
            R_RESP: begin
                trx_next_state = trx_send_done ? IDLE : trx_current_state;
            end

            FORWARD_WREQ: begin
                trx_next_state = (l2_req_if_awvalid_o && l2_req_if_awready_i) ? (w_has_data ? FORWARD_W_CONTENT : RESP_ACK ) : trx_current_state;   
            end
            FORWARD_W_CONTENT: begin
                trx_next_state = w_complete ? RESP_ACK : trx_current_state;
            end
            RESP_ACK: begin
                trx_next_state = trx_send_done ? IDLE  : trx_current_state;   
            end
        endcase
    end
end

always @(posedge clk) begin
    if(rst) begin
        trx_current_state <= IDLE;
        trx_pre_state <= IDLE;
    end else begin
        trx_pre_state <= trx_current_state;
        trx_current_state <= trx_next_state; 
    end
end

// ebi control signal
wire [OPCODE_WIDTH-1:0] opcode =    (trx_next_state == R_RESP) ? slave_RD_RESP :
                                    (trx_next_state == RESP_ACK) ? slave_ACK :
                                    (trx_next_state == SEND_SNP_REQ) ?  host_SNP_REQ : host_IDLE;

wire is_counter_reload = (trx_pre_state != trx_current_state);
wire is_send_mode = ((trx_current_state == SEND_SNP_REQ) || (trx_current_state == R_RESP) || (trx_current_state == RESP_ACK));
wire is_rd_rcv = ((trx_current_state == RECV_SNP_RESP) || (trx_current_state == RECV_WR));
wire is_counter_ena  = is_send_mode | is_rd_rcv;


localparam SEND_BUFFER_LENGTH = EBI_WIDTH + CACHELINE_LENGTH + EBI_WIDTH + PADDR_WIDTH + EBI_WIDTH;
wire [SEND_BUFFER_LENGTH-1 : 0] trx_senddata_mux;

assign trx_senddata_mux =   (trx_current_state == SEND_SNP_REQ) ? {{CACHELINE_LENGTH{1'b0}}, snp_buffer} :
                            (trx_current_state == R_RESP) ? r_buffer :{{(SEND_BUFFER_LENGTH-2*EBI_WIDTH){1'b0}}, {EBI_WIDTH{1'b1}}, {EBI_WIDTH{1'b0}}};  //default is ack slot

wire [CACHELINE_LENGTH + EBI_WIDTH + PADDR_WIDTH -1 : 0] trx_req_data;

outer_ebi_trx outer_ebi_trx_u (
    .clk(clk),
    .rst(rst),
    .ebi_o(ebi_o),
    .ebi_i(ebi_i),
    .ebi_oen(ebi_oen),

    .resp_data(trx_req_data),
    .send_data(trx_senddata_mux),  //buffer width is the max value among three sending buffer

    .opcode(opcode), 
    .is_counter_reload(is_counter_reload),
    .is_counter_ena(is_counter_ena),
    .is_rd_rcv(is_rd_rcv),
    .is_send_mode(is_send_mode),
    .trx_rcv_start(trx_rcv_start),
    .trx_send_done(trx_send_done),
    .trx_rcv_done(trx_rcv_done),
    .req_is_read(req_is_read),
    .w_has_data(w_has_data),
    .snp_resp_hasdata(sn_resp_has_data)
);

reg [3:0] snp_resp_counter; // used for read `snoop response`

always @(posedge clk) begin
    if(rst) begin
        snp_resp_counter <= 'b0;
    end else  begin
        if(l2_resp_if_snvalid_o && l2_resp_if_snready_i && sn_resp_has_data) begin
            if(snp_resp_counter < (CACHELINE_LENGTH/DATA_WIDTH - 1)) begin
                snp_resp_counter <= snp_resp_counter + 1;
            end     
        end else if(trx_current_state == IDLE) begin
            snp_resp_counter <= 'b0;
        end
    end
end

assign snp_resp_done = l2_resp_if_snvalid_o && l2_resp_if_snready_i && ((!sn_resp_has_data) || (sn_resp_has_data && (snp_resp_counter == (CACHELINE_LENGTH/DATA_WIDTH - 1))));
//------------------------interface----------------------------------
assign l2_req_if_arvalid_o = (trx_current_state == FORWARD_RREQ) && (current_bus_occupy == RELEASE_BUS);
assign araddr_o = trx_req_data[PADDR_WIDTH-1:0];
assign arsnoop_o = trx_req_data[PADDR_WIDTH +: 4];
assign l2_resp_if_rready_o = (trx_current_state == WAIT_R_CONTENT) && (current_bus_occupy == RELEASE_BUS);
assign l2_req_if_awvalid_o = (trx_current_state == FORWARD_WREQ) && (current_bus_occupy == RELEASE_BUS);
assign l2_req_if_wvalid_o = (trx_current_state == FORWARD_W_CONTENT) && (current_bus_occupy == RELEASE_BUS);
assign wdata_o = trx_req_data[PADDR_WIDTH + EBI_WIDTH + write_counter*DATA_WIDTH +: DATA_WIDTH];
assign awmesi_o = trx_req_data[PADDR_WIDTH +: 2];
assign awaddr_o = trx_req_data[PADDR_WIDTH-1:0];
assign l2_req_if_snready_o = (trx_current_state == IDLE) && (current_bus_occupy == ACCQUIRE_BUS);
assign l2_resp_if_snvalid_o = (trx_current_state == READ_SNP_RESP) && (current_bus_occupy == ACCQUIRE_BUS);
assign ack = ~sn_resp_has_data;
assign sn_resp_dat = trx_req_data[snp_resp_counter*DATA_WIDTH +: DATA_WIDTH];

endmodule