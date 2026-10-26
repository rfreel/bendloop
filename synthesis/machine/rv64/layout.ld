ENTRY(synth4_eval)
SECTIONS {
  . = 0x80000000;
  .text : { *(.text) }
  /DISCARD/ : { *(.comment) *(.riscv.attributes) }
}
