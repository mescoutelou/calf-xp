/*
 * File: calf_core_decoder.sv                                                  *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 11:46:51 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-05 08:57:05 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Instruction decoder: selects the execution unit (seq_o), the   *
 * control fields (ctrl_o) and the operand sources (GPR or immediate).         *
 */


module calf_core_decoder
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_riscv_pkg::*;
  import calf_priv_pkg::*;
  import calf_core_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter calf_core_cfg_t CALF_CORE_CFG = CALF_CORE_CFG_DEFAULT,
    parameter type            ctrl_t = ctrl_def_t
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic [CALF_CORE_CFG.INST_BIT_N - 1:0]  inst_i,

    output seq_e                                  seq_o,

    output ctrl_t                                 ctrl_o,
    
    output logic [CALF_CORE_CFG.GPR_N_BIT - 1:0]  gpr_rs1_o,
    output logic [CALF_CORE_CFG.GPR_N_BIT - 1:0]  gpr_rs2_o,
    output logic                                  s1_gpr_o,
    output logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] s1_data_o,
    output logic                                  s2_gpr_o,
    output logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] s2_data_o,
    output logic                                  s3_gpr_o,
    output logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] s3_data_o
  );

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic [6:0] opcode_w;
  logic [2:0] func3_w;
  logic [6:0] func7_w;
  logic [CALF_CORE_CFG.GPR_N_BIT - 1:0] gpr_rs1_w;
  logic [CALF_CORE_CFG.GPR_N_BIT - 1:0] gpr_rs2_w;
  logic [CALF_CORE_CFG.GPR_N_BIT - 1:0] gpr_rd_w;

// *****************************************************************************
// * FIXED PART
// *****************************************************************************
  always_comb begin
    opcode_w = inst_i[6:0];
    func3_w = inst_i[14:12];
    func7_w = inst_i[31:25];
    
    gpr_rs1_w = inst_i[19:15];
    gpr_rs2_w = inst_i[24:20];
    gpr_rd_w = inst_i[11:7];
  end

  always_comb begin
    gpr_rs1_o = gpr_rs1_w;
    gpr_rs2_o = gpr_rs2_w;
    ctrl_o.gpr_addr = gpr_rd_w;
  end

// *****************************************************************************
// * DECODING
// *****************************************************************************
  always_comb begin
// -----------------------------------------------------------------------------
// - DEFAULT
// -----------------------------------------------------------------------------
    seq_o = SEQ_NO_SEQ;

    ctrl_o.pc_rel = 1'b0;
    ctrl_o.alu_sign = 1'b0;
    ctrl_o.alu_uop = ALU_NO_UOP;
    ctrl_o.bru_sign = 1'b0;
    ctrl_o.bru_uop = BRU_NO_UOP;
    ctrl_o.lsu_rw = RW_NO;
    ctrl_o.lsu_size = LSU_8;
    ctrl_o.lsu_sign = 1'b0;
    ctrl_o.csr_rw = RW_NO;
    ctrl_o.csr_uop = CSR_NO_UOP;
    ctrl_o.gpr_wb = 1'b0;

    s1_gpr_o = 1'b0;
    s1_data_o = 'h0;
    s2_gpr_o = 1'b0;
    s2_data_o = 'h0;
    s3_gpr_o = 1'b0;
    s3_data_o = 'h0;

