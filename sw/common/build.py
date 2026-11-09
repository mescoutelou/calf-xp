###
 # File: build.py                                                              #
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
 # Description: Builds a RISC-V program with the common software files: the    #
 # startup code and headers of sw/common/src, the linker script                #
 # sw/common/script.ld, and the sources of <dir>/src (<dir>/sw for the         #
 # experiments, with --src sw). Output: <dir>/hex/<name>.mem (bytes, for the   #
 # simulation, sim/sim.py) and <name>_word.mem (32-bit words, RAM_FILE of a    #
 # bitstream).                                                                 #
 #   python3 sw/common/build.py <dir> [--src <src>] [--name <name>]            #
 #     [-D NAME=VALUE]...                                                      #
###
#!/usr/bin/env python3


import argparse
import shutil
import subprocess
import sys
from pathlib import Path

# ******************************************************************************
# * CONFIGURATION
# ******************************************************************************
COMMON_DIR = Path(__file__).resolve().parent
COMMON_SRC_DIR = COMMON_DIR / "src"
BUILD_DIRS = ["obj", "elf", "hex", "lst", "log"]

LD_SCRIPT = COMMON_DIR / "script.ld"
START_FILE = COMMON_SRC_DIR / "start.S"
SRC_EXT = [".S", ".s", ".c"]

TOOLCHAIN = "riscv64-unknown-elf"
CC = f"{TOOLCHAIN}-gcc"
LD = f"{TOOLCHAIN}-gcc"
OBJDUMP = f"{TOOLCHAIN}-objdump"
OBJCOPY = f"{TOOLCHAIN}-objcopy"

CFLAGS = [
  "-O3", "-ffreestanding", "-nostartfiles", "-fstrict-volatile-bitfields", "-ffunction-sections", "-fdata-sections",
  "-Wall", "-Woverflow",
  "-march=rv32i_zicsr_zicntr_zbs", "-mabi=ilp32",
]
LDFLAGS = ["-nostdlib", "-Wl,--gc-sections"]

# ******************************************************************************
# * RUN / LOG
# ******************************************************************************
def run(cmd, log_dir=None):
  """Run a command, print it and its outputs (except the stdout of objdump), and log it with its errors.

  IN: cmd (list[str])
  IN: log_dir (Path | None): directory of build.log, None for no log
  OUT: result (subprocess.CompletedProcess): raises RuntimeError if the command fails
  """

  print("  $ " + " ".join(cmd))
  log(log_dir, "$ " + " ".join(cmd) + "\n")
  result = subprocess.run(cmd, capture_output=True, text=True)
  if result.stdout and cmd[0] != OBJDUMP:
    print(result.stdout, end="")
  if result.stderr:
    print(result.stderr, end="", file=sys.stderr)
    log(log_dir, result.stderr)
  if result.returncode != 0:
    raise RuntimeError(f"Command failed ({result.returncode}): {' '.join(cmd)}")
  return result

def log(log_dir, msg):
  """Append a message to build.log.

  IN: log_dir (Path | None): directory of build.log, None for no log
  IN: msg (str)
  """

  if log_dir is not None:
    with open(log_dir / "build.log", "a") as log_f:
      log_f.write(msg)

# ******************************************************************************
# * ENVIRONMENT
# ******************************************************************************
def build_dirs(prog_dir):
  """Create the generated directories of a program: obj, elf, hex, lst and log.

  IN: prog_dir (Path)
  """

  for d in BUILD_DIRS:
    (prog_dir / d).mkdir(parents=True, exist_ok=True)

def clean(prog_dir):
  """Remove the generated directories of a program.

  IN: prog_dir (Path)
  """

  for d in BUILD_DIRS:
    shutil.rmtree(prog_dir / d, ignore_errors=True)

# ******************************************************************************
# * SOURCES
# ******************************************************************************
def src_files(src_dir):
  """Return the sources to compile: start.S of sw/common/src first, so that _start comes first, then all the
  .S/.s/.c files under the src directory of the program.

  IN: src_dir (Path)
  OUT: src_list (list[Path])
  """

  return [START_FILE] + sorted(f for f in src_dir.rglob("*") if f.is_file() and f.suffix in SRC_EXT)

def inc_dirs(src_dir):
  """Return the include path: sw/common/src, then every directory under the src directory of the program holding a
  header.

  IN: src_dir (Path)
  OUT: dir_list (list[Path])
  """

  return [COMMON_SRC_DIR] + sorted({f.parent for f in src_dir.rglob("*.h")})

def obj_file(src, src_dir, obj_dir):
  """Return the object file of a source. The object files mirror the src tree, so two files with the same name in
  different directories do not collide.

  IN: src (Path)
  IN: src_dir (Path)
  IN: obj_dir (Path)
  OUT: obj (Path)
  """

  if src == START_FILE:
    return obj_dir / "start.o"
  return obj_dir / src.relative_to(src_dir).with_suffix(".o")

# ******************************************************************************
# * COMPILE
# ******************************************************************************
def word_file(hex_file):
  """Return the word hex file that goes with a byte hex file: `<name>_word.mem`.

  IN: hex_file (Path)
  OUT: word_file (Path)
  """

  return hex_file.with_name(f"{hex_file.stem}_word.mem")

def image(hex_file):
  """Read a byte hex file (objcopy -O verilog: '@<address>' tokens, then one byte per token) as the memory image
  from address 0, e.g. to send it to the bootloader. The gaps are filled with 0.

  IN: hex_file (Path | str)
  OUT: image (bytes)
  """

  data = bytearray()
  addr = 0

  for token in Path(hex_file).read_text().split():
    if token[0] == "@":
      addr = int(token[1:], 16)
      continue
    if addr >= len(data):
      data.extend(bytes(addr + 1 - len(data)))
    data[addr] = int(token, 16)
    addr += 1
  return bytes(data)

