# Chapter 8: Falling Objects

A red ball falls from the top of the screen while we move the bucket left and right — our first two-sprite program.

## The Code

Create `src/faller.asm`:

```asm
; faller.asm - Falling object with moving bucket
; Ball falls from random positions, bucket catches with joystick

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2064
!byte $0c, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2064"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

* = $0810                       ; Code start (2064 decimal)

sprite_x   = $02                ; Bucket X position, low byte
sprite_x_h = $03                ; Bucket X position, high byte (0 or 1)
ball_y     = $04                ; Ball Y position

    ; --- Initialize bucket sprite (sprite 0) ---

    lda #172                    ; X = 172 (center)
    sta sprite_x
    lda #0                      ; High byte = 0
    sta sprite_x_h

    lda #36                     ; Bucket data at $0900 (36 x 64)
    sta $07f8                   ; Sprite 0 pointer

    lda #224                    ; Near bottom of screen
    sta $d001                   ; Sprite 0 Y

    lda #$01                    ; White
    sta $d027                   ; Sprite 0 color

    ; --- Initialize ball sprite (sprite 1) ---

    lda #37                     ; Ball data at $0940 (37 x 64)
    sta $07f9                   ; Sprite 1 pointer

    lda #50                     ; Start near top of screen
    sta ball_y
    sta $d003                   ; Sprite 1 Y

    lda #172                    ; Start at center X
    sta $d002                   ; Sprite 1 X

    lda #$02                    ; Red
    sta $d028                   ; Sprite 1 color

    ; --- Enable sprites 0 and 1 ---

    lda $d015                   ; Read sprite enable register
    ora #%00000011              ; Set bits 0 and 1
    sta $d015

    ; --- Set up SID voice 3 for random numbers ---

    lda #$ff                    ; Maximum frequency
    sta $d40e                   ; Voice 3 frequency low
    sta $d40f                   ; Voice 3 frequency high
    lda #$80                    ; Noise waveform, gate off
    sta $d412                   ; Voice 3 control register

    ; --- Game loop ---

loop:
    ; --- Read joystick, move bucket ---

    lda $dc00                   ; Read joystick port 2
    and #%00000100              ; Test bit 2 (left)
    beq move_left

    lda $dc00                   ; Re-read
    and #%00001000              ; Test bit 3 (right)
    beq move_right

    jmp move_ball               ; No horizontal input

move_left:
    lda sprite_x
    sec
    sbc #1
    sta sprite_x
    lda sprite_x_h
    sbc #0
    sta sprite_x_h
    jmp move_ball

move_right:
    lda sprite_x
    clc
    adc #1
    sta sprite_x
    lda sprite_x_h
    adc #0
    sta sprite_x_h

move_ball:
    ; --- Animate ball: move down one pixel ---

    inc ball_y                  ; Increment Y position
    lda ball_y
    sta $d003                   ; Update sprite 1 Y register

    ; Check if ball reached bottom of screen
    cmp #250                    ; Past visible area?
    bcc update                  ; No: skip reset

    ; --- Reset ball to top with new random X ---

    lda #50                     ; Back to top
    sta ball_y
    sta $d003

    lda $d41b                   ; Read SID voice 3 random value
    sta $d002                   ; New X position for ball

    lda $d010                   ; Read X position MSB register
    and #%11111101              ; Clear bit 1 (sprite 1)
    sta $d010                   ; Keep ball in 0-255 X range

update:
    ; --- Update bucket X position ---

    lda sprite_x                ; Low 8 bits of X
    sta $d000                   ; Sprite 0 X position

    ; Update bucket X MSB (bit 8)
    lda sprite_x_h
    and #%00000001
    beq msb_clear

    lda $d010
    ora #%00000001              ; Set bit 0 (sprite 0)
    sta $d010
    jmp delay

msb_clear:
    lda $d010
    and #%11111110              ; Clear bit 0 (sprite 0)
    sta $d010

delay:
    ldx #$06                    ; Outer loop
delay_outer:
    ldy #$ff                    ; Inner loop
delay_inner:
    dey
    bne delay_inner
    dex
    bne delay_outer

    jmp loop                    ; Back to game loop

; --- Sprite Data ---
* = $0900                       ; Bucket sprite (pointer = 36)

bucket_data:
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

* = $0940                       ; Ball sprite (pointer = 37)

ball_data:
    ; Rows 0-6: empty
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00
    ; Row 7: top of ball
    !byte $00,$3c,$00
    ; Row 8
    !byte $00,$7e,$00
    ; Rows 9-12: middle
    !byte $00,$ff,$00
    !byte $00,$ff,$00
    !byte $00,$ff,$00
    !byte $00,$ff,$00
    ; Row 13
    !byte $00,$7e,$00
    ; Row 14: bottom of ball
    !byte $00,$3c,$00
    ; Rows 15-20: empty
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
```

The bucket movement is carried over from [Chapter 7](07-BUCKET.md). The new parts are the second sprite, the falling animation, and the SID noise generator for random positions.

## Code Explanation

### Setting Up Multiple Sprites

Each of the C64's 8 sprites has its own set of registers. Sprite 1 uses the same pattern as sprite 0, just at different addresses:

