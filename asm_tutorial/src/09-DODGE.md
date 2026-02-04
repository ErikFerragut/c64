# Chapter 9: Collision Detection

The ball and bucket can now interact. This chapter adds sprite collision detection, reorganizes the code into subroutines with JSR/RTS, and tracks lives with a game over state.

## Building on Chapter 8

Before making changes, save a copy of your current file:

```bash
cp src/faller.asm src/dodge.asm
```

Open `src/dodge.asm`. The changes this time are substantial — we are restructuring the entire game loop into subroutines and adding collision logic. Here is what's new:

### New Variables

Add `lives` and `caught` to the zero page variables:

```asm
lives      = $04                ; Lives remaining
caught     = $07                ; 1 = ball was caught this pass
```

We place `lives` at `$04` (next to the bucket position at `$02`-`$03`) and `caught` at `$07`, leaving room for score variables in a later chapter.

### Initialization

Initialize lives to 3 and the caught flag to 0:

```asm
    lda #3
    sta lives
    lda #0
    sta caught
```

After all the sprite setup, display the starting lives and enter the game loop:

```asm
    jsr show_lives

loop:
    jsr read_input
    jsr animate_ball
    jsr check_collision
    jsr update_sprites
    jsr delay_loop
    jmp loop
```

This is a major change from Chapter 8. The inline game loop — where input reading, ball animation, sprite updates, and delay code were all woven together with JMP instructions — is now split into five subroutines, each called with JSR and ending with RTS. The main loop reads like a table of contents.

### Subroutine Refactor

Every section of the old game loop becomes its own subroutine. The `read_input` subroutine handles joystick movement and returns with RTS. The `animate_ball` subroutine moves the ball down and handles the reset-at-bottom logic. The `update_sprites` subroutine writes the bucket position to the VIC-II. The `delay_loop` subroutine provides speed control. Each one ends with `rts` instead of falling through to the next section.

### Collision Detection

The new `check_collision` subroutine reads the VIC-II's sprite collision register:

```asm
check_collision:
    lda $d01e                   ; Read collision register (clears on read)
    and #%00000011              ; Sprites 0 and 1 both involved?
    cmp #%00000011
    bne cc_done                 ; No collision

    lda caught                  ; Already caught this pass?
    bne cc_done

    lda #1
    sta caught                  ; Mark as caught

    ; Flash border green briefly
    lda #$05
    sta $d020
```

When a collision is detected, the border flashes green — catching the ball is a good thing. The `caught` flag prevents scoring multiple times while the sprites overlap.

### Ball Miss and Lives

In `animate_ball`, when the ball reaches the bottom of the screen without being caught, the player loses a life:

```asm
    ; Ball reached bottom — was it caught?
    lda caught
    bne ab_reset                ; Yes: just reset

    ; Missed! Lose a life
    dec lives
    jsr show_lives

    ; Flash border red
    lda #$02
    sta $d020
```

The border flashes red on a miss. If lives reaches zero, the game enters a permanent halt:

```asm
    lda lives
    bne ab_reset

    lda #$02
    sta $d020
    lda #$00
    sta $d021
game_over:
    jmp game_over
```

### Displaying Lives

The `show_lives` subroutine writes the lives count to the top-left corner of the screen:

```asm
show_lives:
    lda lives
    clc
    adc #$30                    ; Convert number to screen code
    sta $0400                   ; Screen position: row 0, col 0
    lda #$01                    ; White
    sta $d800                   ; Color RAM
    rts
```

Adding `$30` converts a number (0-9) to the corresponding screen code for that digit.

## The Complete Code

Here is the full listing:

