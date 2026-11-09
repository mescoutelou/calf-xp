/*
 * File: calf_riscv_pkg.sv                                                     *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 12:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-06 01:41:08 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: RISC-V ISA constants: opcodes, funct3/funct7 fields,           *
 * instruction patterns, and immediate decoding (riscv_imm_f).                 *
 */


package calf_riscv_pkg;
// *****************************************************************************
// * OPCODE
// *****************************************************************************
  localparam logic [6:0] OPCODE_LUI         = 7'b0110111;
  localparam logic [6:0] OPCODE_AUIPC       = 7'b0010111;
  localparam logic [6:0] OPCODE_JAL         = 7'b1101111;
  localparam logic [6:0] OPCODE_JALR        = 7'b1100111;
  localparam logic [6:0] OPCODE_BRANCH      = 7'b1100011;
  localparam logic [6:0] OPCODE_LOAD        = 7'b0000011;
  localparam logic [6:0] OPCODE_STORE       = 7'b0100011;
  localparam logic [6:0] OPCODE_OP_IMM      = 7'b0010011;
  localparam logic [6:0] OPCODE_OP          = 7'b0110011;
  localparam logic [6:0] OPCODE_MISC_MEM    = 7'b0001111;
  localparam logic [6:0] OPCODE_SYSTEM      = 7'b1110011;

// *****************************************************************************
// * FUNC3
// *****************************************************************************
  localparam logic [2:0] FUNC3_JALR         = 3'b000;

  localparam logic [2:0] FUNC3_BEQ          = 3'b000;
  localparam logic [2:0] FUNC3_BNE          = 3'b001;
  localparam logic [2:0] FUNC3_BLT          = 3'b100;
  localparam logic [2:0] FUNC3_BGE          = 3'b101;
  localparam logic [2:0] FUNC3_BLTU         = 3'b110;
  localparam logic [2:0] FUNC3_BGEU         = 3'b111;

  localparam logic [2:0] FUNC3_LB           = 3'b000;
  localparam logic [2:0] FUNC3_LH           = 3'b001;
  localparam logic [2:0] FUNC3_LW           = 3'b010;
  localparam logic [2:0] FUNC3_LBU          = 3'b100;
  localparam logic [2:0] FUNC3_LHU          = 3'b101;

  localparam logic [2:0] FUNC3_SB           = 3'b000;
  localparam logic [2:0] FUNC3_SH           = 3'b001;
  localparam logic [2:0] FUNC3_SW           = 3'b010;

  localparam logic [2:0] FUNC3_ADD          = 3'b000;
  localparam logic [2:0] FUNC3_SLL          = 3'b001;
  localparam logic [2:0] FUNC3_SLT          = 3'b010;
  localparam logic [2:0] FUNC3_SLTU         = 3'b011;
  localparam logic [2:0] FUNC3_XOR          = 3'b100;
  localparam logic [2:0] FUNC3_SR           = 3'b101;
  localparam logic [2:0] FUNC3_OR           = 3'b110;
  localparam logic [2:0] FUNC3_AND          = 3'b111;

  localparam logic [2:0] FUNC3_CSRRW        = 3'b001;
  localparam logic [2:0] FUNC3_CSRRS        = 3'b010;
  localparam logic [2:0] FUNC3_CSRRC        = 3'b011;
  localparam logic [2:0] FUNC3_CSRRWI       = 3'b101;
  localparam logic [2:0] FUNC3_CSRRSI       = 3'b110;
  localparam logic [2:0] FUNC3_CSRRCI       = 3'b111;

  localparam logic [2:0] FUNC3_BCLR         = 3'b001;
  localparam logic [2:0] FUNC3_BEXT         = 3'b101;
  localparam logic [2:0] FUNC3_BINV         = 3'b001;
  localparam logic [2:0] FUNC3_BSET         = 3'b001;

// *****************************************************************************
// * FUNC7
// *****************************************************************************
  localparam logic [6:0] FUNC7_ADD          = 7'b0000000;
  localparam logic [6:0] FUNC7_SUB          = 7'b0100000;
  localparam logic [6:0] FUNC7_SLL          = 7'b0000000;
  localparam logic [6:0] FUNC7_SRL          = 7'b0000000;
  localparam logic [6:0] FUNC7_SRA          = 7'b0100000;

  localparam logic [6:0] FUNC7_BCLR         = 7'b0100100;
  localparam logic [6:0] FUNC7_BEXT         = 7'b0100100;
  localparam logic [6:0] FUNC7_BINV         = 7'b0110100;
  localparam logic [6:0] FUNC7_BSET         = 7'b0010100;

