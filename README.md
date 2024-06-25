# tiny-usb-swift

A test project for integrating TinyUSB into an embedded Swift project.

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

### Exposing Swift APIs to C++

The apparent issue is that the rest of the compiled C source can't see the methods defined in the Swift portion. I thought [emitting a header](https://www.swift.org/documentation/cxx-interop/#exposing-swift-apis-to-c) of the Swift code, which could then be linked along with `tusb_config.h` might work. Again, this didn't work as expected.

Adding `-module-name` and `-emit-clang-header-path` to the `swiftc` command does emit a header file, but it doesn't contain the callback methods. Setting `-cxx-interoperability-mode=default` causes the build to fail because `cassert` isn't defined in the `pico-sdk`.

### `@_cdecl`

Looking through the Swift Forums I found a [post](https://forums.swift.org/t/cdecl-doesnt-work-in-emdedded-dependency/72368) pointing out a bug around exposing Swift APIs from a dependency. Fortunately they mentioned that a solution was to annotate the function and include it in the main app, which is exactly what TinyUSB needs for the callbacks.

Adding `@_cdecl("func_name")` to each of the callbacks (the reports and status) correctly exposes the methods to TinyUSB, no C shim needed.

## Successfully Building TinyUSB

There appear to be two fixes needed to build TinyUSB into a Swift project:

- Manually specifying `CFG_TUSB_MCU`
- Annotating the callback methods with `@_cdecl`

There are a couple of caveats. The first is the aforementioned issues with manually setting the MCU, this should be pulled from the board config. Secondly the callbacks have to be global functions, which isn't too much of an issue.
