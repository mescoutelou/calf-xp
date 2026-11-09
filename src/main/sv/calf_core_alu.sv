/*
 * File: calf_core_alu.sv                                                      *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 09:46:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-01 02:06:12 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Arithmetic and logic unit: ADD, SUB, SLT(U), XOR, OR, AND,     *
 * shifts, and Zbs bit operations (BCLR, BEXT, BINV, BSET) when EXT_ZBS_USE is *
 * set.                                                                        *
 */


module calf_core_alu
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_core_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter calf_core_cfg_t CALF_CORE_CFG = CALF_CORE_CFG_DEFAULT,

    localparam int            SHAMT_N_BIT = $clog2(CALF_CORE_CFG.DATA_BIT_N)
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input alu_uop_e                               uop_i,
    input logic                                   sign_i,
    input logic [CALF_CORE_CFG.DATA_BIT_N - 1:0]  s1_i,
    input logic [CALF_CORE_CFG.DATA_BIT_N - 1:0]  s2_i,
    output logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] res_o
  );

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic [SHAMT_N_BIT - 1:0] shamt_w;

// *****************************************************************************
// * RESULT
// *****************************************************************************
  always_comb begin
    shamt_w = s2_i[SHAMT_N_BIT - 1:0];
  end

  always_comb begin
    case (uop_i)
      ALU_ADD: begin 
        res_o = s1_i + s2_i;
      end
      ALU_SUB: begin 
        res_o = s1_i - s2_i;
      end
      ALU_SLT: begin
        if (sign_i) begin
          res_o = ($signed(s1_i) < $signed(s2_i)) ? 'h1 : 'h0;
        end else begin
          res_o = (s1_i < s2_i) ? 'h1 : 'h0;
        end
      end
      ALU_XOR: begin
        res_o = s1_i ^ s2_i;
      end
      ALU_OR: begin
        res_o = s1_i | s2_i;
      end
      ALU_AND: begin
        res_o = s1_i & s2_i;
      end
      ALU_SL: begin
        res_o = s1_i << shamt_w;
      end
      ALU_SR: begin
        if (sign_i) begin
          res_o = $signed(s1_i) >>> shamt_w;
        end else begin
          res_o = s1_i >> shamt_w;
        end
      end
      default: begin
        res_o = 'h0;
      end
    endcase

    if (CALF_CORE_CFG.EXT_ZBS_USE) begin
      case (uop_i)
        ALU_BCLR: begin
          res_o = s1_i;
          res_o[shamt_w] = 1'b0;
        end
        ALU_BEXT: begin
          res_o = 'h0;
          res_o[0] = s1_i[shamt_w];
        end
        ALU_BINV: begin
          res_o = s1_i;
          res_o[shamt_w] = ~s1_i[shamt_w];
        end
        ALU_BSET: begin
          res_o = s1_i;
          res_o[shamt_w] = 1'b1;
        end
        default: begin
        // Every other operation keeps the result the base case computed
        end
      endcase
    end
  end
endmodule
