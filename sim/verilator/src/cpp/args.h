/*
 * File: args.h                                                                *
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
 * Description: Command line options of the simulator.                         *
 */

#ifndef __ARGS_H__
#define __ARGS_H__

#include <cstdint>
#include <string>

struct Args {
  std::string ram_file;           // Program preloaded in the RAM (byte hex)
  std::string boot_file;          // Program sent through the bootloader (byte hex)
  std::string vcd_file;           // Waveform output, none if empty
  uint64_t max_cycles = 1000000;  // Core cycles before timeout
};

// Parses --ram <file>, --boot <file>, --vcd <file> and --ntrigger <cycles>.
// Exits with an error message on an unknown option or a missing value.
Args parse_args(int argc, char** argv);

#endif /* __ARGS_H__ */
