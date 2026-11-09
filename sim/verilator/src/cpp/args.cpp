/*
 * File: args.cpp                                                              *
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
 * Description: Command line parsing of the simulator.                         *
 */

#include "args.h"

#include <cstdlib>
#include <iostream>

static void usage(const char* prog) {
  std::cerr << "usage: " << prog << " (--ram <file.hex> | --boot <file.hex>)"
            << " [--vcd <file.vcd>] [--ntrigger <cycles>]" << std::endl;
  exit(EXIT_FAILURE);
}

Args parse_args(int argc, char** argv) {
  Args args;

  for (int a = 1; a < argc; a++) {
    std::string opt = argv[a];

    // Verilator options (+verilator+...) are handled by Verilated::commandArgs
    if (opt[0] == '+') {
      continue;
    }

    if (a + 1 >= argc) {
      std::cerr << "error: " << opt << " expects a value" << std::endl;
      usage(argv[0]);
    }
    std::string val = argv[++a];

    if (opt == "--ram") {
      args.ram_file = val;
    } else if (opt == "--boot") {
      args.boot_file = val;
    } else if (opt == "--vcd") {
      args.vcd_file = val;
    } else if (opt == "--ntrigger") {
      args.max_cycles = std::strtoull(val.c_str(), nullptr, 0);
    } else {
      std::cerr << "error: unknown option " << opt << std::endl;
      usage(argv[0]);
    }
  }

  if (args.ram_file.empty() == args.boot_file.empty()) {
    std::cerr << "error: give one program, with --ram or --boot" << std::endl;
    usage(argv[0]);
  }
  return args;
}
