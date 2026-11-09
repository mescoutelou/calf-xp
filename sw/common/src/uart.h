/*
 * File: uart.h                                                                *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-11-04 02:40:00 pm                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-05 11:00:00 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Polling functions of UART 0. UART_BAUD must match the baud     *
 * rate set by the host (implem/xilinx/src/cw312_a7_35t.py).                   *
 */


#ifndef __UART_H__
#define __UART_H__

#include <stdint.h>

#include "hw.h"

// ******************************************************************************
// * CONSTANT
// ******************************************************************************
#define UART_STATUS_RX_VALID  0x01
#define UART_STATUS_TX_READY  0x02

#define UART_BAUD       9600

// ******************************************************************************
// * FUNCTION
// ******************************************************************************
// Sets the baud rate, before any transfer. baud must be a constant: the core
// has no M extension and the program is not linked with libgcc, so the
// division is only possible at compile time.
static inline void uart_init(uint32_t baud) {
  UART_0_BAUD_DIV = CLK_FREQ / baud;
}

// The RX side holds one byte: a byte received before the previous one is read
// is lost.
static inline int uart_rx_valid(void) {
  return UART_0_STATUS & UART_STATUS_RX_VALID;
}

static inline uint8_t uart_read(void) {
  while (!uart_rx_valid());
  return UART_0_RX_DATA;
}

static inline void uart_write(uint8_t data) {
  while (!(UART_0_STATUS & UART_STATUS_TX_READY));
  UART_0_TX_DATA = data;
}

// 32-bit words are exchanged little-endian
static inline uint32_t uart_read_word(void) {
  uint32_t data = 0;

  for (int b = 0; b < 4; b = b + 1) {
    data |= (uint32_t) uart_read() << (8 * b);
  }
  return data;
}

static inline void uart_write_word(uint32_t data) {
  for (int b = 0; b < 4; b = b + 1) {
    uart_write(data >> (8 * b));
  }
}

static inline void uart_puts(const char *str) {
  while (*str) {
    uart_write(*str++);
  }
}

// digit_n hexadecimal digits, most significant first
static inline void uart_puthex(uint32_t data, int digit_n) {
  for (int d = digit_n - 1; d >= 0; d--) {
    uart_write("0123456789abcdef"[(data >> (4 * d)) & 0xf]);
  }
}

// Decimal, without leading zeros. Each digit is found by subtracting its power
// of ten: the core has no M extension, and the program is not linked with
// libgcc, so there is no division.
static inline void uart_putdec(uint32_t data) {
  static const uint32_t POW_10[10] = {
    1000000000, 100000000, 10000000, 1000000, 100000, 10000, 1000, 100, 10, 1
  };
  int lead = 1;

  for (int p = 0; p < 10; p = p + 1) {
    char digit = '0';

    while (data >= POW_10[p]) {
      data -= POW_10[p];
      digit++;
    }
    if ((digit != '0') || !lead || (p == 9)) {
      uart_write(digit);
      lead = 0;
    }
  }
}

#endif /* __UART_H__ */
