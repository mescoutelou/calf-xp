/*
 * File: calf_uart_tx.sv                                                       *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 12:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-07 10:35:16 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: UART transmitter (8N1, LSB first): one byte per valid/ready    *
 * handshake, baud_div_i cycles per bit, registered output.                    *
 */


module calf_uart_tx
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
    output logic                    ready_o,
    input logic                     valid_i,
    input logic [7:0]               data_i,

    output logic                    tx_o
  );

// *****************************************************************************
// * ENUMERATE
// *****************************************************************************
  typedef enum logic [1:0] {
    FSM_IDLE,
    FSM_START,
    FSM_DATA,
    FSM_STOP
  } fsm_e;

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  fsm_e fsm_r, fsm_n;
  logic [BAUD_BIT_N - 1:0] baud_div_r, baud_div_n;
  logic [7:0] data_r, data_n;
  logic [BAUD_BIT_N - 1:0] baud_cnt_r, baud_cnt_n;
  logic [2:0] bit_cnt_r, bit_cnt_n;
  logic tx_r, tx_n;

// *****************************************************************************
// * FSM
// *****************************************************************************
  always_comb begin
    ready_o = (fsm_r == FSM_IDLE);
  end

  always_comb begin
    fsm_n = fsm_r;
    baud_div_n = baud_div_r;
    data_n = data_r;
    baud_cnt_n = baud_cnt_r;
    bit_cnt_n = bit_cnt_r;
    tx_n = tx_r;

    case (fsm_r)
      FSM_IDLE: begin
        tx_n = 1'b1;
  
        if (valid_i) begin
          fsm_n = FSM_START;
          baud_div_n = baud_div_i;
          data_n = data_i;
          baud_cnt_n = 'h0;
          bit_cnt_n = 'h0;
        end
      end

      FSM_START: begin
        tx_n = 1'b0;
  
        if (baud_cnt_r == (baud_div_r - BAUD_BIT_N'('h1))) begin
          fsm_n = FSM_DATA;
          baud_cnt_n = 'h0;
          bit_cnt_n = 'h0;
        end else begin
          baud_cnt_n = baud_cnt_r + 'h1;
        end
      end

      FSM_DATA: begin
        tx_n = data_r[bit_cnt_r];
        
        if (baud_cnt_r == (baud_div_r - BAUD_BIT_N'('h1))) begin
          if (bit_cnt_r == 'h7) begin
            fsm_n = FSM_STOP;
            baud_cnt_n = 'h0;
          end else begin
            baud_cnt_n = 'h0;
            bit_cnt_n = bit_cnt_r + 'h1;
          end
        end else begin
          baud_cnt_n = baud_cnt_r + 'h1;
        end
      end

      FSM_STOP: begin
        tx_n = 1'b1;
  
        if (baud_cnt_r == (baud_div_r - BAUD_BIT_N'('h1))) begin
          fsm_n = FSM_IDLE;
          baud_cnt_n = 'h0;
        end else begin
          baud_cnt_n = baud_cnt_r + 'h1;
        end
      end

      default: begin
        fsm_n = FSM_IDLE;
      end
    endcase
  end

// *****************************************************************************
// * TX
// *****************************************************************************
  always_comb begin
    tx_o = tx_r;
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
      tx_r <= 1'b1;
    end else begin
      fsm_r <= fsm_n;
      baud_div_r <= baud_div_n;
      data_r <= data_n;
      baud_cnt_r <= baud_cnt_n;
      bit_cnt_r <= bit_cnt_n;
      tx_r <= tx_n;
    end
  end
endmodule
