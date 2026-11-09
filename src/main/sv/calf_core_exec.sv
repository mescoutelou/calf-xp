/*
 * File: calf_core_exec.sv                                                     *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 11:45:53 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-07 05:17:34 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: CALF execution unit (RV32I/E, Zicsr, Zicntr, Zbs),             *
 * multi-cycle, no pipeline. One memory bus for fetch and data: byte address,  *
 * lane-shifted wmask/wdata, full-word rdata. Requests on valid/ready, read    *
 * data on rready.                                                             *
 */


module calf_core_exec
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_core_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter calf_core_usr_t   CALF_CORE_USR = CALF_CORE_USR_DEFAULT,

    localparam calf_core_cfg_t  CALF_CORE_CFG = calf_core_cfg_f(CALF_CORE_USR)
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic                                     clk_i,
    input logic                                     rst_i,

    input logic                                     boot_i,

    input logic                                     mem_ready_i,
    output logic                                    mem_valid_o,
    output logic [CALF_CORE_CFG.ADDR_BIT_N - 1:0]   mem_addr_o,
    output logic [CALF_CORE_CFG.DATA_BYTE_N - 1:0]  mem_wmask_o,
    output logic [CALF_CORE_CFG.DATA_BIT_N - 1:0]   mem_wdata_o,
    input logic                                     mem_rready_i,
    input logic [CALF_CORE_CFG.DATA_BIT_N - 1:0]    mem_rdata_i
  );

// *****************************************************************************
// * STRUCTURE
// *****************************************************************************
  typedef struct packed {
    logic pc_rel;
    logic alu_sign;
    alu_uop_e alu_uop;
    logic bru_sign;
    bru_uop_e bru_uop;
    rw_e lsu_rw;
    lsu_size_e lsu_size;
    logic lsu_sign;
    rw_e csr_rw;
    csr_uop_e csr_uop;
    logic gpr_wb;
    logic [CALF_CORE_CFG.GPR_N_BIT - 1:0] gpr_addr;
  } ctrl_t;

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
logic [CALF_CORE_CFG.ADDR_BIT_N - 1:0] pc_r, pc_n;
logic [CALF_CORE_CFG.INST_BIT_N - 1:0] inst_r, inst_n;
ctrl_t ctrl_r, ctrl_n;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] s1_res_r, s1_res_n;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] s2_pc_r, s2_pc_n;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] s3_csr_r, s3_csr_n;
logic br_r, br_n;

logic [CALF_CORE_CFG.INST_BIT_N - 1:0] inst_w;
seq_e seq_w;
logic fsm_fetch_w;
logic fsm_inst_w;
logic fsm_decoder_w;
logic fsm_alu_w;
logic fsm_bru_w;
logic fsm_mem_req_w;
logic fsm_mem_ack_w;
logic fsm_csrr_w;
logic fsm_csrw_w;
logic fsm_wb_w;
ctrl_t decoder_ctrl_w;
logic [CALF_CORE_CFG.GPR_N_BIT - 1:0] decoder_rs1_w;
logic [CALF_CORE_CFG.GPR_N_BIT - 1:0] decoder_rs2_w;
logic decoder_s1_gpr_w;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] decoder_s1_data_w;
logic decoder_s2_gpr_w;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] decoder_s2_data_w;
logic decoder_s3_gpr_w;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] decoder_s3_data_w;
logic [1:0][CALF_CORE_CFG.DATA_BIT_N - 1:0] gpr_read_data_w;
logic gpr_write_valid_w;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] alu_s1_w;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] alu_s2_w;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] alu_res_w;
logic bru_br_w;
logic csr_read_valid_w;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] csr_read_data_w;
logic unused_csr_read_exc_w;
logic csr_write_valid_w;
logic unused_csr_write_exc_w;
logic csr_instret_w;
logic [CALF_CORE_CFG.DATA_BYTE_N_BIT - 1:0] mem_shift_w;
logic [CALF_CORE_CFG.DATA_BYTE_N - 1:0] mem_wmask_w;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] mem_wdata_w;
logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] mem_rdata_w;

