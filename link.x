MEMORY {
    /* 0x60300 here matches the bootloader's initial jump to 768 */
    FLASH : ORIGIN = 0x60060300, LENGTH = 2096384  /* 2M - 768 */
    RAM   : ORIGIN = 0x61000000, LENGTH = 2048K
}

_data_lma = LOADADDR(.data);
_data_size = SIZEOF(.data);
_bss_size = SIZEOF(.bss);
_ram_top = ORIGIN(RAM) + LENGTH(RAM);
_scratch_stack = _ram_top - 16; /* reserved for trap handler (DMA gutter!) */
_stack_base = _ram_top - 4K; /* no DMA gutter here because already below top */

ENTRY(_start)

SECTIONS {

    /* Mash read-only sections together for easy extraction with objcopy */
    .firmware : {
        *(.text._start)  /* initialization code MUST come first */
        . = ALIGN(16);   /* _trap must be aligned or bad stuff will happen */
        *(.text._trap)
        *(.text*)
        . = ALIGN(16);   /* 16 to make it look pretty in hexdump -C */
        *(.rodata*)
        . = ALIGN(16);
        *(.srodata*)
        . = ALIGN(16);
    } > FLASH

    /* This gets its own section to make the LMA & VMA addressing clear */
    .data : {
        _data_vma = .;
        __global_pointer = . + 0x800; /* for initializing gp */
        KEEP(*(.data*))
        . = ALIGN(16);
        KEEP(*(.sdata*))
        . = ALIGN(16);
    } > RAM AT > FLASH

    .bss (NOLOAD) : {
        _bss_vma = .;
        *(.bss*)
        . = ALIGN(16);
        *(.sbss*)
        . = ALIGN(16);
    } > RAM

    /* Drop these for smaller file size and better reproducibility. These
     * sections have stack unwinding metadata, gdb stuff, etc.
     */
    /DISCARD/ : {
        *(.eh_frame*)
        *(.comment*)
        *(.riscv.attributes*)
        *(.debug*)
    }
}
