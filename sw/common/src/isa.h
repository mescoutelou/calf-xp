/*
 * File: isa.h                                                                 *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-11-04 02:40:00 pm                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-11-04 09:30:00 pm                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Instructions of the core (rv32i_zicsr_zicntr_zbs) without a C  *
 * equivalent: cycle counter.                                                  *
 */


#ifndef __ISA_H__
#define __ISA_H__

#include <stdint.h>

// ******************************************************************************
// * CONSTANT
// ******************************************************************************

// ******************************************************************************
// * FUNCTION
// ******************************************************************************
static inline uint32_t cycle_read(void) {
  uint32_t cycle;

  asm volatile ("rdcycle %0" : "=r" (cycle));
  return cycle;
}

#endif /* __ISA_H__ */
