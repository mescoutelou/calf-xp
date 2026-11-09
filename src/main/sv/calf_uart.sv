/*
 * File: calf_uart.sv                                                          *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 12:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-07 05:43:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Memory-mapped UART (8N1): BAUD_DIV, STATUS, RX_DATA, TX_DATA   *
 * registers. While boot_i is set, RX/TX go to the bootloader. BAUD_INIT_N is  *
 * the reset value of BAUD_DIV (5208 = 50MHz / 9600 baud).                     *
 */ 


module calf_uart
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_addr_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter int   DATA_BIT_N = 32,
    parameter int   BAUD_BIT_N = 16,
    parameter int   BAUD_INIT_N = 5208,

    localparam int  DATA_BYTE_N = DATA_BIT_N / 8
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic                         clk_i,
    input logic                         rst_i,

    input logic                         boot_i,
    output logic                        boot_rx_valid_o,
    output logic [7:0]                  boot_rx_data_o,
    output logic                        boot_tx_ready_o,
    input logic                         boot_tx_valid_i,
    input logic [7:0]                   boot_tx_data_i,

    output logic                        mem_ready_o,
    input logic                         mem_valid_i,
    input logic [UART_ADDR_N_BIT - 1:0] mem_addr_i,
    input logic [DATA_BYTE_N - 1:0]     mem_wmask_i,
    input logic [DATA_BIT_N - 1:0]      mem_wdata_i,
    output logic                        mem_rready_o,
    output logic [DATA_BIT_N - 1:0]     mem_rdata_o,

    input logic                         rx_i,
    output logic                        tx_o
  );

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic [BAUD_BIT_N - 1:0] baud_div_r, baud_div_n;
  logic rready_r, rready_n;
  logic [DATA_BIT_N - 1:0] rdata_r, rdata_n;
  logic rx_valid_r, rx_valid_n;
  logic [7:0] rx_data_r, rx_data_n;

  logic rx_valid_w;
  logic [7:0] rx_data_w;
  logic tx_ready_w;
  logic tx_valid_w;
  logic [7:0] tx_data_w;

// *****************************************************************************
// * READ
// *****************************************************************************
  always_comb begin
    rready_n = mem_valid_i && (mem_wmask_i == 'h0);
    case (mem_addr_i)
      UART_ADDR_OFFSET_CONFIG: begin
        rdata_n = 'h0;
      end
      UART_ADDR_OFFSET_BAUD_DIV: begin
        rdata_n = {{(DATA_BIT_N - BAUD_BIT_N){1'b0}}, baud_div_r};
      end
      UART_ADDR_OFFSET_STATUS: begin
        rdata_n = {{(DATA_BIT_N - 2){1'b0}}, tx_ready_w, rx_valid_r};
      end
      UART_ADDR_OFFSET_RX_DATA: begin
        rdata_n = {{(DATA_BIT_N - 8){1'b0}}, rx_data_r};
      end
      default: begin
        rdata_n = 'h0;
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      rready_r <= 1'b0;
      rdata_r <= 'h0;
    end else begin
      rready_r <= rready_n;
      rdata_r <= rdata_n;
    end
  end

  always_comb begin
    mem_ready_o = 1'b1;
    mem_rready_o = rready_r;
    mem_rdata_o = rdata_r;
  end

// *****************************************************************************
// * WRITE
// *****************************************************************************
  always_comb begin
    baud_div_n = baud_div_r;

    if (mem_valid_i) begin
      case (mem_addr_i)
        UART_ADDR_OFFSET_BAUD_DIV: begin
          for (int db = 0; db < (BAUD_BIT_N / 8); db = db + 1) begin
            if (mem_wmask_i[db]) begin
              baud_div_n[db*8 +: 8] = mem_wdata_i[db*8 +: 8];
            end
          end
        end

        default: begin
          
        end
      endcase
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      baud_div_r <= BAUD_BIT_N'(BAUD_INIT_N);
    end else begin
      baud_div_r <= baud_div_n;
    end
  end

// *****************************************************************************
// * RX
// *****************************************************************************
  calf_uart_rx #(
    .BAUD_BIT_N (BAUD_BIT_N)
  ) rx_m (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .baud_div_i (baud_div_r),
    .rx_i       (rx_i),
    .valid_o    (rx_valid_w),
    .data_o     (rx_data_w)
  );

  always_comb begin
    rx_valid_n = rx_valid_r;
    rx_data_n = rx_data_r;

    if (mem_valid_i && (mem_addr_i == UART_ADDR_OFFSET_RX_DATA) && (mem_wmask_i == 'h0)) begin
      rx_valid_n = 1'b0;
    end

    if (rx_valid_w && !boot_i) begin
      rx_valid_n = 1'b1;
      rx_data_n = rx_data_w;
    end
  end

  always_comb begin
    boot_rx_valid_o = rx_valid_w && boot_i;
    boot_rx_data_o = rx_data_w;
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      rx_valid_r <= 1'b0;
      rx_data_r <= 'h0;
    end else begin
      rx_valid_r <= rx_valid_n;
      rx_data_r <= rx_data_n;
    end
  end

// *****************************************************************************
// * TX
// *****************************************************************************
  always_comb begin
    boot_tx_ready_o = tx_ready_w;
  end

  always_comb begin
    if (boot_i) begin
      tx_valid_w = boot_tx_valid_i;
      tx_data_w = boot_tx_data_i;
    end else if (mem_valid_i && (mem_addr_i == UART_ADDR_OFFSET_TX_DATA) && (mem_wmask_i != 'h0)) begin
      tx_valid_w = 1'b1;
      tx_data_w = mem_wdata_i[7:0];
    end else begin
      tx_valid_w = 1'b0;
      tx_data_w = 'h0;
    end
  end

  calf_uart_tx #(
    .BAUD_BIT_N (BAUD_BIT_N)
  ) tx_m (
    .clk_i      (clk_i),
    .rst_i      (rst_i),
    .baud_div_i (baud_div_r),
    .tx_o       (tx_o),
    .ready_o    (tx_ready_w),
    .valid_i    (tx_valid_w),
    .data_i     (tx_data_w)
  );
endmodule
