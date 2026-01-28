// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2026 Sam Blenny

use crate::uart;
use core::fmt::{self, Write};

struct SliceWriter<'a> {
    buf: &'a mut [u8],
    len: usize,
}

impl<'a> Write for SliceWriter<'a> {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        let bytes = s.as_bytes();
        let end = self.len + bytes.len();
        if end > self.buf.len() {
            return Err(fmt::Error);
        }
        self.buf[self.len..end].copy_from_slice(bytes);
        self.len = end;
        Ok(())
    }
}

// This lets us use variadic string format arguments in no_std, no_alloc
pub fn log_fmt(args: fmt::Arguments<'_>) {
    let mut buf = [0_u8; 128];
    let mut writer = SliceWriter { buf: &mut buf, len: 0 };
    if writer.write_fmt(args).is_ok() {
        uart::write(&writer.buf[..writer.len]);
    }
}

// Macro that takes variadic formatting arguments
// example usage: log!("hello, world {:x}\r\n", 42);
#[macro_export]
macro_rules! log {
    ($($arg:tt)*) => {
        $crate::log::log_fmt(core::format_args!($($arg)*))
    };
}