// *****************************************************************************
// * INSTRUCTION
// *****************************************************************************
// -----------------------------------------------------------------------------
// - RV32I
// -----------------------------------------------------------------------------
  localparam logic [31:0] RISCV_LUI         = 32'b???????_?????_?????_???_?????_0110111;
  localparam logic [31:0] RISCV_AUIPC       = 32'b???????_?????_?????_???_?????_0010111;
  localparam logic [31:0] RISCV_JAL         = 32'b???????_?????_?????_???_?????_1101111;
  localparam logic [31:0] RISCV_JALR        = 32'b???????_?????_?????_000_?????_1100111;
  localparam logic [31:0] RISCV_BEQ         = 32'b???????_?????_?????_000_?????_1100011;
  localparam logic [31:0] RISCV_BNE         = 32'b???????_?????_?????_001_?????_1100011;
  localparam logic [31:0] RISCV_BLT         = 32'b???????_?????_?????_100_?????_1100011;
  localparam logic [31:0] RISCV_BGE         = 32'b???????_?????_?????_101_?????_1100011;
  localparam logic [31:0] RISCV_BLTU        = 32'b???????_?????_?????_110_?????_1100011;
  localparam logic [31:0] RISCV_BGEU        = 32'b???????_?????_?????_111_?????_1100011;
  localparam logic [31:0] RISCV_LB          = 32'b???????_?????_?????_000_?????_0000011;
  localparam logic [31:0] RISCV_LH          = 32'b???????_?????_?????_001_?????_0000011;
  localparam logic [31:0] RISCV_LW          = 32'b???????_?????_?????_010_?????_0000011;
  localparam logic [31:0] RISCV_LBU         = 32'b???????_?????_?????_100_?????_0000011;
  localparam logic [31:0] RISCV_LHU         = 32'b???????_?????_?????_101_?????_0000011;
  localparam logic [31:0] RISCV_SB          = 32'b???????_?????_?????_000_?????_0100011;
  localparam logic [31:0] RISCV_SH          = 32'b???????_?????_?????_001_?????_0100011;
  localparam logic [31:0] RISCV_SW          = 32'b???????_?????_?????_010_?????_0100011;
  localparam logic [31:0] RISCV_ADDI        = 32'b???????_?????_?????_000_?????_0010011;
  localparam logic [31:0] RISCV_SLTI        = 32'b???????_?????_?????_010_?????_0010011;
  localparam logic [31:0] RISCV_SLTIU       = 32'b???????_?????_?????_011_?????_0010011;
  localparam logic [31:0] RISCV_XORI        = 32'b???????_?????_?????_100_?????_0010011;
  localparam logic [31:0] RISCV_ORI         = 32'b???????_?????_?????_110_?????_0010011;
  localparam logic [31:0] RISCV_ANDI        = 32'b???????_?????_?????_111_?????_0010011;
  localparam logic [31:0] RISCV_SLLI        = 32'b0000000_?????_?????_001_?????_0010011;
  localparam logic [31:0] RISCV_SRLI        = 32'b0000000_?????_?????_101_?????_0010011;
  localparam logic [31:0] RISCV_SRAI        = 32'b0100000_?????_?????_101_?????_0010011;
  localparam logic [31:0] RISCV_ADD         = 32'b0000000_?????_?????_000_?????_0110011;
  localparam logic [31:0] RISCV_SUB         = 32'b0100000_?????_?????_000_?????_0110011;
  localparam logic [31:0] RISCV_SLL         = 32'b0000000_?????_?????_001_?????_0110011;
  localparam logic [31:0] RISCV_SLT         = 32'b0000000_?????_?????_010_?????_0110011;
  localparam logic [31:0] RISCV_SLTU        = 32'b0000000_?????_?????_011_?????_0110011;
  localparam logic [31:0] RISCV_XOR         = 32'b0000000_?????_?????_100_?????_0110011;
  localparam logic [31:0] RISCV_SRL         = 32'b0000000_?????_?????_101_?????_0110011;
  localparam logic [31:0] RISCV_SRA         = 32'b0100000_?????_?????_101_?????_0110011;
  localparam logic [31:0] RISCV_OR          = 32'b0000000_?????_?????_110_?????_0110011;
  localparam logic [31:0] RISCV_AND         = 32'b0000000_?????_?????_111_?????_0110011;

  localparam logic [31:0] RISCV_FENCE       = 32'b???????_?????_?????_000_?????_0001111;
  localparam logic [31:0] RISCV_ECALL       = 32'b0000000_00000_00000_000_00000_1110011;
  localparam logic [31:0] RISCV_EBREAK      = 32'b0000000_00001_00000_000_00000_1110011;
  localparam logic [31:0] RISCV_NOP         = 32'b0000000_00000_00000_000_00000_0010011;
  localparam logic [31:0] RISCV_FENCE_TSO   = 32'b1000001_10011_00000_000_00000_0001111;
  localparam logic [31:0] RISCV_PAUSE       = 32'b0000000_10000_00000_000_00000_0001111;

