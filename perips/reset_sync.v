module reset_sync (
	scan_mode,
	dclk,
	arst_n,
	srst_n
);
	parameter WIDTH = 1;
	input scan_mode;
	input dclk;
	input arst_n;
	output wire srst_n;
	reg in_data_s;
	reg in_data_2s;
	assign srst_n = (scan_mode ? arst_n : in_data_2s);
	always @(negedge arst_n or posedge dclk)
		if (arst_n == 1'b0) begin
			in_data_s <= 1'b0;
			in_data_2s <= 1'b0;
		end
		else begin
			in_data_s <= 1'b1;
			in_data_2s <= in_data_s;
		end
endmodule
