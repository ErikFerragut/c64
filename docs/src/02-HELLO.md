# Chapter 2: Hello World

Our first C64 program changes the screen colors and returns to BASIC.

## The Code

Create `src/hello.asm`:

```asm
; hello.asm - Minimal C64 program
; Changes border color to black and returns to BASIC

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2064
!byte $0c, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2064"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

* = $0810                       ; Code start (2064 decimal)

    lda #$00                    ; Load black (0) into accumulator
    sta $d020                   ; Store to border color register
    sta $d021                   ; Store to background color too
    rts                         ; Return to BASIC
```

## Code Explanation

### Assembly Language Basics

Before diving into the code, let's cover the syntax fundamentals.

**Comments** start with `;` and continue to the end of the line:
```asm
; This entire line is a comment
lda #$00    ; This is an inline comment
```

**Hexadecimal numbers** are prefixed with `$`. The C64 uses a 16-bit address space ($0000-$FFFF), so addresses are written as 4 hex digits:
```asm
$0801       ; = 2049 in decimal
$d020       ; = 53280 in decimal
$00         ; = 0 in decimal
```

**The program counter** (`*`) tells the assembler where to place the following code in memory. The `* = $0801` directive means "put the next bytes at address $0801":
```asm
* = $0801   ; Start assembling at address $0801
```

**ACME directives** start with `!` and emit raw data:
- `!byte $0c, $08` - emit literal byte values
- `!text "2064"` - emit ASCII text bytes

### The C64 Memory Map

The C64 has 64 kilobytes of address space ($0000-$FFFF), divided into regions with different purposes:

| Address Range | What Lives There |
|---------------|-----------------|
| $0000-$00FF | **Zero page** — fast-access RAM (used for variables later) |
| $0100-$01FF | **Stack** — used by JSR/RTS for return addresses |
| $0800-$9FFF | **Program RAM** — where BASIC and your code live |
| $A000-$BFFF | BASIC ROM (can be switched out for RAM) |
| $D000-$D3FF | **VIC-II** — graphics chip registers |
| $D400-$D7FF | **SID** — sound chip registers |
| $D800-$DBFF | **Color RAM** — character colors |
| $DC00-$DCFF | **CIA 1** — keyboard and joystick |
| $DD00-$DDFF | **CIA 2** — serial port and more |
| $E000-$FFFF | **Kernal ROM** — built-in system routines |

When we write to `$D020`, we're not writing to RAM — we're talking directly to the VIC-II graphics chip. This is called **memory-mapped I/O**: hardware registers appear as memory addresses. We'll visit more of these regions as we add input, sound, and sprites.

### The 6502 CPU

