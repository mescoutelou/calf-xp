###
 # File: cw312_a7_35t.xdc                                                      #
 # License: See LICENSE file                                                   #
 # Copyright (c) 2026 HerdWare                                                 #
 # -----                                                                       #
 # Created On: 2026-10-20 10:05:57 am                                          #
 # Initial Author: Mathieu Escouteloup                                         #
 # Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       #
 # -----                                                                       #
 # Last Updated On: 2026-10-20 10:08:31 am                                     #
 # Update Author: Mathieu Escouteloup                                          #
 # Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        #
 # -----                                                                       #
 # Description: Pin and clock constraints of calf_cw312_a7_35t.                #
###


# ******************************************************************************
# * I/O
# ******************************************************************************
# ------------------------------------------------------------------------------
# - USED
# ------------------------------------------------------------------------------
## Clock (HS2 from the ChipWhisperer)
set_property -dict { PACKAGE_PIN D15   IOSTANDARD LVCMOS33 } [get_ports { clk_hs2_i }];

## Reset (nRST from the ChipWhisperer)
set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports { rst_n_i }];

## LEDs
set_property -dict { PACKAGE_PIN R1    IOSTANDARD LVCMOS33 DRIVE 8 } [get_ports { led_o[0] }];
set_property -dict { PACKAGE_PIN V2    IOSTANDARD LVCMOS33 DRIVE 8 } [get_ports { led_o[1] }];
set_property -dict { PACKAGE_PIN V5    IOSTANDARD LVCMOS33 DRIVE 8 } [get_ports { led_o[2] }];

## UART (IO1 = TX, IO2 = RX)
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports { uart_tx_o }];
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports { uart_rx_i }];

## GPIO (IO3)
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { gpio_o }];

## Trigger (IO4)
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { trigger_o }];

# ------------------------------------------------------------------------------
# - UNUSED
# ------------------------------------------------------------------------------

# ******************************************************************************
# * CLOCK
# ******************************************************************************
# HS2 frequency is set by the ChipWhisperer: constrain on the highest one used
create_clock -add -name CLK_HS2 -period 40.00 -waveform {0 20} [get_ports { clk_hs2_i }];

# ******************************************************************************
# * CONFIGURATION
# ******************************************************************************
set_property CFGBVS VCCO [current_design];
set_property CONFIG_VOLTAGE 3.3 [current_design];

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design];
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design];
