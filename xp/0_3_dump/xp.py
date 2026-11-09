###
 # File: xp.py                                                                 #
 # License: See LICENSE file                                                   #
 # Copyright (c) 2026 HerdWare                                                 #
 # -----                                                                       #
 # Created On: 2026-11-05 07:00:00 pm                                          #
 # Initial Author: Mathieu Escouteloup                                         #
 # Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       #
 # -----                                                                       #
 # Last Updated On: 2026-11-05 11:30:00 pm                                     #
 # Update Author: Mathieu Escouteloup                                          #
 # Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        #
 # -----                                                                       #
 # Description: TP 0_3_dump, script to complete (see README.md). Programs the  #
 # CW312T-A35 with bit/0_3_dump.bit (UART bootloader, program in the RAM       #
 # image), dumps the memory through the bootloader in dump/ (raw, hexadecimal  #
 # with ASCII, disassembly), then checks the keys found with the commands of   #
 # the program. With --residue (step 4), shows the RAM keeps a secret across a #
 # reset; with --direct (step 5), reads the hardware key without the program:  #
 # DUMP of its register, then a program injected by the bootloader.            #
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

# Directory of the files to complete, and of the dumps
PROG_DIR = Path(__file__).resolve().parent
DUMP_DIR = PROG_DIR / "dump"
# Example program to analyse (step 1): sw/example of this directory
EXAMPLE_NAME = "example"
# Program to inject (step 5): sw/inject of this directory
INJECT_NAME = "inject"

# Protocol of the bootloader (calf_bootloader.sv)
CMD_INIT = 0x01
CMD_PING = 0x02
CMD_DUMP = 0x03
PING_DATA = 0xaa

# Commands of the program
CMD_SECRET = b"K"
CMD_HW = b"H"
# Command of the injected program (step 5): any byte
CMD_INJECT = b"?"

# KEY_0_DATA register (sw/common/src/hw.h)
KEY_ADDR = 0x10000300
KEY_SIZE = 4

# Memory dumped: the start of the RAM (code and data), then the top of the RAM (stack)
CODE_ADDR = 0x0000
CODE_SIZE = 0x400
STACK_ADDR = 0x3f00
STACK_SIZE = 0x100

# Keys found in the dumps
SECRET_KEY = 0x00000000   # <TODO 2> value found in the code (dump/code.lst)
HW_KEY = 0x00000000       # <TODO 3> value found in the stack (dump/stack.txt)
# Address of the HW_KEY copy in the stack (step 4: remanence)
HW_COPY_ADDR = 0x00000000 # <TODO 4> address of the HW_KEY copy in the stack (found in step 3)

# ******************************************************************************
# * EXAMPLE
# ******************************************************************************
def example():
  """Step 1: build the example program sw/example (no board) and write the hexadecimal view of its memory image in
  example.txt. Its listing, with the symbol names, is in lst/example.lst.
  """

  try:
    hex_file = build.build(PROG_DIR, "sw/example", EXAMPLE_NAME)
  except RuntimeError as e:
    sys.exit(f"error: {e}")
  (PROG_DIR / "example.txt").write_text(build.hexdump(build.image(hex_file)))
  print("Example built: read lst/example.lst (with the symbols) and example.txt")

# ******************************************************************************
# * DUMP
# ******************************************************************************
def dump(uart, addr, size):
  """Read the memory through the bootloader, which then releases the core: the program starts.

  To do (step 2): send NUM = 1, then DUMP (command, ADDR on 4 bytes, SIZE on 4 bytes), read the SIZE bytes of its
  answer and return them.
  Hint: as in 0_2_boot, the timeout of uart.read must cover the answer: 10 bits per byte at uart.baud.

  IN: uart (cw312_a7_35t.Uart)
  IN: addr (int)
  IN: size (int)
  OUT: data (bytes)
  """

  # <TODO 2> NUM = 1, then DUMP, whose answer is returned
  return b""

