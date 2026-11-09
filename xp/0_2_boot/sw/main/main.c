/*
 * File: main.c                                                                *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-11-05 06:00:00 pm                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-05 06:00:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Program of 0_2_boot, loaded in the RAM through the UART        *
 * bootloader (python3 xp/0_2_boot/xp.py): sends back each byte received on    *
 * UART 0 (step 3: letters in upper case). LED 0 toggles on each byte. The     *
 * program only sends after a byte from the host: the host first switches from *
 * the baud rate of the bootloader to UART_BAUD.                               *
 */


#include "main.h"

uint32_t main(void) {
  GPIO_A_OUT = 0;
  GPIO_A_ENO = GPIO_LED_MASK;

  uart_init(UART_BAUD);

  while (1) {
    uint8_t data = uart_read();

    GPIO_A_OUT ^= 0x1;
    // <TODO 3> send back the letters (a to z) in upper case (A to Z)
    uart_write(data);
  }

  return 0;
}
