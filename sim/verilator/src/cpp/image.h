/*
 * File: image.h                                                               *
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

#ifndef __IMAGE_H__
#define __IMAGE_H__

#include <cstdint>
#include <string>
#include <vector>

// image[a] is the byte at address a. The image starts at address 0 and ends
// on the last byte of the file, holes are filled with 0.
typedef std::vector<uint8_t> Image;

// Reads a byte hex file: hex bytes separated by spaces or newlines, with
// optional @<address> tokens. Returns false if the file cannot be opened.
bool read_image(const std::string& file, Image& image);

#endif /* __IMAGE_H__ */
