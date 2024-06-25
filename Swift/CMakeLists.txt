cmake_minimum_required(VERSION 3.13)
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

set(FAMILY rp2040)
set(BOARD pico_sdk)

project(usb-swift)

pico_sdk_init()

execute_process(COMMAND xcrun -f swiftc OUTPUT_VARIABLE SWIFTC OUTPUT_STRIP_TRAILING_WHITESPACE)

add_executable(usb-swift)

message("🐦‍🔥 Compiling Swift Code")

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/_swiftcode.o
    COMMAND
        /Library/Developer/Toolchains/swift-DEVELOPMENT-SNAPSHOT-2024-06-12-a.xctoolchain/usr/bin/swiftc
        -target armv6m-none-none-eabi -Xcc -mfloat-abi=soft -Xcc -fshort-enums
        -Xfrontend -function-sections -enable-experimental-feature Embedded -wmo -parse-as-library
        $$\( echo '$<TARGET_PROPERTY:usb-swift,INCLUDE_DIRECTORIES>' | tr '\;' '\\n' | sed -e 's/\\\(.*\\\)/-Xcc -I\\1/g' \)
        $$\( echo '${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES}'          | tr ' '  '\\n' | sed -e 's/\\\(.*\\\)/-Xcc -I\\1/g' \)
        -import-bridging-header ${CMAKE_CURRENT_LIST_DIR}/BridgingHeader.h

        ${CMAKE_CURRENT_LIST_DIR}/Main.swift
        ${CMAKE_CURRENT_LIST_DIR}/USBReports.swift

        -c -o ${CMAKE_CURRENT_BINARY_DIR}/_swiftcode.o
    DEPENDS
        ${CMAKE_CURRENT_LIST_DIR}/Main.swift
        ${CMAKE_CURRENT_LIST_DIR}/USBReports.swift
)

add_custom_target(usb-swift-swiftcode DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/_swiftcode.o)

target_sources(usb-swift PUBLIC
    # ${CMAKE_CURRENT_LIST_DIR}/USBReports.c
    ${CMAKE_CURRENT_LIST_DIR}/../Shared/usb_descriptors.c
)

# Make sure TinyUSB can find tusb_config.h
target_include_directories(usb-swift PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/../Shared
)

target_link_libraries(usb-swift
    PUBLIC
    pico_stdlib
    hardware_gpio
    tinyusb_device tinyusb_board
    pico_unique_id
    ${CMAKE_CURRENT_BINARY_DIR}/_swiftcode.o
)

# enable usb output, disable uart output
pico_enable_stdio_usb(usb-swift 0)
pico_enable_stdio_uart(usb-swift 0)

add_dependencies(usb-swift usb-swift-swiftcode)

pico_add_extra_outputs(usb-swift)
