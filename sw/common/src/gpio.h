/*
 * File: gpio.h                                                                *
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
 * Description: GPIO A of calf_cw312_a7_35t: bits of the LEDs and of the       *
 * trigger.                                                                    *
 */


#ifndef __GPIO_H__
#define __GPIO_H__

#include <stdint.h>

#include "hw.h"

// ******************************************************************************
// * CONSTANT
// ******************************************************************************
// LED 0-2 are GPIO bits 0-2, the trigger is GPIO bit 3 (IO4)
#define GPIO_LED_MASK 0x07
#define GPIO_TRIGGER  0x08

// ******************************************************************************
// * FUNCTION
// ******************************************************************************

#endif /* __GPIO_H__ */
