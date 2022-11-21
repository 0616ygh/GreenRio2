module arbiter_base #(
    parameter NUM_REQ = 4
)(
  input [NUM_REQ-1:0]    req,
  input [NUM_REQ-1:0]    base,
  output [NUM_REQ-1:0]    gnt
);

wire[2*NUM_REQ-1:0] double_req = {req,req};

wire[2*NUM_REQ-1:0] double_gnt = double_req & ~(double_req - {{NUM_REQ{1'b0}}, base});

assign gnt = double_gnt[NUM_REQ-1:0] | double_gnt[2*NUM_REQ-1:NUM_REQ];

endmodule
