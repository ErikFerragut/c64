# Chapter 4: Joystick Control

Our first hardware input program — push the joystick, watch the border change color.

## VICE Joystick Setup

Before running this program, configure VICE to map your keyboard to joystick port 2:

1. In VICE, open **Settings → Input devices → Joystick**
2. Set **Joystick in port 2** to **Keyset A**
3. The default Keyset A mappings are:

| Key | Direction |
|-----|-----------|
| Numpad 8 | Up |
| Numpad 2 | Down |
| Numpad 4 | Left |
| Numpad 6 | Right |
| Numpad 0 | Fire |

You can also remap these under the Keyset A settings if your keyboard lacks a numpad.

## The Code

Create `src/joystick.asm`:

```asm
; joystick.asm - Read joystick port 2 and change border color
; Up = white, Down = black, Left = red, Right = cyan, Fire = green

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
    and #%00000001              ; Test bit 0 (up)
    beq up                      ; Bit clear = pressed

    lda $dc00                   ; Re-read (AND destroyed A)
    and #%00000010              ; Test bit 1 (down)
    beq down

    lda $dc00                   ; Re-read
    and #%00000100              ; Test bit 2 (left)
    beq left

    lda $dc00                   ; Re-read
    and #%00001000              ; Test bit 3 (right)
    beq right

    lda $dc00                   ; Re-read
    and #%00010000              ; Test bit 4 (fire)
    beq fire

    jmp loop                    ; No input, keep polling

up:
    lda #$01                    ; White
    sta $d020                   ; Set border
    jmp loop

down:
    lda #$00                    ; Black
    sta $d020
    jmp loop

left:
    lda #$02                    ; Red
    sta $d020
    jmp loop

right:
    lda #$03                    ; Cyan
    sta $d020
    jmp loop

fire:
    lda #$05                    ; Green
    sta $d020                   ; Set border
    sta $d021                   ; Set background too
    jmp loop
```

## Code Explanation

### The CIA and Joystick Port

In [Chapter 2](02-HELLO.md) we saw the VIC-II graphics chip at `$d000`. The C64 has another important chip: **CIA 1** (Complex Interface Adapter), mapped to `$dc00-$dcff`. CIA 1 handles keyboard scanning and joystick input.

The register we care about is **$DC00** — CIA 1 Port A. When a joystick is plugged into control port 2, its switches are connected to the lower 5 bits of this register:

| Bit | Direction | Bit Mask |
|-----|-----------|----------|
| 0 | Up | `%00000001` |
| 1 | Down | `%00000010` |
| 2 | Left | `%00000100` |
| 3 | Right | `%00001000` |
| 4 | Fire | `%00010000` |

The joystick is a simple device — each direction is a physical switch. Pushing the stick closes a switch, connecting the CIA pin to ground. The CIA has internal pull-up resistors, so an unpressed switch reads as 1 (pulled high) and a pressed switch reads as 0 (grounded).

This is called **active-low logic**: the signal is active (pressed) when low (0). It's counterintuitive at first — 0 means "yes, pressed" and 1 means "no, not pressed."

### Binary Notation

ACME supports binary literals with the `%` prefix. Each digit is one bit, and we write all 8 bits of a byte:

```asm
%00000001       ; Bit 0 set   = 1 in decimal
%00000010       ; Bit 1 set   = 2 in decimal
%00000100       ; Bit 2 set   = 4 in decimal
%00001000       ; Bit 3 set   = 8 in decimal
%00010000       ; Bit 4 set   = 16 in decimal
```

Bits are numbered right-to-left, starting at 0. The rightmost bit is bit 0 (the **least significant bit**), the leftmost is bit 7 (the **most significant bit**).

Binary notation makes bit operations obvious. Compare:

```asm
and #$04        ; Which bit is this? You have to convert mentally.
and #%00000100  ; Bit 2. Immediately clear.
```

We use binary when working with individual bits, and hex for everything else (addresses, color values, character codes).

### AND — Bit Masking

**AND** is a new instruction. It performs a bitwise AND between the accumulator and a value, storing the result back in A:

```asm
lda $dc00           ; Load joystick port value into A
and #%00000001      ; AND with bit mask — isolate bit 0
```

The AND truth table (per bit):

| A bit | Mask bit | Result |
|-------|----------|--------|
| 0 | 0 | 0 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

A result bit is 1 only when **both** inputs are 1. Any bit ANDed with 0 is forced to 0. Any bit ANDed with 1 passes through unchanged.

This lets us **isolate a single bit**. When we AND with `%00000001`, all bits except bit 0 are forced to zero. Only bit 0 survives:

```
Joystick value:  %11110111      (right pressed — bit 3 is 0)
Mask:            %00000001      (isolate bit 0)
                 ----------
Result:          %00000001 = 1  (bit 0 was 1 → up NOT pressed)
```

The result is either 0 (the tested bit was clear → direction pressed) or non-zero (the tested bit was set → direction not pressed). We use BEQ to branch when the result is zero:

```asm
and #%00000001      ; Isolate bit 0
beq up              ; Zero → bit was 0 → up IS pressed
```

### Why We Re-Read $DC00

Notice that we load from `$dc00` five separate times:

```asm
    lda $dc00                   ; Read for up test
    and #%00000001
    beq up

    lda $dc00                   ; Read AGAIN for down test
    and #%00000010
    beq down
```

Why not read once and test multiple times? Because **AND modifies A**. After `and #%00000001`, A no longer holds the original joystick value — it holds either 0 or 1. The other bits are gone. To test bit 1, we need the original value back, so we read `$dc00` again.

This is a key difference from CMP in [Chapter 3](03-INPUT.md). CMP doesn't modify A, so we could test the same value against multiple keys. AND *does* modify A, so each bit test needs a fresh read.

### Walking Through a Joystick Press

Let's trace what happens when you push right. With right pressed, bit 3 of `$dc00` is 0. All other directions are released, so bits 0, 1, 2, 4 are all 1. The port reads `%11110111` ($F7):

| Instruction | A | Z flag | What happens |
|-------------|---|--------|--------------|
| `lda $dc00` | $F7 | clear | Read port: right pressed (bit 3 = 0) |
| `and #%00000001` | $01 | clear | Isolate bit 0: it's 1 → up not pressed |
| `beq up` | $01 | clear | Not zero → don't branch |
| `lda $dc00` | $F7 | clear | Re-read port |
| `and #%00000010` | $02 | clear | Isolate bit 1: it's 1 → down not pressed |
| `beq down` | $02 | clear | Not zero → don't branch |
| `lda $dc00` | $F7 | clear | Re-read port |
| `and #%00000100` | $04 | clear | Isolate bit 2: it's 1 → left not pressed |
| `beq left` | $04 | clear | Not zero → don't branch |
| `lda $dc00` | $F7 | clear | Re-read port |
| `and #%00001000` | **$00** | **set** | Isolate bit 3: it's 0 → right IS pressed |
| `beq right` | $00 | **set** | Zero → branch to `right` |
| `lda #$03` | $03 | clear | Load cyan |
| `sta $d020` | $03 | — | Border turns cyan |
| `jmp loop` | $03 | — | Back to polling |

Each AND destroys A, but by re-reading `$dc00` we get a fresh copy. The check falls through three non-matching directions before finding the one that's pressed.

## Compiling

```bash
acme -f cbm -o src/joystick.prg src/joystick.asm
```

Same flags as previous chapters: `-f cbm` for the load address header, `-o` for the output file.

## Running

```bash
vice-jz.x64sc -autostart src/joystick.prg
```

Make sure joystick port 2 is configured (see [VICE Joystick Setup](#vice-joystick-setup) above). Push directions on the numpad to change the border color. Press numpad 0 (fire) to set both border and background to green.

Unlike Chapter 3's program, this one has no quit key — it polls forever, just like a real game would. Close the VICE window to exit.

## Exercises

### Exercise 1: EOR Toggle

Modify the fire handler so that pressing fire **toggles** the background between two colors instead of always setting green.

Replace the fire handler with:

```asm
fire:
    lda $d021
    eor #$06
    sta $d021
    lda #$05
    sta $d020
    jmp loop
```

Run it and press fire repeatedly. What two colors does the background alternate between? Why those two?

**Hint:** EOR (Exclusive OR) flips bits. `eor #$06` flips the bits that correspond to the value 6. If the background is 6 (blue), it becomes 0 (black). If it's 0, it becomes 6. This gives you a toggle with a single instruction — no need to compare and branch.

### Exercise 2: Second Player

Add joystick port 1 support using `$DC01` (CIA 1 Port B). The second joystick should change the **background** color (`$d021`) while the first joystick still controls the border.

Use the same bit layout — port 1 uses the same bit-to-direction mapping as port 2, just at a different address.

**Hint:** Add five more LDA/AND/BEQ checks after the port 2 fire test, reading from `$dc01` instead of `$dc00`. Create handlers (e.g., `p1_up`, `p1_down`, etc.) that write to `$d021` instead of `$d020`.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

- Try pressing two directions at once (diagonal) — what happens and why?
- The next chapter will put graphics on the screen
