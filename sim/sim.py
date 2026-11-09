###
 # File: sim.py                                                                #
 # License: See LICENSE file                                                   #
 # Copyright (c) 2026 HerdWare                                                 #
 # -----                                                                       #
 # Created On: 2026-11-05 12:00:00 pm                                          #
 # Initial Author: Mathieu Escouteloup                                         #
 # Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       #
 # -----                                                                       #
 # Last Updated On: 2026-11-05 04:00:00 pm                                     #
 # Update Author: Mathieu Escouteloup                                          #
 # Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        #
 # -----                                                                       #
 # Description: Verilator simulation of CALF (top: sim/verilator/src). Builds  #
 # a simulator in a directory of its own (one per experiment), with hw         #
 # directories whose .sv files replace the ones with the same name in          #
 # src/main/sv, or are added. Runs a program (byte hex file, objcopy -O        #
 # verilog) until it halts ("j .") and returns what it printed on the UART     #
 # and the final state of the core:                                            #
 #   sim_bin = sim.sim_build(xp_dir / "verilator", [xp_dir / "hw"])            #
 #   result = sim.run(sim_bin, hex_file, vcd_file=...)                         #
 #   sim.wave(vcd_file)          (GTKWave, signals of sim/verilator/calf.gtkw) #
 #   python3 sim/sim.py <hex_file> [--obj <dir>] [--hw <dir>]... [--vcd <vcd>] #
###
#!/usr/bin/env python3


import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

# ******************************************************************************
# * CONFIGURATION
# ******************************************************************************
ROOT_DIR = Path(__file__).resolve().parents[1]
SV_DIR = ROOT_DIR / "src" / "main" / "sv"
SIM_DIR = ROOT_DIR / "sim" / "verilator"
SIM_SV_DIR = SIM_DIR / "src" / "sv"
SIM_CPP_DIR = SIM_DIR / "src" / "cpp"
# Default simulator, outside of the experiments
OBJ_DIR = SIM_DIR / "obj"
# Selection of signals of the core for GTKWave
GTKW_FILE = SIM_DIR / "calf.gtkw"

TOP = "calf_sim"
# Packages first, in dependency order
SV_PKG = [
  "calf_riscv_pkg.sv",
  "calf_priv_pkg.sv",
  "calf_cache_pkg.sv",
  "calf_core_pkg.sv",
  "calf_addr_pkg.sv",
  "calf_sys_pkg.sv",
]

VERILATOR = "verilator"
VFLAGS = [
  "--cc", "--exe", "--build", "--trace", "-j", "0",
  "-Wno-fatal", "-Wno-lint", "-Wno-style",
  "-CFLAGS", "-O2",
]

# UART cycles per bit of the simulator: reset value of BAUD_DIV
BAUD_DIV = 8
CYCLE_N = 1000000

# Lines of the final report of sim.cpp
REPORT_RE = re.compile(r"(boot|halt|timeout|cycles|instret|pc|a0)\s*= (.*)|VCD file: .*")

# ******************************************************************************
# * SIMULATOR
# ******************************************************************************
def sv_files(hw_dirs):
  """Return the SystemVerilog files of the simulator: those of src/main/sv, packages first, then the top of
  sim/verilator. A file of a hw directory replaces the one with the same name, the others are added.

  IN: hw_dirs (list[Path]): hardware directories, in order
  OUT: sv_list (list[Path])
  """

  sv_dict = {f: SV_DIR / f for f in SV_PKG}
  sv_dict.update({f.name: f for f in sorted(SV_DIR.glob("*.sv")) if f.name not in SV_PKG})
  sv_dict.update({f.name: f for f in sorted(SIM_SV_DIR.glob("*.sv"))})
  for d in hw_dirs:
    sv_dict.update({f.name: f for f in sorted(Path(d).glob("*.sv"))})

  pkg_list = [f for name, f in sv_dict.items() if name.endswith("_pkg.sv")]
  return pkg_list + [f for name, f in sv_dict.items() if not name.endswith("_pkg.sv")]

def cpp_files():
  """Return the C++ files of the simulator.

  OUT: cpp_list (list[Path])
  """

  return sorted(SIM_CPP_DIR.glob("*.cpp"))

