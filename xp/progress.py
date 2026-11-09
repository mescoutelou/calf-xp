###
 # File: progress.py                                                           #
 # License: See LICENSE file                                                   #
 # Copyright (c) 2026 HerdWare                                                 #
 # -----                                                                       #
 # Created On: 2026-11-05 11:00:00 am                                          #
 # Initial Author: Mathieu Escouteloup                                         #
 # Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       #
 # -----                                                                       #
 # Last Updated On: 2026-11-06 12:30:00 am                                     #
 # Update Author: Mathieu Escouteloup                                          #
 # Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        #
 # -----                                                                       #
 # Description: Progress of an experiment: each part to complete is marked by  #
 # a <TODO N> comment, N being its step in the README.md, that the student     #
 # replaces by <DONE N> once the part is finished. Lists the markers of the    #
 # source files of an experiment (README.md and generated directories left     #
 # out), in step order, with the function or label they are in. A marker       #
 # without its step (<TODO>, <DONE>) is listed last, with a warning:           #
 #   python3 xp/progress.py [<xp_dir>]...                                      #
 #   progress.show(xp_dir)       (in xp.py, --progress)                        #
 #   progress.summary(xp_dir)    (in xp.py, at the end of a run)               #
###
#!/usr/bin/env python3


import argparse
import re
from pathlib import Path

# ******************************************************************************
# * CONFIGURATION
# ******************************************************************************
XP_DIR = Path(__file__).resolve().parent

# <TODO N> or <DONE N>: N is the step; without it, the marker is malformed
MARKER_RE = re.compile(r"<(TODO|DONE)(?:\s+(\d+))?>\s*(.*)")
SRC_EXT = [".py", ".c", ".h", ".S", ".s", ".sv", ".svh", ".xdc", ".tcl"]
# Generated directories
SKIP_DIRS = ["bit", "dump", "elf", "hex", "log", "lst", "obj", "vcd", "verilator", "xpr", "__pycache__"]

# Line that opens the context of a marker, by file extension
CONTEXT_RE = {
  ".py": re.compile(r"^\s*def\s+(\w+)"),
  ".S": re.compile(r"^([A-Za-z_]\w*):"),
  ".s": re.compile(r"^([A-Za-z_]\w*):"),
  ".c": re.compile(r"^[A-Za-z_][\w\s\*]*?\b(\w+)\s*\([^;]*$"),
  ".h": re.compile(r"^[A-Za-z_][\w\s\*]*?\b(\w+)\s*\([^;]*$"),
  ".sv": re.compile(r"^\s*module\s+(\w+)"),
}

# ******************************************************************************
# * MARKER
# ******************************************************************************
def src_files(xp_dir):
  """Return the source files of an experiment, without its generated directories.

  IN: xp_dir (Path)
  OUT: file_list (list[Path])
  """

  return sorted(f for f in xp_dir.rglob("*")
                if f.is_file() and (f.suffix in SRC_EXT) and not set(f.relative_to(xp_dir).parts[:-1]) & set(SKIP_DIRS))

def context(line_list, n, suffix):
  """Return the name of the function, label or module a line is in: the last one opened before it.

  IN: line_list (list[str]): lines of the file
  IN: n (int): index of the line
  IN: suffix (str): extension of the file
  OUT: name (str | None): None if unknown
  """

  r = CONTEXT_RE.get(suffix)
  if r is None:
    return None
  for line in reversed(line_list[:n + 1]):
    m = r.match(line)
    if m:
      return m.group(1)
  return None

def marker_list(xp_dir):
  """Return the <TODO N> and <DONE N> markers of an experiment, in step order, then in file and line order. The
  markers without step come last.

  IN: xp_dir (Path | str): experiment directory
  OUT: marker_list (list[dict]): file (Path, relative to xp_dir), line (int, from 1), done (bool), step (int | None):
       None if the marker has no step, context (str | None), text (str): comment after the marker
  """

  xp_dir = Path(xp_dir).resolve()
  out = []
  for f in src_files(xp_dir):
    line_list = f.read_text(errors="replace").split("\n")
    for n, line in enumerate(line_list):
      m = MARKER_RE.search(line)
      if m:
        out.append({
          "file": f.relative_to(xp_dir),
          "line": n + 1,
          "done": m.group(1) == "DONE",
          "step": int(m.group(2)) if m.group(2) else None,
          "context": context(line_list, n, f.suffix),
          "text": m.group(3).removesuffix("*/").strip(),
        })
  return sorted(out, key=lambda m: (m["step"] is None, m["step"] or 0, str(m["file"]), m["line"]))

# ******************************************************************************
# * DISPLAY
# ******************************************************************************
def marker_text(marker):
  """Write a marker on one line: state, step, place, then its comment.

  IN: marker (dict): from marker_list
  OUT: text (str)
  """

  step = f"step {marker['step']}" if marker["step"] is not None else "step ? (marker without step number)"
  where = f"{marker['file']}:{marker['line']}" + (f" ({marker['context']})" if marker["context"] else "")
  return f"[{'x' if marker['done'] else ' '}] {step}, {where}" + (f": {marker['text']}" if marker["text"] else "")

def warning(marker):
  """Return the warning for the markers without step, if any.

  IN: marker (list[dict]): from marker_list
  OUT: text (str | None)
  """

  bad = [m for m in marker if m["step"] is None]
  if not bad:
    return None
  where = ", ".join(f"{m['file']}:{m['line']}" for m in bad)
  return f"warning: marker without step number ({where}): write <TODO N> or <DONE N>, N being the step"

def show(xp_dir):
  """Print the progress of an experiment: the number of parts done, then each marker.

  IN: xp_dir (Path | str): experiment directory
  """

  xp_dir = Path(xp_dir).resolve()
  marker = marker_list(xp_dir)
  done_n = sum(m["done"] for m in marker)
  print(f"Progress of {xp_dir.name}: {done_n}/{len(marker)} done")
  for m in marker:
    print(f"  {marker_text(m)}")
  if warning(marker):
    print(f"  {warning(marker)}")

def summary(xp_dir):
  """Print the progress of an experiment on one line, with the next part to do.

  IN: xp_dir (Path | str): experiment directory
  """

  marker = marker_list(xp_dir)
  todo = [m for m in marker if not m["done"]]
  text = f"Progress: {len(marker) - len(todo)}/{len(marker)} done"
  if todo:
    text += f", next {marker_text(todo[0])[4:]} (--progress: all)"
  print(text)
  if warning(marker):
    print(warning(marker))

# ******************************************************************************
# * MAIN
# ******************************************************************************
def main():
  """Print the progress of the experiments given on the command line, of all of them by default."""

  parser = argparse.ArgumentParser(description="Progress of the experiments: <TODO N> and <DONE N> markers")

  parser.add_argument("xp_dir", type=Path, nargs="*", help="Experiment directory (default: all of xp/)")

  ARGS = parser.parse_args()

  xp_list = ARGS.xp_dir or sorted(d for d in XP_DIR.iterdir() if d.is_dir() and re.fullmatch(r"S?\d+_\d+_\w+", d.name))
  for d in xp_list:
    show(d)

if __name__ == "__main__":
  main()
