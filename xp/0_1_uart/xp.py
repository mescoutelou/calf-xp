###
 # File: xp.py                                                                 #
 # License: See LICENSE file                                                   #
 # Copyright (c) 2026 HerdWare                                                 #
 # -----                                                                       #
 # Created On: 2026-11-04 03:30:00 pm                                          #
 # Initial Author: Mathieu Escouteloup                                         #
 # Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       #
 # -----                                                                       #
 # Last Updated On: 2026-11-05 03:00:00 pm                                     #
 # Update Author: Mathieu Escouteloup                                          #
 # Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        #
 # -----                                                                       #
 # Description: TP 0_1_uart, script to complete (see README.md). Programs the  #
 # CW312T-A35 with bit/0_1_uart.bit, then exchanges with the C program running #
 # on CALF, one step after the other.                                          #
###
#!/usr/bin/env python3


import argparse
import sys
from pathlib import Path

XP_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(XP_DIR.parents[1] / "implem" / "xilinx" / "src"))
sys.path.insert(0, str(XP_DIR.parent))
import cw312_a7_35t
import progress

# Directory of the files to complete
PROG_DIR = Path(__file__).resolve().parent

# ******************************************************************************
# * STEP 1: RECEIVE
# ******************************************************************************
def step_1(uart):
  """Read the address of the vault, sent by CALF on reset: a 32-bit integer, as 4 bytes little-endian (least
  significant byte first). Print it in hexadecimal.

  To do: read these 4 bytes, convert them to an integer, print it and return it.
  Hint: data = uart.read(4)
        address = int.from_bytes(data, "little")
        print(f"Address of the vault: 0x{address:08x}")

  IN: uart (cw312_a7_35t.Uart)
  OUT: vault (int): address of the vault
  """

  # <TODO 1>
  return None

# ******************************************************************************
# * STEP 2: SEND
# ******************************************************************************
def step_2(uart, vault):
  """Read the content of the vault with the command 'R': send the byte 'R' then an address (4 bytes little-endian),
  CALF answers the 32-bit word at this address (4 bytes little-endian). Print it in hexadecimal.

  To do: send the command, read the answer, convert it to an integer and print it.
  Hint: uart.write(b"R" + address.to_bytes(4, "little"))

  IN: uart (cw312_a7_35t.Uart)
  IN: vault (int): address of the vault, returned by step_1
  """

  # <TODO 2>
  pass

# ******************************************************************************
# * MAIN
# ******************************************************************************
def main():
  """Program the board, then run steps 1 and 2, or print the progress, given the options of the command line."""

  parser = argparse.ArgumentParser(description="TP 0_1_uart: exchanges with the C program of CALF")
  cw312_a7_35t.add_args(parser)
  parser.add_argument("--progress", action="store_true", help="Print the progress (TODO and DONE markers) and exit")

  ARGS = parser.parse_args()

  if ARGS.progress:
    progress.show(PROG_DIR)
    return

  try:
    with cw312_a7_35t.session(XP_DIR, ARGS) as uart:
      vault = step_1(uart)
      if vault is None:
        sys.exit("Step 1: step_1() must return the address of the vault")
      step_2(uart, vault)
  finally:
    progress.summary(PROG_DIR)

if __name__ == "__main__":
  main()
