module lru_get_new_line (
	old_lru,
	new_lru,
	repl_pos
);
	parameter NCACHELINE = 8;
	parameter ADDR_W = $clog2(NCACHELINE);
	parameter LRU_W = 7;
	input wire [LRU_W - 1:0] old_lru;
	output reg [LRU_W - 1:0] new_lru;
	output reg [ADDR_W - 1:0] repl_pos;
	reg signed [31:0] idx;
	reg [LRU_W:0] tmp;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(*) begin
		idx = 1;
		tmp = old_lru;
		repl_pos = 1'sb0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < $clog2(NCACHELINE); i = i + 1)
				begin
					tmp[idx - 1] = ~tmp[idx - 1];
					repl_pos = {repl_pos[0+:ADDR_W - 1], old_lru[idx - 1]};
					idx = (2 * idx) + sv2v_cast_32(repl_pos[0]);
				end
		end
		new_lru = tmp;
	end
endmodule
