# Chapter 9: Collision Detection

The ball is no longer harmless — collide with it and you lose a life. This chapter introduces sprite collision detection, subroutines, and game over state.

## The Code

Create `src/dodge.asm`:

```asm
; dodge.asm - Dodge falling objects
; Collision detection, subroutines, and game over

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
sprite_x_h = $03                ; Bucket X position, high byte
ball_y     = $04                ; Ball Y position
lives      = $05                ; Lives remaining
score      = $06                ; Score (balls dodged)

    ; --- Initialize game state ---

    lda #3
    sta lives
    lda #0
    sta score

    ; --- Initialize bucket sprite (sprite 0) ---

    lda #172
    sta sprite_x
    lda #0
    sta sprite_x_h

    lda #38                     ; Bucket data at $0980 (38 x 64)
    sta $07f8

    lda #224                    ; Near bottom
    sta $d001

    lda #$01                    ; White
    sta $d027

    ; --- Initialize ball sprite (sprite 1) ---

    lda #39                     ; Ball data at $09C0 (39 x 64)
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
    jsr check_collision         ; Test for hits
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

    ; Ball passed bucket without collision — score!
    inc score

    ; Reset ball to top with random X
    lda #50
    sta ball_y
    sta $d003

    lda $d41b                   ; Random X from SID
    sta $d002

    lda $d010
    and #%11111101              ; Clear ball MSB
    sta $d010

ab_done:
    rts

; --- Check sprite collision register ---

check_collision:
    lda $d01e                   ; Read collision register (clears on read)
    and #%00000011              ; Sprites 0 and 1 both involved?
    cmp #%00000011
    bne cc_done                 ; No collision

    ; Collision! Lose a life
    dec lives
    jsr show_lives

    ; Flash border to show hit
    lda #$02                    ; Red
    sta $d020
    ldx #$20
cc_flash:
    ldy #$ff
cc_flash_inner:
    dey
    bne cc_flash_inner
    dex
    bne cc_flash

    lda #$0e                    ; Light blue (default)
    sta $d020

    ; Reset ball position
    lda #50
    sta ball_y
    sta $d003

    lda $d41b
    sta $d002

    lda $d010
    and #%11111101
    sta $d010

    ; Check for game over
    lda lives
    bne cc_done                 ; Still alive

    ; Game over
    lda #$02                    ; Red border
    sta $d020
    lda #$00                    ; Black background
    sta $d021

game_over:
    jmp game_over               ; Halt

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

; --- Display lives digit ---

show_lives:
    lda lives
    clc
    adc #$30                    ; Convert number to screen code for digit
    sta $0400                   ; Screen position: row 0, column 0
    lda #$01                    ; White
    sta $d800                   ; Color RAM for that position
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

; --- Sprite Data ---
* = $0980                       ; Bucket sprite (pointer = 38)

bucket_data:
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $ff,$ff,$ff
    !byte $ff,$ff,$ff
    !byte $7f,$ff,$fe
    !byte $7f,$ff,$fe
    !byte $3f,$ff,$fc
    !byte $3f,$ff,$fc
    !byte $1f,$ff,$f8
    !byte $1f,$ff,$f8
    !byte $0f,$ff,$f0

* = $09c0                       ; Ball sprite (pointer = 39)

ball_data:
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$3c,$00
    !byte $00,$7e,$00
    !byte $00,$ff,$00
    !byte $00,$ff,$00
    !byte $00,$ff,$00
    !byte $00,$ff,$00
    !byte $00,$7e,$00
    !byte $00,$3c,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
```

The code is longer now, but each section is clean because we've broken it into subroutines.

## Code Explanation

### JSR and RTS — Subroutines

Until now, our programs have been one continuous flow with `jmp` to move around. As programs grow, this gets unmanageable. **JSR** (Jump to Subroutine) and **RTS** (Return from Subroutine) let us organize code into reusable blocks:

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
- Never jump *out* of a subroutine without returning — you'll corrupt the stack
- Subroutines can call other subroutines (nested JSR), up to 128 levels deep (stack is 256 bytes, 2 bytes per call)

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

There's a critical detail: **`$D01E` clears itself when read**. The VIC-II resets all bits to 0 after you read the register. This means:

- You only get one chance to read each collision
- If you read `$D01E` twice, the second read returns 0 even if sprites are still overlapping
- Save the value to a variable if you need to check it multiple times

We AND with `%00000011` to isolate just sprites 0 and 1, then CMP with `%00000011` to verify *both* bits are set. If only one bit is set, that sprite collided with something else (not relevant to us with only two sprites, but good practice).

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

The C64's screen memory starts at `$0400` — each byte represents one character on the 40x25 screen. The digits 0-9 have screen codes `$30`-`$39`, so adding `$30` to a number gives the correct character.

**Color RAM** at `$D800` mirrors the screen layout. Each byte sets the color of the corresponding character. Without setting the color, the character would be invisible (same color as the background).

### Game Over State

When lives reaches zero, we change the screen colors and halt:

```asm
    lda lives
    bne cc_done                 ; Still alive? Continue

    lda #$02                    ; Red border
    sta $d020
    lda #$00                    ; Black background
    sta $d021
game_over:
    jmp game_over               ; Infinite loop — halt
```

This is the simplest possible game over: an infinite loop that freezes the program. The red border and black background signal to the player that the game is over. In [Chapter 14](14-GAME.md), we'll replace this with a proper game over screen.

## Compiling

```bash
acme -f cbm -o src/dodge.prg src/dodge.asm
```

## Running

```bash
vice-jz.x64sc -autostart src/dodge.prg
```

Dodge the falling ball! The border flashes red when you're hit, and the lives counter in the top-left decreases. When lives reach 0, the screen turns red/black and the game freezes. The score increments each time a ball passes the bottom without hitting you.

## Exercises

### Exercise 1: Clear-on-Read Behavior

Add a second `lda $d01e` immediately after the first one and store the result in a different zero page location. Add a breakpoint in the VICE monitor (`break check_collision` address) and watch both values. You'll see the first read returns the collision bits, and the second read always returns 0. This clear-on-read behavior is why we only read `$D01E` once per frame.

**Hint:** After `lda $d01e` / `sta $temp1`, add `lda $d01e` / `sta $temp2`. Set a breakpoint with VICE's monitor (Alt+M, then `break` command) and inspect both temp locations.

### Exercise 2: Sprite Expansion

Make the ball twice as large using the VIC-II's sprite expansion registers. Write `%00000010` to `$D017` (double height for sprite 1) and `$D01D` (double width for sprite 1). Notice how the collision area also doubles — the ball is much harder to dodge.

**Hint:** Add these two lines during initialization: `lda #%00000010` / `sta $d017` / `sta $d01d`. Only bit 1 is set because we're expanding sprite 1 only.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

We can dodge the ball, but our game punishes contact. In the next chapter, we'll flip the mechanic — catching the ball scores points, and *missing* it costs a life. We'll add a proper score display and a HUD.
