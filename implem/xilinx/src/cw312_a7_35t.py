###
 # File: cw312_a7_35t.py                                                       #
 # License: See LICENSE file                                                   #
 # Copyright (c) 2026 HerdWare                                                 #
 # -----                                                                       #
 # Created On: 2026-11-04 02:40:00 pm                                          #
 # Initial Author: Mathieu Escouteloup                                         #
 # Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       #
 # -----                                                                       #
 # Last Updated On: 2026-11-05 07:00:00 pm                                     #
 # Update Author: Mathieu Escouteloup                                          #
 # Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        #
 # -----                                                                       #
 # Description: Host side of the experiments on the CW312T-A35 with a          #
 # ChipWhisperer Husky. The bitstream of an experiment (xp/<tp>/bit/<tp>.bit,  #
 # made by xp/gen.py) holds the design and the program in the RAM image:       #
 # programs the FPGA, clocks it on HS2, resets the core and gives a Uart       #
 # object to exchange bytes with the program:                                  #
 #   with cw312_a7_35t.session(xp_dir, args) as uart:                          #
 #     uart.write(b"...")                                                      #
 #     data = uart.read(4)                                                     #
###


import contextlib
import sys
import time
from pathlib import Path

import chipwhisperer as cw
from chipwhisperer.hardware.naeusb.programmer_targetfpga import CW312T_XC7A35T

# ******************************************************************************
# * CONFIGURATION
# ******************************************************************************
# HS2 is the system clock: 25 MHz is the frequency constrained in the .xdc,
# and CLK_FREQ of sw/common/src/hw.h
CLK_FREQ = 25e6
# UART_BAUD of uart.h: uart_init() sets BAUD_DIV, baud rate = HS2 / BAUD_DIV
BAUD = 9600
BAUD_DIV = int(CLK_FREQ) // BAUD
# UART_BAUD_INIT_N of calf_sys_pkg.sv: BAUD_DIV on reset, used by the bootloader
BOOT_BAUD_DIV = 5208
PROG_SPEED = 10e6

def bit_file(xp_dir):
  """Return the bitstream of an experiment: `bit/<tp>.bit` in its student directory.

  IN: xp_dir (Path | str): student directory of the experiment
  OUT: bit_file (Path)
  """

  xp_dir = Path(xp_dir).resolve()
  return xp_dir / "bit" / f"{xp_dir.name}.bit"

# ******************************************************************************
# * UART
# ******************************************************************************
class Uart:
  """Raw access to the UART of the target through the SimpleSerial target of the ChipWhisperer. Timeouts are in
  seconds.
  """

  def __init__(self, target, freq, scope):
    self.target = target                         # SimpleSerial target, already set to the baud rate
    self.freq = freq                             # HS2 frequency, in Hz
    self.scope = scope                           # ChipWhisperer scope, for the reset

  @property
  def baud(self):
    """Baud rate of the ChipWhisperer side.

    OUT: baud (int)
    """

    return self.target.baud

  @property
  def baud_div(self):
    """Divider of HS2 that gives the baud rate, as BAUD_DIV of the UART of CALF.

    OUT: baud_div (int)
    """

    return round(self.freq / self.target.baud)

  @baud_div.setter
  def baud_div(self, baud_div):
    """Set the baud rate of the ChipWhisperer side to the one of a BAUD_DIV of CALF, e.g. BOOT_BAUD_DIV for the
    bootloader, then BAUD_DIV once the program has called uart_init().

    IN: baud_div (int)
    """

    self.target.baud = round(self.freq / baud_div)

  def write(self, data):
    """Send bytes to the target.

    IN: data (bytes | bytearray | list[int])
    """

    self.target.write(bytes(data))

  def read(self, n, timeout=1.0):
    """Wait for bytes from the target: fewer are returned when the timeout expires first.

    IN: n (int): bytes to wait for
    IN: timeout (float): seconds
    OUT: data (bytes)
    """

    return self.target.read(n, max(1, int(timeout * 1000))).encode("latin-1")

  def readline(self, timeout=1.0):
    """Read a line of text from the target, up to its '\\n'.

    IN: timeout (float): seconds for the whole line, else TimeoutError
    OUT: line (str): without its '\\n'
    """

    line = bytearray()
    end = time.monotonic() + timeout

    while not line.endswith(b"\n"):
      left = end - time.monotonic()
      data = self.read(1, left) if left > 0 else b""
      if not data:
        raise TimeoutError(f"incomplete line after {timeout} s: {bytes(line)!r}")
      line += data
    return line[:-1].decode("latin-1")

  def flush(self):
    """Drop the bytes already received."""

    self.target.flush()

  def reset(self):
    """Reset the core: the program, or the bootloader with a bitstream that has one, starts again. The RAM keeps its
    content. The baud rate of the ChipWhisperer side is left as it is.
    """

    reset(self.scope, self.target)

