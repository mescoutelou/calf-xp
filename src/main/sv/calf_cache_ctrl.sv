/*
 * File: calf_cache_ctrl.sv                                                    *
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
 * Description: CALF cache controller: lookup on core request, line refill     *
 * from memory beat by beat, write-through of stores. Requests on valid/ready, *
 * rready for read data only.                                                  *
 */


module calf_cache_ctrl
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_cache_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter calf_cache_usr_t  CALF_CACHE_USR = CALF_CACHE_USR_DEFAULT,

    localparam calf_cache_cfg_t CALF_CACHE_CFG = calf_cache_cfg_f(CALF_CACHE_USR)
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic                                       clk_i,
    input logic                                       rst_i,

    output logic                                      core_ready_o,
    input logic                                       core_valid_i,
    input logic [CALF_CACHE_CFG.ADDR_BIT_N - 1:0]     core_addr_i,
    input logic [CALF_CACHE_CFG.DATA_BYTE_N - 1:0]    core_wmask_i,
    input logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]     core_wdata_i,
    output logic                                      core_rready_o,
    output logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]    core_rdata_o,

    output logic                                      buf_valid_o,
    output logic                                      buf_fill_o,
    output logic [CALF_CACHE_CFG.TAG_BIT_N - 1:0]     buf_tag_o,
    output logic [CALF_CACHE_CFG.SET_N_BIT - 1:0]     buf_set_o,
    output logic [CALF_CACHE_CFG.BEAT_N_BIT - 1:0]    buf_beat_o,
    output logic [CALF_CACHE_CFG.DATA_BYTE_N - 1:0]   buf_wmask_o,
    output logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]    buf_wdata_o,
    input logic                                       buf_hit_i,
    input logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]     buf_rdata_i,

    input logic                                       mem_ready_i,
    output logic                                      mem_valid_o,
    output logic [CALF_CACHE_CFG.ADDR_BIT_N - 1:0]    mem_addr_o,
    output logic [CALF_CACHE_CFG.DATA_BYTE_N - 1:0]   mem_wmask_o,
    output logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]    mem_wdata_o,
    input logic                                       mem_rready_i,
    input logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]     mem_rdata_i
  );

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
fsm_e fsm_r, fsm_n;
logic [CALF_CACHE_CFG.OFFSET_BIT_N - 1:0] offset_r, offset_n;
logic [CALF_CACHE_CFG.BEAT_N_BIT - 1:0] beat_r, beat_n;
logic [CALF_CACHE_CFG.SET_N_BIT - 1:0] set_r, set_n;
logic [CALF_CACHE_CFG.TAG_BIT_N - 1:0] tag_r, tag_n;
logic [CALF_CACHE_CFG.DATA_BYTE_N - 1:0] wmask_r, wmask_n;
logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0] wdata_r, wdata_n;
logic [CALF_CACHE_CFG.BEAT_N_BIT:0] req_bcnt_r, req_bcnt_n;
logic [CALF_CACHE_CFG.BEAT_N_BIT:0] ack_bcnt_r, ack_bcnt_n;

