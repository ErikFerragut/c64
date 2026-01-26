# Chapter 6: Your First Sprite

A white bucket appears at the bottom of the screen — our first hardware sprite.

![Bucket sprite at bottom center of screen](images/06-sprite.png)

## The Code

Create `src/sprite.asm`:

```asm
; sprite.asm - Display a sprite on screen
; Your first C64 sprite!

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2064
!byte $0c, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2064"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

* = $0810                       ; Code start (2064 decimal)

    ; Set sprite 0 data pointer
    lda #33                     ; Sprite data at $0840 (33 x 64)
    sta $07f8                   ; Sprite 0 pointer

    ; Enable sprite 0
    lda $d015                   ; Read sprite enable register
    ora #%00000001              ; Set bit 0 (sprite 0)
    sta $d015                   ; Write back

    ; Position sprite (center bottom of screen)
    lda #172                    ; X position (~center)
    sta $d000                   ; Sprite 0 X
    lda #224                    ; Y position (near bottom)
    sta $d001                   ; Sprite 0 Y

    ; Set sprite color
    lda #$01                    ; White
    sta $d027                   ; Sprite 0 color

done:
    jmp done                    ; Loop forever (sprite stays visible)

; --- Sprite Data ---
* = $0840                       ; 64-byte aligned (pointer = 33)

sprite_data:
    ; Rows 0-11: empty
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    ; Row 12-13: rim (full width)
    !byte $ff,$ff,$ff
    !byte $ff,$ff,$ff
    ; Row 14-15: body tapers
    !byte $7f,$ff,$fe
    !byte $7f,$ff,$fe
    ; Row 16-17
    !byte $3f,$ff,$fc
    !byte $3f,$ff,$fc
    ; Row 18-19
    !byte $1f,$ff,$f8
    !byte $1f,$ff,$f8
    ; Row 20: bottom
    !byte $0f,$ff,$f0
```

The program sets up one sprite and loops forever. No input, no animation — just a bucket shape sitting at the bottom center of the screen. Let's break down every piece.

## Code Explanation

### What Is a Sprite?

A **sprite** is a small graphic that the VIC-II chip draws independently of the background. The C64 supports up to **8 sprites**, numbered 0-7. Each sprite is a **24 x 21 pixel** image that can be positioned anywhere on screen, given its own color, and moved freely without disturbing the background.

Sprites are managed entirely by the VIC-II hardware — you set up the data, tell the chip where to find it, and the chip draws the sprite automatically on every frame. No CPU effort needed to keep it on screen.

### Sprite Data: Drawing in Binary

Each sprite is 24 pixels wide and 21 pixels tall. Since 24 pixels = 3 bytes (8 bits each), one row of a sprite is 3 bytes. The full sprite is:

> 3 bytes per row x 21 rows = **63 bytes**

Each bit corresponds to one pixel: 1 = visible, 0 = transparent. Here's how our bucket looks in binary. Rows 0-11 are all zeros (empty space above the bucket), so the shape starts at row 12:

```
Row 12: XXXXXXXXXXXXXXXXXXXXXXXX  $FF $FF $FF  <- rim (full 24px)
Row 13: XXXXXXXXXXXXXXXXXXXXXXXX  $FF $FF $FF
Row 14: .XXXXXXXXXXXXXXXXXXXXXX.  $7F $FF $FE  <- body tapers
Row 15: .XXXXXXXXXXXXXXXXXXXXXX.  $7F $FF $FE
Row 16: ..XXXXXXXXXXXXXXXXXXXX..  $3F $FF $FC
Row 17: ..XXXXXXXXXXXXXXXXXXXX..  $3F $FF $FC
Row 18: ...XXXXXXXXXXXXXXXXXX...  $1F $FF $F8
Row 19: ...XXXXXXXXXXXXXXXXXX...  $1F $FF $F8
Row 20: ....XXXXXXXXXXXXXXXX....  $0F $FF $F0  <- bottom (16px)
```

Each `X` is a set bit (1) and each `.` is a clear bit (0). The rim at row 12 is all 24 bits set: `%11111111 %11111111 %11111111` = `$FF $FF $FF`. Each pair of rows below loses one pixel on each side — the `$7F` at the start of row 14 is `%01111111` (top bit cleared), and the `$FE` at the end is `%11111110` (bottom bit cleared).

The result is a trapezoid shape — wider at the top (the catching area) and narrowing toward the bottom, like a bucket viewed from the front.

### Memory Layout and Pointers

Sprite data must start on a **64-byte boundary** — an address evenly divisible by 64. Our data lives at `$0840`:

> $0840 / 64 = $0840 / $40 = **33**

We store this pointer value (33) at `$07F8`, which is the **sprite 0 pointer** location. The VIC-II reads this byte to find the sprite data: pointer value x 64 = data address.

Why `$07F8`? Sprite pointers live at the end of **screen memory**. The default screen starts at `$0400` (1024 bytes of character data), and the 8 sprite pointers occupy the last 8 bytes of that 1K block:

| Address | Sprite |
|---------|--------|
| $07F8 | Sprite 0 |
| $07F9 | Sprite 1 |
| $07FA | Sprite 2 |
| $07FB | Sprite 3 |
| $07FC | Sprite 4 |
| $07FD | Sprite 5 |
| $07FE | Sprite 6 |
| $07FF | Sprite 7 |

