MEMORY {
    FLASH : ORIGIN = 0x60060400, LENGTH = 256K
    RAM   : ORIGIN = 0x61000000, LENGTH = 2048K
}

_data_size = SIZEOF(.data);
_bss_size = SIZEOF(.bss);
_ram_top = ORIGIN(RAM) + LENGTH(RAM);

ENTRY(_start)

SECTIONS {

    /* Mash read-only sections together for easy extraction with objcopy */
    .firmware : {
        *(.text._start);  /* initialization code MUST come first */
        *(.text*);
        . = ALIGN(16);  /* 16 to make it look pretty in hexdump -C */
        *(.rodata);
        . = ALIGN(16);
    } > FLASH

    /* Putting .data in its own section makes it easier to verify with
     * objdump -h that the LMA and VMA addressing is correct.
     */
    .data : {
        _data_lma = ABSOLUTE(.);
        _data_vma = .;
        KEEP(*(.data*));
        . = ALIGN(16);
    } > RAM AT > FLASH

    .bss (NOLOAD) : {
        _bss_vma = .;
        *(.bss);
        . = ALIGN(16);
    } > RAM

    /* This stuff is useless (stack unwinding metadata, etc.) */
    /DISCARD/ : {
        *(.eh_frame*);
        *(.comment*)
        *(.riscv.attributes*)
    }
}
