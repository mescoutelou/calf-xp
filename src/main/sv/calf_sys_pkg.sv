/*
 * File: calf_sys_pkg.sv                                                       *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 12:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-05 07:00:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: System configuration: user parameters (core extensions, RAM,   *
 * UART, SPI, key) and derived values used by calf_sys.                        *
 */


package calf_sys_pkg;
  import calf_addr_pkg::ADDR_BIT_N_MAX;

// *****************************************************************************
// * CONFIG
// *****************************************************************************
  localparam int RAM_FILE_CHAR_N_MAX = 128;

  typedef struct packed {
    bit CORE_EXT_E_USE;
    bit CORE_EXT_ZICSR_USE;
    bit CORE_EXT_ZICNTR_USE;
    bit CORE_EXT_ZBS_USE;
    logic [ADDR_BIT_N_MAX - 1:0] CORE_PC_BOOT;
    bit CORE_INST_REG_USE;
    bit CORE_CACHE_USE;
    int CORE_CACHE_BEAT_N;
    int CORE_CACHE_WAY_N;
    int CORE_CACHE_SET_N;

    logic [RAM_FILE_CHAR_N_MAX * 8 - 1:0] RAM_FILE;
    int RAM_DATA_N;

    int UART_BAUD_BIT_N;
    int UART_BAUD_INIT_N;

    int SPI_CLK_DIV_BIT_N;
    int SPI_CLK_DIV_INIT_N;

    logic [31:0] KEY;
  } calf_sys_usr_t;

  typedef struct packed {
    int CORE_BASE_BIT_N;
    bit CORE_EXT_E_USE;
    bit CORE_EXT_ZICSR_USE;
    bit CORE_EXT_ZICNTR_USE;
    bit CORE_EXT_ZBS_USE;

    logic [ADDR_BIT_N_MAX - 1:0] CORE_PC_BOOT;
    bit CORE_INST_REG_USE;
    bit CORE_CACHE_USE;
    int CORE_CACHE_BEAT_N;
    int CORE_CACHE_WAY_N;
    int CORE_CACHE_SET_N;

    int ADDR_BIT_N;
    int DATA_BIT_N;
    int DATA_BYTE_N;
    int DATA_BYTE_N_BIT;

    logic [RAM_FILE_CHAR_N_MAX * 8 - 1:0] RAM_FILE;
    int RAM_DATA_N;
    logic [ADDR_BIT_N_MAX - 1:0] RAM_ADDR_SIZE;

    int UART_BAUD_BIT_N;
    int UART_BAUD_INIT_N;

    int SPI_CLK_DIV_BIT_N;
    int SPI_CLK_DIV_INIT_N;

    logic [31:0] KEY;
  } calf_sys_cfg_t;

  function automatic calf_sys_cfg_t calf_sys_cfg_f(calf_sys_usr_t u);
    calf_sys_cfg_t c;

    c.CORE_BASE_BIT_N = 32;
    c.CORE_EXT_E_USE = u.CORE_EXT_E_USE;
    c.CORE_EXT_ZICSR_USE = u.CORE_EXT_ZICSR_USE;
    c.CORE_EXT_ZICNTR_USE = u.CORE_EXT_ZICNTR_USE;
    c.CORE_EXT_ZBS_USE = u.CORE_EXT_ZBS_USE;

    c.ADDR_BIT_N = c.CORE_BASE_BIT_N;
    c.DATA_BIT_N = c.CORE_BASE_BIT_N;
    c.DATA_BYTE_N = c.DATA_BIT_N / 8;
    c.DATA_BYTE_N_BIT = $clog2(c.DATA_BYTE_N);

    c.CORE_PC_BOOT = u.CORE_PC_BOOT;
    c.CORE_INST_REG_USE = u.CORE_INST_REG_USE;
    c.CORE_CACHE_USE = u.CORE_CACHE_USE;
    c.CORE_CACHE_BEAT_N = u.CORE_CACHE_BEAT_N;
    c.CORE_CACHE_WAY_N = u.CORE_CACHE_WAY_N;
    c.CORE_CACHE_SET_N = u.CORE_CACHE_SET_N;

    c.RAM_FILE = u.RAM_FILE;
    c.RAM_DATA_N = u.RAM_DATA_N;
    c.RAM_ADDR_SIZE = u.RAM_DATA_N * c.DATA_BYTE_N;

    c.UART_BAUD_BIT_N = u.UART_BAUD_BIT_N;
    c.UART_BAUD_INIT_N = u.UART_BAUD_INIT_N;

    c.SPI_CLK_DIV_BIT_N = u.SPI_CLK_DIV_BIT_N;
    c.SPI_CLK_DIV_INIT_N = u.SPI_CLK_DIV_INIT_N;

    c.KEY = u.KEY;

    return c;
  endfunction

  localparam calf_sys_usr_t CALF_SYS_USR_DEFAULT = '{
    CORE_EXT_E_USE: 0,
    CORE_EXT_ZICSR_USE: 1,
    CORE_EXT_ZICNTR_USE: 1,
    CORE_EXT_ZBS_USE: 1,
    CORE_PC_BOOT: 'h0000_0000,
    CORE_INST_REG_USE: 0,
    CORE_CACHE_USE: 0,
    CORE_CACHE_BEAT_N: 4,
    CORE_CACHE_WAY_N: 2,
    CORE_CACHE_SET_N: 16,
    RAM_FILE: "",
    RAM_DATA_N: 'h1000,
    UART_BAUD_BIT_N: 16,
    UART_BAUD_INIT_N: 5208,
    SPI_CLK_DIV_BIT_N: 16,
    SPI_CLK_DIV_INIT_N: 2,
    KEY: 'h0000_0000
  };
  localparam calf_sys_cfg_t CALF_SYS_CFG_DEFAULT = calf_sys_cfg_f(CALF_SYS_USR_DEFAULT);

// *****************************************************************************
// * ENUMERATE
// *****************************************************************************

// *****************************************************************************
// * STRUCTURE
// *****************************************************************************
endpackage
