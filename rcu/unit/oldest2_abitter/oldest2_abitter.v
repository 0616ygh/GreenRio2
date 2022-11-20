module oldest2_abitter#(
    parameter SEL_WIDTH = 8,
    parameter PRIORITY_WIDTH = 3
)(
    input [PRIORITY_WIDTH-1:0] priority_fix_i,
    input [SEL_WIDTH-1:0] req_i,
    output first_grant_valid_o,
    output reg [PRIORITY_WIDTH-1:0] first_grant_index_o,
    output second_grant_valid_o,
    output reg [PRIORITY_WIDTH-1:0] second_grant_index_o
);

wire [SEL_WIDTH-1:0] grant, grant_less, mid, mid_less;
wire [SEL_WIDTH*2-1:0] double_grant, double_grant_less;
wire [SEL_WIDTH*3-1:0] double_first_grant_index, double_second_grant_index;
wire [SEL_WIDTH-1:0] first_grant_preindex, second_grant_preindex;

wire [SEL_WIDTH*2-1:0] double_req;
wire [SEL_WIDTH*2-1:0] double_fixed_req;
wire [SEL_WIDTH-1:0] fixed_req;

reg [SEL_WIDTH-1:0] rff_req;

assign double_req = {req_i, req_i};
assign double_fixed_req = double_req >> priority_fix_i;
assign fixed_req = double_fixed_req[SEL_WIDTH-1:0];

assign double_grant = {grant, grant};
assign double_grant_less = {grant_less, grant_less};

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
    for(genvar j = 1; j < SEL_WIDTH; j = j + 1) begin
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


endmodule
