/*
 * File: calf_priv_pkg.sv                                                      *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-09-30 03:54:32 pm                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-01 11:40:54 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: RISC-V privileged architecture constants: CSR addresses.       *
 */


package calf_priv_pkg;
  localparam logic [11:0] PRIV_CSR_CYCLE      = 12'hC00;
  localparam logic [11:0] PRIV_CSR_TIME       = 12'hC01;
  localparam logic [11:0] PRIV_CSR_INSTRET    = 12'hC02;
  localparam logic [11:0] PRIV_CSR_CYCLEH     = 12'hC80;
  localparam logic [11:0] PRIV_CSR_TIMEH      = 12'hC81;
  localparam logic [11:0] PRIV_CSR_INSTRETH   = 12'hC82;
endpackage
