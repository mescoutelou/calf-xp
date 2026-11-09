/*
 * File: sim.cpp                                                               *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-01-30 10:52:36 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-08 09:30:00 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description: Verilator simulator of calf_sim. Loads a program (byte hex     *
 * format, as produced by objcopy -O verilog) in the RAM, or through the UART  *
 * bootloader, prints the characters sent by the program on the UART, and      *
 * stops on the first "j ." (jump to itself) or after --ntrigger core cycles.  *
 * Exit status: 0 if the program halted.                                       *
 */

#include <cstdlib>
#include <iomanip>
#include <iostream>

#include "verilated.h"

#include "args.h"
#include "boot_host.h"
#include "image.h"
#include "testbench.h"
#include "uart_host.h"

static const int RESET_CYCLE_N = 5;

// ******************************************************************************
// * REPORT
// ******************************************************************************
struct Result {
  bool halt = false;
  uint64_t boot_cycle_n = 0;    // Cycles spent in the bootloader
  uint64_t core_cycle_n = 0;    // Cycles after the bootloader has released the core
};

static void report(Vcalf_sim* dut, const Result& result, const Args& args,
                   const Image& boot_image, const BootHost& boot) {
  std::cout << std::endl;
  if (!args.boot_file.empty()) {
    std::cout << "boot    = " << boot_image.size() << " bytes in " << result.boot_cycle_n << " cycles, "
              << (boot.error_n() == 0 ? "checked" : std::to_string(boot.error_n()) + " error(s)") << std::endl;
  }
  std::cout << (result.halt ? "halt    = jump to self" : "timeout = no halt") << std::endl;
  std::cout << "cycles  = " << result.core_cycle_n << std::endl;
  std::cout << "instret = " << dut->instret_o << std::endl;
  std::cout << std::hex << std::setfill('0');
  std::cout << "pc      = 0x" << std::setw(8) << dut->pc_o << std::endl;
  std::cout << "a0      = 0x" << std::setw(8) << dut->a0_o << std::endl;
  std::cout << std::dec;
  if (!args.vcd_file.empty()) {
    std::cout << "VCD file: " << args.vcd_file << std::endl;
  }
}

// ******************************************************************************
// * MAIN
// ******************************************************************************
int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  Args args = parse_args(argc, argv);
  bool use_boot = !args.boot_file.empty();

  // ------------------------------
  //            PROGRAM
  // ------------------------------
  Image boot_image;
  if (use_boot && !read_image(args.boot_file, boot_image)) {
    std::cerr << "error: cannot open " << args.boot_file << std::endl;
    return EXIT_FAILURE;
  }

  Testbench tb(args.vcd_file);
  Vcalf_sim* dut = tb.dut();
  UartHost uart;
  BootHost boot(uart, boot_image);

  if (!use_boot) {
    tb.load_ram(args.ram_file);
  }

  // ------------------------------
  //             RESET
  // ------------------------------
  tb.reset(use_boot, RESET_CYCLE_N);
  if (use_boot) {
    boot.start();
  }

  // ------------------------------
  //              RUN
  // ------------------------------
  Result result;

  while (!result.halt && (result.core_cycle_n < args.max_cycles) && !Verilated::gotFinish()) {
    uart.step(dut);
    if (use_boot) {
      boot.step();
    }

    if (dut->boot_o) {
      result.boot_cycle_n++;
    } else {
      result.core_cycle_n++;
    }
    result.halt = dut->halt_o;

    tb.tick();
  }

  report(dut, result, args, boot_image, boot);
  return (result.halt && (boot.error_n() == 0)) ? EXIT_SUCCESS : EXIT_FAILURE;
}
