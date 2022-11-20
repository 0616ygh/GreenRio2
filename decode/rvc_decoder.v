/*
 * This RVC decoder is adapted from 
 * https://github.com/ataradov/riscv/blob/master/rtl/riscv_core.v
 * and extended for RV64C
 *
 */

`ifndef RVC_DECODER_V
`define RVC_DECODER_V

module rvc_decoder (
    input clk,
    input rst,
    input is_rv_i,
    input  [31:0] instruction_i,
    output [31:0] rv_inst_o
);

wire [15:0] rvc_inst = instruction_i[15:0];
reg [31:0] rvc_dec_w;

always @ (*) begin
  // An illegal RVC opcode is decoded into 32'h0, which is also an illegal RV opcode.
  // We don't explicitly detect illegal RVC opcodes, but let RV decoder deal with them.
  rvc_dec_w = 32'h0;

  case ({rvc_inst[15:13], rvc_inst[1:0]})
    5'b00000: begin
      if (rvc_inst[12:2] != 11'h0 && rvc_inst[12:5] != 8'h0) // c.add14spn
        rvc_dec_w = { 2'b00, rvc_inst[10:7], rvc_inst[12:11], rvc_inst[5],
          rvc_inst[6], 2'b00, 5'd2, 3'b000, 2'b01, rvc_inst[4:2], 7'b0010011 };
    end

    5'b01000: begin // c.lw
      rvc_dec_w = { 5'b00000, rvc_inst[5], rvc_inst[12:10], rvc_inst[6],
        2'b00, 2'b01, rvc_inst[9:7], 3'b010, 2'b01, rvc_inst[4:2], 7'b0000011 };
    end

    5'b01100: begin // c.ld
      rvc_dec_w = { 4'b0000, rvc_inst[6:5], rvc_inst[12:10],
        3'b000, 2'b01, rvc_inst[9:7], 3'b011, 2'b01, rvc_inst[4:2], 7'b0000011 };
    end

    5'b11000: begin // c.sw
      rvc_dec_w = { 5'b00000, rvc_inst[5], rvc_inst[12], 2'b01, rvc_inst[4:2],
        2'b01, rvc_inst[9:7], 3'b010, rvc_inst[11:10], rvc_inst[6], 2'b00, 7'b0100011 };
    end

    5'b11100: begin // c.sd
      rvc_dec_w = { 4'b0000, rvc_inst[6:5], rvc_inst[12], 2'b01, rvc_inst[4:2],
        2'b01, rvc_inst[9:7], 3'b011, rvc_inst[11:10], 3'b000, 7'b0100011 };
    end

    5'b00001: begin
      if (rvc_inst[12:2] == 11'h0) // c.nop
        rvc_dec_w = { 25'h0, 7'b0010011 };
      else if (rvc_inst[12] != 1'b0 || rvc_inst[6:2] != 5'h0) // c.addi
        rvc_dec_w = { {7{rvc_inst[12]}}, rvc_inst[6:2], rvc_inst[11:7],
          3'b000, rvc_inst[11:7], 7'b0010011 };
    end

    5'b00101: begin 
      if (rvc_inst[11:7] != 5'd0) // c.addiw
        rvc_dec_w = { {7{rvc_inst[12]}}, rvc_inst[6:2], rvc_inst[11:7],
          3'b000, rvc_inst[11:7], 7'b0011011 };
    end

    5'b01001: begin
      if (rvc_inst[11:7] != 5'd0) // c.li
        rvc_dec_w = { {7{rvc_inst[12]}}, rvc_inst[6:2], 5'd0, 3'b000,
          rvc_inst[11:7], 7'b0010011 };
    end

    5'b01101: begin
      if ((rvc_inst[12] != 1'b0 || rvc_inst[6:2] != 5'h0) && rvc_inst[11:7] != 5'd0) begin
        if (rvc_inst[11:7] == 5'd2) // c.addi16sp
          rvc_dec_w = { {3{rvc_inst[12]}}, rvc_inst[4], rvc_inst[3], rvc_inst[5],
            rvc_inst[2], rvc_inst[6], 4'b0000, 5'd2, 3'b000, 5'd2, 7'b0010011 };
        else // c.lui
          rvc_dec_w = { {15{rvc_inst[12]}}, rvc_inst[6:2], rvc_inst[11:7], 7'b0110111 };
      end
    end

    5'b10001: begin
      if (rvc_inst[12:10] == 3'b011 && rvc_inst[6:5] == 2'b00) // c.sub
        rvc_dec_w = { 7'b0100000, 2'b01, rvc_inst[4:2], 2'b01, rvc_inst[9:7],
          3'b000, 2'b01, rvc_inst[9:7], 7'b0110011 };
      else if (rvc_inst[12:10] == 3'b011 && rvc_inst[6:5] == 2'b01) // c.xor
        rvc_dec_w = { 7'b0000000, 2'b01, rvc_inst[4:2], 2'b01, rvc_inst[9:7],
          3'b100, 2'b01, rvc_inst[9:7], 7'b0110011 };
      else if (rvc_inst[12:10] == 3'b011 && rvc_inst[6:5] == 2'b10) // c.or
        rvc_dec_w = { 7'b0000000, 2'b01, rvc_inst[4:2], 2'b01, rvc_inst[9:7],
          3'b110, 2'b01, rvc_inst[9:7], 7'b0110011 };
      else if (rvc_inst[12:10] == 3'b011 && rvc_inst[6:5] == 2'b11) // c.and
        rvc_dec_w = { 7'b0000000, 2'b01, rvc_inst[4:2], 2'b01, rvc_inst[9:7],
          3'b111, 2'b01, rvc_inst[9:7], 7'b0110011 };
      else if (rvc_inst[11:10] == 2'b10) // c.andi
        rvc_dec_w = { {7{rvc_inst[12]}}, rvc_inst[6:2], 2'b01, rvc_inst[9:7],
          3'b111, 2'b01, rvc_inst[9:7], 7'b0010011 };
      else if (rvc_inst[12] == 1'b0 && rvc_inst[6:2] == 5'h0)
        rvc_dec_w = 32'h0;
      else if (rvc_inst[11:10] == 2'b00) // c.srli
        rvc_dec_w = { 6'b000000, {rvc_inst[12], rvc_inst[6:2]}, 2'b01, rvc_inst[9:7],
          3'b101, 2'b01, rvc_inst[9:7], 7'b0010011 };
      else if (rvc_inst[11:10] == 2'b01) // c.srai
        rvc_dec_w = { 6'b010000, {rvc_inst[12], rvc_inst[6:2]}, 2'b01, rvc_inst[9:7],
          3'b101, 2'b01, rvc_inst[9:7], 7'b0010011 };
      else if (rvc_inst[12:10] == 3'b111 && rvc_inst[6:5] == 2'b00) // c.subw
        rvc_dec_w = { 7'b0100000, 2'b01, rvc_inst[4:2], 2'b01, rvc_inst[9:7],
          3'b000, 2'b01, rvc_inst[9:7], 7'b0111011 };
      else if (rvc_inst[12:10] == 3'b111 && rvc_inst[6:5] == 2'b01) // c.addw
        rvc_dec_w = { 7'b0000000, 2'b01, rvc_inst[4:2], 2'b01, rvc_inst[9:7],
          3'b000, 2'b01, rvc_inst[9:7], 7'b0111011 };
    end

    5'b10101: begin // c.j
      rvc_dec_w = { rvc_inst[12], rvc_inst[8], rvc_inst[10:9], rvc_inst[6],
        rvc_inst[7], rvc_inst[2], rvc_inst[11], rvc_inst[5:3], rvc_inst[12],
        {8{rvc_inst[12]}}, 5'd0, 7'b1101111 };
    end

    5'b11001: begin // c.beqz
      rvc_dec_w = { {4{rvc_inst[12]}}, rvc_inst[6], rvc_inst[5], rvc_inst[2],
        5'd0, 2'b01, rvc_inst[9:7], 3'b000, rvc_inst[11], rvc_inst[10],
        rvc_inst[4], rvc_inst[3], rvc_inst[12], 7'b1100011 };
    end

    5'b11101: begin // c.bnez
      rvc_dec_w = { {4{rvc_inst[12]}}, rvc_inst[6], rvc_inst[5], rvc_inst[2],
        5'd0, 2'b01, rvc_inst[9:7], 3'b001, rvc_inst[11], rvc_inst[10],
        rvc_inst[4], rvc_inst[3], rvc_inst[12], 7'b1100011 };
    end

    5'b00010: begin
      if (rvc_inst[11:7] != 5'd0) // c.slli
        rvc_dec_w = { 6'b000000, {rvc_inst[12], rvc_inst[6:2]}, rvc_inst[11:7], 3'b001,
          rvc_inst[11:7], 7'b0010011 };
    end

    5'b01010: begin
      if (rvc_inst[11:7] != 5'h0) // c.lwsp
        rvc_dec_w = { 4'b0000, rvc_inst[3:2], rvc_inst[12], rvc_inst[6:4],
          2'b0, 5'd2, 3'b010, rvc_inst[11:7], 7'b0000011 };
    end

    5'b01110: begin
      if (rvc_inst[11:7] != 5'h0) // c.ldsp
        rvc_dec_w = { 3'b000, rvc_inst[4:2], rvc_inst[12], rvc_inst[6:5], 
          3'b000, 5'd2, 3'b011, rvc_inst[11:7], 7'b0000011 };
    end

    5'b11010: begin // c.swsp
      rvc_dec_w = { 4'b0000, rvc_inst[8:7], rvc_inst[12], rvc_inst[6:2],
        5'd2, 3'b010, rvc_inst[11:9], 2'b00, 7'b0100011 };
    end

    5'b11110: begin // c.sdsp
      rvc_dec_w = { 3'b000, rvc_inst[9:7], rvc_inst[12], rvc_inst[6:2],
        5'd2, 3'b011, rvc_inst[11:10], 3'b000, 7'b0100011 };
    end

    5'b10010: begin
      if (rvc_inst[6:2] == 5'd0) begin
        if (rvc_inst[11:7] == 5'h0) begin
          if (rvc_inst[12] == 1'b1) // c.ebreak
            rvc_dec_w = { 11'h0, 1'b1, 13'h0, 7'b1110011 };
        end else if (rvc_inst[12])
          rvc_dec_w = { 12'h0, rvc_inst[11:7], 3'b000, 5'd1, 7'b1100111 }; // c.jalr
        else
          rvc_dec_w = { 12'h0, rvc_inst[11:7], 3'b000, 5'd0, 7'b1100111 }; // c.jr
      end else if (rvc_inst[11:7] != 5'h0) begin
        if (rvc_inst[12] == 1'b0) // c.mv
          rvc_dec_w = { 7'b0000000, rvc_inst[6:2], 5'd0, 3'b000,
            rvc_inst[11:7], 7'b0110011 };
        else // c.add
          rvc_dec_w = { 7'b0000000, rvc_inst[6:2], rvc_inst[11:7],
            3'b000, rvc_inst[11:7], 7'b0110011 };
      end
    end

    default: begin
    end
  endcase
end

assign rv_inst_o = is_rv_i ? instruction_i : rvc_dec_w;

endmodule

`endif  // RVC_DECODER_V