/*
 * File: calf_cache.sv                                                         *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-26 03:00:00 pm                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-09 11:00:00 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: CALF cache top: controller and tag/data buffer. Unified,       *
 * set-associative, write-through, write-allocate cache with round-robin       *
 * replacement.                                                                *
 */


module calf_cache
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_cache_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter calf_cache_usr_t  CALF_CACHE_USR = CALF_CACHE_USR_DEFAULT,

    localparam calf_cache_cfg_t CALF_CACHE_CFG = calf_cache_cfg_f(CALF_CACHE_USR)
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic                                       clk_i,
    input logic                                       rst_i,

    output logic                                      core_ready_o,
    input logic                                       core_valid_i,
    input logic [CALF_CACHE_CFG.ADDR_BIT_N - 1:0]     core_addr_i,
    input logic [CALF_CACHE_CFG.DATA_BYTE_N - 1:0]    core_wmask_i,
    input logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]     core_wdata_i,
    output logic                                      core_rready_o,
    output logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]    core_rdata_o,

    input logic                                       mem_ready_i,
    output logic                                      mem_valid_o,
    output logic [CALF_CACHE_CFG.ADDR_BIT_N - 1:0]    mem_addr_o,
    output logic [CALF_CACHE_CFG.DATA_BYTE_N - 1:0]   mem_wmask_o,
    output logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]    mem_wdata_o,
    input logic                                       mem_rready_i,
    input logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]     mem_rdata_i
  );

// *****************************************************************************
// * CHECK
// *****************************************************************************
  generate
    if ((CALF_CACHE_CFG.DATA_BIT_N % 8) != 0) begin : data_bit_n_g
      $error("calf_cache: DATA_BIT_N must be a multiple of 8");
    end

    if ((CALF_CACHE_CFG.BEAT_N < 2) || ((1 << CALF_CACHE_CFG.BEAT_N_BIT) != CALF_CACHE_CFG.BEAT_N)) begin : beat_n_g
      $error("calf_cache: BEAT_N must be a power of 2, at least 2");
    end

    if ((CALF_CACHE_CFG.WAY_N < 2) || ((1 << CALF_CACHE_CFG.WAY_N_BIT) != CALF_CACHE_CFG.WAY_N)) begin : way_n_g
      $error("calf_cache: WAY_N must be a power of 2, at least 2");
    end

    if ((CALF_CACHE_CFG.SET_N < 2) || ((1 << CALF_CACHE_CFG.SET_N_BIT) != CALF_CACHE_CFG.SET_N)) begin : set_n_g
      $error("calf_cache: SET_N must be a power of 2, at least 2");
    end
  endgenerate

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic buf_valid_w;
  logic buf_fill_w;
  logic [CALF_CACHE_CFG.TAG_BIT_N - 1:0] buf_tag_w;
  logic [CALF_CACHE_CFG.SET_N_BIT - 1:0] buf_set_w;
  logic [CALF_CACHE_CFG.BEAT_N_BIT - 1:0] buf_beat_w;
  logic [CALF_CACHE_CFG.DATA_BYTE_N - 1:0] buf_wmask_w;
  logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0] buf_wdata_w;
  logic buf_hit_w;
  logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0] buf_rdata_w;

// *****************************************************************************
// * CONTROLLER
// *****************************************************************************
  calf_cache_ctrl #(
    .CALF_CACHE_USR (CALF_CACHE_USR)
  ) ctrl_m (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .core_ready_o   (core_ready_o),
    .core_valid_i   (core_valid_i),
    .core_addr_i    (core_addr_i),
    .core_wmask_i   (core_wmask_i),
    .core_wdata_i   (core_wdata_i),
    .core_rready_o  (core_rready_o),
    .core_rdata_o   (core_rdata_o),
    .buf_valid_o    (buf_valid_w),
    .buf_fill_o     (buf_fill_w),
    .buf_tag_o      (buf_tag_w),
    .buf_set_o      (buf_set_w),
    .buf_beat_o     (buf_beat_w),
    .buf_wmask_o    (buf_wmask_w),
    .buf_wdata_o    (buf_wdata_w),
    .buf_hit_i      (buf_hit_w),
    .buf_rdata_i    (buf_rdata_w),
    .mem_ready_i    (mem_ready_i),
    .mem_valid_o    (mem_valid_o),
    .mem_addr_o     (mem_addr_o),
    .mem_wmask_o    (mem_wmask_o),
    .mem_wdata_o    (mem_wdata_o),
    .mem_rready_i   (mem_rready_i),
    .mem_rdata_i    (mem_rdata_i)
  );

// *****************************************************************************
// * BUFFER
// *****************************************************************************
  calf_cache_buf #(
    .CALF_CACHE_USR (CALF_CACHE_USR)
  ) buf_m (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .ctrl_valid_i   (buf_valid_w),
    .ctrl_fill_i    (buf_fill_w),
    .ctrl_tag_i     (buf_tag_w),
    .ctrl_set_i     (buf_set_w),
    .ctrl_beat_i    (buf_beat_w),
    .ctrl_wmask_i   (buf_wmask_w),
    .ctrl_wdata_i   (buf_wdata_w),
    .ctrl_hit_o     (buf_hit_w),
    .ctrl_rdata_o   (buf_rdata_w)
  );
endmodule
