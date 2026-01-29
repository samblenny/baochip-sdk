// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2026 Sam Blenny
//
#![no_std]
#![no_main]
extern crate dabao_baremetal_poc;
use dabao_baremetal_poc::{gpio, log, sleep, ticktimer, timer0, uart};
use gpio::{AF, GpioPin};
use ticktimer::millis;

#[unsafe(no_mangle)]
pub extern "C" fn main() -> ! {
    // Configure PC13 (PROG button) as input with pull-up
    gpio::set_alternate_function(GpioPin::PortC(gpio::PC13), AF::AF0);
    gpio::disable_output(GpioPin::PortC(gpio::PC13));
    gpio::enable_pullup(GpioPin::PortC(gpio::PC13));

    loop {
        // Print beep now (on boot and after each button press)
        log!("beep {}...", millis());

        // Set an alarm to print boop later using a callback function
        timer0::set_alarm_ms(2000, boop);

        // Wait until PC13 is high (button released)
        while gpio::read_input(GpioPin::PortC(gpio::PC13)) == 0 {
            uart::tick();
        }
        sleep(10);

        // Wait until PC13 is low (button pressed)
        while gpio::read_input(GpioPin::PortC(gpio::PC13)) != 0 {
            uart::tick();
        }
        sleep(10);
    }
}

/// Callback to handle the alarm interupt (runs in interrupt context!)
pub fn boop() {
    log!("boop {}\r\n", millis());
}
