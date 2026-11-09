/*
 * File: boot_host.cpp                                                         *
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

#include "boot_host.h"

#include <iomanip>
#include <iostream>

// Protocol of calf_bootloader.sv
static const uint8_t CMD_INIT = 0x01;
static const uint8_t CMD_PING = 0x02;
static const uint8_t CMD_DUMP = 0x03;
static const uint8_t PING_DATA = 0xaa;

static const int CMD_N = 3;         // INIT, DUMP, PING
static const int ADDR_BYTE_N = 4;   // ADDR_BIT_N / 8
static const int SIZE_BYTE_N = 4;   // DATA_BIT_N / 8

static const int ERROR_PRINT_N = 8;

BootHost::BootHost(UartHost& uart, const Image& image)
  : uart_(uart), image_(image) {}

void BootHost::start() {
  uart_.set_capture(true);
  uart_.send(CMD_N);

  uart_.send(CMD_INIT);
  uart_.send_field(0, ADDR_BYTE_N);
  uart_.send_field(image_.size(), SIZE_BYTE_N);
  for (uint8_t data : image_) {
    uart_.send(data);
  }

  uart_.send(CMD_DUMP);
  uart_.send_field(0, ADDR_BYTE_N);
  uart_.send_field(image_.size(), SIZE_BYTE_N);

  state_ = WAIT_DUMP;
}

void BootHost::step() {
  switch (state_) {
    case WAIT_DUMP:
      if (uart_.send_done() && (uart_.received().size() >= image_.size())) {
        check_dump();
        uart_.send(CMD_PING);
        state_ = WAIT_PING;
      }
      break;

    case WAIT_PING:
      if (uart_.received().size() >= 1) {
        check_ping();
        // From now on, the bytes received come from the program
        uart_.set_capture(false);
        state_ = DONE;
      }
      break;

    default:
      break;
  }
}

bool BootHost::done() const {
  return state_ == DONE;
}

int BootHost::error_n() const {
  return error_n_;
}

void BootHost::check_dump() {
  std::deque<uint8_t>& dump = uart_.received();

  for (size_t a = 0; a < image_.size(); a++) {
    if (dump[a] != image_[a]) {
      if (error_n_ < ERROR_PRINT_N) {
        std::cerr << std::hex << std::setfill('0')
                  << "boot: dump mismatch at 0x" << std::setw(4) << a
                  << ": 0x" << std::setw(2) << (int) dump[a]
                  << " instead of 0x" << std::setw(2) << (int) image_[a]
                  << std::dec << std::endl;
      }
      error_n_++;
    }
  }
  dump.clear();
}

void BootHost::check_ping() {
  std::deque<uint8_t>& answer = uart_.received();

  if (answer[0] != PING_DATA) {
    std::cerr << "boot: ping answered 0x" << std::hex << (int) answer[0]
              << " instead of 0x" << (int) PING_DATA << std::dec << std::endl;
    error_n_++;
  }
  answer.clear();
}