def save(name, data, base):
  """Write a dump in dump/: <name>.bin (raw), <name>.txt (hexadecimal and ASCII) and <name>.lst (disassembly).

  IN: name (str)
  IN: data (bytes)
  IN: base (int): address of the first byte
  """

  DUMP_DIR.mkdir(exist_ok=True)
  bin_file = DUMP_DIR / f"{name}.bin"
  bin_file.write_bytes(data)
  (DUMP_DIR / f"{name}.txt").write_text(build.hexdump(data, base))
  try:
    (DUMP_DIR / f"{name}.lst").write_text(build.disasm(bin_file, base))
  except RuntimeError as e:
    print(f"warning: no disassembly: {e}")
  print(f"Dump: {len(data)} bytes at 0x{base:08x} in dump/{name}.bin, .txt and .lst")

# ******************************************************************************
# * PROGRAM
# ******************************************************************************
def program_baud(uart):
  """Switch to the baud rate of the program, once the bootloader has released the core.

  IN: uart (cw312_a7_35t.Uart)
  """

  # The ChipWhisperer sends in the background: the last bytes must have left at the baud rate of the bootloader
  time.sleep(0.1)
  uart.baud_div = cw312_a7_35t.BAUD_DIV

def check(uart, cmd, key):
  """Send a command of the program with a key, and print its answer.

  IN: uart (cw312_a7_35t.Uart)
  IN: cmd (bytes): CMD_SECRET or CMD_HW
  IN: key (int)
  """

  uart.write(cmd + key.to_bytes(4, "little"))
  try:
    print(f"Key 0x{key:08x}: {uart.readline()}")
  except TimeoutError:
    sys.exit("No answer: the program does not run")

# ******************************************************************************
# * STEP 4: REMANENCE
# ******************************************************************************
def stack_key(uart):
  """Dump the top of the RAM (the stack) and return the word at the address of the HW_KEY copy (step 3). The
  bootloader then releases the core.

  IN: uart (cw312_a7_35t.Uart)
  OUT: key (int | None): None if HW_COPY_ADDR is outside the dumped stack
  """

  data = dump(uart, STACK_ADDR, STACK_SIZE)
  off = HW_COPY_ADDR - STACK_ADDR
  if not (0 <= off <= len(data) - KEY_SIZE):
    return None
  return int.from_bytes(data[off:off + KEY_SIZE], "little")

def residue(uart):
  """Show that a reset does not erase the RAM, but the FPGA programming does. Right after the programming, the HW_KEY
  copy is absent from the stack; the program is run once so it copies the key there, and after a reset the copy is
  still found: the RAM kept it.

  IN: uart (cw312_a7_35t.Uart): bootloader waiting for its commands, right after a fresh FPGA programming
  """

  # Right after the programming, before any run: the stack holds no copy of the key
  before = stack_key(uart)
  if before is None:
    print("Remanence: do step 2 (dump) and set HW_COPY_ADDR to the address found in step 3")
    return
  # dump() released the core: the running program copies the key in the stack on command H
  program_baud(uart)
  check(uart, CMD_HW, HW_KEY)
  # Reset: the bootloader runs again, the RAM keeps its content
  uart.reset()
  uart.baud_div = cw312_a7_35t.BOOT_BAUD_DIV
  after = stack_key(uart)
  print(f"Stack copy after the FPGA programming: 0x{before:08x}")
  print(f"Stack copy after a run and a reset:    0x{after:08x}")

# ******************************************************************************
# * STEP 5: DIRECT ACCESS
# ******************************************************************************
def key_dump(uart):
  """Read the KEY_0_DATA register through the bootloader, as any memory word. The bootloader then releases the core.

  To do (step 5): read the KEY_SIZE bytes at KEY_ADDR with dump(), and return them as an integer (little-endian).

  IN: uart (cw312_a7_35t.Uart)
  OUT: key (int | None): None if the KEY_SIZE bytes were not read
  """

  # <TODO 5> dump() of KEY_0_DATA, converted to an integer
  return None

def inject(uart, image):
  """Load a program in the RAM through the bootloader, at address 0, then release the core with PING, as in 0_2_boot:
  the answer of PING comes once the whole image has been received.

  To do (step 5): send NUM = 2, INIT (ADDR = 0, SIZE, then the image), then PING; read the answer of PING and return
  True if it is PING_DATA.
  Hint: the timeout of the PING answer must cover the sending of the image: 10 bits per byte at uart.baud.

  IN: uart (cw312_a7_35t.Uart)
  IN: image (bytes): memory image from address 0
  OUT: ok (bool): PING answered
  """

  # <TODO 5> NUM = 2, INIT of the image at address 0, then PING, whose answer is checked
  return False

