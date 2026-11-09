/*
 * File: calf_core_fsm.sv                                                      *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 11:45:53 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-06 03:53:26 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Multi-cycle sequencer of the core: fetch, decode, execute      *
 * (ALU, BRU, LSU or CSR) and write-back. Stays in BOOT while boot_i is set.   *
 */


module calf_core_fsm
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
    input logic   clk_i,
    input logic   rst_i,

    input logic   boot_i,

    input logic   fetch_req_i,
    input logic   fetch_ack_i,
    input seq_e   seq_i,
    input logic   mem_req_i,
    input logic   mem_ack_i,

    output logic  fetch_o,
    output logic  inst_o,
    output logic  decoder_o,
    output logic  alu_o,
    output logic  bru_o,
    output logic  mem_req_o,
    output logic  mem_ack_o,
    output logic  csrr_o,
    output logic  csrw_o,
    output logic  wb_o
  );

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  fsm_e fsm_r, fsm_n;

// *****************************************************************************
// * STATE
// *****************************************************************************
  always_comb begin
    case (fsm_r)
      FSM_BOOT: begin
        if (!boot_i) begin
          fsm_n = FSM_IF0;
        end else begin
          fsm_n = FSM_BOOT;
        end

        fetch_o = 1'b0;
        inst_o = 1'b0;
        decoder_o = 1'b0;
        alu_o = 1'b0;
        bru_o = 1'b0;
        mem_req_o = 1'b0;
        mem_ack_o = 1'b0;
        csrr_o = 1'b0;
        csrw_o = 1'b0;
        wb_o = 1'b0;
      end

      FSM_IF0: begin
        if (fetch_req_i) begin
          fsm_n = FSM_IF1;
        end else begin
          fsm_n = FSM_IF0;
        end

        fetch_o = 1'b1;
        inst_o = 1'b0;
        decoder_o = 1'b0;
        alu_o = 1'b0;
        bru_o = 1'b0;
        mem_req_o = 1'b0;
        mem_ack_o = 1'b0;
        csrr_o = 1'b0;
        csrw_o = 1'b0;
        wb_o = 1'b0;
      end

      FSM_IF1: begin
        if (fetch_ack_i) begin
          fsm_n = FSM_ID;
        end else begin
          fsm_n = FSM_IF1;
        end

        fetch_o = 1'b0;
        inst_o = 1'b1;
        decoder_o = 1'b0;
        alu_o = 1'b0;
        bru_o = 1'b0;
        mem_req_o = 1'b0;
        mem_ack_o = 1'b0;
        csrr_o = 1'b0;
        csrw_o = 1'b0;
        wb_o = 1'b0;
      end

      FSM_ID: begin
        case (seq_i)
          SEQ_ALU: begin
            fsm_n = FSM_ALU;
          end
          SEQ_BRU: begin
            fsm_n = FSM_BRU;
          end
          SEQ_LSU: begin
            fsm_n = FSM_AG;
          end
          SEQ_CSR: begin
            if (CALF_CORE_CFG.EXT_ZICSR_USE) begin
              fsm_n = FSM_CSR;
            end else begin
              fsm_n = FSM_WB;
            end
          end
          default: begin
            fsm_n = FSM_WB;
          end
        endcase
        
        fetch_o = 1'b0;
        inst_o = 1'b0;
        decoder_o = 1'b1;
        alu_o = 1'b0;
        bru_o = 1'b0;
        mem_req_o = 1'b0;
        mem_ack_o = 1'b0;
        csrr_o = 1'b0;
        csrw_o = 1'b0;
        wb_o = 1'b0;
      end

      FSM_ALU: begin
        fsm_n = FSM_WB;

        fetch_o = 1'b0;
        inst_o = 1'b0;
        decoder_o = 1'b0;
        alu_o = 1'b1;
        bru_o = 1'b0;
        mem_req_o = 1'b0;
        mem_ack_o = 1'b0;
        csrr_o = 1'b0;
        csrw_o = 1'b0;
        wb_o = 1'b0;
      end

      FSM_BRU: begin
        fsm_n = FSM_WB;

        fetch_o = 1'b0;
        inst_o = 1'b0;
        decoder_o = 1'b0;
        alu_o = 1'b1;
        bru_o = 1'b1;
        mem_req_o = 1'b0;
        mem_ack_o = 1'b0;
        csrr_o = 1'b0;
        csrw_o = 1'b0;
        wb_o = 1'b0;
      end

      FSM_AG: begin
        fsm_n = FSM_MA0;

        fetch_o = 1'b0;
        inst_o = 1'b0;
        decoder_o = 1'b0;
        alu_o = 1'b1;
        bru_o = 1'b0;
        mem_req_o = 1'b1;
        mem_ack_o = 1'b0;
        csrr_o = 1'b0;
        csrw_o = 1'b0;
        wb_o = 1'b0;
      end

      FSM_MA0: begin
        if (mem_req_i) begin
          fsm_n = FSM_MA1;
        end else begin
          fsm_n = FSM_MA0;
        end

        fetch_o = 1'b0;
        inst_o = 1'b0;
        decoder_o = 1'b0;
        alu_o = 1'b0;
        bru_o = 1'b0;
        mem_req_o = 1'b1;
        mem_ack_o = 1'b0;
        csrr_o = 1'b0;
        csrw_o = 1'b0;
        wb_o = 1'b0;
      end

      FSM_MA1: begin
        if (mem_ack_i) begin
          fsm_n = FSM_WB;
        end else begin
          fsm_n = FSM_MA1;
        end

        fetch_o = 1'b0;
        inst_o = 1'b0;
        decoder_o = 1'b0;
        alu_o = 1'b0;
        bru_o = 1'b0;
        mem_req_o = 1'b0;
        mem_ack_o = 1'b1;
        csrr_o = 1'b0;
        csrw_o = 1'b0;
        wb_o = 1'b0;
      end

      FSM_CSR: begin
        fsm_n = FSM_WB;

        fetch_o = 1'b0;
        inst_o = 1'b0;
        decoder_o = 1'b0;
        alu_o = 1'b0;
        bru_o = 1'b0;
        mem_req_o = 1'b0;
        mem_ack_o = 1'b0;
        csrr_o = 1'b1;
        csrw_o = 1'b0;
        wb_o = 1'b0;
      end

      FSM_WB: begin
        fsm_n = FSM_IF0;

        fetch_o = 1'b0;
        inst_o = 1'b0;
        decoder_o = 1'b0;
        alu_o = 1'b0;
        bru_o = 1'b0;
        mem_req_o = 1'b0;
        mem_ack_o = 1'b0;
        csrr_o = 1'b0;
        csrw_o = 1'b0;
        wb_o = 1'b1;
      end

      default: begin
        fsm_n = FSM_IF0;

        fetch_o = 1'b0;
        inst_o = 1'b0;
        decoder_o = 1'b0;
        alu_o = 1'b0;
        bru_o = 1'b0;
        mem_req_o = 1'b0;
        mem_ack_o = 1'b0;
        csrr_o = 1'b0;
        csrw_o = 1'b0;
        wb_o = 1'b0;
      end
    endcase
  end

// *****************************************************************************
// * REGISTER
// *****************************************************************************
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      fsm_r <= FSM_BOOT;
    end else begin
      fsm_r <= fsm_n;
    end
  end
endmodule
