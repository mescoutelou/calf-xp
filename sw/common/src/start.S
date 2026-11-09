/*
 * File: start.S                                                               *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-08 07:33:58 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-04 04:00:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Common startup code: sets gp (the linker relaxes the           *
 * accesses to the globals near __global_pointer$ into gp-relative ones) and   *
 * sp, then calls main.                                                        *
 */


.section .text
.globl _start
_start:
  /* Set the global pointer, without relaxation: la gp would use gp itself */
  .option push
  .option norelax
  la gp, __global_pointer$
  .option pop

  /* Set the stack pointer (top of the RAM) */
  la sp, __stack

  /* Call main */
  call main

  /* Loop forever */
_end:
  j _end
