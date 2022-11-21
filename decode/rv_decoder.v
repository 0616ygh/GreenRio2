`ifndef RV_DECODER_V
`define RV_DECODER_V
`ifdef VERILATOR
`include "params.vh"
`endif

module rv_decoder (
    input clk,
    input rst,

    input tsr_i,
    input tvm_i,
    input tw_i ,

    input [PC_WIDTH-1:0] pc_i,
    input [PC_WIDTH-1:0] next_pc_i,
    input [PC_WIDTH-1:0] predicted_pc_i,
    input [31:0] rv_inst_i,
    input exception_i,
    input [EXCEPTION_CAUSE_WIDTH-1:0] ecause_i,
    input [1:0] privilege_mode_i,

    output reg uses_rs1_o,
    output reg uses_rs2_o,
    output reg uses_rd_o,
    output reg uses_csr_o,
    output reg [PC_WIDTH-1:0] pc_o,
    output reg [PC_WIDTH-1:0] next_pc_o,
    output reg [PC_WIDTH-1:0] predicted_pc_o,
    output reg [VIR_REG_ADDR_WIDTH-1:0] rs1_address_o,
    output reg [VIR_REG_ADDR_WIDTH-1:0] rs2_address_o,
    output reg [VIR_REG_ADDR_WIDTH-1:0] rd_address_o,
    output reg [CSR_ADDR_LEN-1:0] csr_address_o,
    output reg mret_o,
    output reg sret_o,
    output reg wfi_o,
    output reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_o,
    output reg exception_o,
    output reg half_o,
    output reg is_fence_o,
    output reg [1:0] fence_op_o,
    output reg is_aext_o,
    output reg is_mext_o,

    output reg csr_read_o,
    output reg csr_write_o,
    output reg [31:0] imm_data_o,
    output reg [2:0] fu_function_o,
    output reg alu_function_modifier_o,
    output reg [1:0] fu_select_a_o,
    output reg [1:0] fu_select_b_o,
    output reg jump_o,
    output reg branch_o,
    output reg is_alu_o,
    output reg load_o,
    output reg store_o,
    output reg [LDU_OP_WIDTH-1:0] ldu_op_o,
    output reg [STU_OP_WIDTH-1:0] stu_op_o,
    output reg aq_o,
    output reg rl_o
);

wire [31:0] instr = rv_inst_i;
wire [4:0] rs1_address = instr[19:15];
wire [4:0] rs2_address = instr[24:20];
wire [4:0] rd_address  = instr[11:7];

reg uses_rs1_w;
reg uses_rs2_w;
reg uses_csr_w;

always @(*) begin
  case (instr[6:0])
    7'b1100111,  // JALR
    7'b0000011,  // LOAD
    7'b0010011,  // OP-IMM
    7'b0011011:  // OP-IMM half
      begin
      uses_rs1_w = 1;
      uses_rs2_w = 0;
      uses_csr_w = 0;
    end
    7'b1100011,  // Branch
    7'b0100011,  // STORE
    7'b0110011,  // OP
    7'b0111011:  // OP half
      begin
      uses_rs1_w = 1;
      uses_rs2_w = 1;
      uses_csr_w = 0;
    end
    7'b1110011: begin  // SYSTEM
      uses_rs2_w = 0;
      case (instr[14:12])
        3'b001: begin  // CSRRW
          uses_rs1_w = 1;
          uses_csr_w = 1 && (rd_address != 0);
        end
        3'b010,  // CSRRS
        3'b011:  // CSRRC
          begin
          uses_rs1_w = 1;
          uses_csr_w = 1;
        end
        3'b101: begin  // CSRWI
          uses_rs1_w = 0;
          uses_csr_w = 1 && (rd_address != 0);
        end
        3'b110,  // CSRRSI
        3'b111:  // CSRRCI
          begin
          uses_rs1_w = 0;
          uses_csr_w = 1;
        end
        default: begin
          uses_rs1_w = 0;
          uses_csr_w = 0;
        end
      endcase
    end
    7'b0101111: begin  // RV32A, RV64A
      uses_rs1_w = 1;
      uses_csr_w = 0;
      case (instr[31:27])
        5'b00010: begin  // lr.w, lr.d
          uses_rs2_w = 0;
        end
        default: begin
          uses_rs2_w = 1;
        end
      endcase
    end
    default: begin
      uses_rs1_w = 0;
      uses_rs2_w = 0;
      uses_csr_w = 0;
    end
  endcase
end

always @(*) begin
    uses_rs1_o = uses_rs1_w; 
    uses_rs2_o = uses_rs2_w;
    uses_csr_o = uses_csr_w;
    rs1_address_o = rs1_address;
    rs2_address_o = rs2_address;
end

// possible immediate values
wire [31:0] u_type_imm_data = {instr[31:12], 12'b0};
wire [31:0] j_type_imm_data = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
wire [31:0] i_type_imm_data = {{20{instr[31]}}, instr[31:20]};
wire [31:0] s_type_imm_data = {{20{instr[31]}}, instr[31:25], instr[11:7]};
wire [31:0] b_type_imm_data = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
wire [31:0] csr_type_imm_data = {27'b0, rs1_address};

// wire signals 
reg [PC_WIDTH-1:0] pc_w;
reg [PC_WIDTH-1:0] next_pc_w;
reg [PC_WIDTH-1:0] predicted_pc_w;
reg [31:0] imm_data_w;
reg [11:0] csr_address_w;
reg [2:0] fu_function_w;
reg alu_function_modifier_w;
reg [1:0] fu_select_a_w;
reg [1:0] fu_select_b_w;
reg jump_w;
reg branch_w;
reg is_alu_w;
reg load_w;
reg store_w;
reg [LDU_OP_WIDTH-1:0] ldu_op_w;
reg [STU_OP_WIDTH-1:0] stu_op_w;
reg uses_rd_w;
reg [4:0] rd_address_w;
reg csr_read_w;
reg csr_write_w;
reg mret_w;
reg sret_w;
reg wfi_w;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_w;
reg exception_w;
reg half_w;
reg is_fence_w;
reg [1:0] fence_op_w;
reg is_aext_w;
reg is_mext_w;
reg aq_w;
reg rl_w;

always @(*) begin
  pc_w = pc_i;
  next_pc_w = next_pc_i;
  predicted_pc_w = predicted_pc_i;
  imm_data_w = 0;
  csr_address_w = instr[31:20];
  fu_function_w = ALU_OR;
  alu_function_modifier_w = 0;
  fu_select_a_w = ALU_SEL_IMM;
  fu_select_b_w = ALU_SEL_IMM;
  jump_w = 0;
  branch_w = 0;
  is_alu_w = 1;
  load_w = 0;
  store_w = 0;
  ldu_op_w = 0;
  stu_op_w = 0;
  uses_rd_w = 0;
  rd_address_w = 0;
  csr_read_w = 0;
  csr_write_w = 0;
  mret_w = 0;
  sret_w = 0;
  wfi_w = 0;
  ecause_w = ecause_i;
  exception_w = exception_i;
  half_w = 0;
  is_fence_w = 0;
  fence_op_w = 0;
  is_aext_w = 0;
  is_mext_w = 0;
  aq_w = 0;
  rl_w = 0;
  case (instr[6:0])
    7'b0110111: begin  // LUI
      uses_rd_w = 1;
      imm_data_w = u_type_imm_data;
      rd_address_w = rd_address;
    end
    7'b0010111: begin  // AUIPC
      uses_rd_w = 1;
      fu_function_w = ALU_ADD_SUB;
      fu_select_a_w = ALU_SEL_PC;
      imm_data_w = u_type_imm_data;
      rd_address_w = rd_address;
    end
    7'b1101111: begin  // JAL
      uses_rd_w = 1;
      fu_function_w = ALU_ADD_SUB;
      fu_select_a_w = ALU_SEL_PC;
      imm_data_w = j_type_imm_data;
      branch_w = 1;
      jump_w = 1;
      rd_address_w = rd_address;
    end
    7'b1100111: begin  // JALR
      uses_rd_w = 1;
      fu_function_w = ALU_ADD_SUB;
      fu_select_a_w = ALU_SEL_REG;
      imm_data_w = i_type_imm_data;
      branch_w = 1;
      jump_w = 1;
      rd_address_w = rd_address;
      if (instr[14:12] != 0) begin
        ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
        exception_w = 1;
      end
    end
    7'b1100011: begin  // Branch
      fu_function_w = instr[14:12];
      fu_select_a_w = ALU_SEL_PC;
      imm_data_w = b_type_imm_data;
      branch_w = 1;
      if (instr[14:13] == 2'b01) begin
        ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
        exception_w = 1;
      end
    end
    7'b0000011: begin  // LOAD
      uses_rd_w = 1;
      fu_select_a_w = ALU_SEL_REG;
      imm_data_w = i_type_imm_data;
      is_alu_w = 0;  // because of AGU
      load_w = 1;
      ldu_op_w = {2'b00, instr[14:12]};
      rd_address_w = rd_address;
      if ((instr[14:12] == 3'b111)) begin
        ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
        exception_w = 1;
      end
    end
    7'b0100011: begin  // STORE
      fu_select_a_w = ALU_SEL_REG;
      imm_data_w = s_type_imm_data;
      is_alu_w = 0;  // because of AGU
      store_w = 1;
      stu_op_w = {2'b00, instr[14:12]};
      if (instr[14]) begin
        ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
        exception_w = 1;
      end
    end
    7'b0010011: begin  // OP-IMM 64
      uses_rd_w = 1;
      fu_function_w = instr[14:12];
      alu_function_modifier_w = (instr[14:12] == 3'b101 && instr[30]);
      fu_select_a_w = ALU_SEL_REG;
      imm_data_w = i_type_imm_data;
      rd_address_w = rd_address;
      if ((instr[14:12] == 3'b001 && instr[31:26] != 0)  // slli 
          || (instr[14:12] == 3'b101 && (instr[31] != 0 || instr[29:26] != 0))  // srai & srli 
          ) begin
        ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
        exception_w = 1;
      end
    end
    7'b0011011: begin  // OP-IMM 64 half_w
      uses_rd_w = 1;
      fu_function_w = instr[14:12];
      alu_function_modifier_w = (instr[14:12] == 3'b101 && instr[30]);
      fu_select_a_w = ALU_SEL_REG;
      imm_data_w = i_type_imm_data;
      rd_address_w = rd_address;
      half_w = 1;
      if (
            (instr[14:12] == 3'b001 && instr[31:25] != 0)
            || (instr[14:12] == 3'b101 && (instr[31] != 0 || instr[29:25] != 0))
          ) begin
        ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
        exception_w = 1;
      end
    end
    7'b0110011: begin  // OP 64
      uses_rd_w = 1;
      fu_function_w = instr[14:12];
      fu_select_a_w = ALU_SEL_REG;
      fu_select_b_w = ALU_SEL_REG;
      rd_address_w = rd_address;
      if (instr[31:25] == 7'b0000001) begin  // RV64M
        is_alu_w = 0;
        is_mext_w = 1;
      end else begin  // RV32I
        alu_function_modifier_w = instr[30];
        if (instr[31:25] != 0 && (instr[31:25] != 7'b0100000 || (instr[14:12] != 0 && instr[14:12] != 3'b101))) begin
          ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
          exception_w = 1;
        end
      end
    end
    7'b0111011: begin  // OP 64 half_w
      uses_rd_w = 1;
      fu_function_w = instr[14:12];
      fu_select_a_w = ALU_SEL_REG;
      fu_select_b_w = ALU_SEL_REG;
      rd_address_w = rd_address;
      half_w = 1;
      if (instr[31:25] == 7'b0000001) begin  // RV64M
        is_alu_w = 0;
        is_mext_w = 1;
        if ( instr[14:12] == 3'b001 && instr[14:12] == 3'b010 && instr[14:12] == 3'b011 ) begin
          ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
          exception_w = 1;
        end
      end else begin  // RV64I
        alu_function_modifier_w = instr[30];
        if (
              (instr[31:25] == 0 && (instr[14:12] != 0 && instr[14:12] != 3'b001 && instr[14:12] != 3'b101)) ||
              (instr[31:25] != 0 && (instr[31:25] != 7'b0100000 || (instr[14:12] != 0 && instr[14:12] != 3'b101)))
            ) begin
          ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
          exception_w = 1;
        end
      end
    end
    7'b0101111: begin  // RV32A, RV64A
      uses_rd_w = 1;
      rd_address_w = rd_address;
      is_alu_w = 0;
      is_aext_w = 1;
      aq_w = instr[26];
      rl_w = instr[25];
      store_w = 1;
      case ({instr[31:27], instr[14:12]})
        8'b00010010: begin  // LR.W
          load_w = 0;
          store_w = 1;
          stu_op_w = STU_LRW;
          if (instr[24:20] != 0) begin
            ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
            exception_w = 1;
          end
        end
        8'b00011010: begin  // SC.W
          stu_op_w = STU_SCW;
        end
        8'b00001010: begin  // AMOSWAP.W
          stu_op_w = STU_AMOSWAPW;
        end
        8'b00000010: begin  // AMOADD.W
          stu_op_w = STU_AMOADDW;
        end
        8'b00100010: begin  // AMOXOR.W
          stu_op_w = STU_AMOXORW;
        end
        8'b01100010: begin  // AMOAND.W
          stu_op_w = STU_AMOANDW;
        end
        8'b01000010: begin  // AMOOR.W
          stu_op_w = STU_AMOORW;
        end
        8'b10000010: begin  // AMOMIN.W
          stu_op_w = STU_AMOMINW;
        end
        8'b10100010: begin  // AMOMAX.W
          stu_op_w = STU_AMOMAXW;
        end
        8'b11000010: begin  // AMOMINU.W
          stu_op_w = STU_AMOMINUW;
        end
        8'b11100010: begin  // AMOMAXU.W
          stu_op_w = STU_AMOMAXUW;
        end
        8'b00010011: begin  // LR.D
          load_w = 0;
          store_w = 1;
          stu_op_w = STU_LRD;
          if (instr[24:20] != 0) begin
            ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
            exception_w = 1;
          end
        end
        8'b00011011: begin  // SC.D
          stu_op_w = STU_SCD;
        end
        8'b00001011: begin  // AMOSWAP.D
          stu_op_w = STU_AMOSWAPD;
        end
        8'b00000011: begin  // AMOADD.D
          stu_op_w = STU_AMOADDD;
        end
        8'b00100011: begin  // AMOXOR.D
          stu_op_w = STU_AMOXORD;
        end
        8'b01100011: begin  // AMOAND.D
          stu_op_w = STU_AMOANDD;
        end
        8'b01000011: begin  // AMOOR.D
          stu_op_w = STU_AMOORD;
        end
        8'b10000011: begin  // AMOMIN.D
          stu_op_w = STU_AMOMIND;
        end
        8'b10100011: begin  // AMOMAX.D
          stu_op_w = STU_AMOMAXD;
        end
        8'b11000011: begin  // AMOMINU.D
          stu_op_w = STU_AMOMINUD;
        end
        8'b11100011: begin  // AMOMAXU.D
          stu_op_w = STU_AMOMAXUD;
        end
        default: begin
          ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
          exception_w = 1;
        end
      endcase
    end
    7'b0001111: begin  // FENCE, FENCE.I
      is_alu_w = 0;
      is_fence_w = 1;
      store_w = 1;
      case (instr[14:12])
        3'b000: begin  // FENCE
          stu_op_w = STU_FENCE;
          fence_op_w = DEC_FENCE;
        end
        3'b001: begin  // FENCE.I
          stu_op_w = STU_FENCE_I;
          fence_op_w = DEC_FENCE_I;
        end
        default: begin
          ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
          exception_w = 1;
        end
      endcase
    end
    7'b1110011: begin  // SYSTEM
      if (instr[14:12] == 0) begin
        is_alu_w = 0;
        case (instr[31:25])
          7'b0000000: begin
            exception_w = 1;
            if (instr[24:20] == 0 && instr[19:15] == 0 && instr[11:7] == 0) begin  // ECALL
              case (privilege_mode_i)
                M_MODE: begin
                  ecause_w = EXCEPTION_ENV_CALL_M;
                end
                S_MODE: begin
                  ecause_w = EXCEPTION_ENV_CALL_S;
                end
                default: begin
                  ecause_w = EXCEPTION_ENV_CALL_U;
                end
              endcase
            end else if (instr[24:20] == 5'b00001 && instr[19:15] == 0 && instr[11:7] == 0) begin  // EBREAK
              ecause_w = EXCEPTION_BREAKPOINT;
            end else begin
              ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
            end
          end
          7'b0001000: begin
            if (instr[24:20] == 5'b00010 && instr[19:15] == 0 && instr[11:7] == 0) begin  // SRET
              sret_w = 1;
              if (tsr_i) begin
                ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
                exception_w = 1;
              end
            end else if (instr[24:20] == 5'b00101 && instr[19:15] == 0 && instr[11:7] == 0) begin  // WFI
              wfi_w = 1;
              if (tw_i) begin // TODO & FIXME: read textbook
                ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
                exception_w = 1;
              end
            end else begin
              ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
              exception_w = 1;
            end
          end
          7'b0001001: begin  // SFENCE.VMA
            is_fence_w = 1;
            store_w = 1;
            stu_op_w = STU_SFENCE_VMA;
            fence_op_w = DEC_SFENCE_VMA;
            if (instr[11:7] != 0 | privilege_mode_i == 2'b00) begin
              ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
              exception_w = 1;
            end
            if (tvm_i) begin
                ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
                exception_w = 1;
            end
          end
          7'b0011000: begin
            if (instr[24:20] == 5'b00010 && instr[19:15] == 0 && instr[11:7] == 0) begin  // MRET
              mret_w = 1;
            end else begin
              ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
              exception_w = 1;
            end
          end
          default: begin
            ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
            exception_w = 1;
          end
        endcase
      end else begin
        if (csr_address_w[9:8] > privilege_mode_i) begin
            ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
            exception_w = 1;
        end else if ((csr_address_w == 12'h180) & tvm_i) begin
            ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
            exception_w = 1;
        end
        case (instr[14:12])
          3'b001: begin  // CSRRW
            uses_rd_w = 1;
            rd_address_w = rd_address;
            fu_function_w = instr[14:12];
            fu_select_a_w = ALU_SEL_REG;
            csr_read_w = (rd_address != 0);
            csr_write_w = 1;
            if (csr_address_w[11:10] == 2'b11) begin
              ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
              exception_w = 1;
            end
          end
          3'b010: begin  // CSRRS
            uses_rd_w = 1;
            rd_address_w = rd_address;
            fu_function_w = instr[14:12];
            fu_select_a_w = ALU_SEL_REG;
            fu_select_b_w = ALU_SEL_CSR;
            csr_read_w = 1;
            csr_write_w = (rs1_address != 0);
            if ((csr_address_w[11:10] == 2'b11) && (rs1_address != 0)) begin
              ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
              exception_w = 1;
            end
          end
          3'b011: begin  // CSRRC
            uses_rd_w = 1;
            rd_address_w = rd_address;
            fu_function_w = instr[14:12];
            fu_select_a_w = ALU_SEL_REG;
            fu_select_b_w = ALU_SEL_CSR;
            csr_read_w = 1;
            csr_write_w = (rs1_address != 0);
            if ((csr_address_w[11:10] == 2'b11) && (rs1_address != 0)) begin
              ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
              exception_w = 1;
            end
          end
          3'b101: begin  // CSRRWI
            uses_rd_w = 1;
            rd_address_w = rd_address;
            fu_function_w = instr[14:12];
            imm_data_w = csr_type_imm_data;
            csr_read_w = (rd_address != 0);
            csr_write_w = 1;
            if (csr_address_w[11:10] == 2'b11) begin
              ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
              exception_w = 1;
            end
          end
          3'b110: begin  // CSRRSI
            uses_rd_w = 1;
            rd_address_w = rd_address;
            fu_function_w = instr[14:12];
            fu_select_b_w = ALU_SEL_CSR;
            imm_data_w = csr_type_imm_data;
            csr_read_w = 1;
            csr_write_w = (rs1_address != 0);
            if ((csr_address_w[11:10] == 2'b11) && (rs1_address != 0)) begin
              ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
              exception_w = 1;
            end
          end
          3'b111: begin  // CSRRCI
            uses_rd_w = 1;
            rd_address_w = rd_address;
            fu_function_w = instr[14:12];
            fu_select_b_w = ALU_SEL_CSR;
            imm_data_w = csr_type_imm_data;
            csr_read_w = 1;
            csr_write_w = (rs1_address != 0);
            if ((csr_address_w[11:10] == 2'b11) && (rs1_address != 0)) begin
              ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
              exception_w = 1;
            end
          end
          default: begin
            is_alu_w = 0;
            ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
            exception_w = 1;
          end
        endcase        
      end
    end
    default: begin
      is_alu_w = 0;
      ecause_w = EXCEPTION_ILLEGAL_INSTRUCTION;
      exception_w = 1;
    end
  endcase
end

always @(*) begin
    pc_o = pc_w;
    next_pc_o = next_pc_w;
    predicted_pc_o = predicted_pc_w;
    imm_data_o = imm_data_w;
    csr_address_o = csr_address_w;
    fu_function_o = fu_function_w;
    alu_function_modifier_o = alu_function_modifier_w;
    fu_select_a_o = fu_select_a_w;
    fu_select_b_o = fu_select_b_w;
    jump_o = jump_w;
    branch_o = branch_w;
    is_alu_o = is_alu_w;
    load_o = load_w;
    store_o = store_w;
    ldu_op_o = ldu_op_w;
    stu_op_o = stu_op_w;
    uses_rd_o = uses_rd_w;
    rd_address_o = rd_address_w;
    csr_read_o = csr_read_w;
    csr_write_o = csr_write_w;
    mret_o = mret_w;
    sret_o = sret_w;
    wfi_o = wfi_w;
    ecause_o = ecause_w;
    exception_o = exception_w;
    half_o = half_w;
    is_fence_o = is_fence_w;
    fence_op_o = fence_op_w;
    is_aext_o = is_aext_w;
    is_mext_o = is_mext_w;
    aq_o = aq_w;
    rl_o = rl_w;
end

endmodule

`endif  // RV_DECODER_V