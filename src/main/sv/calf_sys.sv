/*
 * File: calf_sys.sv                                                           *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-01 11:45:53 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-06 05:35:18 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: CALF system: core, UART bootloader, address decoding and       *
 * peripherals (RAM, GPIO A, UART 0, SPI 0, KEY 0). Board-independent: pads,   *
 * clocks and FPGA primitives belong to the board top.                         *
 */


module calf_sys
// *****************************************************************************
// * PACKAGE
// *****************************************************************************
  import calf_addr_pkg::*;
  import calf_sys_pkg::*;

// *****************************************************************************
// * PARAMETER
// *****************************************************************************
  #(
    parameter calf_sys_usr_t                          CALF_SYS_USR = CALF_SYS_USR_DEFAULT,

    localparam calf_sys_cfg_t                         CALF_SYS_CFG = calf_sys_cfg_f(CALF_SYS_USR),
    localparam logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0]  RAM_BASE = RAM_ADDR_BASE[CALF_SYS_CFG.ADDR_BIT_N - 1:0],
    localparam logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0]  RAM_SIZE = CALF_SYS_CFG.RAM_ADDR_SIZE[CALF_SYS_CFG.ADDR_BIT_N - 1:0],
    localparam logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0]  GPIO_A_BASE = GPIO_A_ADDR_BASE[CALF_SYS_CFG.ADDR_BIT_N - 1:0],
    localparam logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0]  GPIO_SIZE = GPIO_ADDR_SIZE[CALF_SYS_CFG.ADDR_BIT_N - 1:0],
    localparam logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0]  UART_0_BASE = UART_0_ADDR_BASE[CALF_SYS_CFG.ADDR_BIT_N - 1:0],
    localparam logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0]  UART_SIZE = UART_ADDR_SIZE[CALF_SYS_CFG.ADDR_BIT_N - 1:0],
    localparam logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0]  SPI_0_BASE = SPI_0_ADDR_BASE[CALF_SYS_CFG.ADDR_BIT_N - 1:0],
    localparam logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0]  SPI_SIZE = SPI_ADDR_SIZE[CALF_SYS_CFG.ADDR_BIT_N - 1:0],
    localparam logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0]  KEY_0_BASE = KEY_0_ADDR_BASE[CALF_SYS_CFG.ADDR_BIT_N - 1:0],
    localparam logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0]  KEY_SIZE = KEY_ADDR_SIZE[CALF_SYS_CFG.ADDR_BIT_N - 1:0]
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

    input logic         uart_rx_i,
    output logic        uart_tx_o,

    output logic        spi_cs_n_o,
    output logic        spi_sclk_o,
    output logic        spi_mosi_o,
    input logic         spi_miso_i
  );

// *****************************************************************************
// * STRUCTURE
// *****************************************************************************

