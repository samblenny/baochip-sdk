.PHONY: blinky blinky-bin-hex blinky-uf2-hex clean

STABLE_LIB := $(HOME)/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib
LLVM_BIN := $(STABLE_LIB)/rustlib/x86_64-unknown-linux-gnu/bin
TARGET_DIR := target/riscv32imac-unknown-none-elf/debug/examples
BLINKY := $(TARGET_DIR)/blinky

# Rebuild from scratch every time to avoid the hassle of defining the tree
# of dependencies between sources and outputs.
blinky:
	cargo clean
	cargo build --example blinky
	objdump -h $(BLINKY)
	$(LLVM_BIN)/llvm-objcopy -O binary $(BLINKY) $(BLINKY).bin
	python3 signer.py $(BLINKY).bin $(BLINKY).uf2

blinky-bin-hex:
	hexdump -C $(BLINKY).bin | less

blinky-uf2-hex:
	hexdump -C $(BLINKY).uf2 | less

clean:
	cargo clean
