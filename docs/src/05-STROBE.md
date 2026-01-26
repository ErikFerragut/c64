# Chapter 5: Loops and Timing

Hold the fire button and watch the border explode into a rapid color cycle — release it to stop.

## The Code

Create `src/strobe.asm`:

```asm
; strobe.asm - Hold fire for color strobe effect
; Fire = cycle border colors, Release = stop

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2064
!byte $0c, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2064"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

* = $0810                       ; Code start (2064 decimal)

loop:
    lda $dc00                   ; Read joystick port 2
    and #%00010000              ; Test fire (bit 4)
    bne loop                    ; Not pressed -> keep waiting

    inc $d020                   ; Next border color

    ldx #$20                    ; Outer loop: 32 iterations
delay_outer:
    ldy #$ff                    ; Inner loop: 255 iterations
delay_inner:
    dey                         ; Decrement Y
    bne delay_inner             ; Loop until Y = 0
    dex                         ; Decrement X
    bne delay_outer             ; Loop until X = 0

    jmp loop                    ; Back to main loop
```

This is our shortest program yet. The main loop waits for fire, bumps the border color, wastes some time, and repeats. The interesting part is *how* it wastes time.

## Code Explanation

### X and Y: The Other Registers

So far we've used only the **accumulator** (A). The 6502 actually has three general-purpose registers:

| Register | Load | Store | Increment | Decrement |
|----------|------|-------|-----------|-----------|
| A | LDA | STA | — | — |
| X | LDX | STX | INX | DEX |
| Y | LDY | STY | INY | DEY |

X and Y work much like A — you can load values into them and store them to memory. But they have one key difference: they have built-in **increment** and **decrement** instructions. A single `DEX` subtracts 1 from X without needing to load, subtract, and store back.

X and Y are called **index registers**. We'll see why in a later chapter when we use them to step through arrays of data. For now, we're using them as simple counters.

### INC and DEC — Changing Memory Directly

Look at this line:

```asm
    inc $d020                   ; Next border color
```

**INC** (increment) adds 1 to a memory location directly — no load/store round-trip needed. Compare the alternative:

```asm
    lda $d020                   ; Load border color into A
    clc                         ; Clear carry for addition
    adc #$01                    ; Add 1
    sta $d020                   ; Store back
```

INC does the same thing in a single instruction. Its counterpart **DEC** subtracts 1 from a memory location. These only work on memory — to increment a register, use INX, INY (there's no "INA" on the 6502).

Since the VIC-II only uses the low 4 bits for color (values 0-15), incrementing past 15 wraps to 16, 17, etc. — but the VIC-II ignores the upper bits, so `$10` (16) displays as color 0 (black), `$11` as color 1 (white), and the cycle repeats. The strobe loops through all 16 colors continuously.

### The Delay Loop

After changing the color, we need to slow things down. Without a delay, the color would change every few microseconds — far too fast to see. Here's the inner loop:

```asm
    ldy #$ff                    ; Load 255 into Y
delay_inner:
    dey                         ; Y = Y - 1
    bne delay_inner             ; If Y != 0, loop back
```

This is the **DEX/BNE pattern** (here using Y, but the idea is the same): load a counter, decrement it, branch back if it hasn't reached zero. The loop executes 255 times, then falls through.

Compare our two loop types so far:

| Pattern | Purpose | Runs |
|---------|---------|------|
| `jmp loop` | Infinite loop | Forever |
| `dey` / `bne` | Counted loop | N times |

JMP always jumps — it's unconditional. BNE only jumps when the result isn't zero, so the loop has a built-in exit condition: the counter hits zero.

### The Nested Loop

A single loop of 255 iterations isn't long enough. Each DEY + BNE takes about 5 clock cycles, so 255 iterations = ~1,275 cycles. At the C64's clock speed, that's only about 1.3 milliseconds — the colors would still blur together.

The solution is a **nested loop** — a loop inside a loop:

```asm
    ldx #$20                    ; Outer: 32 times
delay_outer:
    ldy #$ff                    ; Inner: 255 times (reset each outer pass)
delay_inner:
    dey                         ; Inner countdown
    bne delay_inner             ; Inner loop
    dex                         ; Outer countdown
    bne delay_outer             ; Outer loop (resets Y to 255 again)
```

Each time the inner loop completes (Y counts from 255 to 0), X decreases by 1 and the inner loop starts over. The total iterations are:

> 32 outer × 255 inner = **8,160** iterations

Both registers are working at the same time — X controls *how many times* the inner loop runs, and Y does the actual counting within each pass.

### How Fast Is the C64?

The C64's 6510 CPU runs at approximately **1 MHz** — about 1 million clock cycles per second. Every instruction takes a specific number of cycles to execute:

| Instruction | Cycles |
|-------------|--------|
| DEY | 2 |
| BNE (taken) | 3 |
| DEX | 2 |
| LDY #$ff | 2 |

The inner loop body (DEY + BNE) takes ~5 cycles per iteration. Our total delay:

> 32 × 255 × ~5 = **~40,800 cycles**

At 1 MHz, that's roughly **41 milliseconds**. The color changes about 24 times per second — fast enough to look like a strobe, slow enough to see individual colors flash by.

This is how all early computers handled timing — no operating system, no timer API, just burning cycles in a loop. The exact speed depends on the CPU clock, which is why the same code runs at different speeds on different machines.

## Compiling

```bash
acme -f cbm -o src/strobe.prg src/strobe.asm
```

## Running

```bash
vice-jz.x64sc -autostart src/strobe.prg
```

Make sure joystick port 2 is configured (see [Chapter 4](04-JOYSTICK.md) for VICE joystick setup). Hold the fire button (numpad 0) and the border will cycle through all 16 colors. Release to stop.

Like Chapter 4, there's no quit key — close the VICE window to exit.

## Exercises

### Exercise 1: Speed Control

Add joystick up/down to adjust the strobe speed. Store the speed value in a memory location and use `ldx speed` instead of `ldx #$20`:

```asm
speed:  !byte $20               ; Initial speed (32)
```

Before the fire check, test up and down. Up should execute `dec speed` (faster — fewer outer loop iterations). Down should execute `inc speed` (slower — more iterations). This way the strobe speed is adjustable while running.

**Hint:** You'll need to check up and down with the same AND/BEQ pattern from [Chapter 4](04-JOYSTICK.md), but instead of loading a color, use INC and DEC on your speed variable. Load the speed value with `ldx speed` right before the delay loop.

### Exercise 2: Two-Color Strobe

Replace `inc $d020` with an EOR-based toggle between two specific colors — say black (0) and white (1). Instead of cycling through all 16 colors, the border should snap between just two.

**Hint:** Load the current border color, EOR with a value that flips between your two chosen colors, and store it back. Review the EOR toggle from [Chapter 4](04-JOYSTICK.md)'s Exercise 1.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

We've now used all three registers (A, X, Y) and seen how counted loops and nested loops work. The delay loop pattern shows up constantly in C64 programming — for animation timing, sound effects, and anywhere you need precise control over speed.

The next chapter will put graphics on the screen.