// *****************************************************************************
// * DECLARATION
// *****************************************************************************
  logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0] addr_r, addr_n;
  logic void_rready_r, void_rready_n;

  logic boot_w;
  logic boot_rx_valid_w;
  logic [7:0] boot_rx_data_w;
  logic boot_tx_ready_w;
  logic boot_tx_valid_w;
  logic [7:0] boot_tx_data_w;
  logic boot_ready_w;
  logic boot_valid_w;
  logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0] boot_addr_w;
  logic [CALF_SYS_CFG.DATA_BYTE_N - 1:0] boot_wmask_w;
  logic [CALF_SYS_CFG.DATA_BIT_N - 1:0] boot_wdata_w;
  logic boot_rready_w;
  logic [CALF_SYS_CFG.DATA_BIT_N - 1:0] boot_rdata_w;

  logic vslct_ram_w;
  logic vslct_gpio_a_w;
  logic vslct_uart_0_w;
  logic vslct_spi_0_w;
  logic vslct_key_0_w;
  logic vslct_void_w;
  logic rslct_ram_w;
  logic rslct_gpio_a_w;
  logic rslct_uart_0_w;
  logic rslct_spi_0_w;
  logic rslct_key_0_w;
  logic unused_rslct_void_w;

  logic core_ready_w;
  logic core_valid_w;
  logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0] core_addr_w;
  logic [CALF_SYS_CFG.DATA_BYTE_N - 1:0] core_wmask_w;
  logic [CALF_SYS_CFG.DATA_BIT_N - 1:0] core_wdata_w;
  logic core_rready_w;
  logic [CALF_SYS_CFG.DATA_BIT_N - 1:0] core_rdata_w;
  logic bus_ready_w;
  logic bus_valid_w;
  logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0] bus_addr_w;
  logic [CALF_SYS_CFG.DATA_BYTE_N - 1:0] bus_wmask_w;
  logic [CALF_SYS_CFG.DATA_BIT_N - 1:0] bus_wdata_w;
  logic bus_rready_w;
  logic [CALF_SYS_CFG.DATA_BIT_N - 1:0] bus_rdata_w;
  logic ram_ready_w;
  logic ram_valid_w;
  logic ram_rready_w;
  logic [CALF_SYS_CFG.DATA_BIT_N - 1:0] ram_rdata_w;
  logic [CALF_SYS_CFG.ADDR_BIT_N - 1:0] ram_addr_w;
  logic uart_0_ready_w;
  logic uart_0_valid_w;
  logic uart_0_rready_w;
  logic [CALF_SYS_CFG.DATA_BIT_N - 1:0] uart_0_rdata_w;
  logic gpio_a_ready_w;
  logic gpio_a_valid_w;
  logic gpio_a_rready_w;
  logic [CALF_SYS_CFG.DATA_BIT_N - 1:0] gpio_a_rdata_w;
  logic spi_0_ready_w;
  logic spi_0_valid_w;
  logic spi_0_rready_w;
  logic [CALF_SYS_CFG.DATA_BIT_N - 1:0] spi_0_rdata_w;
  logic key_0_ready_w;
  logic key_0_valid_w;
  logic key_0_rready_w;
  logic [CALF_SYS_CFG.DATA_BIT_N - 1:0] key_0_rdata_w;

// *****************************************************************************
// * BOOTLOADER
// *****************************************************************************
  calf_bootloader #(
    .ADDR_BIT_N     (CALF_SYS_CFG.ADDR_BIT_N),
    .DATA_BIT_N     (CALF_SYS_CFG.DATA_BIT_N)
  ) bootloader_m (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .boot_mode_i    (boot_mode_i),
    .boot_o         (boot_w),
    .rx_valid_i     (boot_rx_valid_w),
    .rx_data_i      (boot_rx_data_w),
    .tx_ready_i     (boot_tx_ready_w),
    .tx_valid_o     (boot_tx_valid_w),
    .tx_data_o      (boot_tx_data_w),
    .mem_ready_i    (boot_ready_w),
    .mem_valid_o    (boot_valid_w),
    .mem_addr_o     (boot_addr_w),
    .mem_wmask_o    (boot_wmask_w),
    .mem_wdata_o    (boot_wdata_w),
    .mem_rready_i   (boot_rready_w),
    .mem_rdata_i    (boot_rdata_w)
  );

