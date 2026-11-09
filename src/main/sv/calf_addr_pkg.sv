/*
 * File: calf_addr_pkg.sv                                                      *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 12:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-09 02:32:38 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Address map of the system: base addresses of the RAM and       *
 * peripherals, size and register offsets of each peripheral.                  *
 */


package calf_addr_pkg;
// *****************************************************************************
// * GLOBAL
// *****************************************************************************
  localparam int ADDR_BIT_N_MAX = 64;
  localparam logic [ADDR_BIT_N_MAX - 1:0] RAM_ADDR_BASE = 'h0000_0000_0000_0000;
  localparam logic [ADDR_BIT_N_MAX - 1:0] GPIO_A_ADDR_BASE = 'h0000_0000_1000_0000;
  localparam logic [ADDR_BIT_N_MAX - 1:0] UART_0_ADDR_BASE = 'h0000_0000_1000_0100;
  localparam logic [ADDR_BIT_N_MAX - 1:0] SPI_0_ADDR_BASE = 'h0000_0000_1000_0200;
  localparam logic [ADDR_BIT_N_MAX - 1:0] KEY_0_ADDR_BASE = 'h0000_0000_1000_0300;

  localparam int CACHEABLE_ADDR_BASE = 'h0000_0000_0000_0000;
  localparam int CACHEABLE_ADDR_SIZE = 'h0000_0000_1000_0000;

// *****************************************************************************
// * GPIO
// *****************************************************************************
  localparam int GPIO_ADDR_SIZE = 'h10;
  localparam int GPIO_ADDR_N_BIT = $clog2(GPIO_ADDR_SIZE);
  localparam logic [GPIO_ADDR_N_BIT - 1:0] GPIO_ADDR_OFFSET_ENO = 'h00;
  localparam logic [GPIO_ADDR_N_BIT - 1:0] GPIO_ADDR_OFFSET_IN = 'h04;
  localparam logic [GPIO_ADDR_N_BIT - 1:0] GPIO_ADDR_OFFSET_OUT = 'h08;

// *****************************************************************************
// * UART
// *****************************************************************************
  localparam int UART_ADDR_SIZE = 'h20;
  localparam int UART_ADDR_N_BIT = $clog2(UART_ADDR_SIZE);
  localparam logic [UART_ADDR_N_BIT - 1:0] UART_ADDR_OFFSET_CONFIG = 'h00;
  localparam logic [UART_ADDR_N_BIT - 1:0] UART_ADDR_OFFSET_BAUD_DIV = 'h04;
  localparam logic [UART_ADDR_N_BIT - 1:0] UART_ADDR_OFFSET_STATUS = 'h08;
  localparam logic [UART_ADDR_N_BIT - 1:0] UART_ADDR_OFFSET_RX_DATA = 'h10;
  localparam logic [UART_ADDR_N_BIT - 1:0] UART_ADDR_OFFSET_TX_DATA = 'h14;

// *****************************************************************************
// * SPI
// *****************************************************************************
  localparam int SPI_ADDR_SIZE = 'h20;
  localparam int SPI_ADDR_N_BIT = $clog2(SPI_ADDR_SIZE);
  localparam logic [SPI_ADDR_N_BIT - 1:0] SPI_ADDR_OFFSET_CONFIG = 'h00;
  localparam logic [SPI_ADDR_N_BIT - 1:0] SPI_ADDR_OFFSET_CLK_DIV = 'h04;
  localparam logic [SPI_ADDR_N_BIT - 1:0] SPI_ADDR_OFFSET_STATUS = 'h08;
  localparam logic [SPI_ADDR_N_BIT - 1:0] SPI_ADDR_OFFSET_RX_DATA = 'h10;
  localparam logic [SPI_ADDR_N_BIT - 1:0] SPI_ADDR_OFFSET_TX_DATA = 'h14;

// *****************************************************************************
// * KEY
// *****************************************************************************
  localparam int KEY_ADDR_SIZE = 'h10;
  localparam int KEY_ADDR_N_BIT = $clog2(KEY_ADDR_SIZE);
  localparam logic [KEY_ADDR_N_BIT - 1:0] KEY_ADDR_OFFSET_DATA = 'h00;
endpackage