// *****************************************************************************
// * FSM
// *****************************************************************************
  calf_core_fsm #(
    .CALF_CORE_CFG  (CALF_CORE_CFG)
  ) fsm_m (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .boot_i         (boot_i),
    .fetch_req_i    (mem_valid_o && mem_ready_i),
    .fetch_ack_i    (mem_rready_i),
    .seq_i          (seq_w),
    .mem_req_i      (mem_valid_o && mem_ready_i),
    .mem_ack_i      (mem_rready_i || !ctrl_r.lsu_rw[RW_R_BIT]),
    .fetch_o        (fsm_fetch_w),
    .inst_o         (fsm_inst_w),
    .decoder_o      (fsm_decoder_w),
    .alu_o          (fsm_alu_w),
    .bru_o          (fsm_bru_w),
    .mem_req_o      (fsm_mem_req_w),
    .mem_ack_o      (fsm_mem_ack_w),
    .csrr_o         (fsm_csrr_w),
    .csrw_o         (fsm_csrw_w),
    .wb_o           (fsm_wb_w)
  );

// *****************************************************************************
// * PC
// *****************************************************************************
  always_comb begin
    if (fsm_wb_w) begin
      if (br_r) begin
        pc_n = s2_pc_r;
      end else begin
        pc_n = pc_r + 'h4;
      end
    end else begin
      pc_n = pc_r;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      pc_r <= CALF_CORE_CFG.PC_BOOT[CALF_CORE_CFG.ADDR_BIT_N - 1:0];
    end else begin
      pc_r <= pc_n;
    end
  end

// *****************************************************************************
// * INSTRUCTION
// *****************************************************************************
  always_comb begin
    if (fsm_inst_w) begin
      inst_n = mem_rdata_i;
    end else begin
      inst_n = inst_r;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      inst_r <= 'h0;
    end else begin
      inst_r <= inst_n;
    end
  end

