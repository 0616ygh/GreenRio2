module testio_slave_top #(  
    parameter TI_W = 1,
    parameter BUS_WIDTH = 32
) (
    //testio          
    input               rst,   //Peripheral async reset signal
    // IO Port
    input               clk,
    input      [TI_W-1:0]       test_din,
    output     reg [TI_W-1:0]   test_dout,
    output     reg [TI_W-1:0]   test_doen,
    //mem_if i
    output              testio_wbs_stb_o,
    output       reg       testio_wbs_cyc_o,
    output              testio_wbs_we_o,
    output     [BUS_WIDTH-1:0]   testio_wbs_addr_o,
    output     [BUS_WIDTH-1:0]   testio_wbs_wdata_o,
    output     [(BUS_WIDTH/8)-1:0]    testio_wbs_strb_o,
    input               wbs_testio_ack_i,
    input       [BUS_WIDTH-1:0]  wbs_testio_rdata_i 
);
assign testio_wbs_stb_o =  testio_wbs_cyc_o;
assign testio_wbs_strb_o = 4'hf;

localparam  REQ_READ            = 1'd0;
localparam  REQ_WRITE           = 1'd1;
localparam                   N_CNT_BITS   = 7;
localparam  [N_CNT_BITS-1:0] N_CMD_BITS   = TI_W; //bits number
localparam  [N_CNT_BITS-1:0] N_ADDR_BITS  = BUS_WIDTH;
localparam  [N_CNT_BITS-1:0] N_STRB_BITS  = (TI_W==1) ? (BUS_WIDTH/8) : TI_W; //这里指的是在receive_buffer中所占宽度
localparam  [N_CNT_BITS-1:0] N_DATA_BITS  = BUS_WIDTH;
localparam  [N_CNT_BITS-1:0] N_PRTY_BITS  = TI_W;
localparam  [N_CNT_BITS-1:0] N_ACK_BITS   = TI_W;
localparam  [N_CNT_BITS-1:0] N_STOP_BITS   = TI_W;
localparam  [N_CNT_BITS-1:0] N_CMDBUF_BITS = N_CMD_BITS + N_ADDR_BITS + N_DATA_BITS + N_STRB_BITS + N_PRTY_BITS; //start信号不需要存，直接从command开始存
localparam CMD_CYC = 1;  //cycle number
localparam ADDR_CYC = BUS_WIDTH/TI_W;
localparam STRB_CYC  = (TI_W == 1) ? (BUS_WIDTH/8) : 1; 
localparam DATA_CYC  = BUS_WIDTH/TI_W;
localparam PRTY_CYC  = 1;
localparam ACK_CYC  = 1;
localparam STOP_CYC = 1;


