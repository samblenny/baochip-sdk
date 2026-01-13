<!-- SPDX-License-Identifier: MIT -->
<!-- SPDX-FileCopyrightText: Copyright 2026 Sam Blenny -->
# Dabao Zephyr CircuitPython PoC

**DRAFT: WORK IN PROGRESS**

[*an aspirational blurb about what this is trying to be*:]

This is a proof of concept for building CircuitPython's Zephyr port to run on
the Baochip Dabao board. Most of the work here is about getting Rust no_std
device drivers from the Dabao bootloader to work as Zephyr drivers. There's
some additional stuff for getting the CircuitPython Zephyr port to build with
my Zephyr board definition for Dabao.

**CAUTION:**

1. This is a proof of concept. I don't currently have any intention to maintain
   this once I've got it working. The point is to document how to do it.

2. The Zephyr Project has strict contribution policies which I am not
   following. Commits in this repo are unsuitable for upstreaming. But...

3. I'm arranging things here to hopefully facilitate easy re-implementation or
   translation of my work (e.g. Rust to C with a new copyright). If you want to
   do that and follow the Zephyr Project upstreaming policies, go for it. Best
   of luck.


## Goals & Strategy

What I care about here is getting to the point of CircuitPython running on a
Dabao board by the most straightforward path which seems reasonable and in good
taste. Plan is CPU, ReRAM, RAM, LED blinky, and UART serial first, then maybe
add USB.

Zephyr's configuration system is more complex than I expect to be useful, so I
plan to bypass some of it if I can. Specifically, if possible, I hope to use
the Rust drivers with a C FFI wrapper. To the extent that using Zephyr's
typical Device Tree macros gets in the way of using the Rust drivers, I hope to
bypass the Device Tree stuff.


## Pinout & Electrical Ratings

- Bunnie says the GPIO uses a 22 nm cell that can do **3.3V** IO with **12mA**
  current drive and **2kV HBM** ESD protection.

- ️⚡️🔥☠️ **DO NOT USE 5V**. IO is not 5V tolerant.

