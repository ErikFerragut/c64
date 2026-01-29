# CDis - C64 Disassembler in Elm

"C-Dis" — you need to see this.

## Vision

A browser-based 6502 disassembler for C64 PRG files, built in Elm. Clean, functional, with the long-term goal of informing "Chestnut" — a functional language for C64 that wraps I/O like Elm wraps the DOM.

## Core Features

### Phase 1: Basic Disassembly
- [x] Load PRG file (drag-drop or file picker)
- [x] Parse 2-byte load address header
- [x] Opcode table (all 256 opcodes, including undocumented)
- [x] Linear disassembly from load address
- [x] Display: address | hex bytes | mnemonic operand
- [x] C64 symbol substitution ($D020 → BORDER_COLOR)

### Phase 2: Navigation
- [ ] Scrollable view (virtual scroll for large files)
- [ ] Jump to address (go to $xxxx)
- [ ] Click on address operand to jump there

### Phase 3: Segments & Restart Points
- [ ] Define segments (name, start, end, type: code/data)
- [ ] Tab bar showing all segments
- [ ] Click to jump to segment
- [ ] Set disassembly restart point (for when linear disassembly desyncs)
- [ ] Mark regions as data (show as .byte instead of opcodes)

### Phase 4: Annotation
- [ ] Add comment to any byte offset
- [ ] Comments displayed inline (right side or above)
- [ ] Edit/delete comments
- [ ] Add labels to addresses

### Phase 5: Persistence
- [ ] Save project as JSON (bytes + comments + segments + labels)
- [ ] Load project
- [ ] Export as .asm file (ACME-compatible syntax)

### Phase 6: Code-ness Scoring (the fun part)
- [ ] Build byte frequency distribution from KERNAL/BASIC ROM
- [ ] Compute log-odds ratio for each position
- [ ] Visual indicator (color gradient) of "this looks like code"
- [ ] Use to suggest segment boundaries

## Architecture

```
src/
├── Main.elm              # Entry point, Model/Msg/Update/View
├── Disassembler.elm      # disassemble : Int -> Array Int -> List Line
├── Opcodes.elm           # opcode table, addressing modes
├── Symbols.elm           # C64 address → name mapping
├── Types.elm             # Shared types (Line, Segment, etc.)
└── Ports.elm             # File I/O, localStorage
```

## Data Model

```elm
type alias Model =
    { bytes : Array Int              -- Raw file bytes (without PRG header)
    , loadAddress : Int              -- From PRG header (e.g., 0x0800)
    , comments : Dict Int String     -- Offset → comment
    , labels : Dict Int String       -- Address → label name
    , segments : List Segment        -- Named regions
    , viewStart : Int                -- Scroll position (byte offset)
    , viewLines : Int                -- How many lines visible
    , selectedOffset : Maybe Int     -- Cursor position
    , restartPoints : Set Int        -- Manual "start disassembly here" marks
    , fileName : String              -- For display
    }

type alias Segment =
    { name : String
    , start : Int                    -- Byte offset
    , end : Int
    , segType : SegmentType
    }

type SegmentType = Code | Data | Unknown

type alias Line =
    { offset : Int                   -- Byte offset in file
    , address : Int                  -- Memory address
    , bytes : List Int               -- Raw bytes for this line
    , disassembly : String           -- "LDA #$00" or ".byte $FF"
    , comment : Maybe String
    }
```

## Opcode Table Structure

```elm
type AddressingMode
    = Implied           -- RTS
    | Accumulator       -- ASL A
    | Immediate         -- LDA #$00
    | ZeroPage          -- LDA $00
    | ZeroPageX         -- LDA $00,X
    | ZeroPageY         -- LDX $00,Y
    | Absolute          -- LDA $0000
    | AbsoluteX         -- LDA $0000,X
    | AbsoluteY         -- LDA $0000,Y
    | Indirect          -- JMP ($0000)
    | IndirectX         -- LDA ($00,X)
    | IndirectY         -- LDA ($00),Y
    | Relative          -- BNE label

type alias OpcodeInfo =
    { mnemonic : String
    , mode : AddressingMode
    , bytes : Int           -- 1, 2, or 3
    , cycles : Int          -- base cycles (not counting page cross)
    , undocumented : Bool
    }

opcodeTable : Array OpcodeInfo
-- 256 entries, index is opcode byte
```

## UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  CDis - filename.prg                        [Load] [Save]   │
├─────────────────────────────────────────────────────────────┤
│  [Code $0800-$0FFF] [Data $1000-$17FF] [+ Add Segment]      │
├──────────┬──────────────────────────────────────────────────┤
│ Address  │  Hex          Disassembly              Comment   │
├──────────┼──────────────────────────────────────────────────┤
│ $0800    │  00 0B 08     .byte $00,$0B,$08        ; BASIC   │
│ $0803    │  0A 00        .byte $0A,$00            ; line 10 │
│ $0805    │  9E           .byte $9E                ; SYS     │
│ $0806    │  32 30 36 31  .byte "2061"                       │
│ $080D    │  78           SEI                                │
│ $080E    │  4C 00 80     JMP $8000                          │
│ ...      │                                                  │
└──────────┴──────────────────────────────────────────────────┘
│◀ $0800                    [$____] Go        $0FFF ▶│ scroll │
└─────────────────────────────────────────────────────────────┘
```

## Build & Run

```bash
cd ~/c64/cdis
elm make src/Main.elm --output=cdis.js
# Open index.html in browser
```

## Dependencies

- Elm 0.19.1
- elm/file (for file loading)
- elm/bytes (for binary parsing)
- elm/json (for save/load)

## Notes

- PRG files: first 2 bytes are load address (little-endian)
- All 256 opcodes defined (including undocumented like LAX, SAX, etc.)
- ACME syntax for output compatibility
- Symbols from C64 memory map (VIC at $D000, SID at $D400, etc.)
