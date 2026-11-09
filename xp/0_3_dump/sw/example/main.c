/*
 * File: main.c                                                                *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-11-05 07:00:00 pm                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-05 10:30:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Example program, analysed in TP 0_3_dump (step 1): a program   *
 * whose source is known, to learn where the compiler puts a string, a 32-bit  *
 * constant (lui/addi) and a value copied in the stack. Compiled, not run:     *
 * read the listing lst/example.lst, which keeps the symbol       *
 * names, then apply this to a raw dump with no symbols.                       *
 */


#include "hw.h"
#include "gpio.h"
#include "uart.h"

// A 32-bit constant, like a key: too wide for one instruction, built with
// lui + addi in the code
#define EXAMPLE_KEY     0x12345678

// A string: its characters are in memory, printed one by one
const char MESSAGE[] = "example: ";

// Compares value to the constant, then answers a string: find EXAMPLE_KEY in
// the disassembly, compared (bne) to the received value
static __attribute__((noinline)) const char *key_check(uint32_t value) {
  return (value == EXAMPLE_KEY) ? "OK\n" : "KO\n";
}

// Copies a value in a local variable (the stack): find it in the stack
static __attribute__((noinline)) int stack_copy(uint32_t value) {
  volatile uint32_t local = value;

  return local != 0;
}

uint32_t main(void) {
  uart_init(UART_BAUD);

  while (1) {
    uint32_t value = uart_read_word();

    uart_puts(MESSAGE);
    uart_puts(key_check(value));
    if (stack_copy(value)) {
      GPIO_A_OUT ^= 0x1;
    }
  }

  return 0;
}