- Dabao v3 schematic:
  [github.com/baochip/dabao/blob/main/dabao_v3c.pdf](https://github.com/baochip/dabao/blob/main/dabao_v3c.pdf)

- Bootloader (boot1) serial console: **TX=PB14**, **RX=PB13**, 1M baud 8N1<br>
  (source [README-baochip.md](https://github.com/betrusted-io/xous-core/blob/main/README-baochip.md))


## Debug Serial Port (Debug Logging)

⚠️ Using **macOS** `screen -fn /dev/tty.usb... 1000000` to get a 1 Mbps serial
monitor **won't work** because macOS screen doesn't know how to set
non-standard baud rates. The **easy fix is use Linux**. If you REALLY want to
use macOS, you'll need to find a program that can use the IOSSIOSPEED ioctl to
set non-standard baud rates. The paid "Serial" app on the macOS App Store might
work.

To read debug serial port log messages:

1. Solder 2.54mm header pins to your Dabao so you can put it in a breadboard.

2. Find a fast USB serial adapter that supports 1 Mbps. Adapters using FTDI,
   CP2102, or CP2102N chips are a good bet. The Raspberry Pi Debug Probe seems
   to work.

3. Wire up your serial adapter:

   | FTDI Adapter | Dabao     |
   | ------------ | --------- |
   | TX           | PB13 (RX) |
   | RX           | PB14 (TX) |
   | GND          | GND       |

   | Pi Debug Probe   | Dabao     |
   | ---------------- | --------- |
   | Orange Wire (TX) | PB13 (RX) |
   | Yellow Wire (RX) | PB14 (TX) |
   | Black Wire       | GND       |

4. Connect the adapter, find its device with `ls /dev/tty*` or whatever, then
   start a serial monitor with `screen -fn $ADAPTER_TTY 1000000` or whatever.

5. Connect Dabao to USB. You should see `boot0 console up` and so on.


## USB CDC Serial (Bootloader Shell, etc.)

The bootloader and baremetal app both provide a simple shell interface, **but**
you can only get to it from the USB CDC serial port. For boot1 and baremetal,
the debug serial port just shows log messages.


## Docs, Refs, and Downloads


### Dabao Board (Bao1x dev board)

- ⚠️ The first batch of boards (e.g. from 39C3) shipped with alpha firmware
  that must be updated.

  **Dabao Bootloader Update Instructions**:
  [xous-core/README-baochip.md](https://github.com/betrusted-io/xous-core/blob/main/README-baochip.md)

  The bootloader update instructions describe building `bao1x-alt-boot1.uf2`
  and `bao1x-boot1.uf2` from source, but you can also get them from bunnie's CI
  builds at
  [ci.betrusted.io/latest-ci/baochip/bootloader/](https://ci.betrusted.io/latest-ci/baochip/bootloader/)

- Board design files: [github.com/baochip/dabao](https://github.com/baochip/dabao)


### Bao1x Chip (CSP Package)

These notes and documentation links should help understand peripheral IP blocks
used in the Bao1x SoC. Much of this came from the baochip discord server's
not-rust channel.

- Baochip website with various docs links: [baochip.com](https://baochip.com)

- uDMA block is from Pulp platform from University of Bologna/ETH Zurich:<br>
  [docs](https://docs.openhwgroup.org/projects/core-v-mcu/doc-src/udma_subsystem.html),
  [sample drivers](https://github.com/pulp-platform/pulp-rt/tree/master/drivers)

  uDMA provides UART, I2C, Camera, SPI, SDIO, and ADC peripheral access by DMA

- IRQArray is meant to be an alternative to NVIC that will work better with
  virtual memory. IRQs are split into banks of 16 with each bank getting a
  separate page of memory. This allows drivers to have their own memory spaces.

- CPU cluster register group: [docs](https://ci.betrusted.io/bao1x-cpu/)

  These RV32 registers provide access to IRQArray, timers, and suspend/resume
  features.

- Peripheral cluster register group: [docs](https://ci.betrusted.io/bao1x/)

  These RV32 registers provide access to math/crypto accelerators, TRNG, UDMA,
  BIO, and a variety of other as yet somewhat mysterious peripherals.

- PLL programming is not well documented yet. Best reference is the
  [rust source](https://github.com/betrusted-io/xous-core/blob/main/libs/bao1x-hal/src/clocks.rs).
  But, the bootloader sets up the clocks and the UART, so this might not matter
  unless you need to do something like adjust the main clock to hit a specific
  I2S bit clock rate.

- Bare metal linker file:<br>
  [xous-core/baremetal/src/platform/bao1x/link.x](https://github.com/betrusted-io/xous-core/blob/main/baremetal/src/platform/bao1x/link.x)

- Bare metal stack pointer, trap, and entry point setup:<br>
  [xous-core/baremetal/src/asm.rs](https://github.com/betrusted-io/xous-core/blob/944a8082ec235339e5e73165da48fd209f4a0724/baremetal/src/asm.rs#L35-L56)

- Existing BIO examples depend on Xous APIs. There isn't much documentation yet
  on how to use it outside of Xous (as of Jan 10, 2026). BIO is relevant for
  handling timing sensitive IO like I2S, 1-wire, or LED string drivers.

  Current no_std BIO drivers:
  [xous-core/libs/bao1x-hal/src/bio_hw.rs](https://github.com/betrusted-io/xous-core/blob/main/libs/bao1x-hal/src/bio_hw.rs)


### CircuitPython

- [circuitpython/ports/zephyr-cp/README.md](https://github.com/adafruit/circuitpython/blob/main/ports/zephyr-cp/README.md)
  explains how to install and build the CircuitPython Zephyr port

- CircuitPython Zephyr port build tools:
  [ports/zephyr-cp/cptools](https://github.com/adafruit/circuitpython/tree/main/ports/zephyr-cp/cptools)

  See [zephyr2cp.py](https://github.com/adafruit/circuitpython/blob/main/ports/zephyr-cp/cptools/zephyr2cp.py)
for details of how CircuitPython extracts pin mappings from Device Tree config)


### Zephyr

These are for implementing Zephyr drivers, board definitions, etc.

- [How to Build Drivers for Zephyr RTOS](https://www.zephyrproject.org/how-to-build-drivers-for-zephyr-rtos/)
  (Zephyr Project blog, August 11, 2020)

- [LiteX VexRiscv](https://docs.zephyrproject.org/latest/boards/enjoydigital/litex_vexriscv/doc/index.html)
  board definition

- UART driver samples (github):
  [zephyr/samples/uart/](https://github.com/zephyrproject-rtos/zephyr/tree/main/samples/drivers/uart)

- Zephyr Project
  [UART API docs](https://docs.zephyrproject.org/latest/hardware/peripherals/uart.html)

- Zephyr Project
  [GPIO API docs](https://docs.zephyrproject.org/latest/hardware/peripherals/gpio.html)
