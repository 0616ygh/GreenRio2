module routing(
    input rcu_do_rob_commit_first,
    input rcu2ft_bpu_cmt_is_branch_first,
    input rcu_do_rob_commit_second,
    input rcu2ft_bpu_cmt_is_branch_second,
    output branch_valid_first_w,
    output branch_valid_second_w,

    input lsu_imm,
    input rcu2fu_lsu_fenced,
    input rcu2fu_lsu_aq,
    input rcu2fu_lsu_rl,
    output rcu2fu_lsu_fenced_final,
    output [63:0] rcu2fu_agu_virt_offset,

    output reg func_wrb_alu2_exp_i,
    output reg func_wrb_alu2_ecause_i,
    output reg func_wrb_alu1_exp_i,
    output reg func_wrb_alu1_ecause_i,
    output reg func_wrb_md_exp_i,
    output reg func_wrb_md_ecause_i
);

assign branch_valid_first_w = rcu_do_rob_commit_first & rcu2ft_bpu_cmt_is_branch_first;
assign branch_valid_second_w = rcu_do_rob_commit_second & rcu2ft_bpu_cmt_is_branch_second;

assign rcu2fu_agu_virt_offset = {{32{lsu_imm[31]}},lsu_imm};
assign rcu2fu_lsu_fenced_final = rcu2fu_lsu_fenced | rcu2fu_lsu_aq | rcu2fu_lsu_rl;

always @(*) begin
    func_wrb_alu2_exp_i = 0;
    func_wrb_alu2_ecause_i = 0;
    func_wrb_alu1_exp_i = 0;
    func_wrb_alu1_ecause_i = 0;
    func_wrb_md_exp_i = 0;
    func_wrb_md_ecause_i = 0;
end

endmodule
