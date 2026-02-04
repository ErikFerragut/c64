# C64 Assembly Programming

This repository contains two related projects for Commodore 64 development:

## Learn 6502 Assembly (`asm_tutorial/`)

A hands-on tutorial for learning 6502 assembly language on the Commodore 64. The book takes you from "Hello World" to building a complete game, introducing concepts incrementally:

- BASIC stubs and memory layout
- Keyboard and joystick input
- Raster timing and animation
- Sprite graphics and movement
- Collision detection
- Game loops and state management

Each chapter builds a working program you can run in VICE or on real hardware.

**[Read the book](asm_tutorial/src/SUMMARY.md)**

## cdis - C64 Disassembler (`cdis/`)

An interactive disassembler for analyzing C64 PRG files. Built with Elm and Tauri.

Features:
- Disassemble 6502 machine code with syntax highlighting
- Mark regions as code, data bytes, or PETSCII text
- Add labels and comments for documentation
- Edit instructions and bytes in place
- Export annotated assembly source
- Run directly in VICE emulator

### Building cdis

```bash
cd cdis
npm install
make dev
```

Requires: Node.js, Rust, and Tauri prerequisites.

## License

MIT
