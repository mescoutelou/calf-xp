/*
 * File: testbench.h                                                           *
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
 * Description: Wrapper around the Verilated calf_sim: clock, reset, RAM       *
 * preload and VCD dump.                                                       *
 */

#ifndef __TESTBENCH_H__
#define __TESTBENCH_H__

#include <cstdint>
#include <string>

#include "Vcalf_sim.h"
#include "verilated_vcd_c.h"

class Testbench {
public:
  // Opens the VCD file if vcd_file is not empty
  Testbench(const std::string& vcd_file);
  ~Testbench();

  Vcalf_sim* dut() const;

  // Loads a byte hex file in the RAM (calf_ram ext_readmemh task)
  void load_ram(const std::string& file);

  // Holds the reset for cycle_n cycles. boot_mode_i is set before, as it must
  // be stable when the reset is released.
  void reset(bool boot_mode, int cycle_n);

  // One clock cycle: rising edge, then falling edge. The inputs are set
  // between two calls, while the clock is low.
  void tick();

private:
  void dump();

  Vcalf_sim* dut_;
  VerilatedVcdC* vcd_ = nullptr;
  uint64_t time_ = 0;     // Half cycles since the start
};

#endif /* __TESTBENCH_H__ */
