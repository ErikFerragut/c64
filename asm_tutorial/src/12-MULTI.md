# Chapter 12: Multiple Fallers

Three balls fall simultaneously, each at a different starting position. One loop handles all of them using **indexed addressing** — the X register selects which ball to process from a data table. This chapter is a major refactor that replaces single-ball logic with table-driven loops.

## Building on Chapter 11

Before making changes, save a copy of your current file:

```bash
cp src/sound.asm src/multi.asm
```

Open `src/multi.asm`. This is the biggest set of changes so far — we're converting a single-ball game into a multi-ball game. The bucket movement and sound effects stay largely the same, but animation, collision, and data storage all change fundamentally.

### Constants and Variables

Add a constant for the number of balls and change the `caught` variable's meaning from a flag to a bitmask. Remove `ball_y` from the zero-page variables — ball positions will move to data tables:

```asm
sprite_x   = $02                ; Bucket X position, low byte
sprite_x_h = $03                ; Bucket X position, high byte
lives      = $04                ; Lives remaining
score_lo   = $05                ; Score low byte
score_hi   = $06                ; Score high byte
caught     = $07                ; Caught flags (bits 0-2 for balls 0-2)

NUM_BALLS  = 3                  ; Number of falling balls
```

The `caught` variable was a simple 0-or-1 flag in Chapter 11. Now each ball gets its own bit: bit 0 for ball 0, bit 1 for ball 1, bit 2 for ball 2. We'll use lookup tables to test and set these bits.

### Three Ball Sprites

Replace the single ball initialization with setup for sprites 1-3, all using the same ball shape but different colors:

```asm
    ; --- Initialize ball sprites (sprites 1-3) ---

    lda #34                     ; Ball data at $0880 (34 x 64)
    sta $07f9                   ; Sprite 1 pointer
    sta $07fa                   ; Sprite 2 pointer
    sta $07fb                   ; Sprite 3 pointer

    ; Set ball colors
    lda #$02                    ; Red
    sta $d028                   ; Sprite 1
    lda #$07                    ; Yellow
    sta $d029                   ; Sprite 2
    lda #$05                    ; Green
    sta $d02a                   ; Sprite 3

    ; Set initial positions (staggered)
    lda #50
    sta ball_y_tbl
    sta $d003                   ; Sprite 1 Y
    lda #120
    sta ball_y_tbl+1
    sta $d005                   ; Sprite 2 Y
    lda #190
    sta ball_y_tbl+2
    sta $d007                   ; Sprite 3 Y

    lda #80
    sta ball_x_tbl
    sta $d002                   ; Sprite 1 X
    lda #160
    sta ball_x_tbl+1
    sta $d004                   ; Sprite 2 X
    lda #120
    sta ball_x_tbl+2
    sta $d006                   ; Sprite 3 X
```

Each ball starts at a different height (50, 120, 190) so they're staggered on screen, and at different X positions (80, 160, 120) to spread them across the screen. The positions are stored both in the VIC-II registers (for display) and in our data tables (for game logic).

Enable all four sprites:

```asm
    lda $d015
    ora #%00001111              ; Sprites 0-3
    sta $d015
```

### Game Loop Changes

The game loop calls renamed subroutines — `animate_balls` and `check_collisions` (plural), and `update_bucket` instead of `update_sprites` since only the bucket needs position updates:

```asm
loop:
    jsr read_input
    jsr animate_balls
    jsr check_collisions
    jsr update_bucket
    jsr delay_loop
    jmp loop
```

### The Indexed Animation Loop

This is the core change. Replace `animate_ball` with a loop that processes all three balls using X as the index:

