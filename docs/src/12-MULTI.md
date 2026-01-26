# Chapter 12: Multiple Fallers

Three balls fall simultaneously, each at a different starting position. One loop handles all of them using **indexed addressing** — the X register selects which ball to process from a data table.

## The Code

Create `src/multi.asm`:

The program extends the catch game to manage three falling balls using sprites 1-3. The full source is in `src/multi.asm`. Here's the key new pattern — the indexed animation loop:

```asm
animate_balls:
    ldx #0                      ; Ball index (0, 1, 2)
    stx $0a                     ; VIC register offset (0, 2, 4)

ab_loop:
    ; Increment Y position for this ball
    inc ball_y_tbl,x            ; ball_y_tbl[X] += 1
    lda ball_y_tbl,x

    ; Write to the correct VIC register
    ldy $0a
    sta $d003,y                 ; $D003, $D005, or $D007

    ; ... check bottom, reset, etc ...

ab_next:
    inx                         ; Next ball
    inc $0a
    inc $0a                     ; VIC offset += 2
    cpx #NUM_BALLS              ; Done all 3?
    bne ab_loop
    rts
```

## Code Explanation

### Indexed Addressing

Until now, we've accessed memory at fixed addresses: `lda $d000`, `sta sprite_x`. **Indexed addressing** adds a register value to the address at runtime:

```asm
    lda ball_y_tbl,x            ; Load from address (ball_y_tbl + X)
```

If `ball_y_tbl` is at address `$0C80` and X is 2, this loads from `$0C82`. By changing X, the same instruction accesses different entries in the table.

This is how the 6502 handles arrays. The table:

```asm
ball_y_tbl:
    !byte 50, 120, 190          ; Y positions for balls 0, 1, 2
```

With `ldx #0` / `lda ball_y_tbl,x` we get 50 (ball 0's Y). With `ldx #2` / `lda ball_y_tbl,x` we get 190 (ball 2's Y). One instruction, three different data items.

### Data Tables

All per-ball data is stored in tables — parallel arrays where index N holds the data for ball N:

```asm
ball_y_tbl:
    !byte 50, 120, 190          ; Y positions

ball_x_tbl:
    !byte 80, 160, 120          ; X positions

bit_mask:
    !byte %00000001, %00000010, %00000100   ; Caught flags

bit_mask_spr:
    !byte %00000010, %00000100, %00001000   ; Collision bits (sprites 1-3)

msb_clear_tbl:
    !byte %11111101, %11111011, %11110111   ; MSB clear masks
```

The `bit_mask_spr` table maps ball index to sprite collision bit. Ball 0 is sprite 1 (bit 1), ball 1 is sprite 2 (bit 2), ball 2 is sprite 3 (bit 3). Using a lookup table avoids complex bit-shifting calculations at runtime.

### Two Index Spaces

A complication: the ball table uses indices 0, 1, 2 (stride 1), but VIC-II sprite registers use offsets 0, 2, 4 (stride 2, because each sprite has an X *and* Y register). We need two counters:

```asm
    ldx #0                      ; Ball index: 0, 1, 2
    stx $0a                     ; VIC offset: 0, 2, 4

ab_loop:
    lda ball_y_tbl,x            ; Table uses X (stride 1)
    ldy $0a
    sta $d003,y                 ; VIC uses Y (stride 2)

    ; ...
    inx                         ; Ball index += 1
    inc $0a
    inc $0a                     ; VIC offset += 2
```

X indexes into our data tables (which have one entry per ball), and `$0a` (loaded into Y) indexes into VIC-II registers (which have two bytes per sprite). The 6502 supports both `lda addr,x` and `sta addr,y`, so we can use both index registers in the same loop.

### Preserving Registers Across Subroutine Calls

When `animate_balls` detects a miss, it calls `show_lives` and `sfx_miss`. These subroutines use X and Y internally, destroying our loop counters. We save and restore them using the stack:

```asm
    ; Save loop state before subroutine calls
    txa
    pha                         ; Push ball index (X → A → stack)
    lda $0a
    pha                         ; Push VIC offset

    jsr show_lives
    jsr sfx_miss

    pla
    sta $0a                     ; Restore VIC offset
    pla
    tax                         ; Restore ball index (stack → A → X)
```

The stack is LIFO (last in, first out), so we pull in reverse order. TXA/TAX transfer between X and A because PHA/PLA only work with the accumulator.

### Collision Detection for Multiple Sprites

The collision register `$D01E` sets bits for all sprites involved in any collision. We first check if sprite 0 (the bucket) collided at all, then check which ball(s) it hit:

```asm
check_collisions:
    lda $d01e                   ; Read (and clear) collision register
    sta $0b                     ; Save — can't re-read!

    and #%00000001              ; Sprite 0 involved?
    beq cc_done                 ; No: skip

    ldx #0                      ; Check each ball
cc_loop:
    lda $0b
    and bit_mask_spr,x          ; Ball X's sprite collided?
    beq cc_next                 ; No: skip
    ; ... score points ...
cc_next:
    inx
    cpx #NUM_BALLS
    bne cc_loop
```

We save the collision value to `$0b` immediately because `$D01E` clears on read. Then we check each ball's bit using the lookup table. Multiple balls can be caught in the same frame.

## Compiling

```bash
acme -f cbm -o src/multi.prg src/multi.asm
```

## Running

```bash
vice-jz.x64sc -autostart src/multi.prg
```

Three colored balls (red, yellow, green) fall simultaneously from staggered starting positions. Catch them for points, miss them to lose lives. The game is significantly more challenging with three targets.

## Exercises

### Exercise 1: Variable Fall Speeds

Give each ball its own speed by adding a `ball_speed_tbl` with values like `!byte 1, 2, 1`. In `animate_balls`, replace `inc ball_y_tbl,x` with `lda ball_y_tbl,x` / `clc` / `adc ball_speed_tbl,x` / `sta ball_y_tbl,x`. Now the yellow ball falls twice as fast as the others.

**Hint:** You'll also need to randomize speeds when a ball resets. Read `$D41B`, `and #%00000011` for 0-3, `clc` / `adc #1` for 1-4, then `sta ball_speed_tbl,x`.

### Exercise 2: Branch Out of Range

If you add enough code between a branch instruction and its target label, ACME will report "Target out of range." Branch instructions can only jump -128 to +127 bytes. Fix this by replacing the long branch with a short branch to a nearby JMP (a "trampoline"): `bcc nearby` / `jmp far_target` / `nearby:`.

**Hint:** Try adding 200 bytes of NOP instructions (`!fill 200, $ea`) between `ab_loop` and `ab_next` to trigger the error. Then restructure the branches.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

The game is getting hectic with three balls, but the difficulty stays constant. In the next chapter, we'll add level progression — the balls fall faster as your score increases — and replace the delay loop with proper raster timing for smooth, consistent speed.