def hexdump(data, base=0):
  """Write a memory image as text: 16 bytes per line, with their address, their hexadecimal values and their ASCII
  characters ('.' when not printable).

  IN: data (bytes)
  IN: base (int): address of the first byte
  OUT: text (str)
  """

  lines = []
  for a in range(0, len(data), 16):
    line = data[a:a + 16]
    ascii = "".join(chr(b) if 0x20 <= b < 0x7f else "." for b in line)
    lines.append(f"{base + a:08x}  {line.hex(' '):<47}  {ascii}")
  return "\n".join(lines) + "\n"

def disasm(bin_file, base=0):
  """Disassemble a raw memory image (no symbols): every word is shown as an instruction, the data too. Raises
  RuntimeError if objdump fails.

  IN: bin_file (Path | str): raw image
  IN: base (int): address of the first byte
  OUT: text (str): listing of objdump
  """

  cmd = [OBJDUMP, "-D", "-b", "binary", "-m", "riscv:rv32", "-M", "numeric", f"--adjust-vma={base:#x}", str(bin_file)]
  try:
    result = subprocess.run(cmd, capture_output=True, text=True)
  except FileNotFoundError:
    raise RuntimeError(f"{OBJDUMP} not found (add the RISC-V toolchain to the PATH)")
  if result.returncode != 0:
    raise RuntimeError(result.stderr.strip())
  return result.stdout

def compile(prog_dir, src, name, define):
  """Compile and link a program, then write its listing, its byte hex file (ext_readmemh of calf_ram, Verilator) and
  its word hex file (RAM_FILE of calf_ram).

  IN: prog_dir (Path): directory with the sources, and the generated directories
  IN: src (str): directory of the sources in prog_dir
  IN: name (str): name of the output files
  IN: define (dict[str, str]): defines of the compilation
  OUT: hex_file (Path): byte hex file
  """

  print(f"Building '{name}'...")

  SRC_DIR = prog_dir / src
  OBJ_DIR = prog_dir / "obj"
  LOG_DIR = prog_dir / "log"
  ELF_FILE = prog_dir / "elf" / f"{name}.elf"
  LST_FILE = prog_dir / "lst" / f"{name}.lst"
  HEX_FILE = prog_dir / "hex" / f"{name}.mem"

  INC_FLAGS = [f"-I{d}" for d in inc_dirs(SRC_DIR)]
  DEF_FLAGS = [f"-D{k}={v}" for k, v in define.items()]

  obj_list = []
  for src in src_files(SRC_DIR):
    obj = obj_file(src, SRC_DIR, OBJ_DIR)
    obj.parent.mkdir(parents=True, exist_ok=True)
    run([CC] + CFLAGS + DEF_FLAGS + INC_FLAGS + ["-c", str(src), "-o", str(obj)], LOG_DIR)
    obj_list.append(str(obj))

  run([LD] + CFLAGS + LDFLAGS + ["-T", str(LD_SCRIPT)] + obj_list + ["-o", str(ELF_FILE)], LOG_DIR)
  with open(LST_FILE, "w") as lst_f:
    lst_f.write(run([OBJDUMP, "-D", "-M", "numeric", str(ELF_FILE)], LOG_DIR).stdout)
  # Byte hex format, as expected by calf_ram's ext_readmemh (Verilator)
  run([OBJCOPY, "-O", "verilog", str(ELF_FILE), str(HEX_FILE)], LOG_DIR)
  # Word hex format, as expected by calf_ram's RAM_FILE
  run([OBJCOPY, "-O", "verilog", "--verilog-data-width=4", str(ELF_FILE), str(word_file(HEX_FILE))], LOG_DIR)
  run([f"{TOOLCHAIN}-size", str(ELF_FILE)], LOG_DIR)
  return HEX_FILE

def build(prog_dir, src="src", name=None, define={}):
  """Clean and build a program. Raises RuntimeError if it has no source directory or if a command fails.

  IN: prog_dir (Path | str): directory with the sources
  IN: src (str): directory of the sources in prog_dir
  IN: name (str | None): name of the output files, the one of the directory when None
  IN: define (dict[str, str]): defines of the compilation
  OUT: hex_file (Path): byte hex file
  """

  prog_dir = Path(prog_dir).resolve()
  if not (prog_dir / src).is_dir():
    raise RuntimeError(f"{prog_dir} has no {src} directory")

  clean(prog_dir)
  build_dirs(prog_dir)
  return compile(prog_dir, src, name or prog_dir.name, define)

# ******************************************************************************
# * MAIN
# ******************************************************************************
def main():
  """Build the program given on the command line, or clean it."""

  parser = argparse.ArgumentParser(description="Build a RISC-V program with the common software files (experiments: use xp/gen.py)")

  parser.add_argument("dir", type=Path, help="Program directory, with the source directory (e.g. xp/S0_1_uart)")
  parser.add_argument("--src", default="src", help="Source directory in dir (default: src, experiments: sw)")
  parser.add_argument("--name", help="Program name (default: directory name)")
  parser.add_argument("-D", dest="define", action="append", default=[], metavar="NAME=VALUE", help="Define, repeatable")
  parser.add_argument("--clean", action="store_true", help="Remove generated directories and exit")

  ARGS = parser.parse_args()

  if ARGS.clean:
    clean(ARGS.dir.resolve())
    return

  try:
    build(ARGS.dir, ARGS.src, ARGS.name, dict(d.split("=", 1) for d in ARGS.define))
  except RuntimeError as e:
    print(e, file=sys.stderr)
    sys.exit(1)

if __name__ == "__main__":
  main()