```asm
; dodge.asm - Catch the falling ball
; Collision detection, subroutines, and game over

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2304
!byte $0b, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2304"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

; --- Sprite Data ---
* = $0840                       ; Bucket sprite (pointer = 33)

bucket_data:
    !fill 36, 0                 ; Rows 0-11: empty
    ; Row 12-13: rim (full width)
    !byte %11111111,%11111111,%11111111
    !byte %11111111,%11111111,%11111111
    ; Row 14-15: body tapers
    !byte %01111111,%11111111,%11111110
    !byte %01111111,%11111111,%11111110
    ; Row 16-17
    !byte %00111111,%11111111,%11111100
    !byte %00111111,%11111111,%11111100
    ; Row 18-19
    !byte %00011111,%11111111,%11111000
    !byte %00011111,%11111111,%11111000
    ; Row 20: bottom
    !byte %00001111,%11111111,%11110000

* = $0880                       ; Ball sprite (pointer = 34)

ball_data:
    !fill 21, 0                 ; Rows 0-6: empty
    ; Row 7: top of ball
    !byte %00000000,%00111100,%00000000
    ; Row 8
    !byte %00000000,%01111110,%00000000
    ; Rows 9-12: middle
    !byte %00000000,%11111111,%00000000
    !byte %00000000,%11111111,%00000000
    !byte %00000000,%11111111,%00000000
    !byte %00000000,%11111111,%00000000
    ; Row 13
    !byte %00000000,%01111110,%00000000
    ; Row 14: bottom of ball
    !byte %00000000,%00111100,%00000000
    ; Rows 15-20: empty
    !fill 18, 0

; --- Code ---
* = $0900                       ; Code start (2304 decimal)

sprite_x   = $02                ; Bucket X position, low byte
sprite_x_h = $03                ; Bucket X position, high byte
lives      = $04                ; Lives remaining
caught     = $07                ; 1 = ball was caught this pass
ball_y     = $10                ; Ball Y position

    ; --- Initialize game state ---

    lda #3
    sta lives
    lda #0
    sta caught

    ; --- Initialize bucket sprite (sprite 0) ---

    lda #172
    sta sprite_x
    lda #0
    sta sprite_x_h

    lda #33                     ; Bucket data at $0840 (33 x 64)
    sta $07f8

    lda #224                    ; Near bottom
    sta $d001

    lda #$01                    ; White
    sta $d027

    ; --- Initialize ball sprite (sprite 1) ---

    lda #34                     ; Ball data at $0880 (34 x 64)
    sta $07f9

    lda #50
    sta ball_y
    sta $d003

    lda #172
    sta $d002

    lda #$02                    ; Red
    sta $d028

    ; --- Enable sprites ---

    lda $d015
    ora #%00000011
    sta $d015

    ; --- Set up SID voice 3 for random numbers ---

    lda #$ff
    sta $d40e
    sta $d40f
    lda #$80
    sta $d412

    ; --- Display initial lives ---

    jsr show_lives

    ; --- Game loop ---

loop:
    jsr read_input              ; Handle joystick
    jsr animate_ball            ; Move ball down
    jsr check_collision         ; Test for catch
    jsr update_sprites          ; Write to VIC-II
    jsr delay_loop              ; Speed control
    jmp loop

; =============================================
; Subroutines
; =============================================

; --- Read joystick and move bucket ---

read_input:
    lda $dc00
    and #%00000100              ; Left?
    beq ri_left

    lda $dc00
    and #%00001000              ; Right?
    beq ri_right

    rts                         ; No input

ri_left:
    lda sprite_x
    sec
    sbc #1
    sta sprite_x
    lda sprite_x_h
    sbc #0
    sta sprite_x_h
    rts

ri_right:
    lda sprite_x
    clc
    adc #1
    sta sprite_x
    lda sprite_x_h
    adc #0
    sta sprite_x_h
    rts

; --- Animate ball: move down, reset at bottom ---

animate_ball:
    inc ball_y
    lda ball_y
    sta $d003

    cmp #250                    ; Past bottom?
    bcc ab_done                 ; No: return

    ; Ball reached bottom — was it caught?
    lda caught
    bne ab_reset                ; Yes: just reset

    ; Missed! Lose a life
    dec lives
    jsr show_lives

    ; Flash border red
    lda #$02
    sta $d020
    ldx #$18
ab_flash:
    ldy #$ff
ab_fi:
    dey
    bne ab_fi
    dex
    bne ab_flash
    lda #$0e
    sta $d020

    ; Check game over
    lda lives
    bne ab_reset

    lda #$02
    sta $d020
    lda #$00
    sta $d021
game_over:
    jmp game_over

ab_reset:
    ; Reset ball to top with random X
    lda #50
    sta ball_y
    sta $d003
    lda $d41b
    sta $d002
    lda $d010
    and #%11111101              ; Clear ball MSB
    sta $d010
    lda #0
    sta caught                  ; Clear caught flag

ab_done:
    rts

; --- Check sprite collision ---

check_collision:
    lda $d01e                   ; Read collision register (clears on read)
    and #%00000011              ; Sprites 0 and 1 both involved?
    cmp #%00000011
    bne cc_done                 ; No collision

    lda caught                  ; Already caught this pass?
    bne cc_done

    lda #1
    sta caught                  ; Mark as caught

    ; Flash border green briefly
    lda #$05
    sta $d020
    ldx #$08
cc_flash:
    ldy #$ff
cc_fi:
    dey
    bne cc_fi
    dex
    bne cc_flash
    lda #$0e
    sta $d020

cc_done:
    rts

; --- Update bucket position in VIC-II ---

update_sprites:
    lda sprite_x
    sta $d000

    lda sprite_x_h
    and #%00000001
    beq us_clear

    lda $d010
    ora #%00000001
    sta $d010
    rts

us_clear:
    lda $d010
    and #%11111110
    sta $d010
    rts

; --- Display lives at top-left of screen ---

show_lives:
    lda lives
    clc
    adc #$30                    ; Convert number to screen code
    sta $0400                   ; Screen position: row 0, col 0
    lda #$01                    ; White
    sta $d800                   ; Color RAM
    rts

; --- Delay loop ---

delay_loop:
    ldx #$06
dl_outer:
    ldy #$ff
dl_inner:
    dey
    bne dl_inner
    dex
    bne dl_outer
    rts
```