That's `$0400 + $03F8` = `$07F8` for sprite 0. The pointer is a single byte, so sprite data can address 256 x 64 = 16,384 bytes — the first 16K of memory. Our data at `$0840` is safely within that range and doesn't conflict with the BASIC stub or our code at `$0810`.

### ORA — Setting Bits

In [Chapter 4](04-JOYSTICK.md) we used **AND** to mask off bits and test them. **ORA** does the opposite — it turns bits *on*:

```asm
    lda $d015                   ; Read sprite enable register
    ora #%00000001              ; Set bit 0 (sprite 0)
    sta $d015                   ; Write back
```

ORA (OR with Accumulator) compares each bit pair and sets the result to 1 if *either* input bit is 1:

| A bit | Mask bit | Result |
|-------|----------|--------|
| 0 | 0 | 0 |
| 0 | 1 | **1** |
| 1 | 0 | **1** |
| 1 | 1 | **1** |

With mask `%00000001`, only bit 0 is affected — it gets forced to 1. All other bits pass through unchanged from their original value in `$d015`. This is important: if sprites 1-7 were already enabled, we don't want to accidentally disable them.

Compare with the simpler approach:

```asm
    lda #%00000001              ; Just sprite 0
    sta $d015                   ; Write directly
```

This *also* enables sprite 0, but it **clears all other bits**, disabling sprites 1-7. The read/ORA/write pattern is the safe way to set bits without disturbing others.

The three logical operations form a complete toolkit:

| Instruction | Effect | Use case |
|-------------|--------|----------|
| AND | Clear bits (0 in mask = force off) | Testing bits ([Ch 4](04-JOYSTICK.md)) |
| ORA | Set bits (1 in mask = force on) | Enabling features |
| EOR | Flip bits (1 in mask = toggle) | Toggling states ([Ch 4](04-JOYSTICK.md) exercise) |

### Positioning and Color

Each sprite has its own X and Y coordinate registers. For sprite 0:

```asm
    lda #172                    ; X position
    sta $d000                   ; Sprite 0 X coordinate
    lda #229                    ; Y position
    sta $d001                   ; Sprite 0 Y coordinate
```

The registers follow a pattern — each sprite gets two consecutive bytes:

| Sprite | X register | Y register |
|--------|------------|------------|
| 0 | $D000 | $D001 |
| 1 | $D002 | $D003 |
| 2 | $D004 | $D005 |
| 3 | $D006 | $D007 |
| 4 | $D008 | $D009 |
| 5 | $D00A | $D00B |
| 6 | $D00C | $D00D |
| 7 | $D00E | $D00F |

The visible screen area starts at approximately X=24, Y=50 and ends around X=343, Y=249. Our X=172 centers the 24-pixel-wide sprite horizontally: 24 + (320 - 24) / 2 = 172. Y=229 places it near the bottom.

Since X coordinates can go up to 343 but a single byte only holds 0-255, there's a ninth bit for each sprite's X position stored in register `$D010`. We don't need it here since 172 fits in one byte, but we'll use it in the next chapter.

Sprite color is set through individual color registers:

```asm
    lda #$01                    ; White
    sta $d027                   ; Sprite 0 color
```

Sprites 0-7 use `$D027`-`$D02E`, one register each. The value is a standard C64 color (0-15) from [Appendix A](A-REF.md).

## Sprite Editor Sidebar

Hand-calculating sprite bytes works but gets tedious for detailed shapes. The online tool **spritemate** (spritemate.com) lets you draw sprites visually in a pixel grid and export the data as assembly bytes. It's a modern version of the graph-paper approach C64 programmers used in the 1980s. For our simple bucket shape, hand-coding is fine — but for complex game sprites, a visual editor saves considerable effort.

## Compiling

```bash
acme -f cbm -o src/sprite.prg src/sprite.asm
```

## Running

```bash
vice-jz.x64sc -autostart src/sprite.prg
```

You should see a white bucket-shaped sprite at the bottom center of the screen against the default blue background. The program loops forever — close the VICE window to exit.

## Exercises

### Exercise 1: Change the Color

Change the bucket to green (5), yellow (7), or any color from [Appendix A](A-REF.md). Try setting the border and background colors too (from [Chapter 2](02-HELLO.md)) to create a nice color scheme.

**Hint:** Change the value loaded before `sta $d027`. Add `sta $d020` and `sta $d021` lines to set the border and background.

### Exercise 2: Slide in From the Left

Start the bucket at X=0 and animate it sliding rightward to the center. Use `inc $d000` to move one pixel at a time, a delay loop (from [Chapter 5](05-STROBE.md)) to control speed, and `cmp #172` / `bne slide` to stop at the target position. This combines sprite positioning with the counted loop pattern.

**Hint:** Replace the `lda #172` / `sta $d000` with `lda #0` / `sta $d000` to start at the left edge. Then add a loop after the sprite setup that increments `$d000`, runs a delay, reads the position back with `lda $d000` / `cmp #172`, and branches back with `bne` until it reaches center.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

We've got a sprite on screen — but it just sits there. In the next chapter, we'll connect the joystick from [Chapter 4](04-JOYSTICK.md) to the sprite's position registers, making the bucket move freely across the screen. That's the foundation for every game: a player-controlled object.
