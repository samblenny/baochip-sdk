// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2026 Sam Blenny
//
//! Generic wrapper for C examples using dabao_sdk drivers
//!
//! This example demonstrates how to build C code that uses the dabao_sdk
//! Rust drivers. The C code defines main() which is called by the Rust
//! lib.rs _start() entry point after hardware initialization.
//!
//! Key constraint: C main() must never return. It should loop forever.
//! This allows a single entry point through lib.rs _start().
//!
//! To use this pattern with a C example:
//! 1. Create examples/foo_c.c with an int main() function that never returns
//! 2. Compile C to static library with gcc and ar
//! 3. Build this wrapper with RUSTFLAGS linking the C library
//! 4. The Rust lib.rs _start() initializes hardware and calls C's main()
//!
//! Example Makefile pattern:
//!     foo_c:
//!         cargo clean
//!         mkdir -p $(TARGET_DIR)
//!         riscv64-unknown-elf-gcc $(CFLAGS) -c examples/foo_c.c \
//!             -o $(TARGET_DIR)/foo_c.o
//!         riscv64-unknown-elf-ar rcs $(TARGET_DIR)/libfoo_c.a \
//!             $(TARGET_DIR)/foo_c.o
//!         RUSTFLAGS="-l foo_c -l c -L target/.../examples -L $(LIBC_DIR) ..." \
//!             cargo build --example c_main_wrapper \
//!             --target riscv32imac-unknown-none-elf
//!         # ... sign and package ...

#![no_std]
#![no_main]
extern crate dabao_sdk;

// Declare C main() as a never-returning function
// The C implementation is linked in from the C library
// Suppress dead_code warning: main() is called by lib.rs _start(), not by this code
#[allow(dead_code)]
unsafe extern "C" {
    fn main() -> !;
}
