/*
 * File: calf_bootloader.sv                                                    *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-07 12:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-07 05:55:47 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description:                                                                *
 *   UART bootloader. Protocol (multi-byte fields are little-endian):          *
 *     NUM (1 byte): number of commands, 0 ends immediately                    *
 *     then NUM times CMD (1 byte):                                            *
 *       0x00 IDLE: nothing                                                    *
 *       0x01 INIT: ADDR, SIZE, then SIZE data bytes to write                  *
 *       0x02 PING: answers 0xAA                                               *
 *       0x03 DUMP: ADDR, SIZE, then answers SIZE read bytes                   *
 *       other: treated as IDLE                                                *
 *     ADDR is ADDR_BIT_N / 8 bytes, SIZE is DATA_BIT_N / 8 bytes.             *
 *   Bytes received while answering (DUMP, PING) are lost: the host must       *
 *   wait for the whole answer before sending the next command.                *
 *   The memory port follows the core convention: byte address, wmask/wdata    *
 *   shifted on the byte lane, full-word rdata.                                *
 *   boot_mode_i is sampled once, on the first clock edge after reset release: *
 *   it must be stable before reset is released (no resynchronization).        *
 */


module calf_bootloader
// *****************************************************************************
// * PACKAGE
// *****************************************************************************

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter int   ADDR_BIT_N = 32,
    parameter int   DATA_BIT_N = 32,

    localparam int  ADDR_BYTE_N = ADDR_BIT_N / 8,
    localparam int  DATA_BYTE_N = DATA_BIT_N / 8,
    localparam int  DATA_BYTE_N_BIT = $clog2(DATA_BYTE_N),
    localparam int  FIELD_BYTE_N = (ADDR_BYTE_N > DATA_BYTE_N) ? ADDR_BYTE_N : DATA_BYTE_N,
    localparam int  FIELD_BYTE_N_BIT = $clog2(FIELD_BYTE_N)
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic                      clk_i,
    input logic                      rst_i,

    input logic                      boot_mode_i,
    output logic                     boot_o,

    input logic                      rx_valid_i,
    input logic [7:0]                rx_data_i,
    input logic                      tx_ready_i,
    output logic                     tx_valid_o,
    output logic [7:0]               tx_data_o,

    input logic                      mem_ready_i,
    output logic                     mem_valid_o,
    output logic [ADDR_BIT_N - 1:0]  mem_addr_o,
    output logic [DATA_BYTE_N - 1:0] mem_wmask_o,
    output logic [DATA_BIT_N - 1:0]  mem_wdata_o,
    input logic                      mem_rready_i,
    input logic [DATA_BIT_N - 1:0]   mem_rdata_i
  );

// *****************************************************************************
// * ENUMERATE
// *****************************************************************************
  localparam logic [7:0] CMD_IDLE = 8'h00;
  localparam logic [7:0] CMD_INIT = 8'h01;
  localparam logic [7:0] CMD_PING = 8'h02;
  localparam logic [7:0] CMD_DUMP = 8'h03;

  localparam logic [7:0] PING_DATA = 8'hAA;

  typedef enum logic [3:0] {
    FSM_BOOT,
    FSM_NUM,
    FSM_CMD,
    FSM_ADDR,
    FSM_SIZE,
    FSM_WR_DATA,
    FSM_WR_REQ,
    FSM_RD_REQ,
    FSM_RD_ACK,
    FSM_RD_TX,
    FSM_PING,
    FSM_NEXT,
    FSM_WAIT,
    FSM_END
  } fsm_e;

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  fsm_e fsm_r, fsm_n;
  logic [7:0] num_r, num_n;
  logic [7:0] cmd_cnt_r, cmd_cnt_n;
  logic [7:0] cmd_r, cmd_n;
  logic [FIELD_BYTE_N_BIT - 1:0] field_cnt_r, field_cnt_n;
  logic [ADDR_BIT_N - 1:0] addr_r, addr_n;
  logic [DATA_BIT_N - 1:0] size_r, size_n;
  logic [7:0] data_r, data_n;

  logic [DATA_BYTE_N_BIT - 1:0] shift_w;

// *****************************************************************************
// * FSM
// *****************************************************************************
  always_comb begin
    fsm_n = fsm_r;
    num_n = num_r;
    cmd_cnt_n = cmd_cnt_r;
    cmd_n = cmd_r;
    field_cnt_n = field_cnt_r;
    addr_n = addr_r;
    size_n = size_r;
    data_n = data_r;

    case (fsm_r)
// -----------------------------------------------------------------------------
// - BOOT
// -----------------------------------------------------------------------------
      FSM_BOOT: begin
        cmd_cnt_n = 'h0;

        if (boot_mode_i) begin
          fsm_n = FSM_NUM;
        end else begin
          fsm_n = FSM_END;
        end
      end

