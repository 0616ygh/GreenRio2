module rrv2rvh_ruby_reqtype_trans (
	rrv64_ruby_req_type_i,
	rvh_ld_req_type_o,
	rvh_st_req_type_o,
	is_ld_o
);
	input wire [5:0] rrv64_ruby_req_type_i;
	localparam [31:0] rvh_l1d_pkg_LDU_OP_WIDTH = 3;
	output reg [2:0] rvh_ld_req_type_o;
	localparam [31:0] rvh_l1d_pkg_STU_OP_WIDTH = 5;
	output reg [4:0] rvh_st_req_type_o;
	output reg is_ld_o;
	function automatic [2:0] sv2v_cast_B6C14;
		input reg [2:0] inp;
		sv2v_cast_B6C14 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_D7EFB;
		input reg [4:0] inp;
		sv2v_cast_D7EFB = inp;
	endfunction
	always @(*) begin
		rvh_ld_req_type_o = 1'sb0;
		rvh_st_req_type_o = 1'sb0;
		if (rrv64_ruby_req_type_i == 6'd0) begin
			rvh_st_req_type_o = 1'sb0;
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd1) begin
			rvh_ld_req_type_o = sv2v_cast_B6C14(0);
			is_ld_o = 1'b1;
		end
		else if (rrv64_ruby_req_type_i == 6'd2) begin
			rvh_ld_req_type_o = sv2v_cast_B6C14(3);
			is_ld_o = 1'b1;
		end
		else if (rrv64_ruby_req_type_i == 6'd3) begin
			rvh_ld_req_type_o = sv2v_cast_B6C14(1);
			is_ld_o = 1'b1;
		end
		else if (rrv64_ruby_req_type_i == 6'd4) begin
			rvh_ld_req_type_o = sv2v_cast_B6C14(4);
			is_ld_o = 1'b1;
		end
		else if (rrv64_ruby_req_type_i == 6'd5) begin
			rvh_ld_req_type_o = sv2v_cast_B6C14(2);
			is_ld_o = 1'b1;
		end
		else if (rrv64_ruby_req_type_i == 6'd6) begin
			rvh_ld_req_type_o = sv2v_cast_B6C14(5);
			is_ld_o = 1'b1;
		end
		else if (rrv64_ruby_req_type_i == 6'd7) begin
			rvh_ld_req_type_o = sv2v_cast_B6C14(6);
			is_ld_o = 1'b1;
		end
		else if (rrv64_ruby_req_type_i == 6'd8) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(0);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd9) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(1);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd10) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(2);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd11) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(3);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd12) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(7);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd13) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(8);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd14) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(9);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd15) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(10);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd16) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(11);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd17) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(12);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd18) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(13);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd19) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(14);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd20) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(15);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd21) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(16);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd22) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(17);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd23) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(18);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd24) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(19);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd25) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(20);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd26) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(21);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd27) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(22);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd28) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(23);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd29) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(24);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd30) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(25);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd31) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(26);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd32) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(27);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd33) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(28);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd34) begin
			rvh_ld_req_type_o = sv2v_cast_B6C14(2);
			is_ld_o = 1'b1;
		end
		else if (rrv64_ruby_req_type_i == 6'd35) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(2);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd36) begin
			rvh_ld_req_type_o = sv2v_cast_B6C14(6);
			is_ld_o = 1'b1;
		end
		else if (rrv64_ruby_req_type_i == 6'd37) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(3);
			is_ld_o = 1'b0;
		end
		else if (rrv64_ruby_req_type_i == 6'd38) begin
			rvh_st_req_type_o = sv2v_cast_D7EFB(4);
			is_ld_o = 1'b0;
		end
	end
endmodule