```asm
; --- Animate all balls using indexed loop ---

animate_balls:
    ldx #0                      ; Ball index (0, 1, 2)
    stx $10                     ; VIC register offset (0, 2, 4)

ab_loop:
    ; Increment Y position for this ball
    inc ball_y_tbl,x
    lda ball_y_tbl,x

    ; Write Y to VIC-II (sprite 1+x Y register)
    ldy $10                     ; VIC register offset
    sta $d003,y                 ; $D003, $D005, $D007

    ; Check if past bottom
    cmp #250
    bcc ab_next

    ; Check if this ball was caught
    lda caught
    and bit_mask,x              ; Test this ball's caught bit
    bne ab_do_reset

    ; Missed! Lose a life — save registers before subroutine calls
    txa
    pha                         ; Save ball index
    lda $10
    pha                         ; Save VIC offset

    dec lives
    jsr show_lives
    jsr sfx_miss

    pla
    sta $10                     ; Restore VIC offset
    pla
    tax                         ; Restore ball index

    lda lives
    bne ab_do_reset

    ; Game over
    jsr sfx_gameover
    lda #$02
    sta $d020
    lda #$00
    sta $d021
ab_halt:
    jmp ab_halt

ab_do_reset:
    ; Clear caught flag for this ball
    lda bit_mask,x
    eor #$ff                    ; Invert: create clear mask
    and caught                  ; Clear just this ball's bit
    sta caught

    ; Reset Y to top
    lda #50
    sta ball_y_tbl,x

    ldy $10
    sta $d003,y                 ; Update VIC Y register

    ; Random X position
    lda $d41b
    sta $d002,y                 ; Update VIC X register
    sta ball_x_tbl,x

    ; Clear this ball's MSB
    lda $d010
    and msb_clear_tbl,x
    sta $d010

ab_next:
    inx
    inc $10
    inc $10                     ; VIC offset += 2
    cpx #NUM_BALLS
    bne ab_loop
    rts
```

### Multi-Ball Collision Detection

Replace `check_collision` with a loop that checks each ball against the bucket:

```asm
; --- Check collisions for all balls ---

check_collisions:
    lda $d01e                   ; Read collision register (clears on read)
    sta $11                     ; Save collision state
    and #%00000001              ; Was sprite 0 involved?
    beq cc_done                 ; No collision with bucket

    ; Check each ball
    ldx #0
cc_loop:
    lda $11
    and bit_mask_spr,x          ; Check if sprite 1+x collided
    beq cc_next

    ; This ball hit the bucket — was it already caught?
    lda caught
    and bit_mask,x
    bne cc_next                 ; Already counted

    ; Mark as caught
    lda caught
    ora bit_mask,x
    sta caught

    ; Save X before subroutine calls
    txa
    pha

    ; Add 10 points
    lda score_lo
    clc
    adc #10
    sta score_lo
    lda score_hi
    adc #0
    sta score_hi
    jsr show_score
    jsr sfx_catch

    pla
    tax

cc_next:
    inx
    cpx #NUM_BALLS
    bne cc_loop

cc_done:
    rts
```

### Rename update_sprites

Rename `update_sprites` to `update_bucket` — only the bucket needs position updating since the balls are updated directly in `animate_balls`:

```asm
update_bucket:
    lda sprite_x
    sta $d000
    lda sprite_x_h
    and #%00000001
    beq ub_clear
    lda $d010
    ora #%00000001
    sta $d010
    rts
ub_clear:
    lda $d010
    and #%11111110
    sta $d010
    rts
```

### Simplify Sound Effects

Remove the PHA/PLA from `sfx_catch` and `sfx_miss` — the callers now handle register preservation themselves (they save X, not A):

```asm
sfx_catch:
    lda #$25
    sta $d400
    lda #$1c
    sta $d401
    lda #$09
    sta $d405
    lda #$00
    sta $d406
    lda #$11                    ; Triangle + gate
    sta $d404
    lda #$10                    ; Gate off
    sta $d404
    rts
```

### Shorter Delay

Reduce the delay loop since three balls create more action:

```asm
delay_loop:
    ldx #$04                    ; Shorter delay (more balls = more action)
```

### Data Tables

Add the data tables at the end of the file, after all subroutines:

```asm
; =============================================
; Data tables
; =============================================

; Bit masks for ball index 0-2
bit_mask:
    !byte %00000001, %00000010, %00000100

; Bit masks for sprite collision (sprites 1-3)
bit_mask_spr:
    !byte %00000010, %00000100, %00001000

; MSB clear masks (clear bits 1-3 for sprites 1-3)
msb_clear_tbl:
    !byte %11111101, %11111011, %11110111

; Ball Y positions
ball_y_tbl:
    !byte 50, 120, 190

; Ball X positions
ball_x_tbl:
    !byte 80, 160, 120
```

