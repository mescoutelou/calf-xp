/*
 * File: calf_cache_pkg.sv                                                     *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-26 02:30:00 pm                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-09 11:00:00 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: CALF cache configuration (user parameters and derived values)  *
 * and controller FSM states.                                                  *
 */


package calf_cache_pkg;
// *****************************************************************************
// * CONFIG
// *****************************************************************************
  typedef struct packed {
    int ADDR_BIT_N;
    int DATA_BIT_N;
    int BEAT_N;
    int WAY_N;
    int SET_N;
  } calf_cache_usr_t;

  typedef struct packed {
    int ADDR_BIT_N;
    int DATA_BIT_N;
    int DATA_BYTE_N;
    int OFFSET_BIT_N;
    int BEAT_N;
    int BEAT_N_BIT;
    int WAY_N;
    int WAY_N_BIT;
    int SET_N;
    int SET_N_BIT;
    int TAG_BIT_N;
  } calf_cache_cfg_t;

  function automatic calf_cache_cfg_t calf_cache_cfg_f(calf_cache_usr_t u);
    calf_cache_cfg_t c;

    c.ADDR_BIT_N = u.ADDR_BIT_N;
    c.DATA_BIT_N = u.DATA_BIT_N;
    c.DATA_BYTE_N = u.DATA_BIT_N / 8;
    c.OFFSET_BIT_N = $clog2(c.DATA_BYTE_N);
    c.BEAT_N = u.BEAT_N;
    c.BEAT_N_BIT = $clog2(c.BEAT_N);
    c.WAY_N = u.WAY_N;
    c.WAY_N_BIT = $clog2(c.WAY_N);
    c.SET_N = u.SET_N;
    c.SET_N_BIT = $clog2(c.SET_N);
    c.TAG_BIT_N = c.ADDR_BIT_N - c.OFFSET_BIT_N - c.BEAT_N_BIT - c.SET_N_BIT;

    return c;
  endfunction

  localparam calf_cache_usr_t CALF_CACHE_USR_DEFAULT = '{
    ADDR_BIT_N: 32,
    DATA_BIT_N: 32,
    BEAT_N: 4,
    WAY_N: 2,
    SET_N: 16
  };
  localparam calf_cache_cfg_t CALF_CACHE_CFG_DEFAULT = calf_cache_cfg_f(CALF_CACHE_USR_DEFAULT);

// *****************************************************************************
// * ENUMERATE
// *****************************************************************************
  typedef enum logic [2:0] {
    FSM_IDLE = 3'h0,
    FSM_HIT = 3'h1,
    FSM_MISS = 3'h2,
    FSM_REPLAY = 3'h3,
    FSM_WRITE = 3'h4
  } fsm_e;

// *****************************************************************************
// * STRUCTURE
// *****************************************************************************
endpackage