## Code Explanation

### JSR and RTS -- Subroutines

Until now, our programs have been one continuous flow with JMP to move around. As the code grows, this becomes difficult to follow. **JSR** (Jump to Subroutine) and **RTS** (Return from Subroutine) let us organize code into named blocks:

```asm
loop:
    jsr read_input              ; Call subroutine
    jsr animate_ball
    jsr check_collision
    jsr update_sprites
    jsr delay_loop
    jmp loop
```

When the CPU executes `jsr read_input`, it:

1. Pushes the **return address** onto the stack (the address of the next instruction minus 1)
2. Jumps to `read_input`

When `read_input` finishes with `rts`, the CPU:

1. Pulls the return address from the stack
2. Jumps back to the instruction after the JSR

The **stack** is a 256-byte region at `$0100`-`$01FF` that the CPU uses as a last-in-first-out (LIFO) buffer. Each JSR pushes 2 bytes (the return address), and each RTS pops them back. The stack pointer register (S) tracks the current position.

This is the same pattern functions use in every programming language. The key rules:

- Every subroutine must end with `rts`
- Never jump *out* of a subroutine without returning -- you'll corrupt the stack
- Subroutines can call other subroutines (nested JSR), up to 128 levels deep (the stack is 256 bytes, 2 bytes per call)

Notice that `animate_ball` calls `jsr show_lives` from within itself. This nesting works because each JSR pushes its own return address, and each RTS pops the correct one.

### The Collision Register

The VIC-II chip has a built-in sprite-to-sprite collision detector. Register `$D01E` tells us which sprites are overlapping:

```asm
check_collision:
    lda $d01e                   ; Read collision register
    and #%00000011              ; Test bits 0 and 1
    cmp #%00000011              ; Both sprites involved?
    bne cc_done                 ; No: skip
```

Each bit in `$D01E` corresponds to a sprite. When two sprites' visible pixels overlap, both sprites' bits are set. For a collision between sprite 0 (bucket) and sprite 1 (ball), bits 0 and 1 are both set: `%00000011`.

There is a critical detail: **`$D01E` clears itself when read**. The VIC-II resets all bits to 0 after you read the register. This means:

- You only get one chance to read each collision event
- If you read `$D01E` twice, the second read returns 0 even if sprites are still overlapping
- Save the value to a variable if you need to check it multiple times

We AND with `%00000011` to isolate just sprites 0 and 1, then CMP with `%00000011` to verify *both* bits are set. If only one bit is set, that sprite collided with something else (not relevant to us with only two sprites, but good practice for when we add more).

### The Caught Flag

