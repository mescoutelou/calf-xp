/*
 * File: calf_core_csr.sv                                                      *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 11:17:03 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-01 12:00:42 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Control and status registers: read-only Zicntr counters        *
 * (cycle, time, instret, and their high halves). No writable CSR yet.         *
 */


module calf_core_csr
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_priv_pkg::*;
  import calf_core_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter calf_core_cfg_t CALF_CORE_CFG = CALF_CORE_CFG_DEFAULT
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic                                   clk_i,
    input logic                                   rst_i,

    input logic                                   read_valid_i,
    input logic [11:0]                            read_addr_i,
    output logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] read_data_o,
    output logic                                  read_exc_o,

    input logic                                   write_valid_i,
    input csr_uop_e                               write_uop_i,
    input logic [11:0]                            write_addr_i,
    input logic [CALF_CORE_CFG.DATA_BIT_N - 1:0]  write_mask_i,
    input logic [CALF_CORE_CFG.DATA_BIT_N - 1:0]  write_data_i,
    output logic                                  write_exc_o,

    input logic                                   instret_i
  );

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic [63:0] cycle_r, cycle_n;
  logic [63:0] time_r, time_n;
  logic [63:0] instret_r, instret_n;

  logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] wdata_w;

  logic read_match_w;
  logic write_match_w;

// *****************************************************************************
// * READ
// *****************************************************************************
  always_comb begin
    read_data_o = 'h0;
    read_match_w = 1'b0;

    if (CALF_CORE_CFG.EXT_ZICNTR_USE) begin
      case (read_addr_i)
        PRIV_CSR_CYCLE:     begin
          read_data_o = cycle_r[CALF_CORE_CFG.DATA_BIT_N - 1:0];
          read_match_w = 1'b1;
        end
        PRIV_CSR_TIME:      begin
          read_data_o = time_r[CALF_CORE_CFG.DATA_BIT_N - 1:0];
          read_match_w = 1'b1;
        end
        PRIV_CSR_INSTRET:   begin
          read_data_o = instret_r[CALF_CORE_CFG.DATA_BIT_N - 1:0];
          read_match_w = 1'b1;
        end
        PRIV_CSR_CYCLEH:    begin
          read_data_o = cycle_r[63:32];
          read_match_w = 1'b1;
        end
        PRIV_CSR_TIMEH:     begin
          read_data_o = time_r[63:32];
          read_match_w = 1'b1;
        end
        PRIV_CSR_INSTRETH:  begin
          read_data_o = instret_r[63:32];
          read_match_w = 1'b1;
        end
        default: begin

        end
      endcase
    end
  end

  always_comb begin
    read_exc_o = read_valid_i && !read_match_w;
  end

// *****************************************************************************
// * WRITE
// *****************************************************************************
  always_comb begin
    case (write_uop_i)
      CSR_W:    wdata_w = write_mask_i;
      CSR_S:    wdata_w = write_data_i | write_mask_i;
      CSR_C:    wdata_w = write_data_i & ~write_mask_i;
      default:  wdata_w = write_data_i;
    endcase
  end

  always_comb begin
    write_match_w = 1'b0;
  end

  always_comb begin
    write_exc_o = write_valid_i && !write_match_w;
  end

// *****************************************************************************
// * COUNTER
// *****************************************************************************
  always_comb begin
    cycle_n = cycle_r + 'h1;
    time_n = time_r + 'h1;
    instret_n = instret_r;
    if (instret_i) begin
      instret_n = instret_n + 'h1;
    end
  end

// *****************************************************************************
// * REGISTER
// *****************************************************************************
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      cycle_r <= 'h0;
      time_r <= 'h0;
      instret_r <= 'h0;
    end else begin
      cycle_r <= cycle_n;
      time_r <= time_n;
      instret_r <= instret_n;
    end
  end
endmodule
