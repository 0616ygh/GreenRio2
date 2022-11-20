// it's a master
module inner_ebi #(
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
    output                      l2_req_if_arready_o,
    input                       l2_req_if_arvalid_i,
    input   [PADDR_WIDTH-1:0]   araddr_i,
    input   [3:0]               arsnoop_i,

    // AW 
    output                      l2_req_if_awready_o,
    input                       l2_req_if_awvalid_i,
    input   [PADDR_WIDTH-1:0]   awaddr_i,
    input   [1:0]               awmesi_i,

    // W 
    output  reg                 l2_req_if_wready_o,
    input                       l2_req_if_wvalid_i,
    input   [DATA_WIDTH-1:0]    wdata_i,

    // R
    output                      l2_resp_if_rvalid_o,
    input                       l2_resp_if_rready_i,
    output  [DATA_WIDTH-1:0]    rdata_o,
    output  [1:0]               mesi_sta_o,

    // SNOOP REQ
    input                       l2_req_if_snready_i,
    output                      l2_req_if_snvalid_o,
    output  [PADDR_WIDTH-1:0]   sn_req_addr,
    output  [3:0]               sn_req_snoop,

    // SNOOP RESP
    output                      l2_resp_if_snready_o,
    input                       l2_resp_if_snvalid_i,
    input                       sn_resp_has_data,
    input   [DATA_WIDTH-1:0]    sn_resp_dat,
    input                       ack,  // = ~sn_resp_has_data


    // connected GPIO
    input   [EBI_WIDTH-1:0]     ebi_i,
    output  [EBI_WIDTH-1:0]     ebi_o,
    output  [EBI_WIDTH-1:0]     ebi_oen,  // 0的时候为输出,默认为1

    // master/slave switch
    input                       bus_switch_i,
    output        reg           bus_switch_o,
    output        reg           bus_switch_oen  //slave输出,master监听
);
localparam OPCODE_WIDTH = 4;
localparam IDLE         = 4'h0;
localparam SEND_AR      = 4'h1;
localparam WAIT_R       = 4'h2;
localparam RECV_R       = 4'h3;
localparam RESP_R       = 4'h4;
localparam SEND_W       = 4'h5;
localparam WAIT_WACK    = 4'h6;
localparam CHECK_WACK   = 4'h7;

localparam RECV_SNP             = 4'h8;
localparam WAIT_SNP_REQ_READ    = 4'h9;
localparam WAIT_SNP_RESP        = 4'ha;
localparam SEND_SNP_RESP        = 4'hb;
localparam WAIT_SNP_RESP_ACK    = 4'hc;
localparam CHECK_SNP_ACK        = 4'hd;

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
            if (l2_req_if_arvalid_i | l2_req_if_awvalid_i) begin 
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
            if (bus_switch_i && (trx_current_state == IDLE) && (!l2_req_if_arvalid_i) && (!l2_req_if_awvalid_i)) begin  //加上valid条件是因为idle时ready为高,下一拍即将进行transcation处理
                next_bus_switch_oen = 1'b0;
                next_bus_switch_o = 1'b1;
                next_release_signal = 1'b1; 
            end
        end
    end
end

always @(posedge clk) begin
    if (rst) begin   // To avoid deadlock, initially the inner_occupy should be accquire, outer_occupy should be release
        current_bus_occupy <= ACCQUIRE_BUS;
        asking <= 1'b0;
        bus_switch_o <= 1'b0;
        bus_switch_oen <= 1'b1;
        release_signal <= 1'b0;
    end else begin
        current_bus_occupy <= next_bus_occupy;
        bus_switch_o <= next_bus_switch_o;
        bus_switch_oen <= next_bus_switch_oen;
        asking <= next_asking;
        release_signal <= next_release_signal;
    end
end

