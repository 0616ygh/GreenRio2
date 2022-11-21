`ifdef VERILATOR
`include "params.vh"
`endif
module mul(
    // Clock and reset
    input          clk_i,
    input          rst_ni,
    input   [63:0] operand_a_i,
    input   [63:0] operand_b_i,
    input   [1:0]  req_op_i,
    input          req_word_i,
    input          req_valid_i,
    output reg     req_ready_o,

    output reg     resp_valid_o,
    output reg [63:0] resp_value_o
);

  // This multiplication unit will split operation into 33x33 multiplication.
  //
  // MULW -> 2 cycles
  // MUL  -> 4 cycles
  // MULH -> 5 cycles

  // FSM States
  localparam STATEIDLE = 1'b0;
  localparam STATEPROGRESS = 1'b1;

  reg state_q;
  reg state_d;


  reg [0:0] a_idx_q, a_idx_d;
  reg [0:0] b_idx_q, b_idx_d;

  // Latched input operands. We latch them instead of using the combinational input for timing
  // proposes.
  reg [64:0] a_q, a_d;
  reg [64:0] b_q, b_d;
  reg op_low_q, op_low_d;
  reg op_word_q, op_word_d;

  // Multadd
  reg [65:0] accum, accum_d;
  reg [32:0] mac_op_a;
  reg [32:0] mac_op_b;
  reg [65:0] mac_prod;

  // Output signals
  reg o_valid_d;
  reg [63:0] o_value_d;

  // Perform multiplication
  assign req_ready_o = state_q == STATEIDLE;
  always @(*) begin
    case (a_idx_q)
      0: mac_op_a = {1'b0, a_q[31:0]};
      1: mac_op_a = a_q[64:32];
      default: mac_op_a = 0;
    endcase
    case (b_idx_q)
      0: mac_op_b = {1'b0, b_q[31:0]};
      1: mac_op_b = b_q[64:32];
      default: mac_op_b = 0;
    endcase
    mac_prod = accum + {{33{mac_op_a[32]}}, mac_op_a} * {{33{mac_op_b[32]}}, mac_op_b};
  end

  always @(*) begin
    a_d = a_q;
    b_d = b_q;
    op_low_d = op_low_q;
    op_word_d = op_word_q;
    state_d = state_q;
    accum_d = 0;
    o_value_d = 0;
    o_valid_d = 1'b0;

    a_idx_d = 0;
    b_idx_d = 0;

    case (state_q)
      STATEIDLE: begin
        if (req_valid_i) begin
          a_d = {req_op_i != MUL_OP_MULHU ? operand_a_i[63] : 1'b0, operand_a_i};
          b_d = {req_op_i[1] == 1'b0 ? operand_b_i[63] : 1'b0, operand_b_i};
          op_low_d = req_op_i == MUL_OP_MUL;
          op_word_d = req_word_i;

          o_value_d = 0;
          accum_d = 0;
          a_idx_d = 0;
          b_idx_d = 0;
          state_d = STATEPROGRESS;
        end
      end
      STATEPROGRESS: begin
        accum_d = mac_prod;
        o_value_d = resp_value_o;

        case ({a_idx_q, b_idx_q})
          {1'd0, 1'd0}: begin
            o_value_d[63:0] = {{32{mac_prod[32]}},mac_prod[31:0]};
            accum_d = signed'(mac_prod[65:32]);
            if (op_word_q) begin
              o_valid_d = 1'b1;
              accum_d = 0;
              state_d = STATEIDLE;
            end else begin
              a_idx_d = 1;
              b_idx_d = 0;
            end
          end

          {1'd1, 1'd0}: begin
            a_idx_d = 0;
            b_idx_d = 1;
          end
          {1'd0, 1'd1}: begin
            o_value_d[63:32] = signed'(mac_prod[31:0]);
            accum_d = signed'(mac_prod[65:32]);
            if (op_low_q) begin
              o_valid_d = 1'b1;
              accum_d = 0;
              state_d = STATEIDLE;
            end else begin
              a_idx_d = 1;
              b_idx_d = 1;
            end
          end

          {1'd1, 1'd1}: begin
            o_value_d[63:0] = mac_prod[63:0];
            o_valid_d = 1'b1;
            accum_d = 0;
            state_d = STATEIDLE;
          end
        endcase
      end
    endcase
  end

  always @(posedge clk_i) begin
    if (rst_ni) begin
      state_q <= STATEIDLE;
      a_q <= 0;
      b_q <= 0;
      op_low_q <= 1'b0;
      op_word_q <= 1'b0;
      accum <= '0;
      resp_valid_o <= 1'b0;
      resp_value_o <= 0;
      a_idx_q <= 0;
      b_idx_q <= 0;
    end else begin
      state_q <= state_d;
      a_q <= a_d;
      b_q <= b_d;
      op_low_q <= op_low_d;
      op_word_q <= op_word_d;
      accum <= accum_d;
      resp_valid_o <= o_valid_d;
      resp_value_o <= o_value_d;
      a_idx_q <= a_idx_d;
      b_idx_q <= b_idx_d;
    end
  end

endmodule