| | Sprite 0 | Sprite 1 |
|---|---|---|
| Pointer | $07F8 | $07F9 |
| X position | $D000 | $D002 |
| Y position | $D001 | $D003 |
| Color | $D027 | $D028 |
| Enable bit | Bit 0 of $D015 | Bit 1 of $D015 |
| X MSB bit | Bit 0 of $D010 | Bit 1 of $D010 |

To enable both sprites at once, we set two bits in `$D015`:

```asm
    lda $d015
    ora #%00000011              ; Set bits 0 AND 1
    sta $d015
```

The ORA mask `%00000011` has both bit 0 and bit 1 set, so both sprites are enabled in a single write. If we needed sprites 0, 2, and 5, the mask would be `%00100101`.

### INC — Incrementing Memory

In [Chapter 7](07-BUCKET.md), we used ADC to add to the bucket's X position. For the ball's Y position, we use something simpler — **INC** (increment memory):

```asm
    inc ball_y                  ; Add 1 to ball_y
    lda ball_y                  ; Load the new value
    sta $d003                   ; Write to sprite 1 Y register
```

INC adds 1 directly to a memory location without going through the accumulator. It's the memory equivalent of INX/INY that we used for delay loops in [Chapter 5](05-STROBE.md). There's also **DEC** which subtracts 1 from memory.

Why not use INC for the bucket too? Because the bucket's X position is 16-bit (two bytes) and needs carry propagation. INC doesn't affect the carry flag, so it can't chain to a high byte. For single-byte values like Y positions (which never exceed 255 on the C64), INC is simpler and faster.

### Random Numbers From SID

The C64's SID sound chip has a built-in noise generator that produces pseudo-random values. We exploit this as a random number source:

```asm
    ; Setup: configure voice 3 as a free-running noise generator
    lda #$ff
    sta $d40e                   ; Voice 3 frequency low
    sta $d40f                   ; Voice 3 frequency high
    lda #$80                    ; Noise waveform (bit 7), gate off (bit 0 = 0)
    sta $d412                   ; Voice 3 control register
```

Voice 3's oscillator runs continuously at maximum frequency, cycling through random values. Register `$D41B` gives us the current 8-bit output:

```asm
    lda $d41b                   ; Read random value (0-255)
    sta $d002                   ; Use as ball's X position
```

Each read gives a different value. We don't hear anything because we never set the gate bit (bit 0 of `$D412`), so the sound never reaches the output. The oscillator runs silently in the background.

This is the standard C64 trick for random numbers. It's not cryptographically secure, but it's perfect for games — the ball appears at unpredictable X positions each time it resets.

### The Ball Sprite Shape

The ball uses a simple 8-pixel-diameter circle centered in the middle byte of the 24-pixel-wide sprite:

```
Row 7:  ....####....  $00 $3C $00
Row 8:  ...######...  $00 $7E $00
Row 9:  ..########..  $00 $FF $00
Row 10: ..########..  $00 $FF $00
Row 11: ..########..  $00 $FF $00
Row 12: ..########..  $00 $FF $00
Row 13: ...######...  $00 $7E $00
Row 14: ....####....  $00 $3C $00
```

The first and third bytes are always `$00` — the ball only uses the center 8 pixels. `$3C` = `%00111100` (4 pixels), `$7E` = `%01111110` (6 pixels), `$FF` = `%11111111` (all 8 pixels). The rows widen and narrow to approximate a circle.

## Compiling

```bash
acme -f cbm -o src/faller.prg src/faller.asm
```

## Running

```bash
vice-jz.x64sc -autostart src/faller.prg
```

A red ball falls from the top of the screen and resets to a random X position when it reaches the bottom. Move the bucket with the joystick. There's no collision detection yet — the ball passes right through the bucket. That comes next chapter.

## Exercises

### Exercise 1: Data Table Positions

Instead of using SID random values for the ball's X position, create a table of 8 fixed positions and cycle through them with an index. Define a table with `positions: !byte 40, 80, 120, 160, 200, 140, 60, 100` and a zero-page variable for the index. When the ball resets, load the X position from the table using indexed addressing (`lda positions,x`), increment the index, and wrap it back to 0 when it reaches 8 using `and #%00000111`.

**Hint:** `and #%00000111` masks the index to 3 bits, so values 0-7 cycle to 0-7 and value 8 wraps to 0. This is the standard power-of-2 wrap trick.

### Exercise 2: Variable Fall Speed

Add a `ball_speed` variable in zero page. When the ball resets, read a random value from `$D41B`, mask it with `and #%00000011` to get 0-3, then add 1 to get speed 1-4. Use this speed instead of `inc ball_y` — load `ball_y`, add `ball_speed` with CLC/ADC, and store back.

**Hint:** Replace `inc ball_y` with `lda ball_y` / `clc` / `adc ball_speed` / `sta ball_y`. This moves the ball by 1-4 pixels per frame instead of always 1.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

We have a ball falling past the bucket, but nothing happens when they touch. In the next chapter, we'll read the VIC-II's sprite collision register to detect when the ball hits the bucket, and introduce subroutines with JSR and RTS to organize the growing code.