// *****************************************************************************
// * CORE
// *****************************************************************************
  localparam calf_core_pkg::calf_core_usr_t CORE_USR = '{
    EXT_E_USE:        CALF_SYS_CFG.CORE_EXT_E_USE,
    EXT_ZICSR_USE:    CALF_SYS_CFG.CORE_EXT_ZICSR_USE,
    EXT_ZICNTR_USE:   CALF_SYS_CFG.CORE_EXT_ZICNTR_USE,
    EXT_ZBS_USE:      CALF_SYS_CFG.CORE_EXT_ZBS_USE,
    PC_BOOT:          CALF_SYS_CFG.CORE_PC_BOOT,
    INST_REG_USE:     CALF_SYS_CFG.CORE_INST_REG_USE,
    CACHE_USE:        CALF_SYS_CFG.CORE_CACHE_USE,
    CACHE_BEAT_N:     CALF_SYS_CFG.CORE_CACHE_BEAT_N,
    CACHE_WAY_N:      CALF_SYS_CFG.CORE_CACHE_WAY_N,
    CACHE_SET_N:      CALF_SYS_CFG.CORE_CACHE_SET_N,
    CACHE_ADDR_BASE:  (ADDR_BIT_N_MAX)'(CACHEABLE_ADDR_BASE),
    CACHE_ADDR_SIZE:  (ADDR_BIT_N_MAX)'(CACHEABLE_ADDR_SIZE)
  };

  calf_core #(
    .CALF_CORE_USR  (CORE_USR)
  ) core_m (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .boot_i         (boot_w),
    .mem_ready_i    (core_ready_w),
    .mem_valid_o    (core_valid_w),
    .mem_addr_o     (core_addr_w),
    .mem_wmask_o    (core_wmask_w),
    .mem_wdata_o    (core_wdata_w),
    .mem_rready_i   (core_rready_w),
    .mem_rdata_i    (core_rdata_w)
  );

// *****************************************************************************
// * INITIATOR
// *****************************************************************************
  always_comb begin
    if (boot_w) begin
      bus_valid_w = boot_valid_w;
      bus_addr_w = boot_addr_w;
      bus_wmask_w = boot_wmask_w;
      bus_wdata_w = boot_wdata_w;
    end else begin
      bus_valid_w = core_valid_w;
      bus_addr_w = core_addr_w;
      bus_wmask_w = core_wmask_w;
      bus_wdata_w = core_wdata_w;
    end

    core_ready_w = bus_ready_w && !boot_w;
    core_rready_w = bus_rready_w && !boot_w;
    core_rdata_w = bus_rdata_w;
    boot_ready_w = bus_ready_w && boot_w;
    boot_rready_w = bus_rready_w && boot_w;
    boot_rdata_w = bus_rdata_w;
  end

