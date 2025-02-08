cmake_minimum_required(VERSION 3.13)

include(pico_sdk_import.cmake)

project(howl)

add_executable(howl
        howl.c
        )

target_sources(howl PUBLIC
        ${CMAKE_CURRENT_LIST_DIR}/howl.c
        )

pico_sdk_init()

target_link_libraries(howl PRIVATE pico_stdlib hardware_resets hardware_irq hardware_i2c)

# enable usb output, disable uart output
pico_enable_stdio_usb(howl 1)
pico_enable_stdio_uart(howl 0)

pico_add_extra_outputs(howl)
