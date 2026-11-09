###
 # File: cw312_a7_35t.tcl                                                      #
 # License: See LICENSE file                                                   #
 # Copyright (c) 2026 HerdWare                                                 #
 # -----                                                                       #
 # Created On: 2026-10-20 10:26:14 am                                          #
 # Initial Author: Mathieu Escouteloup                                         #
 # Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       #
 # -----                                                                       #
 # Last Updated On: 2026-11-05 07:00:00 pm                                     #
 # Update Author: Mathieu Escouteloup                                          #
 # Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        #
 # -----                                                                       #
 # Description: Vivado project flow for calf_cw312_a7_35t: (re)creates the     #
 # project, then runs synthesis, implementation and bitstream generation.      #
 # Usage (from any directory):                                                 #
 #   vivado -mode batch -nojournal -nolog                                      #
 #     -source implem/xilinx/src/cw312_a7_35t.tcl                              #
 #     [-tclargs [-boot <0|1>] [-ram <ram_file>] [-key <key>]                  #
 #               [-hw <hw_dir>]... [-xpr <xpr_dir>]]                           #
 # -boot (0 = RAM image, 1 = UART bootloader) overrides BOOT_MODE of the top,  #
 # the top default is kept when omitted. -ram (32-bit word hex file, as        #
 # objcopy -O verilog --verilog-data-width=4) sets RAM_FILE of the top: the    #
 # program is in the bitstream. -key (32-bit, hexadecimal) sets KEY of the     #
 # top, value of the read-only KEY 0 register. -hw adds the .sv and .xdc files #
 # of a directory (not recursive), in order: a file replaces the one with the  #
 # same name in src/main/sv or implem/xilinx/src, the others are added. -xpr   #
 # is the project directory, implem/xilinx/xpr by default. Sources are         #
 # referenced, not copied: the project can be opened in the GUI to edit them.  #
###


# ******************************************************************************
# * CONFIGURATION
# ******************************************************************************
set SRC_DIR     [file dirname [file normalize [info script]]]
set IMPLEM_DIR  [file dirname $SRC_DIR]
set ROOT_DIR    [file dirname [file dirname $IMPLEM_DIR]]
set SV_DIR      [file join $ROOT_DIR src main sv]

set BOARD       "cw312_a7_35t"
set TOP         "calf_${BOARD}"
set PART        "xc7a35tcsg324-1"

# Packages first, in dependency order
set SV_PKG [list \
  calf_riscv_pkg.sv \
  calf_priv_pkg.sv \
  calf_core_pkg.sv \
  calf_addr_pkg.sv \
  calf_sys_pkg.sv \
]

# ******************************************************************************
# * ARGUMENT
# ******************************************************************************
set USAGE "usage: vivado -mode batch -source [info script] \[-tclargs \[-boot <0|1>\] \[-ram <ram_file>\] \[-key <key>\] \[-hw <hw_dir>\]... \[-xpr <xpr_dir>\]\]"

set GENERIC [list]
set HW_DIR_LIST [list]
set XPR_DIR [file join $IMPLEM_DIR xpr]

if {$argc % 2} {
  error $USAGE
}
# Paths are made absolute: synthesis does not run from the caller directory
foreach {OPT VAL} $argv {
  switch -- $OPT {
    -boot {
      if {$VAL ni {0 1}} {
        error "-boot must be 0 (RAM image) or 1 (UART bootloader), got '$VAL'"
      }
      lappend GENERIC "BOOT_MODE=1'b$VAL"
    }
    -ram {
      set RAM_FILE [file normalize $VAL]
      if {![file exists $RAM_FILE]} {
        error "ram_file '$RAM_FILE' not found"
      }
      # RAM_FILE_CHAR_N_MAX of calf_sys_pkg.sv
      if {[string length $RAM_FILE] > 128} {
        error "ram_file path above 128 characters: '$RAM_FILE'"
      }
      lappend GENERIC "RAM_FILE=\"$RAM_FILE\""
    }
    -key {
      if {![regexp {^(0x)?[0-9a-fA-F]{1,8}$} $VAL]} {
        error "-key must be a 32-bit hexadecimal value, got '$VAL'"
      }
      lappend GENERIC "KEY=32'h[regsub {^0x} $VAL {}]"
    }
    -hw {
      set HW_DIR [file normalize $VAL]
      if {![file isdirectory $HW_DIR]} {
        error "hw_dir '$HW_DIR' not found"
      }
      lappend HW_DIR_LIST $HW_DIR
    }
    -xpr {
      set XPR_DIR [file normalize $VAL]
    }
    default {
      error $USAGE
    }
  }
}

