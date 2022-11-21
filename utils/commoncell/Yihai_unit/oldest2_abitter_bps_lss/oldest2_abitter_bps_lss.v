module oldest2_abitter_bps_lss#(
    parameter SEL_WIDTH = 8,
    parameter PRIORITY_WIDTH = 3
)(
    input [PRIORITY_WIDTH-1:0] priority_fix_i,
    input [SEL_WIDTH-1:0] req_i,
    input [SEL_WIDTH-1:0] req_ls_i, //for load store sequence
    input new_req_first_i,
    input new_req_second_i,
    input new_req_ls_first_i, //for load store sequence
    input new_req_ls_second_i, //for load store sequence
    output new_grant_first_o,
    output new_grant_second_o,
    output first_grant_valid_o,
    output reg [PRIORITY_WIDTH-1:0] first_grant_index_o,
    output second_grant_valid_o,
    output reg [PRIORITY_WIDTH-1:0] second_grant_index_o
);

parameter SEL_NEW_WIDTH = SEL_WIDTH + 2;

wire [SEL_NEW_WIDTH-1:0] grant, grant_less, mid, mid_less;
wire [SEL_WIDTH*2-1:0] double_grant, double_grant_less;
wire [SEL_WIDTH*3-1:0] double_first_grant_index, double_second_grant_index;
wire [SEL_WIDTH-1:0] first_grant_preindex, second_grant_preindex;

wire [SEL_WIDTH*2-1:0] double_req, ls_double_req;
wire [SEL_WIDTH*2-1:0] double_fixed_req, ls_double_fixed_req;
wire [SEL_NEW_WIDTH-1:0] fixed_req;

reg [SEL_WIDTH-1:0] rff_req;

// load store operation
wire [SEL_WIDTH*2-1:0] double_ls_req, double_fixed_ls_req, double_ls_gnt;
wire [SEL_NEW_WIDTH-1:0] fixed_ls_req, fixed_ls_req_ver, real_gnt, ls_gnt_sequence;
wire [SEL_NEW_WIDTH*2-1:0] double_fixed2_ls_req, double_fixed2_ls_gnt;
wire [SEL_WIDTH*3-1:0] ls_gnt;

assign fixed_ls_req_ver = ~{new_req_ls_second_i, new_req_ls_first_i, double_ls_req[SEL_WIDTH-1:0]};
assign double_ls_req = {req_ls_i, req_ls_i};
assign double_fixed_ls_req = double_ls_req >> priority_fix_i;

assign fixed_ls_req = {new_req_ls_second_i, new_req_ls_first_i, double_fixed_ls_req[SEL_WIDTH-1:0]};
assign double_fixed2_ls_req = {fixed_ls_req, fixed_ls_req};
assign double_fixed2_ls_gnt = double_fixed2_ls_req & ~(double_fixed2_ls_req - 1);
assign ls_gnt_sequence = double_fixed2_ls_gnt[SEL_NEW_WIDTH-1:0] | double_fixed2_ls_gnt[SEL_NEW_WIDTH*2-1:SEL_NEW_WIDTH];
wire fixed_ls_new_first = ls_gnt_sequence[SEL_NEW_WIDTH-2];
wire fixed_ls_new_second = ls_gnt_sequence[SEL_NEW_WIDTH-1];
assign double_ls_gnt = {ls_gnt_sequence[SEL_WIDTH-1:0], ls_gnt_sequence[SEL_WIDTH-1:0]};
assign ls_gnt = double_ls_gnt << priority_fix_i;
assign real_gnt = {fixed_ls_new_second, fixed_ls_new_first, ls_gnt[SEL_WIDTH*2-1:SEL_WIDTH]} | fixed_ls_req_ver;
// : load store operation

// oldest2_abitter
//with new req
assign new_grant_first_o = grant[SEL_NEW_WIDTH-2] | grant_less[SEL_NEW_WIDTH-2];
assign new_grant_second_o = grant[SEL_NEW_WIDTH-1] | grant_less[SEL_NEW_WIDTH-1];
//: with new req

assign double_req = {req_i, req_i};
assign ls_double_req = {real_gnt[SEL_WIDTH-1:0], real_gnt[SEL_WIDTH-1:0]};
assign double_fixed_req = double_req >> priority_fix_i;
assign ls_double_fixed_req = ls_double_req >> priority_fix_i;
assign fixed_req = {new_req_second_i, new_req_first_i, double_fixed_req[SEL_WIDTH-1:0]} & {real_gnt[SEL_NEW_WIDTH-1], real_gnt[SEL_NEW_WIDTH-2], ls_double_fixed_req[SEL_WIDTH-1:0]};

assign double_grant = {grant[SEL_WIDTH-1:0], grant[SEL_WIDTH-1:0]};
assign double_grant_less = {grant_less[SEL_WIDTH-1:0], grant_less[SEL_WIDTH-1:0]};

assign first_grant_preindex = double_first_grant_index[SEL_WIDTH*2-1:SEL_WIDTH];
assign second_grant_preindex = double_second_grant_index[SEL_WIDTH*2-1:SEL_WIDTH];

assign double_first_grant_index = double_grant << priority_fix_i;
assign double_second_grant_index = double_grant_less << priority_fix_i;

assign grant[0] = fixed_req[0];
assign mid[0] = fixed_req[0];
assign mid_less[0] = fixed_req[0] & !grant[0];
assign grant_less[0] = fixed_req[0] & !grant[0];

assign first_grant_valid_o = (|first_grant_preindex);
assign second_grant_valid_o = (|second_grant_preindex);

generate
    for(genvar j = 1; j < SEL_NEW_WIDTH; j = j + 1) begin
        assign grant[j] = fixed_req[j] & !mid[j-1];
        assign grant_less[j] = fixed_req[j] & !mid_less[j-1] & !grant[j];
        assign mid[j] = fixed_req[j] | mid[j-1];
        assign mid_less[j] = (fixed_req[j] | mid_less[j-1]) & !grant[j];
    end
endgenerate

always @(*) begin
    first_grant_index_o = 0;
    second_grant_index_o = 0;
    for(integer j = 0; j < SEL_WIDTH; j = j + 1) begin
        if (first_grant_preindex[j]) begin
            first_grant_index_o = j;
        end
        if (second_grant_preindex[j]) begin
            second_grant_index_o = j;
        end
    end
end
// : oldest2_abitter

endmodule