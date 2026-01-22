MEMORY {
	FLASH : ORIGIN = 0x60060400, LENGTH = 256K
	RAM   : ORIGIN = 0x61000000, LENGTH = 2048K
}

_stack_size = 32K;
_heap_size = 512K;

ENTRY(_start)

SECTIONS {
	.init :
	{
		KEEP(*(.text.init));
	} > FLASH

	.text : ALIGN(4)
	{
		KEEP(*(.text));
	} > FLASH

	.rodata : ALIGN(4)
	{
		*(.rodata);
	} > FLASH

	.data : ALIGN(4)
	{
		_idata_start = LOADADDR(.data);
		_data_start = .;
		*(.data);
		. = ALIGN(4);
		_data_end = .;
	} > RAM AT > FLASH

	.bss : ALIGN(4)
	{
		_bss_start = .;
		*(.bss);
		. = ALIGN(4);
		_bss_end = .;
	} > RAM

	.heap (NOLOAD) : ALIGN(4)
	{
		_heap_start = .;
		. += _heap_size;
		_heap_end = .;
	} > RAM AT > RAM

	.stack (NOLOAD) : ALIGN(4)
	{
		_stack_start = .;
		. += _stack_size;
		. = ALIGN(4096);  /* assume 4KB cache line */
		_stack_end = .;
	} > RAM AT > RAM
}

ASSERT(_idata_start + SIZEOF(.data) <= ORIGIN(FLASH) + LENGTH(FLASH),
	"ERROR: .data exceeds end of FLASH")

ASSERT(_stack_end <= ORIGIN(RAM) + LENGTH(RAM), ".stack exceeds end of RAM")
