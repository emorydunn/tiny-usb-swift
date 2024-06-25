# tiny-usb-swift

An test project for integrating TinyUSB into an embedded Swift project.

The project is split into two sub-projects, one built using C and one with Swift. Both projects share the same USB configuration files (written in C), with the only difference being the language the working parts of the project are written in. In both cases each project simply blinks the LED based on the USB status, based on the TinyUSB example.

## Hardware

The project is designed to run on a standard Raspberry Pi Pico using the built-in LED. Additionally a momentary switch can be wired between 3V and GPIO0 to reset the Pico into `BOOTSEL` mode without showing up as a mass storage device.

## Building

Each project has a `Makefile` for easily building, cleaning, and deploying the binary to a Pico.

```shell

# Set up the build directory
make -C SDK clean

# Build the project
make -C SDK build

# Copy the binary with picotool
make -C SDK run

# Build and run
make -C SDK
```

## Errors Building the Swift Project

Generating Ninja files (`make clean`) appears to run just fine. However compiling the project tends to fail. I've outlined attempts I've made to compile the Swift project, though so far none have worked.

### Undefined `CFG_TUSB_MCU`

The underlying build error appears to be that `CFG_TUSB_MCU` isn't defined, which should be set in `${PICO_SDK_PATH}/lib/tinyusb/hw/bsp/rp2040/family.cmake`.

A workaround for this is to provide the definition manually in the bridging header, which satisfies the `#ifndef`. This isn't ideal, although for the purposes of adding TinyUSB specifically to a Pico-based project it's probably fine. I'm not sure if a similar step would need to be taken for other MCUs.

```C
#pragma once

#include <stdlib.h>
#include "hardware/gpio.h"
#include "pico/time.h"
#include "pico/bootrom.h"

#ifndef CFG_TUSB_MCU
  #define CFG_TUSB_MCU OPT_MCU_RP2040
#endif

#include "tusb.h"
```

### Undefined References

With the MCU defined, the compiler is free to move onto the next error: `undefined reference to 'tud_hid_set_report_cb'`. The error only shows up when trying to call `tud_task()`.

Defining Swift versions of `tud_hid_set_report_cb` and `tud_hid_get_report_cb` in `Main.swift` doesn't seem to work. However, including them as C functions in a separate source file in `CMakeLists` works. Unfortunately this isn't particularly useful as these two methods are the primary way the device communicates with the host, so they can't really be off in their own world from the main Swift app.

```cmake
target_sources(usb-swift PUBLIC
	${CMAKE_CURRENT_LIST_DIR}/USBReports.c
	${CMAKE_CURRENT_LIST_DIR}/../Shared/usb_descriptors.c
)
```