/*
 * File: main.c                                                                *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-11-05 11:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-05 01:00:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Program of 0_0_sim, run in simulation (python3                 *
 * xp/0_0_sim/xp.py): prints the sum of an array computed in C and in          *
 * assembly. main returns the sum in C, in a0. The UART keeps its reset baud   *
 * rate: the one of the simulator (BAUD_DIV of sim/sim.py).                    *
 */


#include "main.h"

uint32_t data[DATA_N];

// Not inlined: its code stays a function of its own in the listing
static __attribute__((noinline)) uint32_t c_sum(const uint32_t *data, uint32_t n) {
  uint32_t sum = 0;

  for (uint32_t i = 0; i < n; i = i + 1) {
    sum += data[i];
  }
  return sum;
}

static void print(const char *name, uint32_t value) {
  uart_puts(name);
  uart_puts(" = ");
  uart_putdec(value);
  uart_puts("\n");
}

uint32_t main(void) {
  uint32_t sum;

  uart_puts("Hello from CALF\n");

  for (uint32_t i = 0; i < DATA_N; i = i + 1) {
    data[i] = i + 1;
  }

  // Step 1: C
  sum = c_sum(data, DATA_N);
  print("c_sum", sum);

  // Step 2: assembly
  print("asm_sum", asm_sum(data, DATA_N));

  return sum;
}
