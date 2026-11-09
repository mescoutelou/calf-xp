/*
 * File: testbench.cpp                                                         *
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

#include "testbench.h"

#include "Vcalf_sim__Dpi.h"
#include "svdpi.h"
#include "verilated.h"

static const char* RAM_SCOPE = "TOP.calf_sim.sys_m.ram_m";

Testbench::Testbench(const std::string& vcd_file) {
  dut_ = new Vcalf_sim;

  if (!vcd_file.empty()) {
    Verilated::traceEverOn(true);
    vcd_ = new VerilatedVcdC;
    dut_->trace(vcd_, 99);
    vcd_->open(vcd_file.c_str());
  }

  dut_->clk_i = 0;
  dut_->rst_i = 1;
  dut_->boot_mode_i = 0;
  dut_->gpio_in_i = 0;
  dut_->host_tx_valid_i = 0;
  dut_->host_tx_data_i = 0;
  dut_->eval();
}

Testbench::~Testbench() {
  dut_->final();
  if (vcd_ != nullptr) {
    vcd_->close();
    delete vcd_;
  }
  delete dut_;
}

Vcalf_sim* Testbench::dut() const {
  return dut_;
}

void Testbench::load_ram(const std::string& file) {
  svSetScope(svGetScopeFromName(RAM_SCOPE));
  ext_readmemh(file.c_str());
}

void Testbench::reset(bool boot_mode, int cycle_n) {
  dut_->boot_mode_i = boot_mode;
  dut_->rst_i = 1;
  for (int c = 0; c < cycle_n; c++) {
    tick();
  }
  dut_->rst_i = 0;
}

void Testbench::tick() {
  dut_->clk_i = 1;
  dut_->eval();
  dump();

  dut_->clk_i = 0;
  dut_->eval();
  dump();

}

void Testbench::dump() {
  if (vcd_ != nullptr) {
    vcd_->dump(time_ * 5);
  }
  time_++;
}
