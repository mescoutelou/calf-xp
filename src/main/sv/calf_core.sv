/*
 * File: calf_core.sv                                                          *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-26 04:00:00 pm                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-26 04:23:38 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: CALF core: execution unit and optional unified cache. Accesses *
 * inside the cacheable region go through the cache, the others go directly to *
 * the memory port.                                                            *
 */


module calf_core
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_core_pkg::*;
  import calf_cache_pkg::*;

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
// * CHECK
// *****************************************************************************
  generate
    if (CALF_CORE_CFG.CACHE_USE) begin : cache_addr_g
      if (((CALF_CORE_CFG.CACHE_ADDR_BASE % (ADDR_BIT_N_MAX)'(CALF_CORE_CFG.CACHE_LINE_BYTE_N)) != 0) ||
          ((CALF_CORE_CFG.CACHE_ADDR_SIZE % (ADDR_BIT_N_MAX)'(CALF_CORE_CFG.CACHE_LINE_BYTE_N)) != 0)) begin : align_g
        $error("calf_core: CACHE_ADDR_BASE and CACHE_ADDR_SIZE must be aligned on the cache line.");
      end
    end
  endgenerate

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic exec_ready_w;
  logic exec_valid_w;
  logic [CALF_CORE_CFG.ADDR_BIT_N - 1:0] exec_addr_w;
  logic [CALF_CORE_CFG.DATA_BYTE_N - 1:0] exec_wmask_w;
  logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] exec_wdata_w;
  logic exec_rready_w;
  logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] exec_rdata_w;

// *****************************************************************************
// * EXECUTION UNIT
// *****************************************************************************
  calf_core_exec #(
    .CALF_CORE_USR  (CALF_CORE_USR)
  ) exec_m (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .boot_i         (boot_i),
    .mem_ready_i    (exec_ready_w),
    .mem_valid_o    (exec_valid_w),
    .mem_addr_o     (exec_addr_w),
    .mem_wmask_o    (exec_wmask_w),
    .mem_wdata_o    (exec_wdata_w),
    .mem_rready_i   (exec_rready_w),
    .mem_rdata_i    (exec_rdata_w)
  );

// *****************************************************************************
// * CACHE
// *****************************************************************************
  generate
    if (CALF_CORE_CFG.CACHE_USE) begin : cache_g
      localparam calf_cache_usr_t CACHE_USR = '{
        ADDR_BIT_N: CALF_CORE_CFG.ADDR_BIT_N,
        DATA_BIT_N: CALF_CORE_CFG.DATA_BIT_N,
        BEAT_N:     CALF_CORE_CFG.CACHE_BEAT_N,
        WAY_N:      CALF_CORE_CFG.CACHE_WAY_N,
        SET_N:      CALF_CORE_CFG.CACHE_SET_N
      };

      logic cacheable_w;
      logic cache_idle_w;
      logic cache_valid_w;
      logic cache_rready_w;
      logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] cache_rdata_w;
      logic cache_mem_valid_w;
      logic [CALF_CORE_CFG.ADDR_BIT_N - 1:0] cache_mem_addr_w;
      logic [CALF_CORE_CFG.DATA_BYTE_N - 1:0] cache_mem_wmask_w;
      logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] cache_mem_wdata_w;

      always_comb begin
        cacheable_w = ((ADDR_BIT_N_MAX)'(exec_addr_w) >= CALF_CORE_CFG.CACHE_ADDR_BASE) &&
                      ((ADDR_BIT_N_MAX)'(exec_addr_w) < CALF_CORE_CFG.CACHE_ADDR_BASE + CALF_CORE_CFG.CACHE_ADDR_SIZE);
        cache_valid_w = exec_valid_w && cacheable_w;
      end

      // The cache accepts a request only when idle, and is idle only when it
      // waits for no memory response: core_ready_o is used as the idle flag.
      calf_cache #(
        .CALF_CACHE_USR (CACHE_USR)
      ) cache_m (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .core_ready_o   (cache_idle_w),
        .core_valid_i   (cache_valid_w),
        .core_addr_i    (exec_addr_w),
        .core_wmask_i   (exec_wmask_w),
        .core_wdata_i   (exec_wdata_w),
        .core_rready_o  (cache_rready_w),
        .core_rdata_o   (cache_rdata_w),
        .mem_ready_i    (mem_ready_i),
        .mem_valid_o    (cache_mem_valid_w),
        .mem_addr_o     (cache_mem_addr_w),
        .mem_wmask_o    (cache_mem_wmask_w),
        .mem_wdata_o    (cache_mem_wdata_w),
        .mem_rready_i   (mem_rready_i && !cache_idle_w),
        .mem_rdata_i    (mem_rdata_i)
      );

      // Uncached accesses wait for the cache to be idle: the memory port then
      // belongs to the execution unit until its read response is back.
      always_comb begin
        exec_ready_w = cache_idle_w && (cacheable_w || mem_ready_i);
        exec_rready_w = cache_rready_w || (cache_idle_w && mem_rready_i);
        exec_rdata_w = (cache_rready_w) ? cache_rdata_w : mem_rdata_i;
      end

      always_comb begin
        if (!cache_idle_w) begin
          mem_valid_o = cache_mem_valid_w;
          mem_addr_o = cache_mem_addr_w;
          mem_wmask_o = cache_mem_wmask_w;
          mem_wdata_o = cache_mem_wdata_w;
        end else begin
          mem_valid_o = exec_valid_w && !cacheable_w;
          mem_addr_o = exec_addr_w;
          mem_wmask_o = exec_wmask_w;
          mem_wdata_o = exec_wdata_w;
        end
      end

    end else begin : no_cache_g
      always_comb begin
        exec_ready_w = mem_ready_i;
        exec_rready_w = mem_rready_i;
        exec_rdata_w = mem_rdata_i;
      end

      always_comb begin
        mem_valid_o = exec_valid_w;
        mem_addr_o = exec_addr_w;
        mem_wmask_o = exec_wmask_w;
        mem_wdata_o = exec_wdata_w;
      end
    end
  endgenerate
endmodule
