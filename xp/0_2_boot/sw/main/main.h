/*
 * File: main.h                                                                *
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
 * Description: Program of 0_2_boot, loaded through the UART bootloader: echo  *
 * of the bytes received on UART 0, after uart_init(UART_BAUD).                *
 */


#ifndef __MAIN_H__
#define __MAIN_H__

#include <stdint.h>

#include "hw.h"
#include "gpio.h"
#include "uart.h"

uint32_t main(void);

#endif /* __MAIN_H__ */
