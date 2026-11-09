/*
 * File: calf_core_pkg.sv                                                      *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 12:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-06 01:18:48 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Core configuration (user parameters and derived values),       *
 * micro- operation encodings and control structure shared by the core         *
 * modules.                                                                    *
 */


package calf_core_pkg;
// *****************************************************************************
// * CONFIG
// *****************************************************************************
  localparam int ADDR_BIT_N_MAX = 64;

  typedef struct packed {
    bit EXT_E_USE;
    bit EXT_ZICSR_USE;
    bit EXT_ZICNTR_USE;
    bit EXT_ZBS_USE;
    logic [ADDR_BIT_N_MAX - 1:0] PC_BOOT;
    bit INST_REG_USE;

    bit CACHE_USE;
    int CACHE_BEAT_N;
    int CACHE_WAY_N;
    int CACHE_SET_N;
    logic [ADDR_BIT_N_MAX - 1:0] CACHE_ADDR_BASE;
    logic [ADDR_BIT_N_MAX - 1:0] CACHE_ADDR_SIZE;
  } calf_core_usr_t;

  typedef struct packed {
    int BASE_BIT_N;
    bit EXT_E_USE;
    bit EXT_ZICSR_USE;
    bit EXT_ZICNTR_USE;
    bit EXT_ZBS_USE;

    int ADDR_BIT_N;
    int INST_BIT_N;
    int DATA_BIT_N;
    int DATA_BIT_N_BIT;
    int DATA_BYTE_N;
    int DATA_BYTE_N_BIT;
    int GPR_N;
    int GPR_N_BIT;

    logic [ADDR_BIT_N_MAX - 1:0] PC_BOOT;
    bit INST_REG_USE;

    bit CACHE_USE;
    int CACHE_BEAT_N;
    int CACHE_WAY_N;
    int CACHE_SET_N;
    int CACHE_LINE_BYTE_N;
    logic [ADDR_BIT_N_MAX - 1:0] CACHE_ADDR_BASE;
    logic [ADDR_BIT_N_MAX - 1:0] CACHE_ADDR_SIZE;
  } calf_core_cfg_t;

  function automatic calf_core_cfg_t calf_core_cfg_f(calf_core_usr_t u);
    calf_core_cfg_t c;

    c.BASE_BIT_N = 32;
    c.EXT_E_USE = u.EXT_E_USE;
    c.EXT_ZICSR_USE = u.EXT_ZICSR_USE;
    c.EXT_ZICNTR_USE = u.EXT_ZICNTR_USE;
    c.EXT_ZBS_USE = u.EXT_ZBS_USE;

    c.ADDR_BIT_N = c.BASE_BIT_N;
    c.INST_BIT_N = 32;
    c.DATA_BIT_N = c.BASE_BIT_N;
    c.DATA_BIT_N_BIT = $clog2(c.DATA_BIT_N);
    c.DATA_BYTE_N = c.DATA_BIT_N / 8;
    c.DATA_BYTE_N_BIT = $clog2(c.DATA_BYTE_N);
    c.GPR_N = (u.EXT_E_USE) ? 16 : 32;
    c.GPR_N_BIT = $clog2(c.GPR_N);

    c.PC_BOOT = u.PC_BOOT;
    c.INST_REG_USE = u.INST_REG_USE;

    c.CACHE_USE = u.CACHE_USE;
    c.CACHE_BEAT_N = u.CACHE_BEAT_N;
    c.CACHE_WAY_N = u.CACHE_WAY_N;
    c.CACHE_SET_N = u.CACHE_SET_N;
    c.CACHE_LINE_BYTE_N = u.CACHE_BEAT_N * c.DATA_BYTE_N;
    c.CACHE_ADDR_BASE = u.CACHE_ADDR_BASE;
    c.CACHE_ADDR_SIZE = u.CACHE_ADDR_SIZE;

    return c;
  endfunction

  localparam calf_core_usr_t CALF_CORE_USR_DEFAULT = '{
    EXT_E_USE: 0,
    EXT_ZICSR_USE: 1,
    EXT_ZICNTR_USE: 1,
    EXT_ZBS_USE: 0,
    PC_BOOT: 'h0000_0000,
    INST_REG_USE: 0,
    CACHE_USE: 0,
    CACHE_BEAT_N: 4,
    CACHE_WAY_N: 2,
    CACHE_SET_N: 16,
    CACHE_ADDR_BASE: 'h0000_0000,
    CACHE_ADDR_SIZE: 'h1000_0000
  };
  localparam calf_core_cfg_t CALF_CORE_CFG_DEFAULT = calf_core_cfg_f(CALF_CORE_USR_DEFAULT);