A subtle problem arises with collision detection: the ball overlaps the bucket for multiple frames as it falls through. Without protection, we would register a catch every frame of overlap. [QUESTION: If after reading the value it is zero'd out, what would cause it to be reset? Does it happen at rasterization?] The `caught` flag prevents this:

[QUESTION: This is kind of confusing because the operation of setting caught to 1 is idempotent. There's no need to avoid it happening again. This would make more sense if we were increasing score here. But I do see how this teaches debouncing in general.]

```asm
    lda caught                  ; Already caught this pass?
    bne cc_done                 ; Yes: don't double-count

    lda #1
    sta caught                  ; Mark as caught
```

When the ball resets to the top (whether caught or missed), we clear the flag:

```asm
    lda #0
    sta caught                  ; Ready for next ball
```

This is the **one-shot pattern** -- a flag that prevents repeated triggers until a reset event occurs. It appears constantly in game programming: debouncing button presses, preventing repeated pickups, ensuring an animation plays only once. The key is that *one* piece of code sets the flag and a *different* piece of code clears it, creating a clean one-trigger-per-event cycle.

### Screen Memory for Display

We write the lives count directly to screen memory:

```asm
show_lives:
    lda lives                   ; Lives count (0-9)
    clc
    adc #$30                    ; Add $30: converts 0→$30, 1→$31, etc.
    sta $0400                   ; Screen memory, row 0, column 0
    lda #$01                    ; White
    sta $d800                   ; Color RAM
    rts
```
[QUESTION: In this particular program, we could set d800 to 01 in the initialization. It never changes after that.]

The C64's screen memory starts at `$0400` -- each byte represents one character on the 40x25 screen. The digits 0-9 have screen codes `$30`-`$39`, so adding `$30` to a number gives the correct character. This is the same offset as ASCII, which is no coincidence -- Commodore borrowed this convention.

**Color RAM** at `$D800` mirrors the screen layout. Each byte sets the color of the corresponding character. Without setting the color, the character would appear in whatever color was previously there (often light blue, the default). We set it to white (`$01`) so the digit is clearly visible.

### Game Over State

When lives reaches zero, we change the screen colors and halt:

```asm
    lda lives
    bne ab_reset                ; Still alive? Continue

    lda #$02                    ; Red border
    sta $d020
    lda #$00                    ; Black background
    sta $d021
game_over:
    jmp game_over               ; Infinite loop — halt
```

This is the simplest possible game over: an infinite loop that freezes the program. The red border and black background signal to the player that the game is done. In [Chapter 14](14-GAME.md), we will replace this with a proper game over screen and restart option.

## Compiling

```bash
acme -f cbm -o src/dodge.prg src/dodge.asm
```

Your .prg file should be **570 bytes**.

## Running

```bash
vice-jz.x64sc -autostart src/dodge.prg
```

Move the bucket to catch the falling ball. The border flashes green when you make a catch, and the caught flag prevents the collision from being counted more than once per ball. If the ball reaches the bottom without being caught, the border flashes red and you lose a life. The lives digit in the top-left corner updates each time. When lives reach 0, the screen turns red and black and the game halts.

## Exercises

### Exercise 1: Clear-on-Read Behavior

Add a second `lda $d01e` immediately after the first one and store both results in different zero page locations. Set a breakpoint in the VICE monitor at the `check_collision` address and watch both values. You will see that the first read returns the collision bits, and the second read always returns 0 -- even if the sprites are still overlapping. This clear-on-read behavior is why we only read `$D01E` once per frame.

**Hint:** After `lda $d01e` / `sta $temp1`, add `lda $d01e` / `sta $temp2`. Set a breakpoint with VICE's monitor (Alt+M, then `break` command) and inspect both temp locations.

### Exercise 2: Sprite Expansion

Make the ball twice as large using the VIC-II's sprite expansion registers. Write `%00000010` to `$D017` (double height for sprite 1) and `$D01D` (double width for sprite 1). The ball becomes much easier to catch -- and the collision area doubles with it.

**Hint:** Add these two lines during initialization: `lda #%00000010` / `sta $d017` / `sta $d01d`. Only bit 1 is set because we are expanding sprite 1 only.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

We can catch the ball, but there is no score. In the next chapter, we will add 16-bit scoring, a full HUD with "SCORE:" and "LIVES:" labels, and convert our binary score to decimal digits for display.