// -----------------------------------------------------------------------------
// - ZICSR
// -----------------------------------------------------------------------------
  localparam logic [31:0] RISCV_CSRRW       = 32'b???????_?????_?????_001_?????_1110011;
  localparam logic [31:0] RISCV_CSRRW0      = 32'b???????_?????_?????_001_00000_1110011;
  localparam logic [31:0] RISCV_CSRRS       = 32'b???????_?????_?????_010_?????_1110011;
  localparam logic [31:0] RISCV_CSRRS0      = 32'b???????_?????_00000_010_?????_1110011;
  localparam logic [31:0] RISCV_CSRRC       = 32'b???????_?????_?????_011_?????_1110011;
  localparam logic [31:0] RISCV_CSRRC0      = 32'b???????_?????_00000_011_?????_1110011;
  localparam logic [31:0] RISCV_CSRRWI      = 32'b???????_?????_?????_101_?????_1110011;
  localparam logic [31:0] RISCV_CSRRWI0     = 32'b???????_?????_?????_101_00000_1110011;
  localparam logic [31:0] RISCV_CSRRSI      = 32'b???????_?????_?????_110_?????_1110011;
  localparam logic [31:0] RISCV_CSRRSI0     = 32'b???????_?????_00000_110_?????_1110011;
  localparam logic [31:0] RISCV_CSRRCI      = 32'b???????_?????_?????_111_?????_1110011;
  localparam logic [31:0] RISCV_CSRRCI0     = 32'b???????_?????_00000_111_?????_1110011;

// -----------------------------------------------------------------------------
// - ZBS
// -----------------------------------------------------------------------------
  localparam logic [31:0] RISCV_BCLR        = 32'b0100100_?????_?????_001_?????_0110011;
  localparam logic [31:0] RISCV_BCLRI       = 32'b0100100_?????_?????_001_?????_0010011;
  localparam logic [31:0] RISCV_BEXT        = 32'b0100100_?????_?????_101_?????_0110011;
  localparam logic [31:0] RISCV_BEXTI       = 32'b0100100_?????_?????_101_?????_0010011;
  localparam logic [31:0] RISCV_BINV        = 32'b0110100_?????_?????_001_?????_0110011;
  localparam logic [31:0] RISCV_BINVI       = 32'b0110100_?????_?????_001_?????_0010011;
  localparam logic [31:0] RISCV_BSET        = 32'b0010100_?????_?????_001_?????_0110011;
  localparam logic [31:0] RISCV_BSETI       = 32'b0010100_?????_?????_001_?????_0010011;

// *****************************************************************************
// * ENUMERATE
// *****************************************************************************
  typedef enum logic [2:0]{
    IMM_X,
    IMM_I,
    IMM_S,
    IMM_B,
    IMM_U,
    IMM_J,
    IMM_C,
    IMM_Z
  } imm_type_e;

// *****************************************************************************
// * FUNCTION
// *****************************************************************************
  // Decodes an immediate from an instruction, sign/zero-extended on 64 bits
  function automatic logic [63:0] riscv_imm_f(
    input logic [31:0] inst_i,
    input imm_type_e   type_i
  );
    logic [63:0] imm_w;
    logic [6:0] unused_opcode_w;

    unused_opcode_w = inst_i[6:0];

    case (type_i)
      IMM_I:   imm_w = {{52{inst_i[31]}}, inst_i[31:20]};
      IMM_S:   imm_w = {{52{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
      IMM_B:   imm_w = {{52{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
      IMM_U:   imm_w = {{32{inst_i[31]}}, inst_i[31:12], 12'b0};
      IMM_J:   imm_w = {{44{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
      IMM_C:   imm_w = {52'h0, inst_i[31:20]};
      IMM_Z:   imm_w = {59'h0, inst_i[19:15]};
      default: imm_w = {{52{inst_i[31]}}, inst_i[31:20]};
    endcase

    return imm_w;
  endfunction
endpackage
