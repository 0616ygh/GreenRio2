module AgeMatrixSelector (
	enq_fire_i,
	enq_mask_i,
	deq_fire_i,
	deq_mask_i,
	sel_mask_i,
	result_mask_o,
	entry_vld_i,
	clk,
	rstn
);
	parameter EntryCount = 4;
	parameter EnqWidth = 2;
	parameter SelWidth = 2;
	input wire [EnqWidth - 1:0] enq_fire_i;
	input wire [(EnqWidth * EntryCount) - 1:0] enq_mask_i;
	input wire deq_fire_i;
	input wire [EntryCount - 1:0] deq_mask_i;
	input wire [EntryCount - 1:0] sel_mask_i;
	output wire [(SelWidth * EntryCount) - 1:0] result_mask_o;
	input wire [EntryCount - 1:0] entry_vld_i;
	input wire clk;
	input wire rstn;
	wire [EntryCount - 1:0] age_matrix_clk_en;
	wire [EntryCount - 1:0] enq_age_matrix_en;
	wire [EntryCount - 1:0] deq_age_matrix_en;
	wire [(EnqWidth * EntryCount) - 1:0] enq_dependency_vec;
	wire [(EntryCount * EnqWidth) - 1:0] enq_entry_sel_mask;
	wire [(EntryCount * EntryCount) - 1:0] enq_age_matrix;
	wire [(EntryCount * EntryCount) - 1:0] deq_age_matrix;
	reg [(EntryCount * EntryCount) - 1:0] age_matrix_d;
	reg [(EntryCount * EntryCount) - 1:0] age_matrix_q;
	reg [(EntryCount * EntryCount) - 1:0] age_matrix;
	wire [(SelWidth * EntryCount) - 1:0] selected_vec;
	wire [((SelWidth * EntryCount) * EntryCount) - 1:0] masked_age_matrix;
	genvar i;
	generate
		for (i = 0; i < SelWidth; i = i + 1) begin : gen_selected_vec
			if (i == 0) begin : gen_initial_one
				assign selected_vec[i * EntryCount+:EntryCount] = {EntryCount {1'b0}};
			end
			else begin : gen_others
				assign selected_vec[i * EntryCount+:EntryCount] = selected_vec[(i - 1) * EntryCount+:EntryCount] | result_mask_o[(i - 1) * EntryCount+:EntryCount];
			end
		end
		for (i = 0; i < SelWidth; i = i + 1) begin : gen_sel_matrix
			genvar col;
			for (col = 0; col < EntryCount; col = col + 1) begin : gen_col
				genvar row;
				for (row = 0; row < EntryCount; row = row + 1) begin : gen_row
					if (col == row) begin : gen_masked_vld
						assign masked_age_matrix[(((i * EntryCount) + row) * EntryCount) + col] = sel_mask_i[col] & ~selected_vec[(i * EntryCount) + col];
					end
					else begin : gen_masked_dependency
						assign masked_age_matrix[(((i * EntryCount) + row) * EntryCount) + col] = (sel_mask_i[col] & ~selected_vec[(i * EntryCount) + col] ? age_matrix[(row * EntryCount) + col] : 1'b1);
					end
				end
			end
		end
		for (i = 0; i < SelWidth; i = i + 1) begin : gen_multi_result
			genvar row;
			for (row = 0; row < EntryCount; row = row + 1) begin : gen_one
				assign result_mask_o[(i * EntryCount) + row] = &masked_age_matrix[((i * EntryCount) + row) * EntryCount+:EntryCount];
			end
		end
		for (i = 0; i < EntryCount; i = i + 1) begin : gen_enq_entry_en
			assign enq_age_matrix_en[i] = |enq_entry_sel_mask[i * EnqWidth+:EnqWidth];
		end
		for (i = 0; i < EnqWidth; i = i + 1) begin : gen_enq_dependency_vec
			if (i == 0) begin : gen_init_vec
				assign enq_dependency_vec[i * EntryCount+:EntryCount] = (deq_fire_i ? ~entry_vld_i | deq_mask_i : ~entry_vld_i);
			end
			else begin : gen_vec_with_inter_check
				assign enq_dependency_vec[i * EntryCount+:EntryCount] = (enq_fire_i[i - 1] ? enq_dependency_vec[(i - 1) * EntryCount+:EntryCount] & ~enq_mask_i[(i - 1) * EntryCount+:EntryCount] : enq_dependency_vec[(i - 1) * EntryCount+:EntryCount]);
			end
		end
		for (i = 0; i < EntryCount; i = i + 1) begin : gen_enq_entry_sel_mask
			genvar j;
			for (j = 0; j < EnqWidth; j = j + 1) begin : gen_sel
				assign enq_entry_sel_mask[(i * EnqWidth) + j] = enq_fire_i[j] & enq_mask_i[(j * EntryCount) + i];
			end
		end
		for (i = 0; i < EntryCount; i = i + 1) begin : gen_deq_entry_clk_en
			assign deq_age_matrix[i * EntryCount+:EntryCount] = age_matrix[i * EntryCount+:EntryCount] | deq_mask_i;
		end
		for (i = 0; i < EntryCount; i = i + 1) begin : gen_deq_entry_en
			assign deq_age_matrix_en[i] = deq_fire_i & entry_vld_i[i];
		end
	endgenerate
	assign age_matrix_clk_en = enq_age_matrix_en | deq_age_matrix_en;
	always @(*) begin : age_matrix_vld_dff
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < EntryCount; i = i + 1)
				begin
					begin : sv2v_autoblock_2
						reg signed [31:0] j;
						for (j = 0; j < EntryCount; j = j + 1)
							age_matrix[(i * EntryCount) + j] = age_matrix_q[(i * EntryCount) + j];
					end
					age_matrix[(i * EntryCount) + i] = entry_vld_i[i];
				end
		end
	end
	generate
		for (i = 0; i < EntryCount; i = i + 1) begin : gen_age_matrix_update_logic
			wire [EntryCount * 1:1] sv2v_tmp_u_age_matrix_update_MuxOH_data_o;
			always @(*) age_matrix_d[i * EntryCount+:EntryCount] = sv2v_tmp_u_age_matrix_update_MuxOH_data_o;
			MuxOH #(
				.InputWidth(2),
				.DataWidth(EntryCount)
			) u_age_matrix_update_MuxOH(
				.sel_i({enq_age_matrix_en[i], deq_age_matrix_en[i]}),
				.data_i({enq_age_matrix[i * EntryCount+:EntryCount], deq_age_matrix[i * EntryCount+:EntryCount]}),
				.data_o(sv2v_tmp_u_age_matrix_update_MuxOH_data_o)
			);
		end
		for (i = 0; i < EntryCount; i = i + 1) begin : gen_entry_update_dependency_vec
			MuxOH #(
				.InputWidth(EnqWidth),
				.DataWidth(EntryCount)
			) u_depend_vec_MuxOH(
				.sel_i(enq_entry_sel_mask[i * EnqWidth+:EnqWidth]),
				.data_i(enq_dependency_vec),
				.data_o(enq_age_matrix[i * EntryCount+:EntryCount])
			);
		end
	endgenerate
	always @(posedge clk or negedge rstn) begin : age_matrix_dependency_dff
		if (~rstn) begin : sv2v_autoblock_3
			reg signed [31:0] row;
			for (row = 0; row < EntryCount; row = row + 1)
				begin : sv2v_autoblock_4
					reg signed [31:0] col;
					for (col = 0; col < EntryCount; col = col + 1)
						if (row != col)
							age_matrix_q[(row * EntryCount) + col] <= 1'b0;
				end
		end
		else begin : sv2v_autoblock_5
			reg signed [31:0] row;
			for (row = 0; row < EntryCount; row = row + 1)
				if (age_matrix_clk_en[row]) begin : sv2v_autoblock_6
					reg signed [31:0] col;
					for (col = 0; col < EntryCount; col = col + 1)
						if (row != col)
							age_matrix_q[(row * EntryCount) + col] <= age_matrix_d[(row * EntryCount) + col];
				end
		end
	end
endmodule
