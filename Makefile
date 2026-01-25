.PHONY: blinky blinky-disassemble blinky-bin-hex blinky-img-hex blinky-uf2-hex
.PHONY: uart uart-disassemble uart-bin-hex uart-img-hex uart-uf2-hex
.PHONY: clean

STABLE_LIB := $(HOME)/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib
LLVM_BIN := $(STABLE_LIB)/rustlib/x86_64-unknown-linux-gnu/bin
TARGET_DIR := target/riscv32imac-unknown-none-elf/debug/examples
BLINKY := $(TARGET_DIR)/blinky
UART := $(TARGET_DIR)/uart

# Rebuild from scratch every time to avoid the hassle of defining the tree
# of dependencies between sources and outputs.
blinky:
	cargo clean
	cargo build --example blinky
	objdump -h $(BLINKY)
	@echo '---'
	@echo '# Checking .data section LMA (FLASH) and VMA (RAM) addresses:'
	@echo 'llvm-objdump -t blinky | grep _data'
	@$(LLVM_BIN)/llvm-objdump -t $(BLINKY) | grep _data
	@echo '---'
	@echo '# Extracting loadable sections to .bin file:'
	@echo 'llvm-objcopy -O binary blinky blinky.bin'
	@$(LLVM_BIN)/llvm-objcopy -O binary $(BLINKY) $(BLINKY).bin
	@echo '---'
	@echo '# Signing .bin file:'
	python3 signer.py $(BLINKY).bin $(BLINKY).img
	@echo '---'
	@echo '# Packing signed blob as UF2:'
	python3 uf2ify.py $(BLINKY).img $(BLINKY).uf2

blinky-disassemble:
	$(LLVM_BIN)/llvm-objdump -d $(BLINKY) | less

blinky-bin-hex:
	hexdump -C $(BLINKY).bin | less

blinky-img-hex:
	hexdump -C $(BLINKY).img | less

blinky-uf2-hex:
	hexdump -C $(BLINKY).uf2 | less

uart:
	cargo clean
	cargo build --example uart
	objdump -h $(UART)
	@echo '---'
	@echo '# Checking .data section LMA (FLASH) and VMA (RAM) addresses:'
	@echo 'llvm-objdump -t uart | grep _data'
	@$(LLVM_BIN)/llvm-objdump -t $(UART) | grep _data
	@echo '---'
	@echo '# Extracting loadable sections to .bin file:'
	@echo 'llvm-objcopy -O binary uart uart.bin'
	@$(LLVM_BIN)/llvm-objcopy -O binary $(UART) $(UART).bin
	@echo '---'
	@echo '# Signing .bin file:'
	python3 signer.py $(UART).bin $(UART).img
	@echo '---'
	@echo '# Packing signed blob as UF2:'
	python3 uf2ify.py $(UART).img $(UART).uf2

uart-disassemble:
	$(LLVM_BIN)/llvm-objdump -d $(UART) | less

uart-bin-hex:
	hexdump -C $(UART).bin | less

uart-img-hex:
	hexdump -C $(UART).img | less

uart-uf2-hex:
	hexdump -C $(UART).uf2 | less

clean:
	cargo clean
