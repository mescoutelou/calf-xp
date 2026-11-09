/*
 * File: boot_host.h                                                           *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-08 09:30:00 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-08 09:30:00 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Host side of a bootloader session (protocol in                 *
 * calf_bootloader.sv): INIT writes the image at address 0, DUMP reads it back *
 * to check it, and PING checks that the bootloader answers 0xAA. The          *
 * bootloader then releases the core.                                          *
 */

#ifndef __BOOT_HOST_H__
#define __BOOT_HOST_H__

#include "image.h"
#include "uart_host.h"

class BootHost {
public:
  BootHost(UartHost& uart, const Image& image);

  // Sends the commands: NUM, INIT and DUMP. PING is sent by step(), once the
  // dump has been received (the bootloader drops bytes while answering).
  void start();

  // Called once per cycle: checks the answers as they complete
  void step();

  bool done() const;
  int error_n() const;

private:
  enum State {IDLE, WAIT_DUMP, WAIT_PING, DONE};

  void check_dump();
  void check_ping();

  UartHost& uart_;
  const Image& image_;
  State state_ = IDLE;
  int error_n_ = 0;
};

#endif /* __BOOT_HOST_H__ */
