###
 # File: xp.py                                                                 #
 # License: See LICENSE file                                                   #
 # Copyright (c) 2026 HerdWare                                                 #
 # -----                                                                       #
 # Created On: 2026-11-05 06:00:00 pm                                          #
 # Initial Author: Mathieu Escouteloup                                         #
 # Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       #
 # -----                                                                       #
 # Last Updated On: 2026-11-05 06:00:00 pm                                     #
 # Update Author: Mathieu Escouteloup                                          #
 # Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        #
 # -----                                                                       #
 # Description: TP 0_2_boot, script to complete (see README.md). Programs the  #
 # CW312T-A35 with bit/0_2_boot.bit (UART bootloader, empty RAM), builds the   #
 # program of sw/ and loads it through the bootloader, then checks its echo.   #
 # --no-load starts the program already in the RAM instead.                    #
###
#!/usr/bin/env python3


import argparse
import sys
import time
from pathlib import Path

XP_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(XP_DIR.parents[1] / "implem" / "xilinx" / "src"))
sys.path.insert(0, str(XP_DIR.parents[1] / "sw" / "common"))
sys.path.insert(0, str(XP_DIR.parent))
import build
import cw312_a7_35t
import progress

# Directory of the files to complete
PROG_DIR = Path(__file__).resolve().parent

# Protocol of the bootloader (calf_bootloader.sv)
CMD_INIT = 0x01
CMD_PING = 0x02
CMD_DUMP = 0x03
PING_DATA = 0xaa

# ******************************************************************************
# * STEPS 1 AND 2: LOAD
# ******************************************************************************
def boot_load(uart, image):
  """Load a program in the RAM through the bootloader, at address 0, then release the core. The bootloader runs at
  its own baud rate (uart.baud): 10 bits per byte.

  To do (step 1): send NUM = 2 (number of commands), then INIT (command, ADDR = 0 on 4 bytes, SIZE = len(image) on
  4 bytes, then the image), then PING; read the answer of PING and check that it is 0xaa.
  To do (step 2): add DUMP (command, ADDR, SIZE) between INIT and PING, with NUM = 3; read the SIZE bytes of its
  answer and compare them with the image, before sending PING (the bootloader drops the bytes received while it
  answers).
  Hint: uart.write(bytes([2, CMD_INIT]) + (0).to_bytes(4, "little") + len(image).to_bytes(4, "little") + image)
        the default timeout of uart.read (1 s) is too short for a long answer: uart.read(n, timeout)

  IN: uart (cw312_a7_35t.Uart)
  IN: image (bytes): memory image from address 0
  """

  # <TODO 1> NUM, INIT, then PING, whose answer is checked
  # <TODO 2> DUMP between INIT and PING, whose answer is compared with the image
  pass

# ******************************************************************************
# * STEP 4: START WITHOUT LOADING
# ******************************************************************************
def boot_skip(uart):
  """Release the core without loading anything: it runs the program already in the RAM.

  To do: send NUM = 0.

  IN: uart (cw312_a7_35t.Uart)
  """

  # <TODO 4> NUM = 0
  pass

# ******************************************************************************
# * ECHO
# ******************************************************************************
def echo(uart, text):
  """Send a line of text to the program, at its baud rate, and print the line it sends back.

  IN: uart (cw312_a7_35t.Uart)
  IN: text (str)
  """

  uart.write(text.encode() + b"\n")
  try:
    print(f"Echo: '{text}' -> '{uart.readline()}'")
  except TimeoutError:
    sys.exit("Echo: no answer, the program does not run")

# ******************************************************************************
# * MAIN
# ******************************************************************************
def main():
  """Program the board, load the program and check its echo, or print the progress, given the options of the command
  line.
  """

  parser = argparse.ArgumentParser(description="TP 0_2_boot: loads the program of sw/ through the bootloader of CALF")
  cw312_a7_35t.add_args(parser)
  parser.add_argument("--no-load", action="store_true", help="Start the program already in the RAM (step 4)")
  parser.add_argument("--progress", action="store_true", help="Print the progress (TODO and DONE markers) and exit")

  ARGS = parser.parse_args()

  if ARGS.progress:
    progress.show(PROG_DIR)
    return

  try:
    image = None
    if not ARGS.no_load:
      try:
        image = build.image(build.build(PROG_DIR, "sw"))
      except RuntimeError as e:
        sys.exit(f"error: {e}")

    with cw312_a7_35t.session(XP_DIR, ARGS, baud_div=cw312_a7_35t.BOOT_BAUD_DIV) as uart:
      if image is None:
        boot_skip(uart)
      else:
        print(f"Loading {len(image)} bytes at {uart.baud} baud...", flush=True)
        boot_load(uart, image)

      # The program runs: its baud rate after uart_init(). The last byte sent to the bootloader must have left at
      # its baud rate first (the ChipWhisperer sends in the background)
      time.sleep(0.1)
      uart.baud_div = cw312_a7_35t.BAUD_DIV
      echo(uart, "hello calf")
  finally:
    progress.summary(PROG_DIR)

if __name__ == "__main__":
  main()