// -----------------------------------------------------------------------------
// - LUI / AUIPC
// -----------------------------------------------------------------------------
   case (opcode_w)
      OPCODE_LUI: begin
        seq_o = SEQ_ALU;

        ctrl_o.pc_rel = 1'b0;
        ctrl_o.alu_sign = 1'b0;
        ctrl_o.alu_uop = ALU_ADD;
        ctrl_o.gpr_wb = 1'b1;

        s1_gpr_o = 1'b0;
        s1_data_o = 'h0;
        s2_gpr_o = 1'b0;
        s2_data_o = {inst_i[31:12], 12'h0};
        s3_gpr_o = 1'b0;
        s3_data_o = 'h0;
      end

      OPCODE_AUIPC: begin
        seq_o = SEQ_ALU;

        ctrl_o.pc_rel = 1'b1;
        ctrl_o.alu_sign = 1'b0;
        ctrl_o.alu_uop = ALU_ADD;
        ctrl_o.gpr_wb = 1'b1;

        s1_gpr_o = 1'b0;
        s1_data_o = 'h0;
        s2_gpr_o = 1'b0;
        s2_data_o = 'h0;
        s3_gpr_o = 1'b0;
        s3_data_o = {inst_i[31:12], 12'h0};
      end


// -----------------------------------------------------------------------------
// - JAL / JALR / BRANCH
// -----------------------------------------------------------------------------
      OPCODE_JAL: begin
        seq_o = SEQ_BRU;

        ctrl_o.pc_rel = 1'b1;
        ctrl_o.alu_sign = 1'b0;
        ctrl_o.alu_uop = ALU_ADD;
        ctrl_o.bru_sign = 1'b0;
        ctrl_o.bru_uop = BRU_JAL;
        ctrl_o.gpr_wb = 1'b1;

        s1_gpr_o = 1'b0;
        s1_data_o = 'h0;
        s2_gpr_o = 1'b0;
        s2_data_o = 'h0;
        s3_gpr_o = 1'b0;
        s3_data_o = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
      end

      OPCODE_JALR: begin
        seq_o = SEQ_BRU;

        ctrl_o.alu_sign = 1'b0;
        ctrl_o.alu_uop = ALU_ADD;
        ctrl_o.bru_sign = 1'b0;
        ctrl_o.bru_uop = BRU_JAL;
        ctrl_o.gpr_wb = 1'b1;

        s1_gpr_o = 1'b1;
        s1_data_o = 'h0;
        s2_gpr_o = 1'b0;
        s2_data_o = {{20{inst_i[31]}}, inst_i[31:20]};
        s3_gpr_o = 1'b0;
        s3_data_o = 'h0;
      end

      OPCODE_BRANCH: begin
        ctrl_o.pc_rel = 1'b1;
        ctrl_o.alu_sign = 1'b0;
        ctrl_o.alu_uop = ALU_ADD;

        case (func3_w)
          FUNC3_BEQ: begin
            seq_o = SEQ_BRU;
            ctrl_o.bru_sign = 1'b0;
            ctrl_o.bru_uop = BRU_BEQ;
          end
          FUNC3_BNE: begin
            seq_o = SEQ_BRU;
            ctrl_o.bru_sign = 1'b0;
            ctrl_o.bru_uop = BRU_BNE;
          end
          FUNC3_BLT: begin
            seq_o = SEQ_BRU;
            ctrl_o.bru_sign = 1'b1;
            ctrl_o.bru_uop = BRU_BLT;
          end
          FUNC3_BGE: begin
            seq_o = SEQ_BRU;
            ctrl_o.bru_sign = 1'b1;
            ctrl_o.bru_uop = BRU_BGE;
          end
          FUNC3_BLTU: begin
            seq_o = SEQ_BRU;
            ctrl_o.bru_sign = 1'b0;
            ctrl_o.bru_uop = BRU_BLT;
          end
          FUNC3_BGEU: begin
            seq_o = SEQ_BRU;
            ctrl_o.bru_sign = 1'b0;
            ctrl_o.bru_uop = BRU_BGE;
          end
          default: begin
            seq_o = SEQ_NO_SEQ;
            ctrl_o.bru_sign = 1'b0;
            ctrl_o.bru_uop = BRU_NO_UOP;
          end
        endcase

        s1_gpr_o = 1'b1;
        s1_data_o = 'h0;
        s2_gpr_o = 1'b1;
        s2_data_o = 'h0;
        s3_gpr_o = 1'b0;
        s3_data_o = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
      end

// -----------------------------------------------------------------------------
// - LOAD / STORE
// -----------------------------------------------------------------------------
      OPCODE_LOAD: begin
        ctrl_o.alu_sign = 1'b0;
        ctrl_o.alu_uop = ALU_ADD;
        ctrl_o.lsu_rw = RW_R;

        case (func3_w)
          FUNC3_LB: begin
            seq_o = SEQ_LSU;
            ctrl_o.lsu_size = LSU_8;
            ctrl_o.lsu_sign = 1'b1;
            ctrl_o.gpr_wb = 1'b1;
          end
          FUNC3_LH: begin
            seq_o = SEQ_LSU;
            ctrl_o.lsu_size = LSU_16;
            ctrl_o.lsu_sign = 1'b1;
            ctrl_o.gpr_wb = 1'b1;
          end
          FUNC3_LW: begin
            seq_o = SEQ_LSU;
            ctrl_o.lsu_size = LSU_32;
            ctrl_o.lsu_sign = 1'b1;
            ctrl_o.gpr_wb = 1'b1;
          end
          FUNC3_LBU: begin
            seq_o = SEQ_LSU;
            ctrl_o.lsu_size = LSU_8;
            ctrl_o.lsu_sign = 1'b0;
            ctrl_o.gpr_wb = 1'b1;
          end
          FUNC3_LHU: begin
            seq_o = SEQ_LSU;
            ctrl_o.lsu_size = LSU_16;
            ctrl_o.lsu_sign = 1'b0;
            ctrl_o.gpr_wb = 1'b1;
          end
          default: begin
            seq_o = SEQ_NO_SEQ;
            ctrl_o.lsu_size = LSU_8;
            ctrl_o.lsu_sign = 1'b0;
            ctrl_o.gpr_wb = 1'b0;
          end
        endcase

        s1_gpr_o = 1'b1;
        s1_data_o = 'h0;
        s2_gpr_o = 1'b0;
        s2_data_o = {{20{inst_i[31]}}, inst_i[31:20]};
        s3_gpr_o = 1'b0;
        s3_data_o = 'h0;
      end

      OPCODE_STORE: begin
        ctrl_o.alu_sign = 1'b0;
        ctrl_o.alu_uop = ALU_ADD;
        ctrl_o.lsu_rw = RW_W;
        ctrl_o.gpr_wb = 1'b0;

        case (func3_w)
          FUNC3_SB: begin
            seq_o = SEQ_LSU;
            ctrl_o.lsu_size = LSU_8;
            ctrl_o.lsu_sign = 1'b0;
          end
          FUNC3_SH: begin
            seq_o = SEQ_LSU;
            ctrl_o.lsu_size = LSU_16;
            ctrl_o.lsu_sign = 1'b0;
          end
          FUNC3_SW: begin
            seq_o = SEQ_LSU;
            ctrl_o.lsu_size = LSU_32;
            ctrl_o.lsu_sign = 1'b0;
          end
          default: begin
            seq_o = SEQ_NO_SEQ;
            ctrl_o.lsu_size = LSU_8;
            ctrl_o.lsu_sign = 1'b0;
          end
        endcase

        s1_gpr_o = 1'b1;
        s1_data_o = 'h0;
        s2_gpr_o = 1'b0;
        s2_data_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
        s3_gpr_o = 1'b1;
        s3_data_o = 'h0;
      end

// -----------------------------------------------------------------------------
// - OP_IMM
// -----------------------------------------------------------------------------
      OPCODE_OP_IMM: begin
        case (func3_w)
          {FUNC3_ADD}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_ADD;
            ctrl_o.gpr_wb = 1'b1;
          end
          {FUNC3_SLL}: begin
            case (func7_w)
              FUNC7_SLL: begin
                seq_o = SEQ_ALU;
                ctrl_o.alu_sign = 1'b0;
                ctrl_o.alu_uop = ALU_SL;
                ctrl_o.gpr_wb = 1'b1;
              end
              default: begin
                seq_o = SEQ_NO_SEQ;
                ctrl_o.alu_sign = 1'b0;
                ctrl_o.alu_uop = ALU_NO_UOP;
                ctrl_o.gpr_wb = 1'b0;
              end
            endcase
          end
          {FUNC3_SLT}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b1;
            ctrl_o.alu_uop = ALU_SLT;
            ctrl_o.gpr_wb = 1'b1;
          end
          {FUNC3_SLTU}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_SLT;
            ctrl_o.gpr_wb = 1'b1;
          end
          {FUNC3_SR}: begin
            case (func7_w)
              FUNC7_SRL: begin
                seq_o = SEQ_ALU;
                ctrl_o.alu_sign = 1'b0;
                ctrl_o.alu_uop = ALU_SR;
                ctrl_o.gpr_wb = 1'b1;
              end
              FUNC7_SRA: begin
                seq_o = SEQ_ALU;
                ctrl_o.alu_sign = 1'b1;
                ctrl_o.alu_uop = ALU_SR;
                ctrl_o.gpr_wb = 1'b1;
              end
              default: begin
                seq_o = SEQ_NO_SEQ;
                ctrl_o.alu_sign = 1'b0;
                ctrl_o.alu_uop = ALU_NO_UOP;
                ctrl_o.gpr_wb = 1'b0;
              end
            endcase
          end
          {FUNC3_XOR}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_XOR;
            ctrl_o.gpr_wb = 1'b1;
          end
          {FUNC3_OR}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_OR;
            ctrl_o.gpr_wb = 1'b1;
          end
          {FUNC3_AND}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_AND;
            ctrl_o.gpr_wb = 1'b1;
          end
        endcase

        if (CALF_CORE_CFG.EXT_ZBS_USE) begin
          case ({func7_w, func3_w})
            {FUNC7_BCLR, FUNC3_BCLR}: begin
              seq_o = SEQ_ALU;
              ctrl_o.alu_sign = 1'b0;
              ctrl_o.alu_uop = ALU_BCLR;
              ctrl_o.gpr_wb = 1'b1;
            end
            {FUNC7_BEXT, FUNC3_BEXT}: begin
              seq_o = SEQ_ALU;
              ctrl_o.alu_sign = 1'b0;
              ctrl_o.alu_uop = ALU_BEXT;
              ctrl_o.gpr_wb = 1'b1;
            end
            {FUNC7_BINV, FUNC3_BINV}: begin
              seq_o = SEQ_ALU;
              ctrl_o.alu_sign = 1'b0;
              ctrl_o.alu_uop = ALU_BINV;
              ctrl_o.gpr_wb = 1'b1;
            end
            {FUNC7_BSET, FUNC3_BSET}: begin
              seq_o = SEQ_ALU;
              ctrl_o.alu_sign = 1'b0;
              ctrl_o.alu_uop = ALU_BSET;
              ctrl_o.gpr_wb = 1'b1;
            end
          endcase
        end

        s1_gpr_o = 1'b1;
        s1_data_o = 'h0;
        s2_gpr_o = 1'b0;
        s2_data_o = {{20{inst_i[31]}}, inst_i[31:20]};
        s3_gpr_o = 1'b0;
        s3_data_o = 'h0;
      end

// -----------------------------------------------------------------------------
// - OP
// -----------------------------------------------------------------------------
      OPCODE_OP: begin
        case ({func7_w, func3_w})
          {FUNC7_ADD, FUNC3_ADD}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_ADD;
            ctrl_o.gpr_wb = 1'b1;
          end
          {FUNC7_SUB, FUNC3_ADD}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_SUB;
            ctrl_o.gpr_wb = 1'b1;
          end
          {7'h00, FUNC3_SLL}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_SL;
            ctrl_o.gpr_wb = 1'b1;
          end
          {7'h00, FUNC3_SLT}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b1;
            ctrl_o.alu_uop = ALU_SLT;
            ctrl_o.gpr_wb = 1'b1;
          end
          {7'h00, FUNC3_SLTU}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_SLT;
            ctrl_o.gpr_wb = 1'b1;
          end
          {FUNC7_SRL, FUNC3_SR}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_SR;
            ctrl_o.gpr_wb = 1'b1;
          end
          {FUNC7_SRA, FUNC3_SR}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b1;
            ctrl_o.alu_uop = ALU_SR;
            ctrl_o.gpr_wb = 1'b1;
          end
          {7'h00, FUNC3_XOR}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_XOR;
            ctrl_o.gpr_wb = 1'b1;
          end
          {7'h00, FUNC3_OR}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_OR;
            ctrl_o.gpr_wb = 1'b1;
          end
          {7'h00, FUNC3_AND}: begin
            seq_o = SEQ_ALU;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_AND;
            ctrl_o.gpr_wb = 1'b1;
          end
          default: begin
            seq_o = SEQ_NO_SEQ;
            ctrl_o.alu_sign = 1'b0;
            ctrl_o.alu_uop = ALU_NO_UOP;
            ctrl_o.gpr_wb = 1'b0;
          end
        endcase

        if (CALF_CORE_CFG.EXT_ZBS_USE) begin
          case ({func7_w, func3_w})
            {FUNC7_BCLR, FUNC3_BCLR}: begin
              seq_o = SEQ_ALU;
              ctrl_o.alu_sign = 1'b0;
              ctrl_o.alu_uop = ALU_BCLR;
              ctrl_o.gpr_wb = 1'b1;
            end
            {FUNC7_BEXT, FUNC3_BEXT}: begin
              seq_o = SEQ_ALU;
              ctrl_o.alu_sign = 1'b0;
              ctrl_o.alu_uop = ALU_BEXT;
              ctrl_o.gpr_wb = 1'b1;
            end
            {FUNC7_BINV, FUNC3_BINV}: begin
              seq_o = SEQ_ALU;
              ctrl_o.alu_sign = 1'b0;
              ctrl_o.alu_uop = ALU_BINV;
              ctrl_o.gpr_wb = 1'b1;
            end
            {FUNC7_BSET, FUNC3_BSET}: begin
              seq_o = SEQ_ALU;
              ctrl_o.alu_sign = 1'b0;
              ctrl_o.alu_uop = ALU_BSET;
              ctrl_o.gpr_wb = 1'b1;
            end
          endcase
        end

        s1_gpr_o = 1'b1;
        s1_data_o = 'h0;
        s2_gpr_o = 1'b1;
        s2_data_o = 'h0;
        s3_gpr_o = 1'b0;
        s3_data_o = 'h0;
      end

// -----------------------------------------------------------------------------
// - SYSTEM
// -----------------------------------------------------------------------------
      OPCODE_SYSTEM: begin
        if (CALF_CORE_CFG.EXT_ZICSR_USE) begin
          case (func3_w)
            FUNC3_CSRRW: begin
              seq_o = SEQ_CSR;
              ctrl_o.csr_rw = (gpr_rd_w != 0) ? RW_RW : RW_W;
              ctrl_o.csr_uop = CSR_W;
              ctrl_o.gpr_wb = (gpr_rd_w != 0);
              s1_gpr_o = 1'b1;
              s1_data_o = 'h0;
            end
            FUNC3_CSRRS: begin
              seq_o = SEQ_CSR;
              ctrl_o.csr_rw = (inst_i[19:15] != 0) ? RW_RW : RW_R;
              ctrl_o.csr_uop = CSR_S;
              ctrl_o.gpr_wb = 1'b1;
              s1_gpr_o = 1'b1;
              s1_data_o = 'h0;
            end
            FUNC3_CSRRC: begin
              seq_o = SEQ_CSR;
              ctrl_o.csr_rw = (inst_i[19:15] != 0) ? RW_RW : RW_R;
              ctrl_o.csr_uop = CSR_C;
              ctrl_o.gpr_wb = 1'b1;
              s1_gpr_o = 1'b1;
              s1_data_o = 'h0;
            end
            FUNC3_CSRRWI: begin
              seq_o = SEQ_CSR;
              ctrl_o.csr_rw = (gpr_rd_w != 0) ? RW_RW : RW_W;
              ctrl_o.csr_uop = CSR_W;
              ctrl_o.gpr_wb = (gpr_rd_w != 0);
              s1_gpr_o = 1'b0;
              s1_data_o = {{27{1'b0}}, inst_i[19:15]};
            end
            FUNC3_CSRRSI: begin
              seq_o = SEQ_CSR;
              ctrl_o.csr_rw = (inst_i[19:15] != 0) ? RW_RW : RW_R;
              ctrl_o.csr_uop = CSR_S;
              ctrl_o.gpr_wb = 1'b1;
              s1_gpr_o = 1'b0;
              s1_data_o = {{27{1'b0}}, inst_i[19:15]};
            end
            FUNC3_CSRRCI: begin
              seq_o = SEQ_CSR;
              ctrl_o.csr_rw = (inst_i[19:15] != 0) ? RW_RW : RW_R;
              ctrl_o.csr_uop = CSR_C;
              ctrl_o.gpr_wb = 1'b1;
              s1_gpr_o = 1'b0;
              s1_data_o = {{27{1'b0}}, inst_i[19:15]};
            end
            default: begin
              seq_o = SEQ_NO_SEQ;
              ctrl_o.csr_rw = RW_NO;
              ctrl_o.csr_uop = CSR_NO_UOP;
              ctrl_o.gpr_wb = 1'b0;
              s1_gpr_o = 1'b0;
              s1_data_o = 'h0;
            end
          endcase

          s2_gpr_o = 1'b0;
          s2_data_o = 'h0;
          s3_gpr_o = 1'b0;
          s3_data_o = {{20{1'b0}}, inst_i[31:20]};
        end
      end

// -----------------------------------------------------------------------------
// - MISC_MEM
// -----------------------------------------------------------------------------
      OPCODE_MISC_MEM: begin
        seq_o = SEQ_NO_SEQ;

        s1_gpr_o = 1'b0;
        s1_data_o = 'h0;
        s2_gpr_o = 1'b0;
        s2_data_o = 'h0;
        s3_gpr_o = 1'b0;
        s3_data_o = 'h0;
      end

// -----------------------------------------------------------------------------
// - OTHERS
// -----------------------------------------------------------------------------
      default: begin
        seq_o = SEQ_NO_SEQ;

        ctrl_o.pc_rel = 1'b0;
        ctrl_o.alu_sign = 1'b0;
        ctrl_o.alu_uop = ALU_NO_UOP;
        ctrl_o.bru_sign = 1'b0;
        ctrl_o.bru_uop = BRU_NO_UOP;
        ctrl_o.lsu_rw = RW_NO;
        ctrl_o.lsu_size = LSU_8;
        ctrl_o.lsu_sign = 1'b0;
        ctrl_o.csr_rw = RW_NO;
        ctrl_o.csr_uop = CSR_NO_UOP;
        ctrl_o.gpr_wb = 1'b0;

        s1_gpr_o = 1'b0;
        s1_data_o = 'h0;
        s2_gpr_o = 1'b0;
        s2_data_o = 'h0;
        s3_gpr_o = 1'b0;
        s3_data_o = 'h0;
      end
    endcase
  end
endmodule
