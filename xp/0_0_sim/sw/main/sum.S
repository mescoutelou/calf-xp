/*
 * File: sum.S                                                                 *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-11-05 11:00:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-05 02:00:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Sum of an array of 32-bit words, in assembly (step 2):         *
 * uint32_t asm_sum(const uint32_t *data, uint32_t n)                          *
 * Arguments in a0 (data) and a1 (n), result in a0.                            *
 */


.section .text
.globl asm_sum
asm_sum:
  /* <TODO 2> a0 = sum of the n words (a1) of the array at the address data (a0) */
  li a0, 0
  ret