// *****************************************************************************
// * SELECT
// *****************************************************************************

  always_comb begin
    vslct_ram_w = (bus_addr_w >= RAM_BASE) && (bus_addr_w < RAM_BASE + RAM_SIZE);
    ram_valid_w = bus_valid_w && vslct_ram_w;
    
    vslct_gpio_a_w = (bus_addr_w >= GPIO_A_BASE) && (bus_addr_w < GPIO_A_BASE + GPIO_SIZE);
    gpio_a_valid_w = bus_valid_w && vslct_gpio_a_w;
    
    vslct_uart_0_w = (bus_addr_w >= UART_0_BASE) && (bus_addr_w < UART_0_BASE + UART_SIZE);
    uart_0_valid_w = bus_valid_w && vslct_uart_0_w;

    vslct_spi_0_w = (bus_addr_w >= SPI_0_BASE) && (bus_addr_w < SPI_0_BASE + SPI_SIZE);
    spi_0_valid_w = bus_valid_w && vslct_spi_0_w;

    vslct_key_0_w = (bus_addr_w >= KEY_0_BASE) && (bus_addr_w < KEY_0_BASE + KEY_SIZE);
    key_0_valid_w = bus_valid_w && vslct_key_0_w;

    vslct_void_w = !vslct_ram_w && !vslct_gpio_a_w && !vslct_uart_0_w && !vslct_spi_0_w && !vslct_key_0_w;

    if (vslct_ram_w) begin
      bus_ready_w = ram_ready_w;
    end else if (vslct_gpio_a_w) begin
      bus_ready_w = gpio_a_ready_w;
    end else if (vslct_uart_0_w) begin
      bus_ready_w = uart_0_ready_w;
    end else if (vslct_spi_0_w) begin
      bus_ready_w = spi_0_ready_w;
    end else if (vslct_key_0_w) begin
      bus_ready_w = key_0_ready_w;
    end else begin
      bus_ready_w = 1'b1;
    end
  end

  // Response routing uses the address of the last accepted request. Reads
  // outside the address map are answered with zero one cycle later.
  always_comb begin
    if (bus_valid_w && bus_ready_w) begin
      addr_n = bus_addr_w;
    end else begin
      addr_n = addr_r;
    end

    void_rready_n = bus_valid_w && bus_ready_w && vslct_void_w && (bus_wmask_w == 'h0);
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      addr_r <= 'h0;
      void_rready_r <= 1'b0;
    end else begin
      addr_r <= addr_n;
      void_rready_r <= void_rready_n;
    end
  end

  always_comb begin
    rslct_ram_w = (addr_r >= RAM_BASE) && (addr_r < RAM_BASE + RAM_SIZE);
    rslct_gpio_a_w = (addr_r >= GPIO_A_BASE) && (addr_r < GPIO_A_BASE + GPIO_SIZE);
    rslct_uart_0_w = (addr_r >= UART_0_BASE) && (addr_r < UART_0_BASE + UART_SIZE);
    rslct_spi_0_w = (addr_r >= SPI_0_BASE) && (addr_r < SPI_0_BASE + SPI_SIZE);
    rslct_key_0_w = (addr_r >= KEY_0_BASE) && (addr_r < KEY_0_BASE + KEY_SIZE);
    unused_rslct_void_w = !rslct_ram_w && !rslct_gpio_a_w && !rslct_uart_0_w && !rslct_spi_0_w && !rslct_key_0_w;

    if (rslct_ram_w) begin
      bus_rready_w = ram_rready_w;
      bus_rdata_w = ram_rdata_w;
    end else if (rslct_gpio_a_w) begin
      bus_rready_w = gpio_a_rready_w;
      bus_rdata_w = gpio_a_rdata_w;
    end else if (rslct_uart_0_w) begin
      bus_rready_w = uart_0_rready_w;
      bus_rdata_w = uart_0_rdata_w;
    end else if (rslct_spi_0_w) begin
      bus_rready_w = spi_0_rready_w;
      bus_rdata_w = spi_0_rdata_w;
    end else if (rslct_key_0_w) begin
      bus_rready_w = key_0_rready_w;
      bus_rdata_w = key_0_rdata_w;
    end else begin
      bus_rready_w = void_rready_r;
      bus_rdata_w = 'h0;
    end
  end

// *****************************************************************************
// * MEMORY
// *****************************************************************************
  always_comb begin
    ram_addr_w = bus_addr_w - RAM_BASE;
  end

  calf_ram #(
    .RAM_FILE       (string'(CALF_SYS_CFG.RAM_FILE)),
    .RAM_DATA_N     (CALF_SYS_CFG.RAM_DATA_N),
    .DATA_BYTE_N    (CALF_SYS_CFG.DATA_BYTE_N),
    .PORT_N         (1)
  ) ram_m (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .mem_ready_o    ({ram_ready_w}),
    .mem_valid_i    ({ram_valid_w}),
    .mem_addr_i     ({ram_addr_w[$clog2(CALF_SYS_CFG.RAM_DATA_N) + CALF_SYS_CFG.DATA_BYTE_N_BIT - 1: CALF_SYS_CFG.DATA_BYTE_N_BIT]}),
    .mem_wmask_i    ({bus_wmask_w}),
    .mem_wdata_i    ({bus_wdata_w}),
    .mem_rready_o   ({ram_rready_w}),
    .mem_rdata_o    ({ram_rdata_w})
  );

// *****************************************************************************
// * GPIO
// *****************************************************************************
  calf_gpio #(
    .DATA_BIT_N     (CALF_SYS_CFG.DATA_BIT_N)
  ) gpio_a_m (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .mem_ready_o    (gpio_a_ready_w),
    .mem_valid_i    (gpio_a_valid_w),
    .mem_addr_i     (bus_addr_w[GPIO_ADDR_N_BIT - 1:0]),
    .mem_wmask_i    (bus_wmask_w),
    .mem_wdata_i    (bus_wdata_w),
    .mem_rready_o   (gpio_a_rready_w),
    .mem_rdata_o    (gpio_a_rdata_w),
    .eno_o          (gpio_eno_o),
    .in_i           (gpio_in_i),
    .out_o          (gpio_out_o)
  );