def sim_build(obj_dir=OBJ_DIR, hw_dirs=[], baud=BAUD_DIV, force=False):
  """Build the simulator in a directory, if a source is newer than it, or if its files or its parameters change.
  Exits if Verilator fails.

  IN: obj_dir (Path | str): directory of the simulator
  IN: hw_dirs (list[Path | str]): hardware directories, whose files replace or complete src/main/sv
  IN: baud (int): UART cycles per bit
  IN: force (bool): rebuild in any case
  OUT: sim_bin (Path): simulator
  """

  obj_dir = Path(obj_dir).resolve()
  sim_bin = obj_dir / TOP
  cfg_file = obj_dir / "config"
  log_file = obj_dir / "build.log"

  src_list = sv_files([Path(d).resolve() for d in hw_dirs]) + cpp_files()
  cfg = f"BAUD_DIV={baud}\n" + "".join(f"{f}\n" for f in src_list)

  need = force or not sim_bin.exists() or not cfg_file.exists() or (cfg_file.read_text() != cfg)
  if not need:
    # Headers are not given to Verilator, but a change rebuilds the simulator
    bin_time = sim_bin.stat().st_mtime
    need = any(f.stat().st_mtime > bin_time for f in src_list + sorted(SIM_CPP_DIR.glob("*.h")))
  if not need:
    return sim_bin

  print(f"Building simulator in {obj_dir}...", flush=True)
  shutil.rmtree(obj_dir, ignore_errors=True)
  obj_dir.mkdir(parents=True)
  cmd = [VERILATOR] + VFLAGS + [
    "--top-module", TOP, f"-GBAUD_DIV={baud}",
    "-Mdir", str(obj_dir), "-o", TOP,
  ] + [str(f) for f in src_list]
  with open(log_file, "w") as log_f:
    log_f.write("$ " + " ".join(cmd) + "\n")
    log_f.flush()
    try:
      result = subprocess.run(cmd, stdout=log_f, stderr=subprocess.STDOUT)
    except FileNotFoundError:
      sys.exit(f"error: {VERILATOR} not found")
  if result.returncode != 0:
    print(log_file.read_text()[-4000:], file=sys.stderr)
    sys.exit(f"error: simulator build failed, see {log_file}")
  cfg_file.write_text(cfg)
  return sim_bin

# ******************************************************************************
# * RUN
# ******************************************************************************
def run(sim_bin, hex_file, cycle_n=CYCLE_N, vcd_file=None, boot=False):
  """Run a program on the simulator, until it halts or after cycle_n cycles.

  IN: sim_bin (Path): simulator, from sim_build
  IN: hex_file (Path | str): program, byte hex file
  IN: cycle_n (int): maximum number of core cycles
  IN: vcd_file (Path | str | None): waveforms, none if None
  IN: boot (bool): load the program through the UART bootloader instead of the RAM preload
  OUT: result (dict): uart (str): characters sent by the program; report (list[str]): final report of the simulator;
       halt (bool); cycles, instret, pc, a0 (int)
  """

  cmd = [str(sim_bin), "--boot" if boot else "--ram", str(Path(hex_file).resolve()), "--ntrigger", str(cycle_n)]
  if vcd_file is not None:
    vcd_file = Path(vcd_file).resolve()
    vcd_file.parent.mkdir(parents=True, exist_ok=True)
    cmd += ["--vcd", str(vcd_file)]
  out = subprocess.run(cmd, stdout=subprocess.PIPE, text=True).stdout

  # The report ends the output, after an empty line
  lines = out.split("\n")
  while lines and lines[-1] == "":
    lines.pop()
  r = len(lines)
  while (r > 0) and REPORT_RE.fullmatch(lines[r - 1]):
    r -= 1
  report = lines[r:]
  uart = "\n".join(lines[:r - 1] if (r > 0) and (lines[r - 1] == "") else lines[:r])

  value = {m.group(1): m.group(2) for m in map(REPORT_RE.fullmatch, report) if m.group(1)}
  return {
    "uart": uart,
    "report": report,
    "halt": "halt" in value,
    "cycles": int(value.get("cycles", "0")),
    "instret": int(value.get("instret", "0")),
    "pc": int(value.get("pc", "0"), 16),
    "a0": int(value.get("a0", "0"), 16),
  }

def wave(vcd_file, gtkw_file=GTKW_FILE):
  """Open waveforms in GTKWave, in the background.

  IN: vcd_file (Path | str)
  IN: gtkw_file (Path | str): selection of signals
  """

  try:
    subprocess.Popen(["gtkwave", str(vcd_file), str(gtkw_file)])
  except FileNotFoundError:
    sys.exit("error: gtkwave not found")

# ******************************************************************************
# * MAIN
# ******************************************************************************
def main():
  """Build the simulator and run the program given on the command line."""

  parser = argparse.ArgumentParser(description="Verilator simulation of CALF")

  parser.add_argument("hex_file", type=Path, help="Program, byte hex file (objcopy -O verilog)")
  parser.add_argument("--obj", type=Path, default=OBJ_DIR, help=f"Directory of the simulator (default: {OBJ_DIR.relative_to(ROOT_DIR)})")
  parser.add_argument("--hw", type=Path, action="append", default=[], help="Hardware directory, repeatable")
  parser.add_argument("-b", "--boot", action="store_true", help="Load the program through the UART bootloader")
  parser.add_argument("-c", "--cycles", type=int, default=CYCLE_N, help=f"Maximum number of core cycles (default: {CYCLE_N})")
  parser.add_argument("-t", "--vcd", type=Path, help="Dump waveforms in this file")
  parser.add_argument("--wave", action="store_true", help="Open the waveforms of --vcd in GTKWave")
  parser.add_argument("-r", "--rebuild", action="store_true", help="Force a rebuild of the simulator")

  ARGS = parser.parse_args()

  sim_bin = sim_build(ARGS.obj, ARGS.hw, force=ARGS.rebuild)
  result = run(sim_bin, ARGS.hex_file, ARGS.cycles, ARGS.vcd, ARGS.boot)
  print(result["uart"])
  print("\n".join(result["report"]))
  if ARGS.wave and ARGS.vcd:
    wave(ARGS.vcd)
  sys.exit(0 if result["halt"] else 1)

if __name__ == "__main__":
  main()
