/*
 * File: image.cpp                                                             *
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
 * Description: Program image read from a byte hex file (objcopy -O verilog    *
 * format).                                                                    *
 */

#include "image.h"

#include <fstream>

bool read_image(const std::string& file, Image& image) {
  std::ifstream f(file);
  if (!f.is_open()) {
    return false;
  }

  image.clear();
  std::string token;
  size_t addr = 0;

  while (f >> token) {
    if (token[0] == '@') {
      addr = std::stoul(token.substr(1), nullptr, 16);
      continue;
    }

    if (addr >= image.size()) {
      image.resize(addr + 1, 0);
    }
    image[addr] = std::stoul(token, nullptr, 16);
    addr++;
  }
  return true;
}