def direct(uart, image):
  """Read the hardware key without the program of the bitstream: DUMP of its register, then reset and injection of
  a program that sends it. The injected program replaces the one of the bitstream in the RAM.

  IN: uart (cw312_a7_35t.Uart): bootloader waiting for its commands
  IN: image (bytes): memory image of the program to inject (sw/inject)
  """

  # The bootloader reads the register as any word of the memory
  key = key_dump(uart)
  print("KEY_0_DATA by DUMP: " + (f"0x{key:08x}" if key is not None else "nothing read (key_dump)"))

  # The reset starts the bootloader again, which loads the program
  uart.reset()
  uart.baud_div = cw312_a7_35t.BOOT_BAUD_DIV
  if not inject(uart, image):
    print("Injected program: not loaded (inject)")
    return
  program_baud(uart)
  uart.write(CMD_INJECT)
  data = uart.read(KEY_SIZE)
  print("KEY_0_DATA by the injected program: "
        + (f"0x{int.from_bytes(data, 'little'):08x}" if len(data) == KEY_SIZE else "no answer (sw/inject/main.c)"))

# ******************************************************************************
# * MAIN
# ******************************************************************************
def main():
  """Program the board, dump the code then check SECRET_KEY, dump the stack then check HW_KEY, show the RAM
  remanence, read the hardware key directly, or print the progress, given the options of the command line.
  """

  parser = argparse.ArgumentParser(description="TP 0_3_dump: dumps the memory of CALF through the bootloader")
  cw312_a7_35t.add_args(parser)
  parser.add_argument("--example", action="store_true", help="Step 1: build and show the example program, then exit")
  parser.add_argument("--residue", action="store_true",
                      help="Step 4: show the RAM keeps the HW_KEY copy across a reset, but not across an FPGA "
                      "programming, then exit")
  parser.add_argument("--direct", action="store_true",
                      help="Step 5: read the hardware key by DUMP and by an injected program (replaces the program of "
                      "the RAM), then exit")
  parser.add_argument("--progress", action="store_true", help="Print the progress (TODO and DONE markers) and exit")

  ARGS = parser.parse_args()

  if ARGS.progress:
    progress.show(PROG_DIR)
    return

  if ARGS.example:
    example()
    return

  if ARGS.residue:
    try:
      with cw312_a7_35t.session(XP_DIR, ARGS, baud_div=cw312_a7_35t.BOOT_BAUD_DIV) as uart:
        residue(uart)
    finally:
      progress.summary(PROG_DIR)
    return

  if ARGS.direct:
    try:
      image = build.image(build.build(PROG_DIR, "sw/inject", INJECT_NAME))
    except RuntimeError as e:
      sys.exit(f"error: {e}")
    try:
      with cw312_a7_35t.session(XP_DIR, ARGS, baud_div=cw312_a7_35t.BOOT_BAUD_DIV) as uart:
        direct(uart, image)
    finally:
      progress.summary(PROG_DIR)
    return

  try:
    with cw312_a7_35t.session(XP_DIR, ARGS, baud_div=cw312_a7_35t.BOOT_BAUD_DIV) as uart:
      # Step 2: the code, before the program starts
      code = dump(uart, CODE_ADDR, CODE_SIZE)
      if not code:
        sys.exit("Step 2: dump() must return the bytes read")
      save("code", code, CODE_ADDR)
      program_baud(uart)
      check(uart, CMD_SECRET, SECRET_KEY)

      # Step 3: the program reads the hardware key, then the reset starts the bootloader again
      check(uart, CMD_HW, HW_KEY)
      uart.reset()
      uart.baud_div = cw312_a7_35t.BOOT_BAUD_DIV
      save("stack", dump(uart, STACK_ADDR, STACK_SIZE), STACK_ADDR)
      program_baud(uart)
      check(uart, CMD_HW, HW_KEY)
  finally:
    progress.summary(PROG_DIR)

if __name__ == "__main__":
  main()
