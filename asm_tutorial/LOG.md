# C64 Development Log

## 2026-01-25

### Environment Setup

- Installed VICE emulator via snap (`vice-jz`)
- Verified `vice-jz.x64sc` (cycle-exact C64 emulator) works in WSL2
- Installed ACME cross-assembler (`sudo apt install acme`)

### Project Structure

```
~/c64/
├── asm_tutorial/
│   ├── LOG.md        # This file
│   └── TOOLS.md      # Tool documentation
├── games/            # D64 disk images and PRG files
│   ├── oligofrenico.d64
│   ├── mikaels_lekis.d64
│   └── warmup.d64
└── src/
    ├── hello.asm     # First test program
    └── hello.prg     # Compiled output
```

### First Program

Created and tested `hello.asm`:
- BASIC stub to auto-run via SYS 2064
- Sets border ($d020) and background ($d021) to black
- Returns to BASIC

Compiled with: `acme -f cbm -o src/hello.prg src/hello.asm`

Tested successfully in VICE - border and background turn black as expected.

### Next Steps

- Learn 6502 instruction set
- Experiment with VIC-II graphics registers
- Try sprite or character graphics