// ----------------------- READ_BUFFER FSM---------------------
localparam R_BUFFER_LENGTH = EBI_WIDTH + PADDR_WIDTH + EBI_WIDTH + EBI_WIDTH;
reg [R_BUFFER_LENGTH-1:0] r_buffer;
reg r_buffer_valid;
wire r_resp_done;
always @(posedge clk) begin
    if(rst) begin
        r_buffer <= 'b0;
        r_buffer_valid <= 1'b0;
    end else begin
        if(l2_req_if_arvalid_i && l2_req_if_arready_o) begin
            r_buffer <= {{(EBI_WIDTH-4){1'b0}}, arsnoop_i, araddr_i, {(EBI_WIDTH-OPCODE_WIDTH){1'b0}}, host_DR, {EBI_WIDTH{1'b0}}};  //地址先发低位后发高位
            r_buffer_valid <= 1'b1;
        end else if(r_resp_done) begin //完成了一次direct read transaction
            r_buffer_valid <= 1'b0;
        end//resp
    end
end

// -----------------------W_BUFFER FSM----------------------
localparam W_BUFFER_LENGTH = EBI_WIDTH + CACHELINE_LENGTH + EBI_WIDTH + PADDR_WIDTH + EBI_WIDTH;
localparam W_NODATA_LENGTH = W_BUFFER_LENGTH - CACHELINE_LENGTH;
reg wdata_exist;
reg w_buffer_valid;
reg [W_BUFFER_LENGTH-1:0] w_buffer;
reg [4:0] w_buf_fill_count;
localparam W_FILL = CACHELINE_LENGTH / DATA_WIDTH;

// buffer 是从低向高发
always @(posedge clk) begin
    if(rst) begin
        w_buffer_valid <= 1'b0;
        w_buffer <= 'b0;
        wdata_exist <= 1'b0;
        l2_req_if_wready_o <= 1'b0;
        w_buf_fill_count <= 'b0;
    end else begin
        if(l2_req_if_awready_o && l2_req_if_awvalid_i) begin
            if(awmesi_i == 2'b11) begin   //mesi == M
                w_buffer <= {{W_NODATA_LENGTH{1'b0}}, {(EBI_WIDTH-2){1'b0}}, awmesi_i, awaddr_i, {(EBI_WIDTH-OPCODE_WIDTH){1'b0}}, host_DW1, {EBI_WIDTH{1'b0}}};
                wdata_exist <= 1'b1;
                l2_req_if_wready_o <= 1'b1;
                w_buf_fill_count <= 'b0;
            end else begin
                w_buffer <= {{W_NODATA_LENGTH{1'b0}}, {(EBI_WIDTH-2){1'b0}}, awmesi_i, awaddr_i, {(EBI_WIDTH-OPCODE_WIDTH){1'b0}}, host_DW2, {EBI_WIDTH{1'b0}}};
                w_buffer_valid <= 1'b1;
                wdata_exist <= 1'b0;
            end
        end else begin
            if (l2_req_if_wready_o && l2_req_if_wvalid_i) begin
                w_buffer[EBI_WIDTH*3 + PADDR_WIDTH + w_buf_fill_count * DATA_WIDTH +: DATA_WIDTH] <= wdata_i;
                w_buf_fill_count <=  w_buf_fill_count + 1;
                if (w_buf_fill_count == W_FILL-1) begin
                    l2_req_if_wready_o <= 1'b0;
                    w_buffer_valid <= 1'b1;
                end
            end else if ((trx_pre_state ==  WAIT_WACK) && (trx_current_state == CHECK_WACK)) begin  //完成了一次direct write transaction
                w_buffer_valid <= 1'b0;
                wdata_exist <= 1'b0;
            end
        end
    end
end

// -----------------------SNP_BUFFER FSM----------------------
localparam SNP_BUFFER_LENGTH = EBI_WIDTH + CACHELINE_LENGTH + EBI_WIDTH;  // opcode 为snp
reg snpdata_exist;
reg [SNP_BUFFER_LENGTH-1:0] snp_buffer;
reg [4:0] snp_buf_fill_count;
localparam SNP_FILL = CACHELINE_LENGTH / DATA_WIDTH;
reg snp_buffer_valid;
// buffer 是从低向高发
always @(posedge clk) begin
    if(rst) begin
        snp_buffer_valid <= 1'b0;
        snp_buffer <= 'b0;
        snpdata_exist <= 1'b0;
        snp_buf_fill_count <= 'b0;
    end else begin
        if(l2_resp_if_snready_o && l2_resp_if_snvalid_i) begin
            if(!sn_resp_has_data) begin
                snp_buffer <= {{CACHELINE_LENGTH{1'b0}}, {(EBI_WIDTH-OPCODE_WIDTH){1'b0}}, slave_SNP_RESP2, {EBI_WIDTH{1'b0}}};
                snp_buffer_valid <= 1'b1;
                snpdata_exist <= 1'b0;
            end else begin
                if(snp_buf_fill_count == SNP_FILL-2) begin // -2 是因为0占一个buffer位置, 还要提前一拍告诉大fsm拉低ready
                    snp_buffer_valid <= 1'b1;
                end
                if(snp_buf_fill_count < SNP_FILL) begin
                    snp_buffer[EBI_WIDTH*2-1 : 0] <= {{(EBI_WIDTH-OPCODE_WIDTH){1'b0}}, slave_SNP_RESP1, {EBI_WIDTH{1'b0}}};
                    snpdata_exist <= 1'b1;
                    snp_buffer[2*EBI_WIDTH + snp_buf_fill_count * DATA_WIDTH +: DATA_WIDTH] <=  sn_resp_dat;
                    snp_buf_fill_count <= snp_buf_fill_count + 1;
                end
            end
        end else if ((trx_pre_state ==  WAIT_SNP_RESP) && (trx_current_state == SEND_SNP_RESP)) begin  //完成了一次direct write transaction
            snp_buf_fill_count <= 'b0;
            snp_buffer_valid <= 1'b0;
            snpdata_exist <= 1'b0;
        end
    end
end

//--------------------------------- TRX FSM --------------------------------

always @(*) begin
    trx_next_state = trx_current_state;
    if (current_bus_occupy) begin  // ebi as master to read/write
        case(trx_current_state)
            IDLE: begin
                trx_next_state = r_buffer_valid ? SEND_AR :
                                w_buffer_valid ? SEND_W : trx_current_state;
            end
            SEND_AR: begin
                trx_next_state = trx_send_done ? WAIT_R  : trx_current_state;   //counter 达到一定的值(这个值由opcode决定)
            end
            WAIT_R: begin
                trx_next_state = trx_rcv_start ? RECV_R : trx_current_state;
            end
            RECV_R: begin
                trx_next_state = trx_rcv_done ? RESP_R  : trx_current_state;   //trx收到的数据长度是一定的,recv_buffer的counter达到该长度时done拉高
            end
            RESP_R: begin
                trx_next_state = r_resp_done  ? IDLE    : trx_current_state;   //ebi与cache_r_channel握手,将数据传回
            end

            SEND_W: begin 
                trx_next_state = trx_send_done ? WAIT_WACK  : trx_current_state;
            end
            WAIT_WACK: begin
                trx_next_state = trx_rcv_start ? CHECK_WACK   : trx_current_state;
            end
            CHECK_WACK: begin
                trx_next_state = IDLE;
            end
        endcase
    end else begin  // ebi as slave to response snoop
        case(trx_current_state)
            IDLE: begin
                trx_next_state = trx_rcv_start ? RECV_SNP : trx_current_state;
            end
            RECV_SNP: begin
                trx_next_state = trx_rcv_done ? WAIT_SNP_REQ_READ  : trx_current_state;
            end
            WAIT_SNP_REQ_READ: begin
                trx_next_state = (l2_req_if_snready_i && l2_req_if_snvalid_o) ? WAIT_SNP_RESP : trx_current_state;
            end
            WAIT_SNP_RESP: begin
                trx_next_state = snp_buffer_valid ? SEND_SNP_RESP : trx_current_state;  // 等待snoop resp握手
            end 
            SEND_SNP_RESP: begin   //此时他只能作为slave,所以不用ack
                trx_next_state = trx_send_done ? IDLE : trx_current_state;
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
wire [OPCODE_WIDTH-1:0] opcode =    (trx_next_state == SEND_AR) ? host_DR :
                                    (trx_next_state == SEND_W) ? (wdata_exist ? host_DW1 : host_DW2) :
                                    (trx_next_state == SEND_SNP_RESP) ? (snpdata_exist ? slave_SNP_RESP1 : slave_SNP_RESP2) : host_IDLE;

wire is_counter_reload = (trx_pre_state != trx_current_state);
wire is_send_mode = ((trx_current_state == SEND_SNP_RESP) || (trx_current_state == SEND_AR) || (trx_current_state == SEND_W));
wire is_rd_rcv = ((trx_current_state == RECV_R) || (trx_current_state == RECV_SNP));
wire is_counter_ena  = is_send_mode | is_rd_rcv;


localparam SEND_BUFFER_LENGTH = EBI_WIDTH + CACHELINE_LENGTH + EBI_WIDTH + PADDR_WIDTH + EBI_WIDTH;
wire [SEND_BUFFER_LENGTH-1 : 0] trx_senddata_mux;

assign trx_senddata_mux =   (trx_current_state == SEND_AR) ? {{CACHELINE_LENGTH{1'b0}}, r_buffer} :
                            (trx_current_state == SEND_W) ? w_buffer : snp_buffer; //default: snp_buffer

wire [CACHELINE_LENGTH + EBI_WIDTH*2 -1 : 0] trx_resp_data;

inner_ebi_trx inner_ebi_trx_u (
    .clk(clk),
    .rst(rst),
    .ebi_o(ebi_o),
    .ebi_i(ebi_i),
    .ebi_oen(ebi_oen),

    .resp_data(trx_resp_data),
    .send_data(trx_senddata_mux),  //buffer width is the max value among three sending buffer

    .opcode(opcode), 
    .is_counter_reload(is_counter_reload),
    .is_counter_ena(is_counter_ena),
    .is_rd_rcv(is_rd_rcv),
    .is_send_mode(is_send_mode),
    .trx_rcv_start(trx_rcv_start),
    .trx_send_done(trx_send_done),
    .trx_rcv_done(trx_rcv_done)
);

reg [3:0] read_counter; // used for read `direct read data`

always @(posedge clk) begin
    if(rst) begin
        read_counter <= 'b0;
    end else  begin
        if(l2_resp_if_rvalid_o && l2_resp_if_rready_i && (!r_resp_done)) begin
            read_counter <= read_counter + 1;
        end else if(r_resp_done) begin
            read_counter <= 'b0;
        end
    end
end

assign r_resp_done = l2_resp_if_rvalid_o && l2_resp_if_rready_i && (read_counter == (CACHELINE_LENGTH/DATA_WIDTH - 1));


//------------------------interface----------------------------------
assign mesi_sta_o = trx_resp_data[CACHELINE_LENGTH +: 2];
assign rdata_o = trx_resp_data[read_counter * DATA_WIDTH +: DATA_WIDTH]; //ebi_width include opcode
assign l2_resp_if_rvalid_o = (trx_current_state == RESP_R);
assign l2_req_if_arready_o = (!r_buffer_valid) && (current_bus_occupy == ACCQUIRE_BUS);
assign l2_req_if_awready_o = (!w_buffer_valid) && (current_bus_occupy == ACCQUIRE_BUS) && (!wdata_exist);
assign l2_req_if_snvalid_o = (trx_current_state ==  WAIT_SNP_REQ_READ) && (current_bus_occupy == RELEASE_BUS);
assign l2_resp_if_snready_o = (trx_current_state ==  WAIT_SNP_RESP) && (current_bus_occupy == RELEASE_BUS);
assign sn_req_addr = trx_resp_data[0 +: PADDR_WIDTH];
assign sn_req_snoop = trx_resp_data[PADDR_WIDTH +: 4];
endmodule