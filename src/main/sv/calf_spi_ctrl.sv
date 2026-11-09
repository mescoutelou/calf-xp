/*
 * File: calf_spi_ctrl.sv                                                      *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-07 11:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-07 08:22:15 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: SPI master, one 8-bit full-duplex transfer at a time, MSB      *
 * first, modes 0 to 3 (CPOL / CPHA). SCLK toggles every clk_div_i cycles      *
 * (0 counts as 2^CLK_DIV_BIT_N, like baud_div_i in calf_uart_tx).             *
 */


module calf_spi_ctrl
// *****************************************************************************
// * PACKAGE
// *****************************************************************************

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter int   CLK_DIV_BIT_N = 16
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic                       clk_i,
    input logic                       rst_i,

    input logic [CLK_DIV_BIT_N - 1:0] clk_div_i,
    input logic                       cpol_i,
    input logic                       cpha_i,

    output logic                      tx_ready_o,
    input logic                       tx_valid_i,
    input logic [7:0]                 tx_data_i,

    output logic                      rx_valid_o,
    output logic [7:0]                rx_data_o,

    output logic                      sclk_o,
    output logic                      mosi_o,
    input logic                       miso_i
  );

// *****************************************************************************
// * ENUMERATE
// *****************************************************************************
  typedef enum logic [1:0] {
    FSM_IDLE,
    FSM_DATA,
    FSM_DONE
  } fsm_e;

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  fsm_e fsm_r, fsm_n;
  logic [CLK_DIV_BIT_N - 1:0] clk_div_r, clk_div_n;
  logic cpha_r, cpha_n;
  logic [CLK_DIV_BIT_N - 1:0] clk_cnt_r, clk_cnt_n;
  logic [3:0] edge_cnt_r, edge_cnt_n;
  logic [7:0] tx_r, tx_n;
  logic [7:0] rx_r, rx_n;
  logic sclk_r, sclk_n;

  logic sample_w;
  logic shift_w;

// *****************************************************************************
// * EDGE
// *****************************************************************************
  // Edges are numbered from 0 to 15: even edges are leading, odd edges are
  // trailing. MISO is sampled on leading edges in CPHA = 0, on trailing edges
  // in CPHA = 1. MOSI moves on the other edges, except before the first bit
  // (already on MOSI when CPHA = 0) and after the last one.
  always_comb begin
    sample_w = (edge_cnt_r[0] == cpha_r);
    shift_w = (edge_cnt_r[0] != cpha_r) && (edge_cnt_r != 4'h0) && (edge_cnt_r != 4'hf);
  end

// *****************************************************************************
// * FSM
// *****************************************************************************
  always_comb begin
    tx_ready_o = (fsm_r == FSM_IDLE);
  end

  always_comb begin
    fsm_n = fsm_r;
    clk_div_n = clk_div_r;
    cpha_n = cpha_r;
    clk_cnt_n = clk_cnt_r;
    edge_cnt_n = edge_cnt_r;
    tx_n = tx_r;
    rx_n = rx_r;
    sclk_n = sclk_r;

    case (fsm_r)
      FSM_IDLE: begin
        sclk_n = cpol_i;

        if (tx_valid_i) begin
          fsm_n = FSM_DATA;
          clk_div_n = clk_div_i;
          cpha_n = cpha_i;
          clk_cnt_n = 'h0;
          edge_cnt_n = 'h0;
          tx_n = tx_data_i;
        end
      end

      FSM_DATA: begin
        if (clk_cnt_r == (clk_div_r - CLK_DIV_BIT_N'('h1))) begin
          clk_cnt_n = 'h0;
          edge_cnt_n = edge_cnt_r + 'h1;
          sclk_n = ~sclk_r;

          if (sample_w) begin
            rx_n = {rx_r[6:0], miso_i};
          end

          if (shift_w) begin
            tx_n = {tx_r[6:0], 1'b0};
          end

          if (edge_cnt_r == 4'hf) begin
            fsm_n = FSM_DONE;
          end
        end else begin
          clk_cnt_n = clk_cnt_r + 'h1;
        end
      end

      FSM_DONE: begin
        fsm_n = FSM_IDLE;
      end

      default: begin
        fsm_n = FSM_IDLE;
      end
    endcase
  end

// *****************************************************************************
// * RX
// *****************************************************************************
  always_comb begin
    rx_valid_o = (fsm_r == FSM_DONE);
    rx_data_o = rx_r;
  end

// *****************************************************************************
// * SPI
// *****************************************************************************
  always_comb begin
    sclk_o = sclk_r;
    mosi_o = tx_r[7];
  end

// *****************************************************************************
// * REGISTER
// *****************************************************************************
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      fsm_r <= FSM_IDLE;
      clk_div_r <= 'h0;
      cpha_r <= 1'b0;
      clk_cnt_r <= 'h0;
      edge_cnt_r <= 'h0;
      tx_r <= 'h0;
      rx_r <= 'h0;
      sclk_r <= 1'b0;
    end else begin
      fsm_r <= fsm_n;
      clk_div_r <= clk_div_n;
      cpha_r <= cpha_n;
      clk_cnt_r <= clk_cnt_n;
      edge_cnt_r <= edge_cnt_n;
      tx_r <= tx_n;
      rx_r <= rx_n;
      sclk_r <= sclk_n;
    end
  end
endmodule
