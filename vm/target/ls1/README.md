# Zwölf LS1x

The LS10 module uses the CH32V003 MCU.

## Pinout

```
1  2  3  4  5  6
7  8  9  10 11 12
```

| Pin | GPIO | Primary Function | Alternative Function(s) |
|-----|------|------------------|-------------------------|
| 1 | A | Global I2C SCL (slave) | - |
| 2 | B | Global I2C SDA (slave) | - |
| 3 | C | Local I2C SCL (master) | GPIO / UART RX |
| 4 | D | Local I2C SDA (master) | GPIO / UART TX |
| 5 | - | GND | Ground |
| 6 | - | 3V3 | Power |
| 7 | E | GPIO | USB\_PU |
| 8 | F | GPIO | USB\_DP |
| 9 | G | GPIO | USB\_DN |
| 10 | - | SWDIO | - |
| 11 | - | RESETN | device reset (active low) |
| 12 | - | WPN | write protect (active low) |

Note: There is an onboard LED that is mapped to GPIOH.

## Flashing the Firmware

### WCH-LinkE

If you're using WCH-LinkE, connect 3V3, GND and wire SWIO to SWDIO and then:

```
$ make
```

### Werkzeug or Raspberry Pi Pico

| Zwölf | RP2040 |
|-------|--------|
| 3V3 | 3V3 |
| GND | GND |
| SWDIO | GPIO28 |

Note: You will also need a ~1K pull-up resistor between SWDIO and 3V3.

To program the firmware:

```
$ git clone https://github.com/machdyne/picorvd
$ cd picorvd
$ mkdir build
$ cd build
$ cmake -DPICO_BOARD=machdyne_werkzeug ..
$ gdb-multiarch -x gdbinit -ex 'load' -ex 'detach' -ex 'quit' ls1.elf
```
