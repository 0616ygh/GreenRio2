module outer_ebi_trx#(
    parameter DATA_WIDTH  = 64,
    parameter PADDR_WIDTH = 32,
    parameter CACHELINE_LENGTH = 512,
    parameter EBI_WIDTH = 16,
                                   //start                        //opcode                //control info 
    parameter SEND_BUFFER_LENGTH = EBI_WIDTH + CACHELINE_LENGTH + EBI_WIDTH + PADDR_WIDTH + EBI_WIDTH ,
                                                  //control info     
    parameter RECV_BUFFER_LENGTH = CACHELINE_LENGTH + EBI_WIDTH  + PADDR_WIDTH
) (
    input                                       clk,
    input                                       rst,
    // outside interface
    output          [EBI_WIDTH-1:0]             ebi_o,
    input           [EBI_WIDTH-1:0]             ebi_i,
    output reg      [EBI_WIDTH-1:0]             ebi_oen,

    // interface with buffer
    output          [RECV_BUFFER_LENGTH-1:0]    resp_data, 
    input           [SEND_BUFFER_LENGTH-1:0]    send_data,  //buffer width is the max value among three sending buffer

    // control signal
    input           [3:0]                       opcode, 
    input                                       is_counter_reload,
    input                                       is_counter_ena,
    input                                       is_rd_rcv,
    input                                       is_send_mode,

    //
    output                                      trx_rcv_start,
    output                                      trx_send_done,
    output                                      trx_rcv_done,
    output              reg                     req_is_read,
    output              reg                     w_has_data,
    output              reg                     snp_resp_hasdata

);

// PAY ATTENTION: cycle defination here if differnt with inner_ebi !!!!!!!!!
localparam START_CYCLE      = 1;
localparam OPCODE_CYCLE     = 1;  // read or write
localparam ADDR_CYCLE       = PADDR_WIDTH/EBI_WIDTH; 
localparam DATA_CYCLE       = CACHELINE_LENGTH/EBI_WIDTH; 
localparam ARSNOOP_CYCLE    = 1;
localparam STOP_CYCLE       = 1;
localparam ACK_CYCLE        = 1;
localparam MESISTA_CYCLE    = 1;
localparam SN_REQ_SNOOP_CYCLE = 1;
localparam HAS_DATA_CYCLE   = 1;
localparam WS_ACK_CYCLE      = START_CYCLE + STOP_CYCLE;
localparam R_REQ_CYCLE      = START_CYCLE + OPCODE_CYCLE + ADDR_CYCLE + ARSNOOP_CYCLE + STOP_CYCLE - 3;  // -3 because don't accept start and stop signal and opcode
localparam R_RESP_CYCLE     = START_CYCLE + OPCODE_CYCLE + DATA_CYCLE + MESISTA_CYCLE + STOP_CYCLE;  
localparam W_REQ1_CYCLE     = START_CYCLE + OPCODE_CYCLE + ADDR_CYCLE + ARSNOOP_CYCLE + DATA_CYCLE + STOP_CYCLE - 3;
localparam W_REQ2_CYCLE     = START_CYCLE + OPCODE_CYCLE + ADDR_CYCLE + ARSNOOP_CYCLE + STOP_CYCLE - 3;
localparam SNP_REQ_CYCLE    = START_CYCLE + OPCODE_CYCLE + ADDR_CYCLE + SN_REQ_SNOOP_CYCLE + STOP_CYCLE;
localparam SNP_RESP1_CYCLE  = START_CYCLE + OPCODE_CYCLE + DATA_CYCLE + STOP_CYCLE - 2;
localparam SNP_RESP2_CYCLE  = START_CYCLE + OPCODE_CYCLE + STOP_CYCLE - 2;


localparam host_DR = 4'd0;
localparam host_DW1 = 4'd1;
localparam host_DW2 = 4'd2;
localparam slave_SNP_RESP1 = 4'd3;
localparam slave_SNP_RESP2 = 4'd4;
localparam host_IDLE = 4'd5;
localparam host_SNP_REQ = 4'd6;
localparam slave_RD_RESP = 4'd7;
localparam slave_IDLE = 4'd8;
localparam slave_ACK = 4'hf;  //与stop重合, start后直接stop即为ack


