/*
 * File: main.c                                                                *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-11-05 11:30:00 pm                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-05 11:30:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Program to inject, in TP 0_3_dump (step 5): loaded in the RAM  *
 * by the bootloader (xp.py --direct) in place of the program of the           *
 * bitstream, it sends the hardware key KEY_0_DATA on UART 0 each time it      *
 * receives a byte.                                                            *
 */


#include "hw.h"
#include "uart.h"

uint32_t main(void) {
  uart_init(UART_BAUD);

  while (1) {
    // Waits for a byte: the PC has switched to the baud rate of the program
    uart_read();

    // <TODO 5> send KEY_0_DATA (4 bytes, little-endian, see uart.h)
  }

  return 0;
}
