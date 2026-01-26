# Chapter 13: Difficulty Progression

The balls start slow and get faster as your score climbs. This chapter introduces raster timing for smooth animation and a level system that ramps up the challenge.

## The Code

Create `src/levels.asm`:

The program extends the multi-ball game with level progression and raster-synchronized timing. The full source is in `src/levels.asm`. Here are the key new sections:

### Raster Wait (Replaces Delay Loop)

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

### Level Check

```asm
check_level:
    lda score_lo
    cmp #150
    bcs cl_4                    ; Score >= 150: level 4
    cmp #100
    bcs cl_3                    ; Score >= 100: level 3
    cmp #50
    bcs cl_2                    ; Score >= 50:  level 2
    ; ... set fall_speed based on level ...
```

### Variable Fall Speed

```asm
    lda ball_y_tbl,x
    clc
    adc fall_speed              ; Add 1, 2, or 3 pixels per frame
    sta ball_y_tbl,x
```

## Code Explanation

### The Raster and Vertical Blank

The C64's display is drawn by an electron beam that scans across the screen line by line, 50 times per second (PAL) or 60 times per second (NTSC). The current scan line is stored in two places:

- `$D012` — raster line low 8 bits (0-255)
- Bit 7 of `$D011` — raster line bit 8

Together they give a 9-bit value (0-311 on PAL, 0-262 on NTSC). Lines 0-250 draw the visible screen. Lines 251+ are the **vertical blank** (vblank) — the beam is below the visible area, returning to the top.

Our `wait_vblank` subroutine waits for line 251:

```asm
wait_vblank:
    lda $d011
    and #%10000000              ; Check bit 8 of raster
    bne wait_vblank             ; If set, raster > 255 — wait
wv_low:
    lda $d012
    cmp #251
    bcc wv_low                  ; Less than 251? Keep waiting
    rts
```

First we wait for the raster to be in the 0-255 range (bit 8 clear), then we wait for it to reach 251. This ensures we detect the transition to vblank rather than catching it while it's already past.

### Why Raster Timing?

Until now we used a delay loop to control speed. Delay loops have a problem: they waste CPU time doing nothing, and their timing depends on how much work the game loop does. Adding more game logic makes the loop slower, changing the game speed.

Raster timing is different. The vblank happens at a fixed interval — every 20ms on PAL (50 Hz) or 16.7ms on NTSC (60 Hz). By waiting for vblank at the start of each loop iteration, we lock the game to a consistent frame rate regardless of how much work we do:

```asm
loop:
    jsr wait_vblank             ; Wait for next frame
    jsr read_input              ; ~50 cycles
    jsr animate_balls           ; ~300 cycles
    jsr check_collisions        ; ~200 cycles
    jsr update_bucket           ; ~50 cycles
    jsr check_level             ; ~30 cycles
    jmp loop                    ; Total: ~630 cycles
```

The game logic takes about 630 cycles. A PAL frame is ~19,656 cycles. That means 97% of the frame is spent waiting — the CPU has plenty of headroom. Even if we doubled the game logic, the speed would remain constant. The delay loop is gone completely.

### Level Progression

The `check_level` subroutine compares the score against thresholds and sets the fall speed:

| Score | Level | Fall Speed | Effect |
|-------|-------|------------|--------|
| 0-49 | 1 | 1 pixel/frame | Gentle start |
| 50-99 | 2 | 2 pixels/frame | Noticeably faster |
| 100-149 | 3 | 2 pixels/frame | Same speed, more pressure |
| 150+ | 4 | 3 pixels/frame | Frantic |

```asm
check_level:
    lda score_lo
    cmp #150
    bcs cl_4
    cmp #100
    bcs cl_3
    cmp #50
    bcs cl_2
    ; Level 1: speed 1
    lda #1
    sta fall_speed
    ; ...
```

We use CMP with BCS (Branch if Carry Set, meaning >=) to check thresholds in descending order. The first threshold that matches determines the level. When the level changes, we play an ascending tone to signal the increase.

The fall speed is applied in `animate_balls`:

```asm
    lda ball_y_tbl,x
    clc
    adc fall_speed              ; Move 1, 2, or 3 pixels
    sta ball_y_tbl,x
```

Instead of `inc` (always +1), we use `adc` with the speed variable. At level 4 with speed 3, each ball crosses the screen in about 67 frames — just over a second on PAL. That's fast enough to be challenging but still playable.

### Faster Bucket Movement

To keep the game fair at higher speeds, the bucket now moves 2 pixels per frame instead of 1:

```asm
ri_left:
    lda sprite_x
    sec
    sbc #2                      ; 2 pixels per frame
    sta sprite_x
```

This is a simple change — replace `#1` with `#2` — but it makes a meaningful difference in playability. The bucket can cross the screen twice as fast, which it needs to when balls are falling at speed 3.

## Compiling

```bash
acme -f cbm -o src/levels.prg src/levels.asm
```

## Running

```bash
vice-jz.x64sc -autostart src/levels.prg
```

The game starts at level 1 with slow-falling balls. As you catch more (every 50 points), the level increases and balls fall faster. The HUD shows the current level. Notice the smooth, consistent animation — the raster timing eliminates the jitter from delay loops.

## Exercises

### Exercise 1: Vblank Timing Test

Add a border color change at the start and end of the game logic (before and after the subroutine calls in the game loop). Set border to red before the work and back to light blue after. The red stripe shows exactly how much of each frame the CPU spends on game logic. As you add more code in future chapters, this stripe grows — when it reaches the bottom of the screen, you've run out of frame time.

**Hint:** `lda #$02` / `sta $d020` before the subroutine calls, and `lda #$0e` / `sta $d020` after. The width of the red band on screen shows CPU utilization.

### Exercise 2: Speed Curve

Instead of step-wise level transitions, make speed increase smoothly. Every 20 points, increment `fall_speed` by 1 (up to a max of 4). Use `lda score_lo` / `lsr` / `lsr` / `lsr` / `lsr` to divide score by 16, then add 1 for the minimum speed. Clamp at 4 with `cmp #5` / `bcc ok` / `lda #4`.

**Hint:** `lsr` four times divides by 16. Score 0-15 gives speed 1, 16-31 gives speed 2, 32-47 gives speed 3, 48+ gives speed 4. This gives a smoother difficulty curve.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

We have a complete game with challenge progression. The last chapter adds the finishing touches — a title screen, game over screen with high score, and the ability to replay. It's the full Bucket Brigade experience.
