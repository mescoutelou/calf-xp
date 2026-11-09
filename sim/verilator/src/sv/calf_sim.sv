/*
 * File: calf_sim.sv                                                           *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-08 09:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-05 05:00:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Verilator top: calf_sys with a short UART bit period, a host   *
 * UART (calf_uart_tx/rx, driven by sim.cpp with byte handshakes), and         *
 * internal signals exported for sim.cpp (bootloader state, end detection,     *
 * final state). The general-purpose registers are also copied one by one,     *
 * with their ABI name (x0_zero to x31_t6), for the waveforms. The SPI MISO is *
 * tied low.                                                                   *
 */


module calf_sim
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_sys_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter int   BAUD_DIV = 8
  )

// *****************************************************************************
// * INTERFACE
// *****************************************************************************
  (
    input logic         clk_i,
    input logic         rst_i,

    input logic         boot_mode_i,

    output logic [7:0]  gpio_eno_o,
    input logic [7:0]   gpio_in_i,
    output logic [7:0]  gpio_out_o,

    output logic        host_tx_ready_o,
    input logic         host_tx_valid_i,
    input logic [7:0]   host_tx_data_i,
    output logic        host_rx_valid_o,
    output logic [7:0]  host_rx_data_o,

    output logic        boot_o,
    output logic        halt_o,
    output logic [31:0] pc_o,
    output logic [31:0] a0_o,
    output logic [63:0] instret_o
  );

// *****************************************************************************
// * CONFIGURATION
// *****************************************************************************
  function automatic calf_sys_usr_t usr_f();
    calf_sys_usr_t u = CALF_SYS_USR_DEFAULT;
    u.UART_BAUD_INIT_N = BAUD_DIV;
    return u;
  endfunction

  localparam calf_sys_usr_t USR = usr_f();
  localparam int BAUD_BIT_N = USR.UART_BAUD_BIT_N;

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic uart_rx_w;
  logic uart_tx_w;

  // Registers by name, for the waveforms (sim/verilator/calf.gtkw)
  logic [31:0][31:0] gpr_w;
  logic [31:0] x0_zero;
  logic [31:0] x1_ra;
  logic [31:0] x2_sp;
  logic [31:0] x3_gp;
  logic [31:0] x4_tp;
  logic [31:0] x5_t0;
  logic [31:0] x6_t1;
  logic [31:0] x7_t2;
  logic [31:0] x8_s0;
  logic [31:0] x9_s1;
  logic [31:0] x10_a0;
  logic [31:0] x11_a1;
  logic [31:0] x12_a2;
  logic [31:0] x13_a3;
  logic [31:0] x14_a4;
  logic [31:0] x15_a5;
  logic [31:0] x16_a6;
  logic [31:0] x17_a7;
  logic [31:0] x18_s2;
  logic [31:0] x19_s3;
  logic [31:0] x20_s4;
  logic [31:0] x21_s5;
  logic [31:0] x22_s6;
  logic [31:0] x23_s7;
  logic [31:0] x24_s8;
  logic [31:0] x25_s9;
  logic [31:0] x26_s10;
  logic [31:0] x27_s11;
  logic [31:0] x28_t3;
  logic [31:0] x29_t4;
  logic [31:0] x30_t5;
  logic [31:0] x31_t6;

// *****************************************************************************
// * SYSTEM
// *****************************************************************************
  calf_sys #(
    .CALF_SYS_USR (USR)
  ) sys_m (
    .clk_i        (clk_i),
    .rst_i        (rst_i),
    .boot_mode_i  (boot_mode_i),
    .gpio_eno_o   (gpio_eno_o),
    .gpio_in_i    (gpio_in_i),
    .gpio_out_o   (gpio_out_o),
    .uart_rx_i    (uart_rx_w),
    .uart_tx_o    (uart_tx_w),
    .spi_cs_n_o   (),
    .spi_sclk_o   (),
    .spi_mosi_o   (),
    .spi_miso_i   (1'b0)
  );

// *****************************************************************************
// * HOST UART
// *****************************************************************************
  calf_uart_tx #(
    .BAUD_BIT_N   (BAUD_BIT_N)
  ) host_tx_m (
    .clk_i        (clk_i),
    .rst_i        (rst_i),
    .baud_div_i   (BAUD_BIT_N'(BAUD_DIV)),
    .ready_o      (host_tx_ready_o),
    .valid_i      (host_tx_valid_i),
    .data_i       (host_tx_data_i),
    .tx_o         (uart_rx_w)
  );

  calf_uart_rx #(
    .BAUD_BIT_N   (BAUD_BIT_N)
  ) host_rx_m (
    .clk_i        (clk_i),
    .rst_i        (rst_i),
    .baud_div_i   (BAUD_BIT_N'(BAUD_DIV)),
    .valid_o      (host_rx_valid_o),
    .data_o       (host_rx_data_o),
    .rx_i         (uart_tx_w)
  );

// *****************************************************************************
// * PROBE
// *****************************************************************************
  always_comb begin
    boot_o = sys_m.boot_w;
    // "j ." : a taken jump whose target is its own PC
    halt_o = sys_m.core_m.exec_m.fsm_wb_w && sys_m.core_m.exec_m.br_r && (sys_m.core_m.exec_m.s2_pc_r == sys_m.core_m.exec_m.pc_r);
    pc_o = sys_m.core_m.exec_m.pc_r;
    a0_o = sys_m.core_m.exec_m.gpr_m.data_r[10];
    instret_o = sys_m.core_m.exec_m.csr_m.instret_r;
  end

  // 16 registers with the E extension: the others stay at 0. x0 reads as 0,
  // whatever is written in data_r[0].
  always_comb begin
    gpr_w = 1024'(sys_m.core_m.exec_m.gpr_m.data_r);

    x0_zero = 32'h0;
    x1_ra = gpr_w[1];
    x2_sp = gpr_w[2];
    x3_gp = gpr_w[3];
    x4_tp = gpr_w[4];
    x5_t0 = gpr_w[5];
    x6_t1 = gpr_w[6];
    x7_t2 = gpr_w[7];
    x8_s0 = gpr_w[8];
    x9_s1 = gpr_w[9];
    x10_a0 = gpr_w[10];
    x11_a1 = gpr_w[11];
    x12_a2 = gpr_w[12];
    x13_a3 = gpr_w[13];
    x14_a4 = gpr_w[14];
    x15_a5 = gpr_w[15];
    x16_a6 = gpr_w[16];
    x17_a7 = gpr_w[17];
    x18_s2 = gpr_w[18];
    x19_s3 = gpr_w[19];
    x20_s4 = gpr_w[20];
    x21_s5 = gpr_w[21];
    x22_s6 = gpr_w[22];
    x23_s7 = gpr_w[23];
    x24_s8 = gpr_w[24];
    x25_s9 = gpr_w[25];
    x26_s10 = gpr_w[26];
    x27_s11 = gpr_w[27];
    x28_t3 = gpr_w[28];
    x29_t4 = gpr_w[29];
    x30_t5 = gpr_w[30];
    x31_t6 = gpr_w[31];
  end

endmodule
