/*
 * File: calf_uart_rx.sv                                                       *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 12:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-07 10:35:20 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: UART receiver (8N1): 2-flop input synchronizer, start bit      *
 * checked at its middle, data bits sampled every baud_div_i cycles. Stop bit  *
 * not checked.                                                                *
 */


module calf_uart_rx
// *****************************************************************************
// * PACKAGE
// *****************************************************************************

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter int   BAUD_BIT_N = 16
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic                     clk_i,
    input logic                     rst_i,
    
    input logic [BAUD_BIT_N - 1:0]  baud_div_i,
    output logic                    valid_o,
    output logic [7:0]              data_o,

    input logic                     rx_i
  );

// *****************************************************************************
// * ENUMERATE
// *****************************************************************************
  typedef enum logic [2:0] {
    FSM_IDLE,
    FSM_START,
    FSM_DATA,
    FSM_STOP,
    FSM_SEND
  } fsm_e;

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  fsm_e fsm_r, fsm_n;
  logic [BAUD_BIT_N - 1:0] baud_div_r, baud_div_n;
  logic [7:0] data_r, data_n;
  logic [BAUD_BIT_N - 1:0] baud_cnt_r, baud_cnt_n;
  logic [2:0] bit_cnt_r, bit_cnt_n;
  logic [1:0] rx_r, rx_n;

// *****************************************************************************
// * FSM
// *****************************************************************************
  always_comb begin
    fsm_n = fsm_r;
    baud_div_n = baud_div_r;
    data_n = data_r;
    baud_cnt_n = baud_cnt_r;
    bit_cnt_n = bit_cnt_r;

    case (fsm_r)
      FSM_IDLE: begin
        if (rx_r[1] == 1'b0) begin
          fsm_n = FSM_START;
          baud_div_n = baud_div_i;
          data_n = 'h0;
          baud_cnt_n = 'h0;
          bit_cnt_n = 'h0;
        end
      end

      FSM_START: begin
        if (baud_cnt_r == (baud_div_r >> 1)) begin
          baud_cnt_n = 'h0;
          bit_cnt_n = 'h0;
  
          if (rx_r[1] == 1'b0) begin
            fsm_n = FSM_DATA;
          end else begin
            fsm_n = FSM_IDLE;
          end
        end else begin
          baud_cnt_n = baud_cnt_r + 'h1;
        end
      end

      FSM_DATA: begin
        if (baud_cnt_r == (baud_div_r - BAUD_BIT_N'('h1))) begin
          baud_cnt_n = 'h0;
          data_n[bit_cnt_r] = rx_r[1];
  
          if (bit_cnt_r == 3'h7) begin
            fsm_n = FSM_STOP;
            bit_cnt_n = 'h0;
          end else begin
            bit_cnt_n = bit_cnt_r + 'h1;
          end
        end else begin
          baud_cnt_n = baud_cnt_r + 'h1;
        end
      end

      FSM_STOP: begin
        if (baud_cnt_r == (baud_div_r - BAUD_BIT_N'('h1))) begin
          baud_cnt_n = 'h0;
          fsm_n = FSM_SEND;
        end else begin
          baud_cnt_n = baud_cnt_r + 'h1;
        end
      end

      FSM_SEND: begin
        fsm_n = FSM_IDLE;
      end

      default: begin
        fsm_n = FSM_IDLE;
      end
    endcase
  end

  always_comb begin
    valid_o = (fsm_r == FSM_SEND);
    data_o = data_r;
  end

// *****************************************************************************
// * RX
// *****************************************************************************
  always_comb begin
    rx_n[0] = rx_i;
    rx_n[1] = rx_r[0];
  end

// *****************************************************************************
// * REGISTER
// *****************************************************************************
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      fsm_r <= FSM_IDLE;
      baud_div_r <= 'h0;
      data_r <= 'h0;
      baud_cnt_r <= 'h0;
      bit_cnt_r <= 'h0;
      rx_r <= 2'b11;
    end else begin
      fsm_r <= fsm_n;
      baud_div_r <= baud_div_n;
      data_r <= data_n;
      baud_cnt_r <= baud_cnt_n;
      bit_cnt_r <= bit_cnt_n;
      rx_r <= rx_n;
    end
  end
endmodule
