/*
 * File: cw312_a7_35t.sv                                                       *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-20 09:56:18 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-05 07:00:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: ChipWhisperer CW312T-A35 (Artix-7 35T) board top for calf_sys. *
 *   Clock: HS2 from the ChipWhisperer, used directly as system clock (no      *
 *   MMCM, the core stays synchronous with the capture clock).                 *
 *   Reset: nRST from the ChipWhisperer, asserted asynchronously, released     *
 *   synchronously after RST_CYCLE_N cycles.                                   *
 *   Boot mode: BOOT_MODE parameter (1 = UART bootloader, 0 = RAM image).      *
 *   RAM image: RAM_FILE parameter (32-bit word hex file, objcopy -O verilog   *
 *   --verilog-data-width=4), when not empty (at most RAM_FILE_CHAR_N_MAX      *
 *   characters) it overrides CALF_SYS_USR.RAM_FILE.                           *
 *   Key: KEY parameter, value of the read-only KEY 0 register (calf_key).     *
 *   GPIO: bits 0-2 are LED 0-2, bit 3 is the trigger (IO4), bit 7 is IO3,     *
 *   each driven when its ENO bit is set. No input pad: GPIO pins read back    *
 *   their output value. LEDs are all on while nRST is low.                    *
 *   UART: IO1 (TX) / IO2 (RX). The baud rate is f(HS2) / UART_BAUD_INIT_N:    *
 *   adapt CALF_SYS_USR to the HS2 frequency set on the ChipWhisperer.         *
 *   SPI: no flash on the board, SPI 0 is left unconnected.                    *
 */


module calf_cw312_a7_35t
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_sys_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter calf_sys_usr_t                        CALF_SYS_USR = CALF_SYS_USR_DEFAULT,
    parameter int                                   RST_CYCLE_N = 64,
    parameter bit                                   BOOT_MODE = 1'b0,
    parameter logic [RAM_FILE_CHAR_N_MAX * 8 - 1:0] RAM_FILE = "",
    parameter logic [31:0]                          KEY = 'h0,

    localparam int                                  RST_CYCLE_BIT_N = $clog2(RST_CYCLE_N + 1)
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic         clk_hs2_i,
    input logic         rst_n_i,

    output logic [2:0]  led_o,
    output logic        trigger_o,
    output logic        gpio_o,

    input logic         uart_rx_i,
    output logic        uart_tx_o
  );

// *****************************************************************************
// * CONFIGURATION
// *****************************************************************************
  function automatic calf_sys_usr_t usr_f();
    calf_sys_usr_t u = CALF_SYS_USR;
    if (RAM_FILE != "") begin
      u.RAM_FILE = RAM_FILE;
    end
    u.KEY = KEY;
    return u;
  endfunction

  localparam calf_sys_usr_t USR = usr_f();

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic clk_w;

  logic [1:0] rst_sync_r;
  logic [RST_CYCLE_BIT_N - 1:0] rst_cnt_r;
  logic rst_w;

  logic [7:0] gpio_eno_w;
  logic [7:0] gpio_in_w;
  logic [7:0] gpio_out_w;
  logic [7:0] gpio_drv_w;

  logic unused_spi_cs_n_w;
  logic unused_spi_sclk_w;
  logic unused_spi_mosi_w;

// *****************************************************************************
// * CLOCK
// *****************************************************************************
  always_comb begin
    clk_w = clk_hs2_i;
  end

// *****************************************************************************
// * RESET
// *****************************************************************************
  // Asynchronous assertion, synchronous release: 2-flop synchronizer, then
  // RST_CYCLE_N cycles before the system leaves the reset.
  always_ff @(posedge clk_w, negedge rst_n_i) begin
    if (!rst_n_i) begin
      rst_sync_r <= 2'b00;
      rst_cnt_r <= RST_CYCLE_BIT_N'(RST_CYCLE_N);
    end else begin
      rst_sync_r <= {rst_sync_r[0], 1'b1};
      if (!rst_sync_r[1]) begin
        rst_cnt_r <= RST_CYCLE_BIT_N'(RST_CYCLE_N);
      end else if (rst_cnt_r != 'h0) begin
        rst_cnt_r <= rst_cnt_r - 'h1;
      end
    end
  end

  always_comb begin
    rst_w = (rst_cnt_r != 'h0);
  end

// *****************************************************************************
// * SYSTEM
// *****************************************************************************
  // BOOT_MODE is a constant: stable before the reset release by construction
  calf_sys #(
    .CALF_SYS_USR (USR)
  ) sys_m (
    .clk_i        (clk_w),
    .rst_i        (rst_w),
    .boot_mode_i  (BOOT_MODE),
    .gpio_eno_o   (gpio_eno_w),
    .gpio_in_i    (gpio_in_w),
    .gpio_out_o   (gpio_out_w),
    .uart_rx_i    (uart_rx_i),
    .uart_tx_o    (uart_tx_o),
    .spi_cs_n_o   (unused_spi_cs_n_w),
    .spi_sclk_o   (unused_spi_sclk_w),
    .spi_mosi_o   (unused_spi_mosi_w),
    .spi_miso_i   (1'b1)
  );

// *****************************************************************************
// * GPIO
// *****************************************************************************
  // No input pad: every pin reads back its driven value
  always_comb begin
    gpio_drv_w = gpio_eno_w & gpio_out_w;
    gpio_in_w = gpio_drv_w;
  end

  always_comb begin
    if (!rst_n_i) begin
      led_o = 3'b111;
    end else begin
      led_o = gpio_drv_w[2:0];
    end
  end

  always_comb begin
    trigger_o = gpio_drv_w[3];
    gpio_o = gpio_drv_w[7];
  end

endmodule
