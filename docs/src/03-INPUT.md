# Chapter 3: Keyboard Input

Our first interactive program. Press a key, see the border change color.

## The Code

Create `src/colors.asm`:

```asm
; colors.asm - Press keys to change the border color
; Keys: 1 = black, 2 = red, 3 = blue, Q = quit

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
    jsr $ffe4                   ; Call GETIN: read key into A
    beq loop                    ; No key pressed? Keep waiting

    cmp #$31                    ; Was it "1"?
    bne not_one                 ;   No: skip ahead
    lda #$00                    ;   Yes: load black
    sta $d020                   ;   Set border color
    jmp loop                    ;   Back to waiting

not_one:
    cmp #$32                    ; Was it "2"?
    bne not_two
    lda #$02                    ; Red
    sta $d020
    jmp loop

not_two:
    cmp #$33                    ; Was it "3"?
    bne not_three
    lda #$06                    ; Blue
    sta $d020
    jmp loop

not_three:
    cmp #$51                    ; Was it "Q"?
    beq done                    ;   Yes: quit

    jmp loop                    ; Unknown key, ignore it

done:
    rts                         ; Return to BASIC
```

## Code Explanation

### The Main Loop

Unlike Chapter 2's program, which ran once and returned, this program runs in a **loop**: read a key, act on it, read another key. It keeps going until you press Q.

```
loop → read key → no key?  → go back to loop
                → key "1"? → set black, go back to loop
                → key "2"? → set red, go back to loop
                → key "3"? → set blue, go back to loop
                → key "Q"? → quit
                → other?   → ignore, go back to loop
```

This read-process-repeat pattern is the basis of every interactive program.

### Labels

Labels mark locations in your code so you can jump to them:

```asm
loop:                           ; Marks this address as "loop"
    jsr $ffe4
    beq loop                    ; Jump back to "loop"
```

Labels don't generate any bytes in the output — they just give names to addresses. When the assembler sees `beq loop`, it calculates the distance to `loop` and encodes it as a byte offset.

A label must start at the beginning of a line and end with a colon.[^3]

[^3]: ACME also accepts labels without colons, but using colons makes them easier to spot and is required by most other assemblers.

### The Kernal and GETIN

The C64 has a set of built-in subroutines in ROM called the **Kernal**.[^4] These handle common tasks like reading input, printing characters, and managing files. Each routine lives at a fixed address.

[^4]: Not a typo — Commodore spelled it "Kernal," not "Kernel." The name stuck.

**GETIN** at address `$FFE4` reads one character from the keyboard buffer:
- If a key was pressed, A gets the key's character code
- If no key is waiting, A gets 0

The C64 uses **PETSCII** character encoding. For digits and uppercase letters, the codes match ASCII:

| Key | PETSCII Code |
|-----|-------------|
| "1" | $31 |
| "2" | $32 |
| "3" | $33 |
| ... | ... |
| "8" | $38 |
| "Q" | $51 |

### New Instructions

Chapter 2 used three instructions: LDA, STA, RTS. This chapter adds four more.

**JSR** (Jump to Subroutine) calls a routine and remembers where to come back:

```asm
jsr $ffe4       ; Jump to GETIN at $FFE4, return when it's done
```

JSR saves the return address on the **stack** (a reserved area of memory). When the called routine reaches RTS, execution resumes after the JSR. Think of it as a function call.

We'll write our own subroutines later. For now, we're calling one built into the C64.

**CMP** (Compare) tests whether A equals a value:

```asm
cmp #$31        ; Compare A with $31
```

CMP subtracts the value from A internally but **doesn't store the result** — A keeps its original value. Instead, CMP updates the processor's **status flags**:

| Flag | Name | Set when... |
|------|------|-------------|
| Z | Zero | A **equals** the compared value |
| C | Carry | A is **greater than or equal** to the value |
| N | Negative | Result has bit 7 set |

For now, we only need the Zero flag. The Carry and Negative flags become useful in later chapters for range checks and signed comparisons.

The key point: **CMP doesn't change A.** After `cmp #$31`, A still holds whatever GETIN returned. This is why we can test A against multiple values in sequence — each CMP compares against the same original value.

**BEQ** (Branch if Equal) and **BNE** (Branch if Not Equal) are conditional jumps:

```asm
beq done        ; If Z is set (equal), jump to "done"
bne not_one     ; If Z is clear (not equal), jump to "not_one"
```

These test the Zero flag from the most recent instruction that set it:
- **BEQ** jumps if the values were equal (Z set). Otherwise, execution falls through.
- **BNE** jumps if the values were different (Z clear). Otherwise, execution falls through.

The "fall-through" behavior is important: when the branch isn't taken, execution simply continues to the next line.

**JMP** (Jump) always goes to the target — no condition, no questions:

```asm
jmp loop        ; Always jump to "loop"
```

The difference: BEQ/BNE *might* jump depending on the flags. JMP *always* jumps.

### The CMP/BNE Pattern

Each key check follows the same template:

```asm
    cmp #$32                    ; Is A equal to "2"?
    bne not_two                 ;   No → skip past this block
    lda #$02                    ;   Yes → load the color
    sta $d020                   ;          set the border
    jmp loop                    ;          back to waiting
not_two:                        ; BNE lands here if skipped
```

