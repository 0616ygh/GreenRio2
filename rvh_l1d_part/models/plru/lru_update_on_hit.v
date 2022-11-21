module lru_update_on_hit (
	old_lru,
	hit_pos,
	new_lru
);
	parameter NCACHELINE = 8;
	parameter ADDR_W = $clog2(NCACHELINE);
	parameter LRU_W = 7;
	input wire [LRU_W - 1:0] old_lru;
	input wire [ADDR_W - 1:0] hit_pos;
	output reg [LRU_W - 1:0] new_lru;
	reg [LRU_W - 1:0] tmp;
	reg signed [31:0] idx;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(*) begin
		tmp = old_lru;
		idx = 1;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = $clog2(NCACHELINE) - 1; i >= 0; i = i - 1)
				begin
					tmp[idx - 1] = ~tmp[idx - 1];
					idx = (2 * idx) + sv2v_cast_32(hit_pos[i]);
				end
		end
		new_lru = tmp;
	end
endmodule
