/*
 * File: calf_core_gpr.sv                                                      *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 11:45:53 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-06 11:52:59 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: General-purpose register file: GPR_N registers (32, or 16 with *
 * RV32E), 2 combinational read ports, 1 write port, x0 hardwired to 0.        *
 */


module calf_core_gpr
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
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
    input logic                                         clk_i,
    input logic                                         rst_i,

    input logic [1:0][CALF_CORE_CFG.GPR_N_BIT - 1:0]    read_addr_i,
    output logic [1:0][CALF_CORE_CFG.DATA_BIT_N - 1:0]  read_data_o,

    input logic                                         write_valid_i,
    input logic [CALF_CORE_CFG.GPR_N_BIT - 1:0]         write_addr_i,
    input logic [CALF_CORE_CFG.DATA_BIT_N - 1:0]        write_data_i
  );

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic [CALF_CORE_CFG.GPR_N - 1:0][CALF_CORE_CFG.DATA_BIT_N - 1:0] data_r;

  logic unused_rst_w;

// *****************************************************************************
// * READ / FORWARD
// *****************************************************************************
  always_comb begin
    for (int r = 0; r < 2; r = r + 1) begin
      read_data_o[r] = (read_addr_i[r] == 'h0) ? 'h0 : data_r[read_addr_i[r]];
    end
  end

// *****************************************************************************
// * WRITE
// *****************************************************************************
  always_ff @(posedge clk_i) begin
    if (write_valid_i && (write_addr_i != 'h0)) begin
      data_r[write_addr_i] <= write_data_i;
    end
  end

  always_comb begin
    unused_rst_w = rst_i;
  end
endmodule
