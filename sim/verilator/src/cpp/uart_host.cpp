/*
 * File: uart_host.cpp                                                         *
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

#include "uart_host.h"

#include <iostream>

void UartHost::send(uint8_t data) {
  tx_queue_.push_back(data);
}

void UartHost::send_field(uint32_t value, int n) {
  for (int b = 0; b < n; b++) {
    send((value >> (b * 8)) & 0xff);
  }
}

bool UartHost::send_done() const {
  return tx_queue_.empty();
}

void UartHost::set_capture(bool capture) {
  capture_ = capture;
}

std::deque<uint8_t>& UartHost::received() {
  return rx_queue_;
}

void UartHost::step(Vcalf_sim* dut) {
  // Receive: host_rx_valid_o is a one-cycle pulse
  if (dut->host_rx_valid_o) {
    if (capture_) {
      rx_queue_.push_back(dut->host_rx_data_o);
    } else {
      std::cout << (char) dut->host_rx_data_o << std::flush;
    }
  }

  // Send: the byte is taken on the next rising edge, as ready is already set
  dut->host_tx_valid_i = 0;
  if (dut->host_tx_ready_o && !tx_queue_.empty()) {
    dut->host_tx_valid_i = 1;
    dut->host_tx_data_i = tx_queue_.front();
    tx_queue_.pop_front();
  }
}