// *****************************************************************************
// * MEMORY
// *****************************************************************************
  always_comb begin
    case (ctrl_r.lsu_size)
      LSU_8: begin
        mem_shift_w = s1_res_r[CALF_CORE_CFG.DATA_BYTE_N_BIT - 1:0] & ~(CALF_CORE_CFG.DATA_BYTE_N_BIT)'('h0);
      end
      LSU_16: begin
        mem_shift_w = s1_res_r[CALF_CORE_CFG.DATA_BYTE_N_BIT - 1:0] & ~(CALF_CORE_CFG.DATA_BYTE_N_BIT)'('h1);
      end
      LSU_32: begin
        mem_shift_w = s1_res_r[CALF_CORE_CFG.DATA_BYTE_N_BIT - 1:0] & ~(CALF_CORE_CFG.DATA_BYTE_N_BIT)'('h3);
      end
      default: begin
        mem_shift_w = 'h0;
      end
    endcase
  end

  always_comb begin
    case (ctrl_r.lsu_size)
      LSU_8: begin
        mem_wmask_w = (CALF_CORE_CFG.DATA_BYTE_N)'({1{ctrl_r.lsu_rw[RW_W_BIT]}});
        mem_wdata_w = s3_csr_r[CALF_CORE_CFG.DATA_BIT_N - 1:0];
      end    
      LSU_16: begin
        mem_wmask_w = (CALF_CORE_CFG.DATA_BYTE_N)'({2{ctrl_r.lsu_rw[RW_W_BIT]}});
        mem_wdata_w = s3_csr_r[CALF_CORE_CFG.DATA_BIT_N - 1:0];
      end
      LSU_32: begin
        mem_wmask_w = (CALF_CORE_CFG.DATA_BYTE_N)'({4{ctrl_r.lsu_rw[RW_W_BIT]}});
        mem_wdata_w = s3_csr_r[CALF_CORE_CFG.DATA_BIT_N - 1:0];
      end
      default:  begin
        mem_wmask_w = 'h0;
        mem_wdata_w = s3_csr_r[CALF_CORE_CFG.DATA_BIT_N - 1:0];
      end
    endcase
  end

  always_comb begin
    if (fsm_mem_req_w) begin
      mem_valid_o = !fsm_alu_w;
      mem_addr_o = s1_res_r[CALF_CORE_CFG.ADDR_BIT_N - 1:0];
      mem_wmask_o = mem_wmask_w << mem_shift_w;
      mem_wdata_o = mem_wdata_w << {mem_shift_w, 3'b000};
    end else begin
      mem_valid_o = fsm_fetch_w;
      mem_addr_o = pc_r[CALF_CORE_CFG.ADDR_BIT_N - 1:0];
      mem_wmask_o = 'h0;
      mem_wdata_o = 'h0;
    end
  end
   
  always_comb begin 
    mem_rdata_w = mem_rdata_i >> {mem_shift_w, 3'b000};
  end

// *****************************************************************************
// * DECODER
// *****************************************************************************
  always_comb begin
    inst_w = (CALF_CORE_CFG.INST_REG_USE) ? inst_r : s1_res_r[CALF_CORE_CFG.INST_BIT_N - 1:0];
  end

  calf_core_decoder #(
    .CALF_CORE_CFG  (CALF_CORE_CFG),
    .ctrl_t         (ctrl_t)
  ) decoder_m (
    .inst_i         (inst_w),
    .seq_o          (seq_w),
    .ctrl_o         (decoder_ctrl_w),
    .gpr_rs1_o      (decoder_rs1_w),
    .gpr_rs2_o      (decoder_rs2_w),
    .s1_gpr_o       (decoder_s1_gpr_w),
    .s1_data_o      (decoder_s1_data_w),
    .s2_gpr_o       (decoder_s2_gpr_w),
    .s2_data_o      (decoder_s2_data_w),
    .s3_gpr_o       (decoder_s3_gpr_w),
    .s3_data_o      (decoder_s3_data_w)
  );

  always_comb begin
    if (fsm_decoder_w) begin
      ctrl_n = decoder_ctrl_w;
    end else begin
      ctrl_n = ctrl_r;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      ctrl_r <= 'h0;
    end else begin
      ctrl_r <= ctrl_n;
    end
  end

// *****************************************************************************
// * DATA
// *****************************************************************************
// -----------------------------------------------------------------------------
// - GPR
// -----------------------------------------------------------------------------
  always_comb begin
    gpr_write_valid_w = fsm_wb_w && ctrl_r.gpr_wb;
  end

  calf_core_gpr #(
    .CALF_CORE_CFG  (CALF_CORE_CFG)
  ) gpr_m (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .read_addr_i    ({decoder_rs2_w, decoder_rs1_w}),
    .read_data_o    (gpr_read_data_w),
    .write_valid_i  (gpr_write_valid_w),
    .write_addr_i   (ctrl_r.gpr_addr),
    .write_data_i   (s1_res_r)
  );