// *****************************************************************************
// * ENUMERATE
// *****************************************************************************
  typedef enum logic [3:0] {
    FSM_BOOT,
    FSM_IF0,
    FSM_IF1,
    FSM_ID,
    FSM_ALU,
    FSM_BRU,
    FSM_AG,
    FSM_MA0,
    FSM_MA1,
    FSM_CSR,
    FSM_WB
  } fsm_e;

  typedef logic [2:0] seq_e;
  localparam seq_e SEQ_NO_SEQ     = 'h0;
  localparam seq_e SEQ_ALU        = 'h1;
  localparam seq_e SEQ_BRU        = 'h2;
  localparam seq_e SEQ_LSU        = 'h3;
  localparam seq_e SEQ_CSR        = 'h4;

  typedef logic [1:0] rw_e;
  localparam rw_e RW_NO = 'b00;
  localparam rw_e RW_R  = 'b01;
  localparam rw_e RW_W  = 'b10;
  localparam rw_e RW_RW = 'b11;
  localparam int RW_R_BIT = 0;
  localparam int RW_W_BIT = 1;

  typedef logic [4:0] alu_uop_e;
  localparam alu_uop_e ALU_NO_UOP = 'h00;
  localparam alu_uop_e ALU_ADD    = 'h00;
  localparam alu_uop_e ALU_SUB    = 'h01;
  localparam alu_uop_e ALU_SLT    = 'h02;
  localparam alu_uop_e ALU_XOR    = 'h03;
  localparam alu_uop_e ALU_OR     = 'h04;
  localparam alu_uop_e ALU_AND    = 'h05;
  localparam alu_uop_e ALU_SL     = 'h06;
  localparam alu_uop_e ALU_SR     = 'h07;
  localparam alu_uop_e ALU_BCLR   = 'h08;
  localparam alu_uop_e ALU_BEXT   = 'h09;
  localparam alu_uop_e ALU_BINV   = 'h0a;
  localparam alu_uop_e ALU_BSET   = 'h0b;

  typedef logic [2:0] bru_uop_e;
  localparam bru_uop_e BRU_NO_UOP = 'h0;
  localparam bru_uop_e BRU_JAL    = 'h1;
  localparam bru_uop_e BRU_BEQ    = 'h4;
  localparam bru_uop_e BRU_BNE    = 'h5;
  localparam bru_uop_e BRU_BGE    = 'h6;
  localparam bru_uop_e BRU_BLT    = 'h7;

  typedef logic [1:0] lsu_size_e;
  localparam lsu_size_e LSU_8     = 'h0;
  localparam lsu_size_e LSU_16    = 'h1;
  localparam lsu_size_e LSU_32    = 'h2;

  typedef logic [1:0] csr_uop_e;
  localparam csr_uop_e CSR_NO_UOP = 'h0;
  localparam csr_uop_e CSR_W      = 'h1;
  localparam csr_uop_e CSR_S      = 'h2;
  localparam csr_uop_e CSR_C      = 'h3;

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
    logic [CALF_CORE_CFG_DEFAULT.GPR_N_BIT - 1:0] gpr_addr;
  } ctrl_def_t;
endpackage
