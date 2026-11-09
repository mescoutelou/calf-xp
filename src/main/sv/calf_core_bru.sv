/*
 * File: calf_core_bru.sv                                                      *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 10:05:30 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-05 11:12:28 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Branch resolution unit: compares s1 and s2 for BEQ, BNE,       *
 * BLT(U) and BGE(U), always taken for JAL/JALR. The target is computed by the *
 * ALU.                                                                        *
 */


module calf_core_bru
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
    input bru_uop_e                               uop_i,
//    input logic [CALF_CORE_CFG.ADDR_BIT_N - 1:0]  pc_i,
    input logic                                   sign_i,
    input logic [CALF_CORE_CFG.DATA_BIT_N - 1:0]  s1_i,
    input logic [CALF_CORE_CFG.DATA_BIT_N - 1:0]  s2_i,
//    input logic [CALF_CORE_CFG.DATA_BIT_N - 1:0]  s3_i,
    output logic                                  br_o
//    output logic [CALF_CORE_CFG.ADDR_BIT_N - 1:0] target_o,
//    output logic [CALF_CORE_CFG.DATA_BIT_N - 1:0] res_o
  );

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic eq_w;
  logic ltu_w;
  logic lts_w;

// *****************************************************************************
// * COMPARE
// *****************************************************************************
  always_comb begin
    eq_w = (s1_i == s2_i);
    ltu_w = (s1_i < s2_i);
    lts_w = ($signed(s1_i) < $signed(s2_i));
  end

// *****************************************************************************
// * BRANCH
// *****************************************************************************
  always_comb begin
    case (uop_i)
      BRU_JAL: begin 
        br_o = 1'b1;
      end
      BRU_BEQ: begin
        br_o = eq_w;
      end
      BRU_BNE: begin
        br_o = !eq_w;
      end
      BRU_BGE: begin
        br_o = (!sign_i && !ltu_w) || (sign_i && !lts_w);
      end
      BRU_BLT: begin
        br_o = ((sign_i && lts_w) || (!sign_i && ltu_w));
      end
      default: begin
        br_o = 1'b0;
      end
    endcase
  end

// // *****************************************************************************
// // * TARGET
// // *****************************************************************************
//   always_comb begin
//     case (uop_i)
//       BRU_JAL: begin
//         target_o = s1_i + s2_i;
//         target_o[0] = 1'b0;
//       end
//       BRU_BEQ, BRU_BNE, BRU_BGE, BRU_BLT: begin
//         target_o = pc_i + s3_i;
//       end
//       default: begin
//         target_o = pc_i + 'h4;
//       end
//     endcase
//   end

// // *****************************************************************************
// // * RESULT
// // *****************************************************************************
//   always_comb begin
//     case (uop_i)
//       BRU_SLT: begin
//         res_o = ((sign_i && lts_w) || (!sign_i && ltu_w)) ? 'h1 : 'h0;
//       end
//       BRU_JAL: begin
//         res_o = pc_i + 'h4;
//       end
//       default: begin
//         res_o = 'h0;
//       end
//     endcase
//   end
endmodule