# ******************************************************************************
# * CHIPWHISPERER
# ******************************************************************************
def fpga_program(scope, bit_file):
  """Program the FPGA of the CW312T-A35 with a bitstream, HS2 stopped: it makes the programming less reliable (see
  CW312T_XC7A35T). Exits if the bitstream is missing.

  IN: scope (chipwhisperer scope)
  IN: bit_file (Path)
  """

  if not bit_file.exists():
    sys.exit(f"error: {bit_file} not found")

  print(f"Programming {bit_file}...", flush=True)
  scope.io.hs2 = None
  fpga = CW312T_XC7A35T(scope)
  fpga.program(str(bit_file), sck_speed=PROG_SPEED)

def clock_setup(scope, freq):
  """Start the clock of CALF on HS2. Exits if the clock generator does not lock.

  IN: scope (chipwhisperer scope)
  IN: freq (float): HS2 frequency asked for, in Hz
  OUT: freq (float): HS2 frequency reached, in Hz
  """

  scope.clock.clkgen_freq = freq
  if scope._is_husky:
    # The ADC is not used: keeps its clock in range whatever the HS2 frequency
    scope.clock.adc_mul = 1
  scope.io.hs2 = "clkgen"
  if not scope.try_wait_clkgen_locked(10):
    sys.exit("error: ChipWhisperer clock generator not locked")
  return scope.clock.clkgen_freq

def reset(scope, target):
  """Reset the core through nRST, pulled up by the target board. The program starts on the release: what it sends
  from then on is kept by the ChipWhisperer until read.

  IN: scope (chipwhisperer scope)
  IN: target (chipwhisperer SimpleSerial target): its received bytes are dropped during the reset
  """

  scope.io.nrst = "low"
  time.sleep(0.05)
  target.flush()
  scope.io.nrst = "high_z"

# ******************************************************************************
# * SESSION
# ******************************************************************************
def add_args(parser):
  """Add the options of session to the command line of an experiment: --bit, --no-prog and --freq.

  IN: parser (argparse.ArgumentParser)
  """

  parser.add_argument("--bit", type=Path, help="Bitstream (default: xp/<tp>/bit/<tp>.bit)")
  parser.add_argument("--no-prog", action="store_true", help="Skip the FPGA programming (bitstream already loaded)")
  parser.add_argument("--freq", type=float, default=CLK_FREQ, help=f"HS2 frequency in Hz, must match CLK_FREQ in hw.h (default: {CLK_FREQ:.0f})")

@contextlib.contextmanager
def session(xp_dir, args, baud_div=BAUD_DIV):
  """Program the FPGA with the bitstream of an experiment (unless args.no_prog), start HS2 and reset the core, then
  give the UART connected to the program. Used by a with: the ChipWhisperer is disconnected when it ends, even on an
  error.

  IN: xp_dir (Path | str): student directory of the experiment
  IN: args (argparse.Namespace): options of add_args
  IN: baud_div (int): BAUD_DIV of CALF at the start, BOOT_BAUD_DIV for a bitstream with the bootloader
  OUT: uart (Uart)
  """

  scope = cw.scope()
  # SimpleSerial target: only used for its raw access to the UART
  target = cw.target(scope)
  try:
    # tio1 = serial RX (IO1, target TX), tio2 = serial TX (IO2, target RX)
    scope.default_setup(verbose=False)

    if not args.no_prog:
      fpga_program(scope, args.bit or bit_file(xp_dir))

    freq = clock_setup(scope, args.freq)
    target.baud = round(freq / baud_div)
    print(f"HS2 = {freq / 1e6:.3f} MHz, baud = {target.baud}", flush=True)

    reset(scope, target)
    yield Uart(target, freq, scope)
  finally:
    target.dis()
    scope.dis()
