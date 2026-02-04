# 6502 Optimization Study

Ideas for exploring assembly optimization techniques on the C64.

## 1. Reverse-Engineering Famous Tight Code

Pick legendary C64 demo effects or game routines and analyze them instruction-by-instruction. Why did they do it that way? What's the cycle count? Demoscene coders discovered remarkable tricks under extreme constraints.

**Candidates to analyze**:

*From Llamasource (annotated, verified)*:
- Gridrunner main loop and collision detection
- Matrix sprite multiplexing
- Any tight inner loops in these games

*From "Dirty tricks" article*:
- The 37-byte line drawing routine (competition winner)
- Stack pointer hijacking for program entry

*Classic algorithms to find*:
- Fast multiply (log table method)
- Raster interrupt stabilization
- Sprite multiplexer

**Analysis template**:
- What it does
- Full disassembly with annotations
- Cycle count per iteration
- Memory footprint
- Key tricks used
- Could it be improved?

---

## 2. "Hacker's Delight" for 6502

The book *Hacker's Delight* catalogs bit manipulation tricks for modern CPUs. A 6502-specific version would document patterns unique to or especially useful on the 6502:

**Topics to explore**:
- Branchless conditionals (avoid pipeline... wait, no pipeline. But still saves bytes/cycles)
- Multiplication by constants via shifts and adds
- Division by constants via reciprocal multiplication
- Bit-counting without lookup tables
- Sign extension from 8 to 16 bits
- Min/max without branching
- Absolute value
- Population count (count set bits)
- Finding lowest/highest set bit
- Power of 2 detection
- Modulo by powers of 2 (trivial) and other constants (hard)

**6502-specific considerations**:
- Only 3 registers (A, X, Y), asymmetric capabilities
- Carry flag semantics (set before ADC, clear before SBC)
- No native multiply/divide
- Decimal mode exists but is slow
- Zero page is effectively 256 bytes of "fast registers"

---

## 3. Self-Modifying Code Patterns

Self-modifying code (SMC) is uniquely practical on 6502: no instruction cache to invalidate, no memory protection. What's "forbidden" on modern CPUs is elegant here.

**Patterns to document**:

### Computed Jumps
```asm
; Instead of jump table:
    LDA target_lo
    STA jump+1
    LDA target_hi
    STA jump+2
jump:
    JMP $0000       ; address gets patched
```

### Patching Immediates
```asm
; Loop with changing constant:
    LDA #$00        ; <-- patch this byte
loop:
    STA screen,X
    INX
    BNE loop
; Elsewhere:
    INC loop+1      ; modify the immediate value
```

### Unrolling at Runtime
Generate unrolled loop code into RAM based on runtime parameters.

### Index Register Extension
When you need more than 256-byte indexing:
```asm
    LDA table,X
patch:
    LDA table+256,X ; <-- patch high byte of address
```

**When SMC helps**:
- Eliminating indirect addressing overhead
- Avoiding repeated setup
- Computed dispatch without jump tables
- Parameterized inner loops

