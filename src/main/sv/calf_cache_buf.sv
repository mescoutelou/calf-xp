/*
 * File: calf_cache_buf.sv                                                     *
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
 * Description: CALF cache buffer: tags and valid bits in registers            *
 * (combinational hit), data array with registered read. Allocates on refill,  *
 * round-robin per set.                                                        *
 */


module calf_cache_buf
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

    input logic                                       ctrl_valid_i,
    input logic                                       ctrl_fill_i,
    input logic [CALF_CACHE_CFG.TAG_BIT_N - 1:0]      ctrl_tag_i,
    input logic [CALF_CACHE_CFG.SET_N_BIT - 1:0]      ctrl_set_i,
    input logic [CALF_CACHE_CFG.BEAT_N_BIT - 1:0]     ctrl_beat_i,
    input logic [CALF_CACHE_CFG.DATA_BYTE_N - 1:0]    ctrl_wmask_i,
    input logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]     ctrl_wdata_i,
    output logic                                      ctrl_hit_o,
    output logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0]    ctrl_rdata_o
  );

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0] mem_r [CALF_CACHE_CFG.SET_N * CALF_CACHE_CFG.WAY_N * CALF_CACHE_CFG.BEAT_N - 1:0];
  logic [CALF_CACHE_CFG.SET_N - 1:0][CALF_CACHE_CFG.WAY_N - 1:0] en_r, en_n;
  logic [CALF_CACHE_CFG.SET_N - 1:0][CALF_CACHE_CFG.WAY_N - 1:0][CALF_CACHE_CFG.TAG_BIT_N - 1:0] tag_r, tag_n;
  logic [CALF_CACHE_CFG.SET_N - 1:0][CALF_CACHE_CFG.WAY_N_BIT - 1:0] rep_r, rep_n;
  logic [CALF_CACHE_CFG.DATA_BIT_N - 1:0] rdata_r;

  logic hit_valid_w;
  logic [CALF_CACHE_CFG.WAY_N_BIT - 1:0] hit_way_w;
  logic [CALF_CACHE_CFG.WAY_N_BIT - 1:0] way_w;

// *****************************************************************************
// * HIT
// *****************************************************************************
// -----------------------------------------------------------------------------
// - CHECK
// -----------------------------------------------------------------------------
  always_comb begin
    hit_valid_w = 1'b0;
    hit_way_w = 'h0;

    for (int w = 0; w < CALF_CACHE_CFG.WAY_N; w++) begin
      if (en_r[ctrl_set_i][w] && (tag_r[ctrl_set_i][w] == ctrl_tag_i)) begin
        hit_valid_w = 1'b1;
        hit_way_w = (CALF_CACHE_CFG.WAY_N_BIT)'(w);
      end
    end
  end

// -----------------------------------------------------------------------------
// - WRITE
// -----------------------------------------------------------------------------
  always_comb begin
    way_w = hit_valid_w ? hit_way_w : rep_r[ctrl_set_i];
  end

  always_ff @(posedge clk_i) begin
    if (!rst_i) begin
      for (int b = 0; b < CALF_CACHE_CFG.DATA_BYTE_N; b = b + 1) begin
        if (ctrl_valid_i && (ctrl_wmask_i[b] || ctrl_fill_i)) begin
          mem_r[{ctrl_set_i, way_w, ctrl_beat_i}][b*8 +: 8] <= ctrl_wdata_i[b*8 +: 8];
        end
      end
    end
  end

// -----------------------------------------------------------------------------
// - READ
// -----------------------------------------------------------------------------
  always_comb begin
    ctrl_hit_o = hit_valid_w && ctrl_valid_i && !ctrl_fill_i;
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      rdata_r <= 'h0;
    end else begin
      rdata_r <= mem_r[{ctrl_set_i, hit_way_w, ctrl_beat_i}];
    end
  end

  always_comb begin
    ctrl_rdata_o = rdata_r;
  end

// *****************************************************************************
// * FILL
// *****************************************************************************
  always_comb begin
    en_n = en_r;
    tag_n = tag_r;
    rep_n = rep_r;

    if (ctrl_valid_i && ctrl_fill_i && !hit_valid_w) begin
      en_n[ctrl_set_i][rep_r[ctrl_set_i]] = 1'b1;
      tag_n[ctrl_set_i][rep_r[ctrl_set_i]] = ctrl_tag_i;

      if (rep_r[ctrl_set_i] == (CALF_CACHE_CFG.WAY_N_BIT)'(CALF_CACHE_CFG.WAY_N - 1)) begin
        rep_n[ctrl_set_i] = 'h0;
      end else begin
        rep_n[ctrl_set_i] = rep_r[ctrl_set_i] + 1;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      for (int s = 0; s < CALF_CACHE_CFG.SET_N; s = s + 1) begin
        for (int w = 0; w < CALF_CACHE_CFG.WAY_N; w = w + 1) begin
          en_r[s][w] <= 1'b0;
        end
        rep_r[s] <= 'h0;
      end
    end else begin
      en_r <= en_n;
      tag_r <= tag_n;
      rep_r <= rep_n;
    end
  end
endmodule