localparam  [N_CMD_BITS-1:0] CMD_RD       = 0;
localparam  [N_CMD_BITS-1:0] CMD_WR       = 1;
localparam                   START        = 1'b0;
localparam                   STOP         = 1;
localparam  [N_ACK_BITS-1:0] ACK_OK       = {N_ACK_BITS{1'b0}};
localparam  [N_ACK_BITS-1:0] ACK_ERR      = {N_ACK_BITS{1'b1}};

wire [N_DATA_BITS-1:0] resp_data;

localparam CDC_IDLE = 3'd0;
localparam CDC_CMD = 3'd1;
localparam CDC_RREQ = 3'd2;
localparam CDC_RRSP = 3'd3;
localparam CDC_WREQ = 3'd4;
localparam CDC_WRSP = 3'd5;
localparam CDC_BACK = 3'd6;
reg [2:0] rff_cdcst, next_cdcst;

// the function of dff_test_din is to detect start signal
reg dff_test_din;
always @(posedge clk) begin
    dff_test_din <= test_din;
end

reg test_din_en;
reg dff_test_din_en;
wire test_din_neg;

reg [N_CNT_BITS-1:0] rff_cmd_idx_max;
reg [N_CNT_BITS-1:0] rff_cmd_idx;

assign test_din_neg = (dff_test_din == 1'b1) && (test_din == 1'b0);//start

always @(posedge clk) begin
    if (rst) 
        dff_test_din_en <= 1'd0;
    else 
        dff_test_din_en <= test_din_en;
end

wire [N_CMD_BITS-1:0]    cmd;
always @(*) begin
    if (cmd==CMD_WR)
        rff_cmd_idx_max = N_CNT_BITS + N_STRB_BITS + N_DATA_BITS + N_PRTY_BITS;  
    else if (cmd==CMD_RD)
        rff_cmd_idx_max = N_CNT_BITS  + N_DATA_BITS + N_PRTY_BITS;  
    else 
        rff_cmd_idx_max = {N_CNT_BITS{1'b1}};
end

always @(posedge clk) begin
    if (rst) begin
        rff_cmd_idx <= N_CMDBUF_BITS-1;
        test_din_en <= 1'b0;
    end else if (rff_cmd_idx == TI_W-1) begin
        test_din_en <= 1'b0;
        rff_cmd_idx <= N_CMDBUF_BITS-1;
    end else if (test_din_en) begin//followed start signal and receive bit stream
        rff_cmd_idx <= rff_cmd_idx - TI_W;
    end else if (test_doen && test_din_neg) begin //start signal
        test_din_en <= 1'b1;
        // rff_cmd_idx <= rff_cmd_idx - TI_W;
    end else begin
        rff_cmd_idx <= N_CMDBUF_BITS-1;
        test_din_en <= 1'b0;
    end
end

reg [N_CMDBUF_BITS-1:0] dff_cmdbuf;
always @(posedge clk) begin
    if(rst) begin
        dff_cmdbuf <= 'h0;
    end else if ((test_doen && test_din_neg) | test_din_en) begin
        dff_cmdbuf[rff_cmd_idx -: TI_W] <= test_din;
    end
end

wire [N_ADDR_BITS-1:0]   addr;
wire [N_STRB_BITS-1:0]   wstrb;
wire [N_DATA_BITS-1:0]   wdata;
// wire [N_PRTY_BITS-1:0]   prty;

generate
// for (genvar i = 0; i < N_CMD_BITS; i++) begin : CMD_REORDER_GEN    // 第0位无效？
    assign cmd   = dff_cmdbuf[N_CMDBUF_BITS-1];  //parity
// end
// for (genvar i = 0; i < N_ADDR_BITS; i++) begin : ADDR_REORDER_GEN  //连续
    assign addr  = dff_cmdbuf[N_CMDBUF_BITS-N_CMD_BITS-1 -: N_ADDR_BITS];
// end
// for (genvar i = 0; i < BUS_WIDTH/8; i++) begin : STRB_REORDER_GEN
    // assign wstrb = dff_cmdbuf[N_CMDBUF_BITS-N_CMD_BITS-N_ADDR_BITS-1 -: N_STRB_BITS];
// end
// for (genvar i = 0; i < N_DATA_BITS; i++) begin : WDATA_REORDER_GEN
    assign wdata = dff_cmdbuf[N_CMDBUF_BITS-N_CMD_BITS-N_ADDR_BITS-N_STRB_BITS-1 -: N_DATA_BITS];
// end
// for (genvar i = 0; i < N_PRTY_BITS; i++) begin : PRTY_REORDER_GEN
//     assign prty[i]  = (cmd==CMD_WR) ?  dff_cmdbuf[N_CMD_BITS + N_ADDR_BITS + N_STRB_BITS + N_DATA_BITS + N_PRTY_BITS - i] :
//                                                 dff_cmdbuf[N_CMD_BITS + N_ADDR_BITS + N_PRTY_BITS - i];
// end
endgenerate


reg [N_ACK_BITS-1:0] ack;


always @(posedge clk) begin
// if (cmd==CMD_WR) 
//     ack <= (prty==prty_wreq_exp) ? ACK_OK : ACK_ERR;
// else if (cmd==CMD_RD)
//     ack <= (prty==prty_rreq_exp) ? ACK_OK : ACK_ERR;
// else 
    ack <= 1'b0;
end

reg [TI_W+N_ACK_BITS+N_DATA_BITS+N_PRTY_BITS+TI_W-1:0] dff_payload;
reg [N_CNT_BITS-1:0]                             rff_payload_idx;
reg                                              rff_payload_in_progress;

always @(posedge clk) begin
    if (rst) begin
        dff_payload <= 'h0;
    end
    else begin
        if (cmd==CMD_RD) begin
            if (wbs_testio_ack_i) //dff_payload前面加一组1是为了解决payload_idx变化过快的问题
                dff_payload <= {{TI_W{1'b0}}, {TI_W{ack}}, resp_data, {TI_W{1'b1}}, {TI_W{1'b1}}};  // bit stream to back
                // dff_payload <= 36'h0;
            else /*if (rff_payload_idx == (1+N_ACK_BITS+N_DATA_BITS+N_PRTY_BITS+1-1))*/
                dff_payload <= dff_payload;
        end else if (cmd==CMD_WR) begin
            if ((wbs_testio_ack_i))
                dff_payload <= {{TI_W{1'b0}}, ack, {TI_W{1'b1}}, 32'hFFFF_FFFF};  // ？ what's that?   //对于一个slave来说没必要记录类型
            else /*if (rff_payload_idx == (1+N_ACK_BITS+1-1))*/
                dff_payload <= dff_payload;
        end else begin
            dff_payload <= dff_payload;
        end
    end
end

always @(negedge clk) begin
if (rst) 
    rff_payload_idx <= {N_CNT_BITS{1'b0}};
else case (cmd)
    CMD_RD: begin
        if (wbs_testio_ack_i) 
            rff_payload_idx <= {N_CNT_BITS{1'b0}};
        else if (rff_payload_in_progress)
            rff_payload_idx <= rff_payload_idx + TI_W;
    end
    CMD_WR: begin
        if (wbs_testio_ack_i) 
            rff_payload_idx <= {N_CNT_BITS{1'b0}};
        else if (rff_payload_in_progress) 
            rff_payload_idx <= rff_payload_idx + TI_W;
    end
endcase 
end

always @(negedge clk) begin
    if (rst) 
        rff_payload_in_progress <= 1'b0;
    else begin
        case (cmd)
            CMD_RD: begin
            if (wbs_testio_ack_i) 
                rff_payload_in_progress <= 1'b1;
            else if (rff_payload_idx == (TI_W+N_ACK_BITS+N_DATA_BITS+N_PRTY_BITS+TI_W - TI_W)) //finish 
                rff_payload_in_progress <= 1'b0;
            end
            CMD_WR: begin
            if (wbs_testio_ack_i)
                rff_payload_in_progress <= 1'b1;
            else if (rff_payload_idx == (TI_W+N_ACK_BITS+N_PRTY_BITS+TI_W-TI_W)) //finish 
                rff_payload_in_progress <= 1'b0;
            end
        endcase 
    end
end



always @(posedge clk) begin
    if (rst) begin
        rff_cdcst <= CDC_IDLE;
    end else begin
        rff_cdcst <= next_cdcst;
    end
end

always @(*) begin
    next_cdcst = rff_cdcst; //cdcst is the state
    case (rff_cdcst)
        CDC_IDLE: begin
            if (dff_test_din_en && !test_din_en) begin //!test_din_en代表计数完毕
                next_cdcst = CDC_CMD;
            end
        end
        CDC_CMD: begin
            case (cmd)
                CMD_RD: begin
                next_cdcst = CDC_RREQ;
                end
                CMD_WR: begin
                next_cdcst = CDC_WREQ;
                end
                default: begin
                next_cdcst = CDC_IDLE;
                end
            endcase
        end
        CDC_RREQ: begin
            // if (req_ready_i) begin
                next_cdcst = CDC_RRSP;
            // end
        end
        CDC_RRSP: begin
            if (wbs_testio_ack_i) begin
                next_cdcst = CDC_BACK;
            end
        end
        CDC_WREQ: begin
            // if (req_ready_i) begin
                next_cdcst = CDC_WRSP;
            // end
        end
        CDC_WRSP: begin
            if (wbs_testio_ack_i) begin
                next_cdcst = CDC_BACK;
            end
        end
        CDC_BACK: begin
            if (!rff_payload_in_progress) begin
                next_cdcst = CDC_IDLE;
            end
        end
    endcase
end

always @(*) begin
    test_doen = {TI_W{1'b1}};
    // default output high
    test_dout = {TI_W{1'b1}};
    if (rff_payload_in_progress == 1'b1) begin
        test_doen = {TI_W{1'b0}};
        test_dout = dff_payload[N_CMD_BITS + N_ACK_BITS + N_DATA_BITS + N_PRTY_BITS + N_STOP_BITS - 1 - rff_payload_idx -: TI_W];
    end
end

// assign req_valid_o     = (rff_cdcst == CDC_WREQ) | (rff_cdcst == CDC_RREQ);

always @(posedge clk) begin
    if(rst) begin
        testio_wbs_cyc_o <= 1'b0;
    end else begin
        if(wbs_testio_ack_i && ((rff_cdcst == CDC_WRSP) | (rff_cdcst == CDC_RRSP)))
            testio_wbs_cyc_o <= 1'b0;
        else if((rff_cdcst == CDC_WREQ) | (rff_cdcst == CDC_RREQ))
            testio_wbs_cyc_o <= 1'b1;
    end
end

assign testio_wbs_we_o  = cmd ? REQ_WRITE : REQ_READ;
assign testio_wbs_addr_o = addr[31:0];
assign testio_wbs_wdata_o  = wdata[31:0];
assign resp_data  = wbs_testio_rdata_i;

endmodule