// -----------------------------------------------------------------------------
// - NUMBER
// -----------------------------------------------------------------------------
      FSM_NUM: begin
        if (rx_valid_i) begin
          num_n = rx_data_i;

          if (rx_data_i == 'h0) begin
            fsm_n = FSM_END;
          end else begin
            fsm_n = FSM_CMD;
          end
        end
      end

// -----------------------------------------------------------------------------
// - COMMAND
// -----------------------------------------------------------------------------
      FSM_CMD: begin
        if (rx_valid_i) begin
          cmd_cnt_n = cmd_cnt_r + 'h1;
          cmd_n = rx_data_i;

          case (rx_data_i)
            CMD_INIT, CMD_DUMP: begin
              fsm_n = FSM_ADDR;
              field_cnt_n = 'h0;
              addr_n = 'h0;
              size_n = 'h0;
            end

            CMD_PING: begin
              fsm_n = FSM_PING;
            end

            default: begin
              fsm_n = FSM_NEXT;
            end
          endcase
        end
      end

// -----------------------------------------------------------------------------
// - ADDRESS & SIZE
// -----------------------------------------------------------------------------
      FSM_ADDR: begin
        if (rx_valid_i) begin
          addr_n[field_cnt_r * 8 +: 8] = rx_data_i;

          if (field_cnt_r == (FIELD_BYTE_N_BIT)'(ADDR_BYTE_N - 1)) begin
            fsm_n = FSM_SIZE;
            field_cnt_n = 'h0;
          end else begin
            field_cnt_n = field_cnt_r + 'h1;
          end
        end
      end

      FSM_SIZE: begin
        if (rx_valid_i) begin
          size_n[field_cnt_r * 8 +: 8] = rx_data_i;

          if (field_cnt_r == (FIELD_BYTE_N_BIT)'(DATA_BYTE_N - 1)) begin
            field_cnt_n = 'h0;

            if (size_n == 'h0) begin
              fsm_n = FSM_NEXT;
            end else if (cmd_r == CMD_INIT) begin
              fsm_n = FSM_WR_DATA;
            end else begin
              fsm_n = FSM_RD_REQ;
            end
          end else begin
            field_cnt_n = field_cnt_r + 'h1;
          end
        end
      end

// -----------------------------------------------------------------------------
// - WRITE
// -----------------------------------------------------------------------------
      FSM_WR_DATA: begin
        if (rx_valid_i) begin
          fsm_n = FSM_WR_REQ;
          data_n = rx_data_i;
        end
      end

      FSM_WR_REQ: begin
        if (mem_ready_i) begin
          addr_n = addr_r + 'h1;
          size_n = size_r - 'h1;

          if (size_r == 'h1) begin
            fsm_n = FSM_NEXT;
          end else begin
            fsm_n = FSM_WR_DATA;
          end
        end
      end

// -----------------------------------------------------------------------------
// - READ
// -----------------------------------------------------------------------------
      FSM_RD_REQ: begin
        if (mem_ready_i) begin
          fsm_n = FSM_RD_ACK;
        end
      end

      FSM_RD_ACK: begin
        if (mem_rready_i) begin
          fsm_n = FSM_RD_TX;
          data_n = 8'(mem_rdata_i >> {shift_w, 3'b000});
        end
      end

      FSM_RD_TX: begin
        if (tx_ready_i) begin
          addr_n = addr_r + 'h1;
          size_n = size_r - 'h1;

          if (size_r == 'h1) begin
            fsm_n = FSM_NEXT;
          end else begin
            fsm_n = FSM_RD_REQ;
          end
        end
      end

// -----------------------------------------------------------------------------
// - PING
// -----------------------------------------------------------------------------
      FSM_PING: begin
        if (tx_ready_i) begin
          fsm_n = FSM_NEXT;
        end
      end

// -----------------------------------------------------------------------------
// - NEXT
// -----------------------------------------------------------------------------
      FSM_NEXT: begin
        if (cmd_cnt_r == num_r) begin
          fsm_n = FSM_WAIT;
        end else begin
          fsm_n = FSM_CMD;
        end
      end

// -----------------------------------------------------------------------------
// - WAIT
// -----------------------------------------------------------------------------
      FSM_WAIT: begin
        if (tx_ready_i) begin
          fsm_n = FSM_END;
        end
      end

// -----------------------------------------------------------------------------
// - END
// -----------------------------------------------------------------------------
      FSM_END: begin

      end

      default: begin
        fsm_n = FSM_END;
      end
    endcase
  end

// *****************************************************************************
// * OUTPUT
// *****************************************************************************
  always_comb begin
    boot_o = (fsm_r != FSM_END);
  end

  always_comb begin
    case (fsm_r)
      FSM_RD_TX: begin
        tx_valid_o = 1'b1;
        tx_data_o = data_r;
      end

      FSM_PING: begin
        tx_valid_o = 1'b1;
        tx_data_o = PING_DATA;
      end

      default: begin
        tx_valid_o = 1'b0;
        tx_data_o = 'h0;
      end
    endcase
  end

// *****************************************************************************
// * MEMORY
// *****************************************************************************
  always_comb begin
    shift_w = addr_r[DATA_BYTE_N_BIT - 1:0];

    mem_valid_o = (fsm_r == FSM_WR_REQ) || (fsm_r == FSM_RD_REQ);
    mem_addr_o = addr_r;

    if (fsm_r == FSM_WR_REQ) begin
      mem_wmask_o = (DATA_BYTE_N)'('h1) << shift_w;
      mem_wdata_o = (DATA_BIT_N)'(data_r) << {shift_w, 3'b000};
    end else begin
      mem_wmask_o = 'h0;
      mem_wdata_o = 'h0;
    end
  end

// *****************************************************************************
// * REGISTER
// *****************************************************************************
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      fsm_r <= FSM_BOOT;
      num_r <= 'h0;
      cmd_cnt_r <= 'h0;
      cmd_r <= CMD_IDLE;
      field_cnt_r <= 'h0;
      addr_r <= 'h0;
      size_r <= 'h0;
      data_r <= 'h0;
    end else begin
      fsm_r <= fsm_n;
      num_r <= num_n;
      cmd_cnt_r <= cmd_cnt_n;
      cmd_r <= cmd_n;
      field_cnt_r <= field_cnt_n;
      addr_r <= addr_n;
      size_r <= size_n;
      data_r <= data_n;
    end
  end
endmodule
