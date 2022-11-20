module StaticPrioritySelector (
	enq_mask_o,
	sel_mask_i,
	result_mask_o,
	entry_vld_i
);
	parameter Depth = 8;
	parameter EnqWidth = 2;
	parameter SelWidth = 2;
	output wire [(EnqWidth * Depth) - 1:0] enq_mask_o;
	input wire [Depth - 1:0] sel_mask_i;
	output wire [(SelWidth * Depth) - 1:0] result_mask_o;
	input wire [Depth - 1:0] entry_vld_i;
	wire [(EnqWidth * Depth) - 1:0] enq_allocated_mask;
	wire [(EnqWidth * Depth) - 1:0] masked_enq_rdy;
	wire [(SelWidth * Depth) - 1:0] selected_mask;
	wire [(SelWidth * Depth) - 1:0] masked_sel_mask;
	genvar i;
	generate
		for (i = 0; i < EnqWidth; i = i + 1) begin : gen_enq_allocated_mask
			if (i == 0) begin : gen_initial_one
				assign enq_allocated_mask[i * Depth+:Depth] = {Depth {1'b0}};
			end
			else begin : gen_others
				assign enq_allocated_mask[i * Depth+:Depth] = enq_allocated_mask[(i - 1) * Depth+:Depth] | enq_mask_o[(i - 1) * Depth+:Depth];
			end
			assign masked_enq_rdy[i * Depth+:Depth] = ~enq_allocated_mask[i * Depth+:Depth] & ~entry_vld_i;
		end
		for (i = 0; i < EnqWidth; i = i + 1) begin : gen_enq_mask
			assign enq_mask_o[i * Depth+:Depth] = masked_enq_rdy[i * Depth+:Depth] & ~(masked_enq_rdy[i * Depth+:Depth] - 1);
		end
		for (i = 0; i < SelWidth; i = i + 1) begin : gen_masked_sel_mask
			if (i == 0) begin : gen_initial_one
				assign selected_mask[i * Depth+:Depth] = {Depth {1'b0}};
			end
			else begin : gen_others
				assign selected_mask[i * Depth+:Depth] = selected_mask[(i - 1) * Depth+:Depth] | result_mask_o[(i - 1) * Depth+:Depth];
			end
			assign masked_sel_mask[i * Depth+:Depth] = ~selected_mask[i * Depth+:Depth] & sel_mask_i;
		end
		for (i = 0; i < SelWidth; i = i + 1) begin : gen_sel_result
			assign result_mask_o[i * Depth+:Depth] = masked_sel_mask[i * Depth+:Depth] & ~(masked_sel_mask[i * Depth+:Depth] - 1);
		end
	endgenerate
endmodule
