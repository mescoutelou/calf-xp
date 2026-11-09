###
 # File: xp.py                                                                 #
 # License: See LICENSE file                                                   #
 # Copyright (c) 2026 HerdWare                                                 #
 # -----                                                                       #
 # Created On: 2026-11-05 11:00:00 am                                          #
 # Initial Author: Mathieu Escouteloup                                         #
 # Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       #
 # -----                                                                       #
 # Last Updated On: 2026-11-05 04:00:00 pm                                     #
 # Update Author: Mathieu Escouteloup                                          #
 # Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        #
 # -----                                                                       #
 # Description: TP 0_0_sim: builds the program of sw/ and runs it on the       #
 # Verilator simulator of CALF, built in verilator/ (see README.md). -t dumps  #
 # the waveforms in vcd/, --wave opens them in GTKWave.                        #
###
#!/usr/bin/env python3


import argparse
import sys
from pathlib import Path

XP_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(XP_DIR.parents[1] / "sw" / "common"))
sys.path.insert(0, str(XP_DIR.parents[1] / "sim"))
sys.path.insert(0, str(XP_DIR.parent))
import build
import progress
import sim

# ******************************************************************************
# * RUN
# ******************************************************************************
def run(ARGS):
  """Build the program, run it in simulation and print its output, then the final state of the core.

  IN: ARGS (argparse.Namespace): options of main
  """

  try:
    hex_file = build.build(XP_DIR, "sw")
  except RuntimeError as e:
    sys.exit(f"error: {e}")

  sim_bin = sim.sim_build(XP_DIR / "verilator", [XP_DIR / "hw"] if (XP_DIR / "hw").is_dir() else [])
  vcd_file = XP_DIR / "vcd" / f"{XP_DIR.name}.vcd" if (ARGS.vcd or ARGS.wave) else None

  print(f"Running {hex_file.relative_to(XP_DIR)}...", flush=True)
  result = sim.run(sim_bin, hex_file, ARGS.cycles, vcd_file)
  print(result["uart"])
  print()
  print("\n".join(result["report"]))

  if ARGS.wave:
    sim.wave(vcd_file)
  if not result["halt"]:
    sys.exit("error: the program did not halt")

# ******************************************************************************
# * MAIN
# ******************************************************************************
def main():
  """Run the experiment, or print its progress, given the options of the command line."""

  parser = argparse.ArgumentParser(description="TP 0_0_sim: runs the program of sw/ on the simulator of CALF")

  parser.add_argument("-c", "--cycles", type=int, default=sim.CYCLE_N, help=f"Maximum number of core cycles (default: {sim.CYCLE_N})")
  parser.add_argument("-t", "--vcd", action="store_true", help=f"Dump the waveforms in vcd/{XP_DIR.name}.vcd")
  parser.add_argument("--wave", action="store_true", help="Dump the waveforms and open them in GTKWave")
  parser.add_argument("--progress", action="store_true", help="Print the progress (TODO and DONE markers) and exit")

  ARGS = parser.parse_args()

  if ARGS.progress:
    progress.show(XP_DIR)
    return

  try:
    run(ARGS)
  finally:
    progress.summary(XP_DIR)

if __name__ == "__main__":
  main()