// -----------------------------------------------------------------------------
// - REGISTER
// -----------------------------------------------------------------------------
  always_comb begin
    if (fsm_inst_w) begin
      if (CALF_CORE_CFG.INST_REG_USE) begin
        s1_res_n = s1_res_r;
      end else begin
        s1_res_n = mem_rdata_i;
      end
      s2_pc_n = s2_pc_r;
      s3_csr_n = s3_csr_r;
    end else if (fsm_decoder_w) begin
      s1_res_n = (decoder_s1_gpr_w) ? gpr_read_data_w[0] : decoder_s1_data_w;
      s2_pc_n = (decoder_s2_gpr_w) ? gpr_read_data_w[1] : decoder_s2_data_w;
      s3_csr_n = (decoder_s3_gpr_w) ? gpr_read_data_w[1] : decoder_s3_data_w;
    end else if (fsm_bru_w) begin
      s1_res_n = pc_r + 'h4;
      s2_pc_n = alu_res_w;
      s2_pc_n[0] = 1'b0;
      s3_csr_n = 'h0;
    end else if (fsm_alu_w && !fsm_mem_req_w) begin
      s1_res_n = alu_res_w;
      s2_pc_n = s2_pc_r;
      s3_csr_n = 'h0;
    end else if (fsm_alu_w && fsm_mem_req_w) begin
      s1_res_n = alu_res_w;
      s2_pc_n = s2_pc_r;
      s3_csr_n = s3_csr_r;
    end else if (fsm_mem_ack_w && mem_rready_i) begin
      case (ctrl_r.lsu_size)
        LSU_8: begin
          s1_res_n = (ctrl_r.lsu_sign) ? {{(CALF_CORE_CFG.DATA_BIT_N - 8){mem_rdata_w[7]}}, mem_rdata_w[7:0]} : {{(CALF_CORE_CFG.DATA_BIT_N - 8){1'b0}}, mem_rdata_w[7:0]};
        end
        LSU_16: begin
          s1_res_n = (ctrl_r.lsu_sign) ? {{(CALF_CORE_CFG.DATA_BIT_N - 16){mem_rdata_w[15]}}, mem_rdata_w[15:0]} : {{(CALF_CORE_CFG.DATA_BIT_N - 16){1'b0}}, mem_rdata_w[15:0]};
        end
        LSU_32: begin
          s1_res_n = mem_rdata_w;
        end
        default: begin
          s1_res_n = 'h0;
        end
      endcase

      s2_pc_n = s2_pc_r;
      s3_csr_n = s3_csr_r;
    end else if (fsm_csrr_w) begin
      s1_res_n = csr_read_data_w;
      s2_pc_n = s1_res_r;
      s3_csr_n = s3_csr_r;
    end else begin
      s1_res_n = s1_res_r;
      s2_pc_n = s2_pc_r;
      s3_csr_n = s3_csr_r;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      s1_res_r <= 'h0;
      s2_pc_r <= 'h0;
      s3_csr_r <= 'h0;
    end else begin
      s1_res_r <= s1_res_n;
      s2_pc_r <= s2_pc_n;
      s3_csr_r <= s3_csr_n;
    end
  end

// -----------------------------------------------------------------------------
// - ALU
// -----------------------------------------------------------------------------
  always_comb begin
    alu_s1_w = (ctrl_r.pc_rel) ? pc_r : s1_res_r;
    alu_s2_w = (ctrl_r.pc_rel) ? s3_csr_r : s2_pc_r;
  end

  calf_core_alu #(
    .CALF_CORE_CFG  (CALF_CORE_CFG)
  ) alu_m (
    .uop_i          (ctrl_r.alu_uop),
    .sign_i         (ctrl_r.alu_sign),
    .s1_i           (alu_s1_w),
    .s2_i           (alu_s2_w),
    .res_o          (alu_res_w)
  );

// -----------------------------------------------------------------------------
// - BRU / NEW BRANCH
// -----------------------------------------------------------------------------
  calf_core_bru #(
    .CALF_CORE_CFG  (CALF_CORE_CFG)
  ) bru_m (
    .uop_i          (ctrl_r.bru_uop),
    .sign_i         (ctrl_r.bru_sign),
    .s1_i           (s1_res_r),
    .s2_i           (s2_pc_r),
    .br_o           (bru_br_w)
  );

  always_comb begin
    if (fsm_wb_w) begin
      br_n = 1'b0;
    end else if (fsm_bru_w) begin
      br_n = bru_br_w;
    end else begin
      br_n = br_r;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      br_r <= 1'b0;
    end else begin
      br_r <= br_n;
    end
  end

// -----------------------------------------------------------------------------
// - CSR
// -----------------------------------------------------------------------------
  always_comb begin
    csr_read_valid_w = fsm_csrr_w && ctrl_r.csr_rw[RW_R_BIT];
  end

  always_comb begin
    csr_write_valid_w = fsm_csrw_w && ctrl_r.csr_rw[RW_W_BIT];
  end

  always_comb begin
    csr_instret_w = fsm_wb_w;
  end

  calf_core_csr #(
    .CALF_CORE_CFG  (CALF_CORE_CFG)
  ) csr_m (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .read_valid_i   (csr_read_valid_w),
    .read_addr_i    (s3_csr_r[11:0]),
    .read_data_o    (csr_read_data_w),
    .read_exc_o     (unused_csr_read_exc_w),
    .write_valid_i  (csr_write_valid_w),
    .write_uop_i    (ctrl_r.csr_uop),
    .write_addr_i   (s3_csr_r[11:0]),
    .write_mask_i   (s2_pc_r),
    .write_data_i   (s1_res_r),
    .write_exc_o    (unused_csr_write_exc_w),
    .instret_i      (csr_instret_w)
  );
endmodule
