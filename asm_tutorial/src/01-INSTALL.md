# Chapter 1: Installation

This chapter covers installing the C64 development environment on WSL/Ubuntu.

## Overview

We need two tools:
- **VICE** - A C64 emulator to run our programs
- **ACME** - A cross-assembler to compile 6502 assembly to machine code

## Installing VICE

VICE is available as a snap package called `vice-jz`:

```bash
sudo snap install vice-jz
```

This installs several emulators for different Commodore machines. For C64 development, use:

- `vice-jz.x64sc` - Cycle-exact C64 emulator (recommended)
- `vice-jz.x64` - Faster but less accurate C64 emulator

Verify it works:

```bash
vice-jz.x64sc
```

A C64 screen should appear with the familiar blue background and "READY." prompt:

![VICE C64 startup screen](images/ready-screen.png)

### Key Shortcuts

| Shortcut | Action |
|----------|--------|
| Alt+W | Warp mode (fast forward) |
| Alt+P | Pause |
| Alt+Q | Quit |
| F12 | Reset |

## Installing ACME

ACME is a cross-assembler for 6502/65C02/65816 processors. It's available in Ubuntu's package repository:

```bash
sudo apt install acme
```

Verify it works:

```bash
acme --help
```

## Project Structure

Create a directory structure for your C64 projects:

```bash
mkdir -p ~/c64/{src,asm_tutorial,games}
```

```
~/c64/
├── src/           # Assembly source files
├── asm_tutorial/  # This tutorial
└── games/         # Downloaded games and disk images
```

## Next Steps

With the tools installed, proceed to [Chapter 2: Hello World](02-HELLO.md) to write your first program.
