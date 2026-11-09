/*
 * File: hw.h                                                                  *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-11-04 02:40:00 pm                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-05 07:00:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Hardware of the experiments on calf_cw312_a7_35t: clock        *
 * frequency, RAM, GPIO A, UART 0 and KEY 0 registers (calf_addr_pkg.sv).      *
 * CLK_FREQ must match the HS2 frequency set by the host                       *
 * (implem/xilinx/src/cw312_a7_35t.py).                                        *
 */


#ifndef __HW_H__
#define __HW_H__

#include <stdint.h>

// ******************************************************************************
// * INFORMATION
// ******************************************************************************
// Frequency
#define CLK_FREQ        25000000

// ******************************************************************************
// * MEMORY MAPPING
// ******************************************************************************
// RAM (calf_sys_pkg.sv: 0x1000 words)
#define RAM_BASE        0x00000000
#define RAM_SIZE        0x00004000

// GPIO A registers
#define GPIO_A_BASE     0x10000000
#define GPIO_A_ENO      (*(volatile uint32_t *) (GPIO_A_BASE + 0x00))
#define GPIO_A_IN       (*(volatile uint32_t *) (GPIO_A_BASE + 0x04))
#define GPIO_A_OUT      (*(volatile uint32_t *) (GPIO_A_BASE + 0x08))

// UART 0 registers
#define UART_0_BASE     0x10000100
#define UART_0_BAUD_DIV (*(volatile uint32_t *) (UART_0_BASE + 0x04))
#define UART_0_STATUS   (*(volatile uint32_t *) (UART_0_BASE + 0x08))
#define UART_0_RX_DATA  (*(volatile uint32_t *) (UART_0_BASE + 0x10))
#define UART_0_TX_DATA  (*(volatile uint32_t *) (UART_0_BASE + 0x14))

// KEY 0 register: read-only, value set when the bitstream is built
#define KEY_0_BASE      0x10000300
#define KEY_0_DATA      (*(volatile uint32_t *) (KEY_0_BASE + 0x00))

#endif /* __HW_H__ */
