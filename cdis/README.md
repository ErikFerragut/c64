# cdis - C64 Disassembler

An interactive disassembler for Commodore 64 PRG files. Built with Elm and Tauri.

![cdis screenshot](screenshot.png)

## Features

- **Disassembly** - Decode 6502 opcodes with proper addressing modes, including undocumented instructions (marked with `*`)
- **Region marking** - Define areas as code, data bytes (`.byte`), or PETSCII text (`.text`)
- **Annotations** - Add labels, inline comments, and multi-line block comments
- **Live editing** - Modify instructions, bytes, and text in place with immediate reassembly
- **Segments** - Group related code sections and navigate between them
- **Export** - Generate clean, reassemblable `.asm` source files
- **VICE integration** - Launch directly in the VICE emulator for testing

## Building

Prerequisites:
- Node.js
- Rust toolchain
- Tauri prerequisites ([see Tauri docs](https://tauri.app/start/prerequisites/))

```bash
npm install
make dev      # Development mode with hot reload
make build    # Production build
```

## Usage

Launch cdis and open a `.prg` file. The two-byte load address header is parsed automatically.

### Keyboard Reference

#### Navigation
| Key | Action |
|-----|--------|
| `↑` / `↓` | Previous / Next line |
| `PgUp` / `PgDn` | Page up / down |
| `G` | Go to address (hex) |
| `J` | Jump to address under cursor |
| `Shift+J` | Jump back |
| `O` | Outline - navigate between segments |
| `Ctrl+L` | Center selected line |

#### Editing
| Key | Action |
|-----|--------|
| `;` | Edit inline comment |
| `:` | Edit label at address |
| `"` | Edit major (block) comment |
| `Enter` | Edit current value (instruction/byte/text) |
| `Escape` | Cancel edit / Clear mark |

#### Regions & Segments
| Key | Action |
|-----|--------|
| `Ctrl+Space` | Set/clear mark (for selection) |
| `B` / `Shift+B` | Mark/clear as bytes |
| `T` / `Shift+T` | Mark/clear as text |
| `S` / `Shift+S` | Mark/clear as segment |
| `R` | Restart disassembly (peel off byte) |
| `N` | NOP current byte |

#### File & Tools
| Key | Action |
|-----|--------|
| `Ctrl+S` | Save project (.cdis file) |
| `A` | Export as .asm |
| `V` | Run in VICE |
| `D` | Decimal to hex converter |
| `H` | Hex to decimal converter |
| `?` | Toggle help |

## Project Files

When you save (`Ctrl+S`), cdis creates a `.cdis` file alongside your `.prg` containing:
- Labels and comments
- Region definitions (bytes/text)
- Segment boundaries
- Byte patches

This file is automatically loaded when you reopen the PRG.

## Export Format

The `A` key exports assembly compatible with the ACME assembler:

```asm
* = $0801

; BASIC stub
.basic:
    !byte $0b, $08, $0a, $00
    !byte $9e
    !text "2064"
    !byte $00, $00, $00

start:
    lda #$00        ; border color
    sta $d020
    rts
```

## Credits

- PETSCII font: [Pet Me 64](http://www.kreativekorp.com/software/fonts/c64.shtml) by Kreative Software
