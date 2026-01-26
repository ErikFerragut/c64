# C64 Development Tools

## VICE (vice-jz)

Commodore 64 emulator installed via snap as `vice-jz`.

**Key executables:**
- `vice-jz.x64sc` - Cycle-exact C64 emulator (recommended)
- `vice-jz.x64` - Faster but less accurate C64 emulator
- `vice-jz.c1541` - Disk image utility

**Common usage:**
```bash
vice-jz.x64sc -autostart program.prg    # Run a program
vice-jz.x64sc -autostart disk.d64       # Run from disk image
```

**Key shortcuts:**
- Alt+W - Warp mode (fast forward)
- Alt+P - Pause
- Alt+Q - Quit
- F12 - Reset

## ACME

Cross-assembler for 6502/65C02/65816 processors.

**Install:**
```bash
sudo apt install acme
```

**Usage:**
```bash
acme -f cbm -o output.prg source.asm
```

**Flags:**
- `-f cbm` - Output CBM format (adds 2-byte load address header)
- `-o file` - Output filename
- `-r report` - Generate label report
- `-v` - Verbose output

**Documentation:** Run `acme --help` or see `/usr/share/doc/acme/`
