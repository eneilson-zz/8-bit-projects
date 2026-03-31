# C64 Joystick Tester

A Commodore 64 diagnostic utility for testing joystick inputs in real time.

## Purpose

Displays a live visual representation of all directional and fire button inputs
for both joystick ports. Useful for verifying that a joystick is
working correctly, identifying stuck or missing directions, and confirming which
physical port a joystick is connected to.

## Features

- Real-time input display for both joystick ports
- Visual grid showing all 8 directions (cardinal and diagonal) per joystick
- Diagonal inputs (UL, UR, DL, DR) activate only when both constituent
  directions are pressed simultaneously
- Fire button highlight per joystick
- Raw 8-bit CIA register values displayed for each port
- Press **RUN/STOP** to exit and reset the C64

## C64 Port Mapping

| Label      | Physical Port | CIA Register |
|------------|---------------|--------------|
| Joystick 1 | Port 2        | CIA1 Port A `$DC00` |
| Joystick 2 | Port 1        | CIA1 Port B `$DC01` |

> Note: This is a well-known C64 hardware quirk. The port physically labeled
> "Joystick 2" on the machine is the primary port used by most games.

## Building

Requires [KickAssembler](http://www.theweb.dk/KickAssembler/) and Java.

```bash
scripts/build.sh
```

Output is written to `bin/joystick_test.prg`.

## Running

Load from disk:

```
LOAD"*",8,1
RUN
```

Or use the **C64 Build + Run (VICE)** launch configuration in VS Code to build
and launch directly in the VICE emulator.

## Requirements

- KickAssembler v5.x at `/Applications/KickAssembler/KickAss.jar`
  (or set `KICKASS_JAR` environment variable)
- Java runtime
- VICE x64sc emulator (for VS Code launch config)