# ******************************************************************************
# * PROJECT
# ******************************************************************************
# Keeps the Vivado temporary files (.Xil) out of the caller directory
file mkdir $XPR_DIR
cd $XPR_DIR

# Always recreated: this script is the reference, not the .xpr
create_project -force $BOARD $XPR_DIR -part $PART

# ******************************************************************************
# * SOURCE
# ******************************************************************************
# Files by name: a file of a hw directory replaces the one with the same name
set SV_DICT [dict create]
foreach f $SV_PKG {
  dict set SV_DICT $f [file join $SV_DIR $f]
}
foreach f [lsort [glob -directory $SV_DIR *.sv]] {
  if {[file tail $f] ni $SV_PKG} {
    dict set SV_DICT [file tail $f] $f
  }
}
dict set SV_DICT ${BOARD}.sv [file join $SRC_DIR ${BOARD}.sv]
set XDC_DICT [dict create ${BOARD}.xdc [file join $SRC_DIR ${BOARD}.xdc]]

foreach d $HW_DIR_LIST {
  foreach f [lsort [glob -nocomplain -directory $d *.sv *.xdc]] {
    set NAME [file tail $f]
    if {[file extension $f] eq ".sv"} {
      set DICT_NAME SV_DICT
    } else {
      set DICT_NAME XDC_DICT
    }
    if {[dict exists [set $DICT_NAME] $NAME]} {
      puts "INFO: \[hw\] $f replaces [dict get [set $DICT_NAME] $NAME]"
    } else {
      puts "INFO: \[hw\] $f added"
    }
    dict set $DICT_NAME $NAME $f
  }
}

# Packages first: those of src/main/sv in dependency order, then the added ones
set SV_LIST [list]
set SV_OTHER_LIST [list]
dict for {NAME f} $SV_DICT {
  if {[string match *_pkg.sv $NAME]} {
    lappend SV_LIST $f
  } else {
    lappend SV_OTHER_LIST $f
  }
}
set SV_LIST [concat $SV_LIST $SV_OTHER_LIST]

add_files -fileset sources_1 $SV_LIST
set_property file_type SystemVerilog [get_files $SV_LIST]
set_property top $TOP [get_filesets sources_1]
set_property generic $GENERIC [get_filesets sources_1]

add_files -fileset constrs_1 [dict values $XDC_DICT]

# ******************************************************************************
# * SYNTHESIS
# ******************************************************************************
launch_runs synth_1
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
  error "synthesis failed, see [get_property DIRECTORY [get_runs synth_1]]/runme.log"
}

# ******************************************************************************
# * IMPLEMENTATION AND BITSTREAM
# ******************************************************************************
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
  error "implementation failed, see [get_property DIRECTORY [get_runs impl_1]]/runme.log"
}

# Not fatal: HS2 can run below the constrained frequency
set WNS [get_property STATS.WNS [get_runs impl_1]]
if {$WNS ne "" && $WNS < 0} {
  puts "CRITICAL WARNING: timing not met (WNS = $WNS ns), see [get_property DIRECTORY [get_runs impl_1]]/${TOP}_timing_summary_routed.rpt"
}

puts "Project: [file join $XPR_DIR ${BOARD}.xpr]"
puts "Bitstream: [file join [get_property DIRECTORY [get_runs impl_1]] ${TOP}.bit]"
