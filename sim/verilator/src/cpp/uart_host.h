/*
 * File: uart_host.h                                                           *
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
 * Description: Host side of the UART. Bytes are exchanged with the host_tx_m  *
 * and host_rx_m instances of calf_sim (calf_uart_tx/rx) through their         *
 * valid/ready handshakes: no bit timing here.                                 *
 */

#ifndef __UART_HOST_H__
#define __UART_HOST_H__

#include <cstdint>
#include <deque>

#include "Vcalf_sim.h"

class UartHost {
public:
  // Queues bytes to send to the core
  void send(uint8_t data);
  // Queues the n low bytes of value, least significant first
  void send_field(uint32_t value, int n);

  bool send_done() const;

  // Bytes received while capture is on are kept (see received()), the others
  // are printed on stdout: they are characters sent by the program.
  void set_capture(bool capture);
  std::deque<uint8_t>& received();

  // Called once per cycle, while the clock is low: collects the byte received
  // in this cycle, and offers the next byte to send.
  void step(Vcalf_sim* dut);

private:
  std::deque<uint8_t> tx_queue_;
  std::deque<uint8_t> rx_queue_;
  bool capture_ = false;
};

#endif /* __UART_HOST_H__ */
