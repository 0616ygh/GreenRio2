module rvh_pmp_entry (
	cfg_set_vld_i,
	cfg_set_payload_i,
	addr_set_vld_i,
	addr_set_payload_i,
	pmpaddr_o,
	pmpcfg_o,
	lock_formmer_entry_o,
	lock_from_latter_entry_i,
	formmer_entry_addr_i,
	permission_check_vld_i,
	permission_check_paddr_i,
	permission_check_access_type_i,
	permission_check_entry_match_o,
	permission_check_fail_o,
	clk,
	rstn
);
	parameter PADDR_WIDTH = 56;
	input cfg_set_vld_i;
	input [7:0] cfg_set_payload_i;
	input addr_set_vld_i;
	input [63:0] addr_set_payload_i;
	output [63:0] pmpaddr_o;
	output [7:0] pmpcfg_o;
	output lock_formmer_entry_o;
	input lock_from_latter_entry_i;
	input [PADDR_WIDTH - 1:2] formmer_entry_addr_i;
	input permission_check_vld_i;
	input [PADDR_WIDTH - 1:0] permission_check_paddr_i;
	input [1:0] permission_check_access_type_i;
	output permission_check_entry_match_o;
	output permission_check_fail_o;
	input clk;
	input rstn;
	localparam PMP_ACCESS_TYPE_R = 0;
	localparam PMP_ACCESS_TYPE_W = 1;
	localparam PMP_ACCESS_TYPE_X = 2;
	localparam PMPCFG_A_OFF = 0;
	localparam PMPCFG_A_TOR = 1;
	localparam PMPCFG_A_NA4 = 2;
	localparam PMPCFG_A_NAPOT = 3;
	wire pmpaddr_clk_en;
	wire pmpcfg_clk_en;
	wire [PADDR_WIDTH - 1:2] pmpaddr_d;
	wire pmpcfg_L_d;
	wire [1:0] pmpcfg_A_d;
	wire pmpcfg_X_d;
	wire pmpcfg_W_d;
	wire pmpcfg_R_d;
	reg [PADDR_WIDTH - 1:2] pmpaddr_q;
	reg pmpcfg_L_q;
	reg [1:0] pmpcfg_A_q;
	reg pmpcfg_X_q;
	reg pmpcfg_W_q;
	reg pmpcfg_R_q;
	wire [PADDR_WIDTH - 1:2] first_zero_mask;
	wire [PADDR_WIDTH - 1:2] napot_mask;
	reg [PADDR_WIDTH - 1:2] pmpaddr;
	reg [PADDR_WIDTH - 1:0] base;
	reg [PADDR_WIDTH - 1:0] bound;
	wire hit_range;
	reg permission_deny;
	assign first_zero_mask = ~pmpaddr_q & (~pmpaddr_q - 1'b1);
	assign napot_mask = first_zero_mask | (first_zero_mask - 1'b1);
	always @(*) begin : check_range
		case (pmpcfg_A_q)
			PMPCFG_A_TOR: begin
				base = {formmer_entry_addr_i, 2'b00};
				bound = {pmpaddr_q, 2'b00};
			end
			PMPCFG_A_NA4: begin
				base = {pmpaddr_q, 2'b00};
				bound = {pmpaddr_q, 2'b11};
			end
			PMPCFG_A_NAPOT: begin
				base = {pmpaddr_q & ~napot_mask, 2'b00};
				bound = {pmpaddr_q | napot_mask, 2'b11};
			end
			default: begin
				base = {PADDR_WIDTH {1'b0}};
				bound = {PADDR_WIDTH {1'b1}};
			end
		endcase
	end
	always @(*) begin : check_permission
		case (permission_check_access_type_i)
			PMP_ACCESS_TYPE_R: permission_deny = ~pmpcfg_R_q;
			PMP_ACCESS_TYPE_W: permission_deny = ~pmpcfg_W_q;
			PMP_ACCESS_TYPE_X: permission_deny = ~pmpcfg_X_q;
			default: permission_deny = 1'b1;
		endcase
	end
	assign hit_range = ((pmpcfg_A_q != PMPCFG_A_OFF) & (permission_check_paddr_i >= base)) & (permission_check_paddr_i < bound);
	assign permission_check_entry_match_o = permission_check_vld_i & hit_range;
	assign permission_check_fail_o = permission_check_entry_match_o & permission_deny;
	assign pmpaddr_o = {{64 - PADDR_WIDTH {1'b0}}, pmpaddr_q, 2'b00};
	assign pmpcfg_o = {pmpcfg_L_q, 2'b00, pmpcfg_A_q, pmpcfg_X_q, pmpcfg_W_q, pmpcfg_R_q};
	assign lock_formmer_entry_o = (pmpcfg_A_q == PMPCFG_A_TOR) & pmpcfg_L_q;
	assign pmpaddr_clk_en = (addr_set_vld_i & ~pmpcfg_L_q) & ~lock_from_latter_entry_i;
	assign pmpcfg_clk_en = (cfg_set_vld_i & ~pmpcfg_L_q) & ~lock_from_latter_entry_i;
	assign pmpaddr_d = addr_set_payload_i[PADDR_WIDTH - 1:2];
	assign pmpcfg_L_d = cfg_set_payload_i[7];
	assign pmpcfg_A_d = cfg_set_payload_i[4:3];
	assign pmpcfg_X_d = cfg_set_payload_i[2];
	assign pmpcfg_W_d = cfg_set_payload_i[1];
	assign pmpcfg_R_d = cfg_set_payload_i[0];
	DFFRE #(.Width(PADDR_WIDTH - 2)) u_pmp_addr_DFFRE(
		.CLK(clk),
		.RSTN(rstn),
		.DRST({PADDR_WIDTH - 2 {1'b0}}),
		.EN(pmpaddr_clk_en),
		.D(pmpaddr_d),
		.Q(pmpaddr_q)
	);
	DFFRE #(.Width(6)) u_pmp_cfg_DFFRE(
		.CLK(clk),
		.RSTN(rstn),
		.DRST(6'b000000),
		.EN(pmpcfg_clk_en),
		.D({pmpcfg_L_d, pmpcfg_A_d, pmpcfg_X_d, pmpcfg_W_d, pmpcfg_R_d}),
		.Q({pmpcfg_L_q, pmpcfg_A_q, pmpcfg_X_q, pmpcfg_W_q, pmpcfg_R_q})
	);
endmodule
