cmake_minimum_required(VERSION 3.13)
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

set(FAMILY rp2040)
set(BOARD pico_sdk)

project(usb-swift)

pico_sdk_init()

execute_process(COMMAND xcrun -f swiftc OUTPUT_VARIABLE SWIFTC OUTPUT_STRIP_TRAILING_WHITESPACE)

add_executable(usb-swift)

target_sources(usb-swift PUBLIC
	${CMAKE_CURRENT_LIST_DIR}/main.c
	${CMAKE_CURRENT_LIST_DIR}/../Shared/usb_descriptors.c
)

# Make sure TinyUSB can find tusb_config.h
target_include_directories(usb-swift PUBLIC
	${CMAKE_CURRENT_LIST_DIR}/../Shared)

target_link_libraries(usb-swift
	PUBLIC
	pico_stdlib
	hardware_gpio
	tinyusb_device tinyusb_board
	pico_unique_id
)

# enable usb output, disable uart output
pico_enable_stdio_usb(usb-swift 0)
pico_enable_stdio_uart(usb-swift 0)

pico_add_extra_outputs(usb-swift)
