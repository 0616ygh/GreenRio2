module one_hot_rr_arb #(
  parameter N_INPUT = 2,
  localparam int unsigned N_INPUT_WIDTH = N_INPUT > 1 ? $clog2(N_INPUT) : 1,
  localparam int unsigned IS_LOG2 = (2 ** N_INPUT_WIDTH) == N_INPUT 
) (
  input   logic [N_INPUT-1:0] req_i,
  input   logic               update_i,
  output  logic [N_INPUT-1:0] grt_o,
  output  logic [N_INPUT_WIDTH-1:0] grt_idx_o,
  input   logic               rstn, clk
);

  logic req_vld;
  logic [N_INPUT*2-1:0] req_pre_shift, req_shift;
  logic [N_INPUT*2-1:0] reversed_dereordered_selected_req_pre_shift, reversed_dereordered_selected_req_shift;
  logic [N_INPUT-1:0] reodered_req, reordered_selected_req;
  logic [N_INPUT-1:0] dereordered_selected_req;
  logic [N_INPUT-1:0] reversed_reordered_selected_req, reversed_dereordered_selected_req;
  logic [N_INPUT_WIDTH-1:0] round_ptr_q, round_ptr_d;
  logic [N_INPUT_WIDTH-1:0] selected_req_idx;

  assign req_vld = update_i;

  always @(posedge clk) begin
    if (~rstn) begin
      round_ptr_q <= '0;
    end else begin
      if (req_vld) begin
        round_ptr_q <= round_ptr_d;
      end
    end
  end

//7 6 5 4 3 2 1 0 // req_i
//2 1 0 7 6 5 4 3 // reodered_req
//3 4 5 6 7 0 1 2 // reversed_reordered_selected_req
//0 1 2 3 4 5 6 7 // reversed_dereordered_selected_req
//7 6 5 4 3 2 1 0 // dereordered_selected_req

  assign req_pre_shift = {{N_INPUT{1'b0}}, req_i};
  assign req_shift = req_pre_shift << round_ptr_q;
  always_comb begin : reorder_req_for_sel
    if(round_ptr_q == '0) begin
      reodered_req = req_i;
    end else begin
      reodered_req = req_shift[N_INPUT-1:0] | req_shift[N_INPUT*2-1:N_INPUT];
    end 
  end

  always_comb begin : reverse_reordered_selected_req
    for(int i = 0; i < N_INPUT; i++) begin
       reversed_reordered_selected_req[i] = reordered_selected_req[N_INPUT-1-i];
    end
  end

  assign reversed_dereordered_selected_req_pre_shift = {{N_INPUT{1'b0}}, reversed_reordered_selected_req};
  assign reversed_dereordered_selected_req_shift = reversed_dereordered_selected_req_pre_shift << round_ptr_q;
  always_comb begin : dereorder_sel_for_output
    if(round_ptr_q == '0) begin
      reversed_dereordered_selected_req = reversed_reordered_selected_req;
    end else begin
      reversed_dereordered_selected_req = reversed_dereordered_selected_req_shift[N_INPUT-1:0] | reversed_dereordered_selected_req_shift[N_INPUT*2-1:N_INPUT];
    end 
  end

  always_comb begin : reverse_reversed_dereordered_selected_req
    for(int i = 0; i < N_INPUT; i++) begin
       dereordered_selected_req[i] = reversed_dereordered_selected_req[N_INPUT-1-i];
    end
  end

  one_hot_priority_encoder
  #(
    .SEL_WIDTH    (N_INPUT)
  )
  biased_one_hot_priority_encoder_u
  (
    .sel_i    (reodered_req           ),
    .sel_o    (reordered_selected_req )
  );
  // priority_encoder
  // #(
  //   .SEL_WIDTH(N_INPUT)
  // )
  // biased_one_hot_priority_encoder_u
  // (
  //     .sel_i    (reodered_req ),
  //     .id_vld_o (),
  //     .id_o     (reordered_selected_req)
  // );

  logic [N_INPUT-1:0] dereordered_selected_req_oh_to_all_one;
  assign dereordered_selected_req_oh_to_all_one = dereordered_selected_req - 1;

  one_counter 
  #(
    .DATA_WIDTH(N_INPUT-1)
  ) 
  oh_to_idx_u 
  (
      .data_i(dereordered_selected_req_oh_to_all_one[N_INPUT-1-1:0]),
      .cnt_o (selected_req_idx)
  );
  

  assign round_ptr_d = (selected_req_idx == (N_INPUT-1)) ? '0
                                                         : selected_req_idx + 1;
  
  assign grt_o      = dereordered_selected_req;
  assign grt_idx_o  = selected_req_idx;
  
endmodule