See `src/multi.asm` for the complete listing.

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

The `bit_mask` table maps ball index to its bit in the `caught` variable. Ball 0 uses bit 0, ball 1 uses bit 1, ball 2 uses bit 2. To test whether ball X was caught: `lda caught` / `and bit_mask,x`.

The `bit_mask_spr` table maps ball index to sprite collision bit. Ball 0 is sprite 1 (bit 1), ball 1 is sprite 2 (bit 2), ball 2 is sprite 3 (bit 3). Using a lookup table avoids complex bit-shifting calculations at runtime.

The `msb_clear_tbl` provides pre-inverted masks for clearing a ball's X MSB bit. When ball 0 resets, we need to clear bit 1 of `$D010` — the mask `%11111101` does this with a single AND.

### Two Index Spaces

A complication: the ball table uses indices 0, 1, 2 (stride 1), but VIC-II sprite registers use offsets 0, 2, 4 (stride 2, because each sprite has an X *and* Y register). We need two counters:

```asm
    ldx #0                      ; Ball index: 0, 1, 2
    stx $10                     ; VIC offset: 0, 2, 4

ab_loop:
    lda ball_y_tbl,x            ; Table uses X (stride 1)
    ldy $10
    sta $d003,y                 ; VIC uses Y (stride 2)

    ; ...
    inx                         ; Ball index += 1
    inc $10
    inc $10                     ; VIC offset += 2
```

X indexes into our data tables (which have one entry per ball), and `$10` (loaded into Y) indexes into VIC-II registers (which have two bytes per sprite). The 6502 supports both `lda addr,x` and `sta addr,y`, so we can use both index registers in the same loop.

Why `$10` instead of just using Y directly? Because Y would be destroyed by the inner delay loop and subroutine calls. Storing the VIC offset in a zero-page variable lets us save and restore it across calls.

### Preserving Registers Across Subroutine Calls

When `animate_balls` detects a miss, it calls `show_lives` and `sfx_miss`. These subroutines use X and Y internally, destroying our loop counters. We save and restore them using the stack:

```asm
    ; Save loop state before subroutine calls
    txa
    pha                         ; Push ball index (X -> A -> stack)
    lda $10
    pha                         ; Push VIC offset

    jsr show_lives
    jsr sfx_miss

    pla
    sta $10                     ; Restore VIC offset
    pla
    tax                         ; Restore ball index (stack -> A -> X)
```

The stack is LIFO (last in, first out), so we pull in reverse order. TXA/TAX transfer between X and A because PHA/PLA only work with the accumulator.

Notice that in Chapter 11, the sound effects themselves used PHA/PLA to save A. Now the *callers* handle register preservation instead. This is a design choice: since we need to save X (the loop index) anyway, and the callers know which registers matter, it's cleaner to let the caller decide what to preserve. The sound effects become simpler — just write to SID and return.

### Collision Detection for Multiple Sprites

The collision register `$D01E` sets bits for all sprites involved in any collision. Reading it clears it, so we save the value immediately:

```asm
check_collisions:
    lda $d01e                   ; Read (and clear) collision register
    sta $11                     ; Save — can't re-read!
```

We first check if sprite 0 (the bucket) was involved at all. If not, no ball could have been caught:

```asm
    and #%00000001              ; Sprite 0 involved?
    beq cc_done                 ; No: skip
```

Then we loop through each ball, checking if its sprite collided:

```asm
    ldx #0
cc_loop:
    lda $11
    and bit_mask_spr,x          ; Ball X's sprite collided?
    beq cc_next                 ; No: skip
    ; ... score points ...
cc_next:
    inx
    cpx #NUM_BALLS
    bne cc_loop
```

Multiple balls can be caught in the same frame — the loop handles each independently.

## Compiling

```bash
acme -f cbm -o src/multi.prg src/multi.asm
```

Your .prg file should be **947 bytes**.

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