// buffer 从低向高填充
reg [5:0] send_counter;
reg [5:0] recv_counter;
reg [5:0] send_counter_max;
reg [5:0] recv_counter_max;

wire is_cycle_count_left_one  = (send_counter == (send_counter_max - 1));
// wire is_state_changed = is_counter_reload;


// -----------------RECEIVE FSM-----------------------------------------
wire [EBI_WIDTH-1:0] rff_rcv_data;
ebi_dffr #(EBI_WIDTH) rcv_dffr_u (
    .clk(clk), 
    .rstn(rst), 
    .d(ebi_i), 
    .q(rff_rcv_data)
);  //synchronize input


reg [RECV_BUFFER_LENGTH-1:0] rcv_buf;

// receive count
always @(posedge clk) begin
    if(rst) begin
        recv_counter <= 'b0;
        recv_counter_max <= 'h1f;
        rcv_buf <= 'h0;
        req_is_read <= 'b0;
        w_has_data <= 'b0;
        snp_resp_hasdata <= 'b0;
    end else begin
        if (is_counter_reload) begin
            recv_counter <= 'b0;  // this operation will cover the counter corresponding to  opcode, so recv_buffer don't store opcode
            case(rff_rcv_data[3:0])  // 4bit opcode in transaction header
                host_DR: begin
                    recv_counter_max <= R_REQ_CYCLE;
                    req_is_read <= 1'b1;
                end
                host_DW1: begin
                    req_is_read <= 1'b0; 
                    w_has_data <= 1'b1;
                    recv_counter_max <= W_REQ1_CYCLE;
                end
                host_DW2: begin
                    req_is_read <= 1'b0;
                    w_has_data <= 1'b0;
                    recv_counter_max <= W_REQ2_CYCLE;
                end
                slave_SNP_RESP1: begin
                    snp_resp_hasdata <= 1'b1;
                    recv_counter_max <= SNP_RESP1_CYCLE;
                end
                slave_SNP_RESP2: begin
                    snp_resp_hasdata <= 1'b0;
                    recv_counter_max <= SNP_RESP2_CYCLE;
                end
            endcase
        end else if (is_counter_ena) begin
            if(recv_counter < recv_counter_max) begin
                recv_counter <= recv_counter + 1'b1;
            end
        end
        if(is_rd_rcv) begin
            rcv_buf[recv_counter*EBI_WIDTH +: EBI_WIDTH] <= rff_rcv_data; //会接收到opcode 自低向高接收
        end
    end
end

// --------------------------SEND FSM----------------------------
wire [5:0] expected_counter_max =   (opcode == slave_RD_RESP) ? R_RESP_CYCLE :
                                    (opcode == host_SNP_REQ) ? SNP_REQ_CYCLE : 
                                    (opcode == slave_ACK) ? WS_ACK_CYCLE : 6'h3f;
// send count counter应该在下降沿增加
always @(negedge clk) begin
    if(rst) begin
        send_counter <= 'b0;
        send_counter_max <= 'h1f;
    end else begin
        if(is_counter_reload) begin
            send_counter <= 'b0;
            send_counter_max <= expected_counter_max;
        end else if(is_counter_ena) begin
            if(send_counter < send_counter_max) begin
                send_counter <= send_counter + 1'b1;
            end
        end
    end
end

// fsm control
assign trx_rcv_start   = (ebi_oen[0] == 1'b1) && (rff_rcv_data[0] == 0);   //rcv_start 是在下降沿拉高
assign trx_send_done   = (send_counter == send_counter_max);
assign trx_rcv_done    = (recv_counter == recv_counter_max - 1);  //提前一拍通知ebi

always @(negedge clk) begin
    if(rst) begin  //默认接收
        ebi_oen <= {EBI_WIDTH{1'b1}};
    end else begin
        ebi_oen <= (is_send_mode && !is_cycle_count_left_one) ? {EBI_WIDTH{1'b0}} : {EBI_WIDTH{1'b1}};
    end
end

assign ebi_o = is_send_mode ? ((is_cycle_count_left_one || trx_send_done) ? {EBI_WIDTH{1'b1}} :send_data[EBI_WIDTH * send_counter +: EBI_WIDTH]) : {EBI_WIDTH{1'b1}};
assign resp_data = rcv_buf;

endmodule