If the key doesn't match, BNE skips the handler. If it does match, we fall through into the handler: load the color, set the border, and JMP back to the loop. The `jmp loop` is essential — without it, execution would fall through into the next CMP check.

### Putting It Together

Here's what happens when you press "2" (PETSCII $32):

| Instruction | A | Z flag | What happens |
|-------------|---|--------|-------------|
| `jsr $ffe4` | $32 | clear | GETIN returns $32 ("2") |
| `beq loop` | $32 | clear | A != 0, don't branch |
| `cmp #$31` | $32 | clear | $32 != $31, Z stays clear |
| `bne not_one` | $32 | clear | Not equal → branch to `not_one` |
| `cmp #$32` | $32 | **set** | $32 = $32, Z is set |
| `bne not_two` | $32 | **set** | Equal → don't branch, fall through |
| `lda #$02` | **$02** | — | Load red into A |
| `sta $d020` | $02 | — | Border turns red |
| `jmp loop` | $02 | — | Back to reading keys |

Notice that A stays $32 through both CMP instructions — neither one changes it. Only when we reach the handler do we overwrite A with the color value.

### Why BEQ Works Right After JSR

Look at the first two instructions:

```asm
    jsr $ffe4                   ; Call GETIN
    beq loop                    ; Branch if result is zero
```

BEQ tests the Zero flag, but JSR was the previous instruction — doesn't JSR set the flag? No. **JSR doesn't affect any flags.** The Zero flag that BEQ sees comes from inside GETIN itself. GETIN uses LDA internally to load the result into A, and LDA sets the Zero flag based on the loaded value. Since neither RTS nor JSR touch the flags, they survive the return trip.

Result: if GETIN returned 0, Z is set and `beq loop` branches back. If GETIN returned a keycode, Z is clear and we fall through to the CMP checks.

This `jsr $ffe4` / `beq loop` pattern is a standard C64 idiom.

## Compiling

```bash
acme -f cbm -o src/colors.prg src/colors.asm
```

Same flags as Chapter 2: `-f cbm` for the load address header, `-o` for the output file.

## Running

```bash
vice-jz.x64sc -autostart src/colors.prg
```

Press 1, 2, 3 to change the border color. Press Q to return to BASIC. Other keys are ignored.

Note that the program gives no on-screen indication that it's running — the screen still shows the BASIC listing and `RUN` with no cursor. This is normal. The program is sitting in its GETIN loop, waiting for your keypress.

## Debugging with the VICE Monitor

When something goes wrong — or you just want to see what your code is doing — VICE has a built-in debugger. Press **Alt+H** to open it. You'll get a command prompt:

```
(C:$e5cd) _
```

The address shown (`$e5cd` or similar) is where the CPU was when you interrupted it. Useful commands:

| Command | What it does |
|---------|-------------|
| `r` | Show registers: A, X, Y, SP, PC, and status flags |
| `d 0810` | Disassemble starting at $0810 (our code) |
| `m 0810 0840` | Hex dump of memory from $0810 to $0840 |
| `break 0813` | Set a breakpoint at address $0813 |
| `z` | Execute one instruction (single-step) |
| `g` | Continue running |
| `x` | Exit the monitor, return to emulation |

### Quick Check: Is My Code Running?

1. Press **Alt+H** to open the monitor
2. Type `r` — look at the **PC** (program counter) value
3. If PC is between `$0810` and `$0840`, you're in your code
4. If PC is in the `$E000`–`$FFFF` range, you're inside a Kernal routine (GETIN calls deep into ROM) — this is also normal
5. Type `x` to resume

### Watching a Keypress

1. Open the monitor with **Alt+H**
2. Set a breakpoint after the `beq loop`: `break 0815`
3. Type `x` to resume, then press a key
4. The monitor pops up at the breakpoint — type `r` to see A holds the PETSCII code of your key
5. Type `z` repeatedly to single-step through the CMP/BNE chain and watch the comparison logic work
6. Type `g` to let it finish, or `x` to resume normal execution

The breakpoint address `$0815` is right after `jsr $ffe4` (3 bytes at $0810) and `beq loop` (2 bytes at $0813). You can verify addresses with `d 0810`.

## Exercises

### Exercise 1: All Eight Colors

Add keys 4 through 8 using more colors from the [palette](A-REF.md):

| Key | Color | Value | PETSCII |
|-----|-------|-------|---------|
| 4 | White | $01 | $34 |
| 5 | Cyan | $03 | $35 |
| 6 | Purple | $04 | $36 |
| 7 | Green | $05 | $37 |
| 8 | Yellow | $07 | $38 |

**Hint:** Follow the same CMP/BNE/LDA/STA/JMP pattern for each new key. Add the new blocks between `not_three` and the "Q" check.

### Exercise 2: Border and Background

Modify each key handler to set both the border (`$d020`) and the background (`$d021`) to different colors. For example, key 1 could set a black border with a white background.

**Hint:** Each handler needs two LDA/STA pairs — one for each color register. This is the same technique as [Chapter 2, Exercise 2](02-HELLO.md#exercise-2-two-colors).

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

- Try other PETSCII codes — what happens if you check for "A" ($41)?
- The next chapter adds joystick input and introduces bit masking
