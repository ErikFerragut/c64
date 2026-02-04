# Chapter 13: Difficulty Progression

The game gets harder as you play. Balls fall faster at higher scores, and a level indicator tracks your progress. We also replace the delay loop with **raster timing** -- synchronizing to the display hardware for smooth, consistent speed.

## Building on Chapter 12

Copy the previous chapter's source as a starting point:

```bash
cp src/multi.asm src/levels.asm
```

We make several changes to add difficulty progression and proper timing.

**New variables.** Add `level` and `fall_speed` to the zero page assignments:

```asm
level      = $08                ; Current level (1-4)
fall_speed = $09                ; Pixels per frame for balls
```

Initialize them at the start of the program alongside the other game state:

```asm
    lda #1
    sta level
    sta fall_speed              ; Start: 1 pixel per frame
```

**Replace delay_loop with wait_vblank.** Remove the `delay_loop` subroutine entirely and add this in its place:

```asm
wait_vblank:
    lda $d011                   ; Read control register (bit 7 = raster bit 8)
    and #%10000000              ; Isolate raster high bit
    bne wait_vblank             ; Wait if raster > 255

wv_low:
    lda $d012                   ; Read raster line (low 8 bits)
    cmp #251                    ; Reached line 251?
    bcc wv_low                  ; Not yet: keep waiting
    rts
```

The game loop calls `jsr wait_vblank` instead of `jsr delay_loop`, and now includes `jsr check_level`:

```asm
loop:
    ; Wait for vertical blank (raster line 251)
    jsr wait_vblank

    jsr read_input
    jsr animate_balls
    jsr check_collisions
    jsr update_bucket
    jsr check_level
    jmp loop
```

**Variable-speed ball movement.** In `animate_balls`, replace the single `inc` with an addition using `fall_speed`:

```asm
ab_loop:
    ; Move ball down by fall_speed pixels
    lda ball_y_tbl,x
    clc
    adc fall_speed              ; Add speed (1, 2, 3, or 4)
    sta ball_y_tbl,x
```

This makes balls fall 1 pixel per frame at level 1 and up to 3 pixels per frame at level 4.

**Faster bucket.** The bucket now moves 2 pixels per frame instead of 1, keeping it playable at higher ball speeds:

```asm
ri_left:
    lda sprite_x
    sec
    sbc #2                      ; Move 2 pixels (faster bucket)
    sta sprite_x
    lda sprite_x_h
    sbc #0
    sta sprite_x_h
    rts

ri_right:
    lda sprite_x
    clc
    adc #2                      ; Move 2 pixels
    sta sprite_x
    lda sprite_x_h
    adc #0
    sta sprite_x_h
    rts
```

**Level checking.** A new subroutine compares the score against thresholds and sets the level and fall speed:

```asm
check_level:
    ; Level 1: 0-49    speed 1
    ; Level 2: 50-99   speed 2
    ; Level 3: 100-149 speed 2
    ; Level 4: 150+    speed 3

    lda score_hi
    bne cl_high                 ; Score >= 256? Level 4

    lda score_lo
    cmp #150
    bcs cl_4
    cmp #100
    bcs cl_3
    cmp #50
    bcs cl_2

    ; Level 1
    lda #1
    sta fall_speed
    lda #1
    jmp cl_set

cl_2:
    lda #2
    sta fall_speed
    lda #2
    jmp cl_set

cl_3:
    lda #2
    sta fall_speed
    lda #3
    jmp cl_set

cl_high:
cl_4:
    lda #3
    sta fall_speed
    lda #4

cl_set:
    cmp level                   ; Changed?
    beq cl_done
    sta level
    jsr show_level
    jsr sfx_level               ; Level-up sound
cl_done:
    rts
```

**Level-up sound effect.** A quick ascending beep that sweeps frequency from `$10` to `$20`:

```asm
sfx_level:
    ; Quick ascending beep
    lda #$09
    sta $d405
    lda #$00
    sta $d406
    lda #$10
    sta $d401
    lda #$11
    sta $d404
    ldx #$10
sl_asc:
    stx $d401
    ldy #$80
sl_d:
    dey
    bne sl_d
    inx
    cpx #$20
    bne sl_asc
    lda #$10
    sta $d404
    rts
```

**HUD additions.** The `draw_hud` subroutine now writes "LVL:" at screen positions `$0410`-`$0413`, and a `show_level` subroutine displays the current level digit at `$0414`:

```asm
    lda #12                     ; L
    sta $0410
    lda #22                     ; V
    sta $0411
    lda #12                     ; L
    sta $0412
    lda #58                     ; :
    sta $0413
```

```asm
show_level:
    lda level
    clc
    adc #$30
    sta $0414
    rts
```

The full source is in `src/levels.asm`.

## Code Explanation

### The Raster and Vertical Blank

The C64's VIC-II chip draws the screen by sweeping an electron beam left-to-right, top-to-bottom, 50 times per second on PAL systems (60 on NTSC). The current scan line is exposed as a **9-bit raster counter** split across two registers:

| Register | Purpose |
|----------|---------|
| `$D012` | Raster line, bits 0-7 (low byte) |
| `$D011` | Bit 7 = raster line bit 8 (high bit) |

On a PAL C64, the raster counts from 0 to 311 (312 lines total). Lines 0-50 and 251-311 are in the **vertical blank** (vblank) -- the beam is off-screen, returning to the top. The visible screen occupies lines 51-250.

Our `wait_vblank` subroutine waits for line 251, the first line after the visible area:

```asm
wait_vblank:
    lda $d011                   ; Check bit 7 (raster >= 256?)
    and #%10000000
    bne wait_vblank             ; If set, raster is 256-311: wait for wrap

wv_low:
    lda $d012                   ; Read low byte
    cmp #251
    bcc wv_low                  ; Below 251: keep waiting
    rts
```

The two-step check is necessary because the raster counter is 9 bits wide. We first wait for bit 8 to clear (raster < 256), then wait for the low byte to reach 251. This ensures we catch line 251 exactly once per frame, not line 507 (which doesn't exist but would match the low byte alone).

### Why Raster Timing?

Chapter 12 used a delay loop -- nested `DEX`/`DEY` loops that waste a fixed number of CPU cycles:

```asm
delay_loop:
    ldx #$04
dl_outer:
    ldy #$ff
dl_inner:
    dey
    bne dl_inner
    dex
    bne dl_outer
    rts
```

This has two problems:

1. **Speed depends on game logic.** If the game loop takes longer one frame (processing a collision, playing a sound), the delay stays the same length, so the total frame time increases. The game stutters.

2. **Speed depends on the machine.** PAL and NTSC C64s run at slightly different clock speeds, and the delay loop runs differently on each.

Raster timing fixes both. The VIC-II reaches line 251 at a fixed interval (every 20ms on PAL, every 16.7ms on NTSC). If our game logic finishes before line 251, `wait_vblank` idles until the beam catches up. If it takes too long, the next frame starts immediately. The result is a **rock-solid frame rate** locked to the display refresh.

As a bonus, the time spent waiting in `wait_vblank` is visible headroom. The game logic takes roughly 630 cycles per frame. A PAL frame is about 19,656 cycles. That means about 97% of the frame is spent waiting -- the CPU has plenty of room to grow. When we add more features, we can measure how much headroom remains (see Exercise 1).

### Level Progression

The `check_level` subroutine uses a cascade of `CMP`/`BCS` (Compare / Branch if Carry Set) instructions to classify the score into levels:

```asm
    lda score_lo
    cmp #150
    bcs cl_4                    ; Score >= 150: level 4
    cmp #100
    bcs cl_3                    ; Score >= 100: level 3
    cmp #50
    bcs cl_2                    ; Score >= 50: level 2
    ; Otherwise: level 1
```

`CMP` subtracts the operand from A and sets the carry flag if A >= operand (no borrow needed). `BCS` branches if carry is set. By testing from highest threshold to lowest, each `BCS` peels off a range:

| Score | Level | Fall Speed |
|-------|-------|------------|
| 0-49 | 1 | 1 px/frame |
| 50-99 | 2 | 2 px/frame |
| 100-149 | 3 | 2 px/frame |
| 150+ | 4 | 3 px/frame |

The `cl_set` code compares the new level against the current level. If it changed, it updates the display and plays the level-up sound. This avoids re-triggering the sound effect every frame.

For scores above 255 (where `score_hi` is nonzero), we jump straight to level 4. The 8-bit `score_lo` can only distinguish values 0-255, so high scores always map to the maximum difficulty.

### Faster Bucket Movement

With balls falling 2-3 pixels per frame at higher levels, the old 1-pixel bucket speed feels sluggish. Doubling it to 2 pixels keeps the game playable. The joystick code simply changes `sbc #1` / `adc #1` to `sbc #2` / `adc #2`. Because the bucket position is 16-bit (for the X MSB), we still propagate the borrow/carry to the high byte.

## Compiling

```bash
acme -f cbm -o src/levels.prg src/levels.asm
```

The compiled program is **1100 bytes**.

## Running

```bash
vice-jz.x64sc -autostart src/levels.prg
```

The game plays like Chapter 12 at first, but as your score crosses 50, 100, and 150, the balls visibly accelerate. The "LVL:" indicator on the HUD updates, and you hear an ascending beep at each transition. The game now has a difficulty curve -- easy enough to start learning, challenging enough to keep playing.

## Exercises

### Exercise 1: Vblank Timing Test

Measure how much CPU time your game logic uses by changing the border color at the start and end of each frame:

```asm
loop:
    jsr wait_vblank
    inc $d020               ; Change border color (start of logic)
    jsr read_input
    jsr animate_balls
    jsr check_collisions
    jsr update_bucket
    jsr check_level
    dec $d020               ; Restore border color (end of logic)
    jmp loop
```

The colored stripe in the border shows exactly how many raster lines your code consumes. A thin stripe means plenty of headroom; a stripe that fills the screen means you are running out of time. This is the standard C64 profiling technique.

**Hint:** Use different colors for different subroutines to see which one costs the most. For example, set `$D020` to red before `animate_balls` and green before `check_collisions`.

### Exercise 2: Speed Curve

Instead of discrete speed jumps at level thresholds, implement a smooth speed increase. Divide the score by 64 using `LSR` (Logical Shift Right) to get a speed value that rises gradually:

```asm
    lda score_lo
    lsr                     ; / 2
    lsr                     ; / 4
    lsr                     ; / 8
    lsr                     ; / 16
    lsr                     ; / 32
    lsr                     ; / 64
    clc
    adc #1                  ; Minimum speed of 1
    sta fall_speed
```

At score 0 the speed is 1; at score 64 it becomes 2; at score 128 it becomes 3; at score 192 it becomes 4. The balls accelerate smoothly instead of in sudden jumps.

**Hint:** This ignores `score_hi`. For a version that handles scores above 255, shift `score_hi` bits into the result using `ROR` (Rotate Right through carry) on a temporary copy.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

The gameplay loop is now complete -- multiple balls, increasing difficulty, raster-locked timing. What's missing is the wrapper: a title screen to greet the player, a game over screen to show the final score, and the ability to play again. In the next chapter, we build the complete game with a state machine that ties it all together.
