/*
 * File: main.h                                                                *
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
 * Description: Program of 0_0_sim: sum of an array in C (step 1) and in       *
 * assembly (sum.S, step 2).                                                   *
 */


#ifndef __MAIN_H__
#define __MAIN_H__

#include <stdint.h>

#include "hw.h"
#include "uart.h"

#define DATA_N          10

// sum.S
uint32_t asm_sum(const uint32_t *data, uint32_t n);

uint32_t main(void);

#endif /* __MAIN_H__ */
