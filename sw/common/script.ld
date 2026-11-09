/*
 * File: script.ld                                                             *
 * License: See LICENSE file                                                   *
 * Copyright (c) 2026 HerdWare                                                 *
 * -----                                                                       *
 * Created On: 2026-10-08 07:46:10 am                                          *
 * Initial Author: Mathieu Escouteloup                                         *
 * Initial Email: mathieu.escouteloup@enseirb-matmeca.fr                       *
 * -----                                                                       *
 * Last Updated On: 2026-10-20 09:53:39 am                                     *
 * Update Author: Mathieu Escouteloup                                          *
 * Update Email: mathieu.escouteloup@enseirb-matmeca.fr                        *
 * -----                                                                       *
 * Description:                                                                *
 */


MEMORY
{
  RAM      (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00004000
}

BOOT_PC     = 0x00000000;
STACK_SIZE  = 0x00000100;

SECTIONS
{  
  .text :
  {
    KEEP(*start.o(.text*));
    *(.text*);
  } > RAM

  .rodata :
  {
    *(.rodata*);
    *(.srodata*);
  } > RAM

  .data :
  {
    _sdata = . ;
    *(.data*);
    *(.sdata*);
    _edata = . ;
  } > RAM

  __global_pointer$ = _sdata + 0x800;

  .bss :
  {
    *(.bss*);
    *(.sbss*);
    *(COMMON);
  } > RAM

  .stack (ORIGIN(RAM) + LENGTH(RAM) - STACK_SIZE) (NOLOAD):
  {
    . = ALIGN(8);
    . = . + STACK_SIZE;
    . = ALIGN(8);
    __stack = . ;
  } > RAM
}
