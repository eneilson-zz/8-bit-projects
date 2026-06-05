# C64 RAMBoard Test

A Commodore 64 RAMBoard tester written in 6502 assembly (KickAssembler). It
re-creates the functionality of the original `RAMBoard Test.prg`
(a CLD 1541/41C/41-II/71 RAMBoard tester) except it adds a new option to select different areas of RAM expansion in 8k blocks within the 1541 to test. Valid RAM areas are now $8000 (default), $2000, $4000, $6000, $A000.

The memory test runs **inside the disk drive**, not on the C64: the C64 host
ships a small 6502 routine into the drive over the DOS command channel
(`M-W` / Memory-Write), executes it (`M-E` / Memory-Execute), and reads back the
pass/fail status.

## Building

If you don't want to build the project yourself, you can download the pre-built .d64 disk image with the program on it from the ./disk directory.

Requires [KickAssembler](http://www.theweb.dk/KickAssembler/) and Java.

```bash
make            # build (same as scripts/build.sh)
make clean      # remove build output in bin/
```

You can also run the scripts directly:

```bash
scripts/build.sh
scripts/clean.sh
```

Output is written to `bin/ramboard test.prg`, along with a ready-to-run
`bin/ramboard test.d64` disk image.

## Running

Load from disk:

```
LOAD"*",8,1
RUN
```

## Requirements

- KickAssembler v5.x at `/Applications/KickAssembler/KickAss.jar`
  (or set `KICKASS_JAR` environment variable)
- Java runtime
- VICE x64sc emulator (for VS Code launch config); its `c1541` tool is used to
  package the `.d64` disk image