The C64's 6502 processor has three main registers:
- **A** (Accumulator) - the primary register for math and data transfer
- **X** and **Y** - index registers (we'll use these later)

Almost all data movement goes through the accumulator. To set a memory location to a value, you first load the value into A, then store A to the memory address. You cannot directly set a constant value into a memory location.[^1]

[^1]: The 65C02, an enhanced version of the 6502, added `STZ` (Store Zero) to directly zero out a memory location. The C64's 6510 doesn't have this instruction.

### The BASIC Stub

C64 programs loaded from disk need a BASIC stub to auto-run. When you `LOAD "*",8,1` and `RUN`, BASIC executes the stub which jumps to your machine code.

BASIC programs always start at address $0801. When you `LOAD "*",8,1`, the `,1` tells the LOAD command to read the 2-byte address header from the PRG file and load the data at that address. The header comes from our `* = $0801` directive — ACME's `-f cbm` flag writes it into the file. If we changed the directive to `* = $1000`, the file would load at $1000 instead. We use $0801 because that's where BASIC's `RUN` command expects to find programs.

| Bytes | Meaning |
|-------|---------|
| `$0c, $08` | Pointer to next BASIC line ($080c). BASIC uses this to find the next line. |
| `$0a, $00` | Line number 10 in little-endian (low byte first). |
| `$9e` | The BASIC token for `SYS`. BASIC stores keywords as single-byte tokens. |
| `"2064"` | The address argument, stored as ASCII text (not a binary number). |
| `$00` | Zero byte marks end of this BASIC line. |
| `$00, $00` | Null pointer (no next line) marks end of program. |

This creates the equivalent of typing: `10 SYS 2064`

When BASIC runs this, `SYS 2064` transfers execution to address 2064 ($0810), where our machine code begins. It also stores the return location on the stack to be accessed later.

### The Machine Code

The 6502 has a small instruction set. Our program uses just three instructions:

**LDA** (Load Accumulator) - copies a value into the A register:
```asm
lda #$00    ; Load the literal value 0 into A (# means "immediate")
lda $d020   ; Load the value FROM memory address $d020 into A (no #)
```
The `#` is crucial: `#$00` means "the number zero", while `$00` means "the contents of address $0000".

These two forms have names — they're **addressing modes**:
- `lda #$00` uses **immediate mode**: the value is encoded directly in the instruction
- `lda $d020` uses **absolute mode**: the instruction contains an address, and the CPU reads the value from that address

The 6502 has several addressing modes. We'll introduce them as we need them.

**STA** (Store Accumulator) - copies A into a memory location:
```asm
sta $d020   ; Copy whatever is in A to address $d020
```

**RTS** (Return from Subroutine) - returns to the caller:
```asm
rts         ; Pop return address from stack and jump there
```
RTS takes no operand — the return address comes from the stack. (This is called **implied mode**: the instruction knows where to find its data without being told.)

Since BASIC called us via `SYS`, RTS returns control to BASIC.

### Putting It Together

| Address | Instruction | What It Does |
|---------|-------------|--------------|
| $0810 | `lda #$00` | Put the value 0 (black) into the accumulator |
| $0812 | `sta $d020` | Write the accumulator to the border color register |
| $0815 | `sta $d021` | Write the accumulator to the background color register (A still holds 0) |
| $0818 | `rts` | Return to BASIC |

Note that we only load the value once, then store it twice. The accumulator keeps its value until we change it.

### The VIC-II Color Registers

The VIC-II graphics chip is mapped to addresses `$d000-$d3ff` (see [Appendix B](B-VIC-II.md)). We're using:
- `$d020` - border color
- `$d021` - background color

Color values are 0-15 (see [Appendix A](A-REF.md) for the full palette). Here are the ones relevant to this program:

| Value | Color |
|-------|-------|
| 0 | Black |
| 6 | Blue (default background) |
| 14 | Light Blue (default border) |

For numbers bigger than 15, VIC-II will just use the low four bits.

## Compiling

Use ACME to assemble the source:

```bash
acme -f cbm -o src/hello.prg src/hello.asm
```

### ACME Arguments

| Flag | Meaning |
|------|---------|
| `-f cbm` | Output in CBM format (adds 2-byte load address header) |
| `-o src/hello.prg` | Output filename |
| `src/hello.asm` | Input source file |

The `-f cbm` flag is essential. Without it, ACME outputs raw bytes. The CBM format prepends the load address so the C64 knows where to place the code in memory.

## Running

Launch in VICE with autostart:

```bash
vice-jz.x64sc -autostart src/hello.prg
```

The screen should turn black (border and background), then show the READY prompt.

## Examining the Binary

The compiled `hello.prg` is 26 bytes. Here's the hexdump:

```
00000000: 0108 0c08 0a00 9e32 3036 3400 0000 0000  .......2064.....
00000010: 00a9 008d 20d0 8d21 d060                 .... ..!.`
```

Breaking it down:

| Offset | Bytes | Meaning |
|--------|-------|---------|
| 0000 | `01 08` | Load address $0801 (little-endian) |
| 0002 | `0c 08` | BASIC: next line pointer |
| 0004 | `0a 00` | BASIC: line number 10 |
| 0006 | `9e` | BASIC: SYS token |
| 0007 | `32 30 36 34` | ASCII "2064" |
| 000b | `00` | BASIC: end of line |
| 000c | `00 00` | BASIC: end of program |
| 000e | `00 00` | Padding (assembler fills gap to $0810) |
| 0010 | `a9 00` | LDA #$00 |
| 0012 | `8d 20 d0` | STA $d020 |
| 0015 | `8d 21 d0` | STA $d021 |
| 0018 | `60` | RTS |

You can generate this hexdump yourself using `xxd`:

```bash
xxd src/hello.prg
```

## Exercises

### Exercise 1: Red Screen

Modify `hello.asm` to set both the border and background to red instead of black.

**Hint:** Red is color value 2. See [Appendix A](A-REF.md) for the full color palette.

### Exercise 2: Two Colors

Modify the program to set the border to red but keep the background black.

**Hint:** You'll need to load and store twice, using different values.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

- This is just the beginning! Go on to the next chapter.