// *****************************************************************************
// * FSM
// *****************************************************************************
  always_comb begin
    fsm_n = fsm_r;
    offset_n = offset_r;
    beat_n = beat_r;
    set_n = set_r;
    tag_n = tag_r;
    wmask_n = wmask_r;
    wdata_n = wdata_r;

    case (fsm_r)
      FSM_IDLE: begin
        if (core_valid_i) begin
          if (buf_hit_i) begin
            if (core_wmask_i != 'h0) begin
              fsm_n = FSM_WRITE;
            end else begin
              fsm_n = FSM_HIT;
            end
          end else begin
            fsm_n = FSM_MISS;
          end
          tag_n = core_addr_i[CALF_CACHE_CFG.ADDR_BIT_N - 1:CALF_CACHE_CFG.ADDR_BIT_N - CALF_CACHE_CFG.TAG_BIT_N];
          set_n = core_addr_i[CALF_CACHE_CFG.ADDR_BIT_N - CALF_CACHE_CFG.TAG_BIT_N - 1:CALF_CACHE_CFG.ADDR_BIT_N - CALF_CACHE_CFG.TAG_BIT_N - CALF_CACHE_CFG.SET_N_BIT];
          beat_n = core_addr_i[CALF_CACHE_CFG.OFFSET_BIT_N + CALF_CACHE_CFG.BEAT_N_BIT - 1:CALF_CACHE_CFG.OFFSET_BIT_N];
          offset_n = core_addr_i[CALF_CACHE_CFG.OFFSET_BIT_N - 1:0];
          wmask_n = core_wmask_i;
          wdata_n = core_wdata_i;
        end
      end
      FSM_HIT: begin
        if (wmask_r != 'h0) begin
          fsm_n = FSM_WRITE;
        end else begin
          fsm_n = FSM_IDLE;
        end
      end
      FSM_MISS: begin
        if ((req_bcnt_r == (CALF_CACHE_CFG.BEAT_N_BIT + 1)'(CALF_CACHE_CFG.BEAT_N)) && (ack_bcnt_r == (CALF_CACHE_CFG.BEAT_N_BIT + 1)'(CALF_CACHE_CFG.BEAT_N))) begin
          fsm_n = FSM_REPLAY;
        end
      end
      FSM_REPLAY: begin
        if (buf_hit_i) begin
          if (wmask_r != 'h0) begin
            fsm_n = FSM_WRITE;
          end else begin
            fsm_n = FSM_HIT;
          end
        end else begin
          fsm_n = FSM_MISS;
        end
      end
      FSM_WRITE: begin
        if (mem_ready_i) begin
          fsm_n = FSM_IDLE;
        end
      end
      default: begin
        fsm_n = FSM_IDLE;
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      fsm_r <= FSM_IDLE;
      offset_r <= 'h0;
      beat_r <= 'h0;
      set_r <= 'h0;
      tag_r <= 'h0;
      wmask_r <= 'h0;
      wdata_r <= 'h0;
    end else begin
      fsm_r <= fsm_n;
      offset_r <= offset_n;
      beat_r <= beat_n;
      set_r <= set_n;
      tag_r <= tag_n;
      wmask_r <= wmask_n;
      wdata_r <= wdata_n;
    end
  end

// *****************************************************************************
// * CORE
// *****************************************************************************
  always_comb begin
    core_ready_o = (fsm_r == FSM_IDLE);
  end
  
  always_comb begin
    if (fsm_r == FSM_HIT) begin
      core_rready_o = (wmask_r == 'h0);
      core_rdata_o = buf_rdata_i;
    end else begin
      core_rready_o = 1'b0;
      core_rdata_o = 'h0;
    end
  end

// *****************************************************************************
// * MEMORY
// *****************************************************************************
  always_comb begin
    if (fsm_r == FSM_MISS) begin
      mem_valid_o = (req_bcnt_r < (CALF_CACHE_CFG.BEAT_N_BIT + 1)'(CALF_CACHE_CFG.BEAT_N));
      mem_addr_o = {tag_r, set_r, req_bcnt_r[CALF_CACHE_CFG.BEAT_N_BIT - 1:0], offset_r};
      mem_wmask_o = 'h0;
      mem_wdata_o = 'h0;
    end else if (fsm_r == FSM_WRITE) begin
      mem_valid_o = 1'b1;
      mem_addr_o = {tag_r, set_r, beat_r, offset_r};
      mem_wmask_o = wmask_r;
      mem_wdata_o = wdata_r;
    end else begin
      mem_valid_o = 1'b0;
      mem_addr_o = 'h0;
      mem_wmask_o = 'h0;
      mem_wdata_o = 'h0;
    end
  end

  always_comb begin
    if (fsm_r == FSM_MISS) begin
      if ((req_bcnt_r < (CALF_CACHE_CFG.BEAT_N_BIT + 1)'(CALF_CACHE_CFG.BEAT_N)) && mem_ready_i) begin
        req_bcnt_n = req_bcnt_r + 'h1;
      end else begin
        req_bcnt_n = req_bcnt_r;
      end

      if ((ack_bcnt_r < (CALF_CACHE_CFG.BEAT_N_BIT + 1)'(CALF_CACHE_CFG.BEAT_N)) && mem_rready_i) begin
        ack_bcnt_n = ack_bcnt_r + 'h1;
      end else begin
        ack_bcnt_n = ack_bcnt_r;
      end
    end else begin
      req_bcnt_n = 'h0;
      ack_bcnt_n = 'h0;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      req_bcnt_r <= 'h0;
      ack_bcnt_r <= 'h0;
    end else begin
      req_bcnt_r <= req_bcnt_n;
      ack_bcnt_r <= ack_bcnt_n;
    end
  end

// *****************************************************************************
// * BUFFER
// *****************************************************************************
  always_comb begin
    if (fsm_r == FSM_IDLE) begin
      buf_valid_o = core_valid_i;
      buf_fill_o = 1'b0;
      buf_tag_o = core_addr_i[CALF_CACHE_CFG.ADDR_BIT_N - 1:CALF_CACHE_CFG.ADDR_BIT_N - CALF_CACHE_CFG.TAG_BIT_N];
      buf_set_o = core_addr_i[CALF_CACHE_CFG.ADDR_BIT_N - CALF_CACHE_CFG.TAG_BIT_N - 1:CALF_CACHE_CFG.ADDR_BIT_N - CALF_CACHE_CFG.TAG_BIT_N - CALF_CACHE_CFG.SET_N_BIT];
      buf_beat_o = core_addr_i[CALF_CACHE_CFG.OFFSET_BIT_N + CALF_CACHE_CFG.BEAT_N_BIT - 1:CALF_CACHE_CFG.OFFSET_BIT_N];
      buf_wmask_o = core_wmask_i;
      buf_wdata_o = core_wdata_i;
    end else if (fsm_r == FSM_MISS) begin
      buf_valid_o = (ack_bcnt_r < (CALF_CACHE_CFG.BEAT_N_BIT + 1)'(CALF_CACHE_CFG.BEAT_N)) && mem_rready_i;
      buf_fill_o = 1'b1;
      buf_tag_o = tag_r;
      buf_set_o = set_r;
      buf_beat_o = ack_bcnt_r[CALF_CACHE_CFG.BEAT_N_BIT - 1:0];
      buf_wmask_o = {CALF_CACHE_CFG.DATA_BYTE_N{1'b1}};
      buf_wdata_o = mem_rdata_i;
    end else if (fsm_r == FSM_REPLAY) begin
      buf_valid_o = 1'b1;
      buf_fill_o = 1'b0;
      buf_tag_o = tag_r;
      buf_set_o = set_r;
      buf_beat_o = beat_r;
      buf_wmask_o = wmask_r;
      buf_wdata_o = wdata_r;
    end else begin
      buf_valid_o = 1'b0;
      buf_fill_o = 1'b0;
      buf_tag_o = 'h0;
      buf_set_o = 'h0;
      buf_beat_o = 'h0;
      buf_wmask_o = 'h0;
      buf_wdata_o = 'h0;
    end
  end
endmodule