**When to avoid**:
- Code in ROM (can't modify)
- Readability matters more than speed
- Code might be re-entered during modification

---

## 4. Optimization Puzzle Collection

Concrete "code golf" challenges for 6502. Each puzzle specifies inputs, outputs, and constraints.

### Puzzle: Multiply by 10
**Input**: A = n (0-25 to avoid overflow)
**Output**: A = n * 10
**Constraints**: Minimize cycles, then bytes

```asm
; Solution 1: shifts and adds (10 = 8 + 2)
    ASL A           ; *2
    STA temp
    ASL A           ; *4
    ASL A           ; *8
    CLC
    ADC temp        ; *8 + *2 = *10
; 11 bytes, 14 cycles
```

Can we do better?

### Puzzle: Swap A and X
**Input**: A, X contain values
**Output**: A, X swapped
**Constraints**: No memory (zero page or otherwise)

```asm
; Impossible without temp? Or is there a trick?
```

### Puzzle: Absolute Value
**Input**: A = signed byte (-128 to 127)
**Output**: A = |A|
**Constraints**: Minimize cycles

### Puzzle: Count Set Bits
**Input**: A = byte
**Output**: A = number of 1 bits (0-8)
**Constraints**: No lookup table

### Puzzle: Max of A and X
**Input**: A, X = unsigned bytes
**Output**: A = max(A, X)
**Constraints**: Branchless?

---

## 5. Compare cc65 Output to Hand-Written

Take simple C functions, compile with cc65 (C compiler for 6502), then show how a human improves them.

**Process**:
1. Write simple C function
2. Compile with cc65, examine output
3. Annotate what the compiler did
4. Hand-optimize
5. Compare size and cycle count

**Candidate functions**:
- Array sum
- String length
- Memory copy
- Binary search
- Simple game logic (collision detection)

---

## Tools

### Disassemblers

**SourceGen (6502bench)** — Best option for serious work
- Interactive GUI, define labels, add comments, see results immediately
- Generates assembler source for ACME, 64tass, cc65, Merlin 32
- Supports 6502, 65C02, 65816, including undocumented opcodes
- Symbol files for C64 memory map (VIC, SID, KERNAL, etc.)
- Windows only, but works under Wine
- https://6502bench.com/
- https://github.com/fadden/6502bench

**Regenerator** — C64-specific, recommended by community
- Auto-labels C64 memory map entries (VIC, SID, etc.)
- Loads PRG files directly
- Windows, requires .NET
- https://csdb.dk/release/?id=227254

**JC64dis** — Cross-platform alternative
- Windows, macOS, Linux
- Handles PRG, SID, CRT, VSF files
- https://iceteam.itch.io/jc64dis

**Dis64** — Outputs Kick Assembler format
- Detects VIC bank allocation and screen buffers
- https://github.com/smnjameson/Dis64

### Assemblers

**ACME** — Currently using, good for tutorials
- `sudo apt install acme`
- Simple, cross-platform

**Kick Assembler** — More powerful, Java-based
- Macros, scripting, better for complex projects
- Popular in demoscene

**64tass** — Feature-rich, good optimization
- Supports all 6502 variants

**ca65 (cc65 suite)** — If also using C
- Linker, relocatable code, proper toolchain

---

## Resources Found

### Game Disassemblies (Excellent for Study)

**Llamasource Project** — Jeff Minter games, fully annotated
- Gridrunner (1982): https://github.com/mwenge/gridrunner
- Matrix (1983): https://github.com/mwenge/matrix
- Project hub: https://mwenge.github.io/llamaSource/
- Includes "Gridrunner: The Little Black Book" — deep dive into source
- Disassemblies compile to byte-identical binaries (verified)

### Demo/Intro Sources

**c64lib examples**
- Blue Vessel (intro/demo): https://github.com/maciejmalecki/bluevessel/
- T-Rex64 (side-scroller): https://github.com/maciejmalecki/trex64/

**awesome-c64** — Curated links
- https://github.com/vigo/awesome-c64

**CSDB (C64 Scene Database)** — Browse for releases with source
- https://csdb.dk/

### Coding Tricks

**"Dirty tricks 6502 programmers use"** — Size-coding competition analysis
- https://nurpax.github.io/posts/2019-08-18-dirty-tricks-6502-programmers-use.html
- Tricks: scrolling instead of addressing, SMC, stack hijacking, exploiting power-on state

**Codebase64** — ⚠️ Domain appears hijacked (2025)
- Was the go-to wiki for algorithms
- Try Wayback Machine: https://web.archive.org/web/*/codebase64.org

### Other Disassembly Projects

**6502disassembly.com** — Apple II, Atari, NES, Arcade
- Super Mario Bros. (NES)
- Asteroids, Battlezone (arcade)
- https://6502disassembly.com/

---

## First Steps

1. **Install SourceGen** (or Regenerator if Windows-only is fine)
2. **Clone Gridrunner** disassembly and study it
3. **Read "Dirty tricks"** article for inspiration
4. **Pick a puzzle** from section 4 and solve it by hand