// *****************************************************************************
// * UART
// *****************************************************************************
  calf_uart #(
    .DATA_BIT_N       (CALF_SYS_CFG.DATA_BIT_N),
    .BAUD_BIT_N       (CALF_SYS_CFG.UART_BAUD_BIT_N),
    .BAUD_INIT_N      (CALF_SYS_CFG.UART_BAUD_INIT_N)
  ) uart_0_m (
    .clk_i            (clk_i),
    .rst_i            (rst_i),
    .boot_i           (boot_w),
    .boot_rx_valid_o  (boot_rx_valid_w),
    .boot_rx_data_o   (boot_rx_data_w),
    .boot_tx_ready_o  (boot_tx_ready_w),
    .boot_tx_valid_i  (boot_tx_valid_w),
    .boot_tx_data_i   (boot_tx_data_w),
    .mem_ready_o      (uart_0_ready_w),
    .mem_valid_i      (uart_0_valid_w),
    .mem_addr_i       (bus_addr_w[UART_ADDR_N_BIT - 1:0]),
    .mem_wmask_i      (bus_wmask_w),
    .mem_wdata_i      (bus_wdata_w),
    .mem_rready_o     (uart_0_rready_w),
    .mem_rdata_o      (uart_0_rdata_w),
    .rx_i             (uart_rx_i),
    .tx_o             (uart_tx_o)
  );

// *****************************************************************************
// * SPI
// *****************************************************************************
  calf_spi #(
    .DATA_BIT_N       (CALF_SYS_CFG.DATA_BIT_N),
    .CLK_DIV_BIT_N    (CALF_SYS_CFG.SPI_CLK_DIV_BIT_N),
    .CLK_DIV_INIT_N   (CALF_SYS_CFG.SPI_CLK_DIV_INIT_N)
  ) spi_0_m (
    .clk_i            (clk_i),
    .rst_i            (rst_i),
    .mem_ready_o      (spi_0_ready_w),
    .mem_valid_i      (spi_0_valid_w),
    .mem_addr_i       (bus_addr_w[SPI_ADDR_N_BIT - 1:0]),
    .mem_wmask_i      (bus_wmask_w),
    .mem_wdata_i      (bus_wdata_w),
    .mem_rready_o     (spi_0_rready_w),
    .mem_rdata_o      (spi_0_rdata_w),
    .cs_n_o           (spi_cs_n_o),
    .sclk_o           (spi_sclk_o),
    .mosi_o           (spi_mosi_o),
    .miso_i           (spi_miso_i)
  );

// *****************************************************************************
// * KEY
// *****************************************************************************
  calf_key #(
    .DATA_BIT_N       (CALF_SYS_CFG.DATA_BIT_N),
    .KEY              (CALF_SYS_CFG.KEY[CALF_SYS_CFG.DATA_BIT_N - 1:0])
  ) key_0_m (
    .clk_i            (clk_i),
    .rst_i            (rst_i),
    .mem_ready_o      (key_0_ready_w),
    .mem_valid_i      (key_0_valid_w),
    .mem_addr_i       (bus_addr_w[KEY_ADDR_N_BIT - 1:0]),
    .mem_wmask_i      (bus_wmask_w),
    .mem_wdata_i      (bus_wdata_w),
    .mem_rready_o     (key_0_rready_w),
    .mem_rdata_o      (key_0_rdata_w)
  );
endmodule
