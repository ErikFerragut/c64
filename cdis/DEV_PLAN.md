# CDis - C64 Disassembler in Elm

"C-Dis" — you need to see this.

## Vision

A desktop 6502 disassembler for C64 PRG files, built in Elm with Tauri. Clean, functional, with the long-term goal of informing "Chestnut" — a functional language for C64 that wraps I/O like Elm wraps the DOM.

## Current Status

**Now runs as a Tauri desktop app** for native file access. No more browser security headaches.

### Keyboard Shortcuts
- `↑/↓` - Navigate lines
- `;` - Edit comment on selected line
- `Ctrl+L` - Center selected line on screen
- `S` - Save project
- `?` - Toggle help

## Core Features

### Phase 1: Basic Disassembly ✅
- [x] Load PRG file via native file picker
- [x] Parse 2-byte load address header
- [x] Opcode table (all 256 opcodes, including undocumented)
- [x] Linear disassembly from load address
- [x] Display: address | hex bytes | mnemonic operand
- [x] C64 symbol substitution ($D020 → BORDER_COLOR)

### Phase 2: Navigation ✅
- [x] Scrollable view (mouse wheel, arrow keys)
- [x] Jump to address (go to $xxxx)
- [x] Keep selected line visible when navigating
- [ ] Click on address operand to jump there

### Phase 3: Segments & Restart Points
*Temporarily removed - will be rebuilt with better UX*
- [ ] Define segments (name, start, end, type: code/data)
- [ ] Tab bar showing all segments
- [ ] Click to jump to segment
- [ ] Set disassembly restart point (for when linear disassembly desyncs)
- [ ] Mark regions as data (show as .byte instead of opcodes)

### Phase 4: Annotation (Partial)
- [x] Add comment to any byte offset (`;` key or double-click)
- [x] Comments displayed inline (right side)
- [x] Edit/delete comments
- [ ] Add labels to addresses

### Phase 5: Persistence ✅
- [x] Save project as JSON (.cdis file next to .prg)
- [x] Auto-load .cdis when opening .prg
- [x] Dirty indicator (*) when unsaved changes
- [ ] Export as .asm file (ACME-compatible syntax)

### Phase 6: Code-ness Scoring (the fun part)
- [ ] Build byte frequency distribution from KERNAL/BASIC ROM
- [ ] Compute log-odds ratio for each position
- [ ] Visual indicator (color gradient) of "this looks like code"
- [ ] Use to suggest segment boundaries

## Architecture

```
src/
├── Main.elm              # Entry point, Model/Msg/Update/View, Ports
├── Disassembler.elm      # disassemble : Int -> Array Int -> List Line
├── Opcodes.elm           # opcode table, addressing modes
├── Symbols.elm           # C64 address → name mapping
├── Types.elm             # Shared types (Line, Model, etc.)
└── Project.elm           # Save/load project JSON

src-tauri/
├── src/lib.rs            # Tauri commands (file read/write)
├── tauri.conf.json       # App configuration
└── Cargo.toml            # Rust dependencies
```

## Data Model

```elm
type alias Model =
    { bytes : Array Int              -- Raw file bytes (without PRG header)
    , loadAddress : Int              -- From PRG header (e.g., 0x0800)
    , comments : Dict Int String     -- Offset → comment
    , labels : Dict Int String       -- Address → label name
    , viewStart : Int                -- Scroll position (byte offset)
    , viewLines : Int                -- How many lines visible
    , selectedOffset : Maybe Int     -- Cursor position
    , restartPoints : Set Int        -- Manual "start disassembly here" marks
    , fileName : String              -- For display
    , dirty : Bool                   -- Unsaved changes indicator
    }

type alias Line =
    { offset : Int                   -- Byte offset in file
    , address : Int                  -- Memory address
    , bytes : List Int               -- Raw bytes for this line
    , disassembly : String           -- "LDA #$00" or ".byte $FF"
    , comment : Maybe String
    }
```

## Build & Run

```bash
cd ~/c64/cdis

# Development (with hot reload)
cargo tauri dev

# Production build
cargo tauri build
```

## Dependencies

### Elm
- elm/file (for file loading)
- elm/bytes (for binary parsing)
- elm/json (for save/load)

### Tauri/Rust
- tauri v2
- tauri-plugin-dialog (file picker)
- tauri-plugin-fs (file read/write)

## Notes

- PRG files: first 2 bytes are load address (little-endian)
- All 256 opcodes defined (including undocumented like LAX, SAX, etc.)
- ACME syntax for output compatibility
- Symbols from C64 memory map (VIC at $D000, SID at $D400, etc.)
- .cdis files are JSON, saved alongside .prg files
- Project version 2 (still reads v1 files)
