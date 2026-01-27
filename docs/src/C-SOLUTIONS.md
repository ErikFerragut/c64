# Appendix C: Exercise Solutions

## Chapter 2: Hello World

### Exercise 1: Red Screen

Change `lda #$00` to `lda #$02`:

```asm
    lda #$02                    ; Load red (2) into accumulator
    sta $d020                   ; Store to border color register
    sta $d021                   ; Store to background color
    rts
```

### Exercise 2: Two Colors

```asm
    lda #$02                    ; Load red (2)
    sta $d020                   ; Border = red
    lda #$00                    ; Load black (0)
    sta $d021                   ; Background = black
    rts
```

Note that we must load a new value into the accumulator before storing to `$d021`, since the accumulator still held 2 (red) from the first `lda`.

## Chapter 3: Keyboard Input

### Exercise 1: All Eight Colors

Add these blocks between `not_three:` and the "Q" check:

```asm
not_three:
    cmp #$34                    ; "4"?
    bne not_four
    lda #$01                    ; White
    sta $d020
    jmp loop

not_four:
    cmp #$35                    ; "5"?
    bne not_five
    lda #$03                    ; Cyan
    sta $d020
    jmp loop

not_five:
    cmp #$36                    ; "6"?
    bne not_six
    lda #$04                    ; Purple
    sta $d020
    jmp loop

not_six:
    cmp #$37                    ; "7"?
    bne not_seven
    lda #$05                    ; Green
    sta $d020
    jmp loop

not_seven:
    cmp #$38                    ; "8"?
    bne not_eight
    lda #$07                    ; Yellow
    sta $d020
    jmp loop

not_eight:
    cmp #$51                    ; "Q"?
    beq done
    jmp loop
```

The pattern is identical for each key — only the PETSCII code and color value change.

### Exercise 2: Border and Background

Each handler needs two LDA/STA pairs. Here's one example:

```asm
    cmp #$31                    ; "1"?
    bne not_one
    lda #$00                    ; Black
    sta $d020                   ; Border = black
    lda #$01                    ; White
    sta $d021                   ; Background = white
    jmp loop

not_one:
    cmp #$32                    ; "2"?
    bne not_two
    lda #$02                    ; Red
    sta $d020                   ; Border = red
    lda #$00                    ; Black
    sta $d021                   ; Background = black
    jmp loop
```

Pick any color combinations you like. Notice that we need a fresh `lda` before each `sta $d021` because the previous `sta $d020` didn't change A — but the *first* `lda` loaded the border color, not the background color.

### Exercise 3 (Challenge): Shorter Code

```asm
loop:
    jsr $ffe4               ; Call GETIN: read key into A
    beq loop                ; No key pressed? Keep waiting

    cmp #$51                ; Was it "Q"?
    beq done                ;   Yes: quit

    cmp #$30                ; Was it < $30?
    bcc loop                ; Yes: out of range, ignore

    cmp #$40                ; Was it >= $40?
    bcs loop                ; Yes: out of range, ignore

    sta $d020               ; Store directly to border color
    jmp loop                ; Back to waiting

done:
    rts                     ; Return to BASIC
```

The Q check must come first — if it came after the range check, "Q" ($51) would be rejected by the `cmp #$40` / `bcs` before we ever test for it.

The trick is that PETSCII digits `$30`-`$39` map to the values 0-9 in their low nibble, and VIC-II ignores the high nibble of color values (it only uses bits 0-3). So storing `$32` into `$D020` has the same effect as storing `$02` — both set the border to red. The "extra" keys `$3A`-`$3F` (`:`, `;`, `<`, `=`, `>`, `?` in PETSCII) map to colors 10-15, giving access to all 16 colors with zero branching per key.

## Chapter 4: Joystick Control

### Exercise 1: EOR Toggle

Replace the `fire:` handler with:

```asm
fire:
    lda $d021                   ; Read current background color
    eor #$06                    ; Flip bits for value 6
    sta $d021                   ; Store new background
    lda #$05                    ; Green
    sta $d020                   ; Set border
    jmp loop
```

**EOR** (Exclusive OR) flips bits where the mask has a 1:

| A bit | Mask bit | Result |
|-------|----------|--------|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

With mask `#$06` (`%00000110`):
- Background starts at Blue (6 = `%00000110`): `%00000110 EOR %00000110 = %00000000` → Black (0)
- Next fire, background is Black (0 = `%00000000`): `%00000000 EOR %00000110 = %00000110` → Blue (6)

The background toggles between Blue and Black on each fire press. EOR is the standard trick for toggling bits — a single instruction with no branching.

### Exercise 2: Second Player

Add these checks after the port 2 fire test (before `jmp loop`):

```asm
    ; --- Port 1 checks (after port 2 fire check) ---

    lda $dc01                   ; Read joystick port 1
    and #%00000001              ; Test bit 0 (up)
    beq p1_up

    lda $dc01
    and #%00000010              ; Test bit 1 (down)
    beq p1_down

    lda $dc01
    and #%00000100              ; Test bit 2 (left)
    beq p1_left

    lda $dc01
    and #%00001000              ; Test bit 3 (right)
    beq p1_right

    lda $dc01
    and #%00010000              ; Test bit 4 (fire)
    beq p1_fire

    jmp loop
```

And the corresponding direction blocks:

```asm
p1_up:
    lda #$01                    ; White
    sta $d021                   ; Set background
    jmp loop

p1_down:
    lda #$00                    ; Black
    sta $d021
    jmp loop

p1_left:
    lda #$02                    ; Red
    sta $d021
    jmp loop

p1_right:
    lda #$03                    ; Cyan
    sta $d021
    jmp loop

p1_fire:
    lda #$05                    ; Green
    sta $d020                   ; Set border
    sta $d021                   ; Set background
    jmp loop
```

The code is identical to the port 2 version — only the read address (`$dc01` instead of `$dc00`) and the write target (`$d021` instead of `$d020`) change. Both ports use the same bit-to-direction mapping.

## Chapter 5: Loops and Timing

### Exercise 1: Speed Control

Add a speed variable and joystick up/down checks before the fire test:

```asm
* = $0810

speed:  !byte $20               ; Initial speed (32)

loop:
    lda $dc00                   ; Read joystick port 2
    and #%00000001              ; Test bit 0 (up)
    bne not_up
    dec speed                   ; Faster (fewer outer iterations)
    jmp loop
not_up:

    lda $dc00
    and #%00000010              ; Test bit 1 (down)
    bne not_down
    inc speed                   ; Slower (more outer iterations)
    jmp loop
not_down:

    lda $dc00
    and #%00010000              ; Test fire (bit 4)
    bne loop                    ; Not pressed -> keep waiting

    inc $d020                   ; Next border color

    ldx speed                   ; Load speed from variable
delay_outer:
    ldy #$ff
delay_inner:
    dey
    bne delay_inner
    dex
    bne delay_outer

    jmp loop
```

The key change is `ldx speed` instead of `ldx #$20`. The `#` means "immediate" (use this exact value). Without `#`, the CPU reads the value *from memory* at the label `speed`. INC and DEC modify that memory location directly, so pushing up/down changes the delay length while the program runs.

Note that `speed` is defined with `!byte $20` — it's a memory location initialized to 32. INC/DEC work on it just like they work on `$d020`.

One gotcha: INC and DEC wrap around silently. If speed reaches 0 and you DEC again, it wraps to 255 — an extremely long delay. If it reaches 255 and you INC, it wraps to 0 — and `ldx #0` followed by `dex`/`bne` will loop 256 times instead of zero. Clamping the value (e.g., don't DEC below 1, don't INC above some maximum) would make this more robust.

### Exercise 2: Two-Color Strobe

Replace `inc $d020` with an EOR toggle:

```asm
    lda $d020                   ; Read current border color
    eor #$01                    ; Flip bit 0
    sta $d020                   ; Store new color
```

With EOR mask `#$01`:
- Black (0 = `%00000000`): `%00000000 EOR %00000001 = %00000001` -> White (1)
- White (1 = `%00000001`): `%00000001 EOR %00000001 = %00000000` -> Black (0)

The border snaps between black and white instead of cycling through all 16 colors. To toggle between different colors, choose an EOR mask that flips the right bits — for example, `eor #$06` toggles between black (0) and blue (6), just like Chapter 4's exercise.

## Chapter 6: Your First Sprite

### Exercise 1: Change the Color

Change `lda #$01` to your chosen color and optionally set border/background:

```asm
    ; Set sprite color
    lda #$05                    ; Green
    sta $d027                   ; Sprite 0 color

    ; Optional: set a color scheme
    lda #$00                    ; Black
    sta $d020                   ; Border = black
    sta $d021                   ; Background = black
```

The sprite color register `$d027` takes the same 0-15 color values as the border and background registers. With a black background and a green sprite, the bucket looks like a classic monochrome terminal.

### Exercise 2: Slide in From the Left

Replace the X positioning and the `done` loop with an animation loop:

```asm
    ; Start sprite at left edge
    lda #0                      ; X position = 0
    sta $d000                   ; Sprite 0 X

slide:
    inc $d000                   ; Move one pixel right

    ; Delay loop (control speed)
    ldx #$10                    ; Outer: 16 iterations
slide_outer:
    ldy #$ff                    ; Inner: 255 iterations
slide_inner:
    dey
    bne slide_inner
    dex
    bne slide_outer

    ; Check if we've reached center
    lda $d000                   ; Read current X position
    cmp #172                    ; Reached center?
    bne slide                   ; No: keep sliding

done:
    jmp done                    ; Yes: stop here
```

This combines three patterns: `inc` on a VIC-II register to move the sprite, a nested delay loop from Chapter 5 to control the animation speed, and `cmp`/`bne` from Chapter 3 to stop at the target position. The sprite glides from the left edge to center, one pixel at a time.

## Chapter 7: Moving Sprites

### Exercise 1: Boundary Checking

Add boundary checks after the subtraction/addition, before storing the result. If the new position is out of range, skip the store and jump directly to `update`:

```asm
move_left:
    lda sprite_x                ; Load X low byte
    sec                         ; Set carry
    sbc #1                      ; Subtract 1
    tax                         ; Save low byte in X
    lda sprite_x_h              ; Load X high byte
    sbc #0                      ; Subtract borrow

    ; Check left boundary (X < 24)
    bne left_ok                 ; High byte = 1 means X >= 256, always OK
    cpx #24                     ; Compare low byte against 24
    bcc update                  ; Below 24? Skip the store
left_ok:
    ; Check for underflow (high byte went to $FF)
    cmp #$ff                    ; Did high byte wrap to $FF?
    beq update                  ; Yes: skip the store
    sta sprite_x_h              ; Store high byte
    stx sprite_x                ; Store low byte
    jmp update

move_right:
    lda sprite_x                ; Load X low byte
    clc                         ; Clear carry
    adc #1                      ; Add 1
    tax                         ; Save low byte in X
    lda sprite_x_h              ; Load X high byte
    adc #0                      ; Add carry

    ; Check right boundary (X > 320)
    cmp #1                      ; High byte > 1? Impossible, but safe
    bne right_lo                ; High byte = 0, check low byte
    cpx #65                     ; High=1: compare low byte against 65
    bcs update                  ; 256 + 65 = 321, too far right
    jmp right_ok
right_lo:
    cmp #0                      ; High byte = 0? Always OK
    beq right_ok
    jmp update                  ; High byte > 1: skip
right_ok:
    sta sprite_x_h              ; Store high byte
    stx sprite_x                ; Store low byte
    jmp update
```

The key insight is checking the 16-bit value in two steps: test the high byte first to determine the range, then compare the low byte against the boundary. For the left side, if the high byte is 0 and the low byte is below 24, we've gone too far. For the right side, if the high byte is 1 and the low byte is 65 or more (256 + 65 = 321), we've gone too far.

### Exercise 2: Add Up/Down Movement

Add two more joystick checks between the right test and `jmp update`:

```asm
    lda $dc00                   ; Re-read joystick
    and #%00000010              ; Test bit 1 (down)
    beq move_down

    lda $dc00
    and #%00000001              ; Test bit 0 (up)
    beq move_up

    jmp update                  ; No movement input
```

And the handlers:

```asm
move_down:
    lda $d001                   ; Read current Y position
    cmp #229                    ; At bottom boundary?
    bcs update                  ; Yes: don't move further down
    inc $d001                   ; Move down 1 pixel
    jmp update

move_up:
    lda $d001                   ; Read current Y position
    cmp #50                     ; At top boundary?
    bcc update                  ; Yes: don't move further up
    dec $d001                   ; Move up 1 pixel
    jmp update
```

Y movement is dramatically simpler than X movement. Since Y coordinates on the C64 never exceed 255, there's no high byte, no 16-bit arithmetic, and no MSB register to manage. We read `$D001` directly, compare against the boundary, and increment or decrement. That's the entire vertical movement system — three instructions per direction plus the boundary check.

## Chapter 8: Falling Objects

### Exercise 1: Data Table Positions

Replace the SID random read with a table lookup:

```asm
pos_index  = $05                ; Zero page: current table index

positions:
    !byte 40, 80, 120, 160, 200, 140, 60, 100

    ; In the ball reset section, replace "lda $d41b / sta $d002" with:
    ldx pos_index               ; Load current index
    lda positions,x             ; Load X position from table
    sta $d002                   ; Set ball X position
    inx                         ; Next index
    txa
    and #%00000111              ; Wrap at 8 (mask to 0-7)
    sta pos_index               ; Store wrapped index
```

The `and #%00000111` trick works because 8 is a power of 2. Binary 8 is `%00001000`, so masking with `%00000111` (one less) wraps any value to the range 0-7. This is faster than CMP/BCC branching and works for any power-of-2 table size.

### Exercise 2: Variable Fall Speed

Add a speed variable and set it randomly on each reset:

```asm
ball_speed = $06                ; Zero page: current fall speed (1-4)

    ; In initialization:
    lda #1
    sta ball_speed

    ; Replace "inc ball_y" with:
    lda ball_y
    clc
    adc ball_speed              ; Move by speed pixels
    sta ball_y

    ; In ball reset section, add:
    lda $d41b                   ; Random value 0-255
    and #%00000011              ; Mask to 0-3
    clc
    adc #1                      ; Adjust to 1-4
    sta ball_speed              ; Set new speed
```

The ball now moves 1-4 pixels per frame depending on the random speed. At speed 4, it crosses the screen in about 50 frames — less than a second. This makes each drop unpredictable.

## Chapter 9: Collision Detection

### Exercise 1: Clear-on-Read Behavior

Add a second read immediately after the first:

```asm
temp1 = $09
temp2 = $0a

check_collision:
    lda $d01e                   ; First read: gets collision bits
    sta temp1                   ; Save result

    lda $d01e                   ; Second read: always 0!
    sta temp2                   ; Save for comparison

    lda temp1                   ; Use first read for logic
    and #%00000011
    cmp #%00000011
    bne cc_done
    ; ... handle collision ...
```

In the VICE monitor, set a breakpoint at `check_collision` and inspect `temp1` and `temp2`. When sprites collide, `temp1` will show `$03` (bits 0 and 1 set) while `temp2` is always `$00`. The VIC-II clears the register on read so the CPU doesn't process the same collision twice.

### Exercise 2: Sprite Expansion

Add these lines during sprite initialization:

```asm
    lda #%00000010              ; Bit 1 = sprite 1
    sta $d017                   ; Double height
    sta $d01d                   ; Double width
```

The ball is now 48x42 pixels (doubled from 24x21). The VIC-II's collision detection also uses the expanded size, so the ball is much harder to dodge. Note that expansion doesn't add detail — it just doubles each pixel. The ball looks blockier but covers a larger area.

## Chapter 10: Catch Game

### Exercise 1: Catch and Avoid

Set up sprite 2 as an avoid-ball:

```asm
    ; Initialization
    lda #34                     ; Same ball shape (pointer 34 = $0880)
    sta $07fa                   ; Sprite 2 pointer
    lda #$02                    ; Red (danger!)
    sta $d029                   ; Sprite 2 color

    ; Change ball (sprite 1) to green (safe to catch)
    lda #$05
    sta $d028

    ; Enable sprite 2
    lda $d015
    ora #%00000111              ; Sprites 0, 1, and 2
    sta $d015
```

In `check_collision`, check sprite 2 separately:

```asm
    lda $0b                     ; Saved collision value
    and #%00000100              ; Sprite 2 involved?
    beq cc_no_avoid

    ; Hit the avoid-ball! Lose a life
    dec lives
    jsr show_lives
    jsr sfx_miss

cc_no_avoid:
```

The player must catch green balls while dodging red ones. This adds a decision element — you can't just park under every falling object.

### Exercise 2: BCD Score Display

Replace the score addition and display with BCD mode:

```asm
    ; Adding 10 points in BCD:
    sed                         ; Enable decimal mode
    lda score_lo
    clc
    adc #$10                    ; BCD: $10 = decimal 10
    sta score_lo
    lda score_hi
    adc #$00
    sta score_hi
    cld                         ; IMPORTANT: disable decimal mode

    ; Display is now trivial:
show_score:
    lda score_lo
    lsr
    lsr
    lsr
    lsr                         ; High nibble = tens digit
    clc
    adc #$30
    sta $0407

    lda score_lo
    and #$0f                    ; Low nibble = ones digit
    clc
    adc #$30
    sta $0408

    lda score_hi
    and #$0f                    ; Hundreds digit
    clc
    adc #$30
    sta $0406
    rts
```

In BCD mode, `$10 + $10 = $20` (not `$20` hex = 32 decimal). Each nibble stays in the 0-9 range. The critical rule: **always CLD** after BCD operations. Leaving decimal mode on will corrupt all other arithmetic in the program.

## Chapter 11: Sound Effects

### Exercise 1: Different Waveforms per Event

```asm
sfx_catch:
    ; Pulse wave with 50% duty cycle
    lda #$00
    sta $d402                   ; Pulse width low
    lda #$08                    ; 50% duty = $0800
    sta $d403                   ; Pulse width high
    lda #$25
    sta $d400
    lda #$1c
    sta $d401
    lda #$09
    sta $d405
    lda #$00
    sta $d406
    lda #$41                    ; Pulse (bit 6) + gate
    sta $d404
    lda #$40                    ; Gate off
    sta $d404
    rts

sfx_miss:
    ; Noise
    lda #$00
    sta $d400
    lda #$18
    sta $d401
    lda #$09
    sta $d405
    lda #$00
    sta $d406
    lda #$81                    ; Noise (bit 7) + gate
    sta $d404
    lda #$80                    ; Gate off
    sta $d404
    rts
```

Pulse sounds hollow and electronic — good for "power-up" effects. Noise sounds like static — good for explosions, hits, and negative events. The pulse width (`$D402`/`$D403`) controls how "hollow" the pulse sounds: `$0800` (50%) is most hollow, values near 0 or `$0FFF` sound thinner.

### Exercise 2: Voice 2 for Simultaneous Sounds

```asm
sfx_miss_v2:
    ; Voice 2 registers are offset by 7 from voice 1
    lda #$00
    sta $d407                   ; V2 frequency low
    lda #$08
    sta $d408                   ; V2 frequency high
    lda #$09
    sta $d40c                   ; V2 attack/decay
    lda #$00
    sta $d40d                   ; V2 sustain/release
    lda #$21                    ; Sawtooth + gate
    sta $d40b                   ; V2 control
    lda #$20                    ; Gate off
    sta $d40b
    rts
```

Now the catch sound (voice 1) and miss sound (voice 2) can play at the same time without cutting each other off. Each SID voice has independent frequency, waveform, and ADSR — they're essentially three separate synthesizers.

## Chapter 12: Multiple Fallers

### Exercise 1: Variable Fall Speeds

```asm
ball_speed_tbl:
    !byte 1, 2, 1               ; Different speed per ball

    ; In animate_balls, replace "inc ball_y_tbl,x" with:
    lda ball_y_tbl,x
    clc
    adc ball_speed_tbl,x        ; Add this ball's speed
    sta ball_y_tbl,x

    ; In ball reset, randomize the speed:
    lda $d41b                   ; Random
    and #%00000011              ; 0-3
    clc
    adc #1                      ; 1-4
    sta ball_speed_tbl,x        ; Set speed for this ball
```

Each ball falls at its own speed. The yellow ball (index 1, initial speed 2) falls twice as fast as the others, making it harder to catch. When a ball resets, it gets a new random speed, so the pattern constantly changes.

### Exercise 2: Branch Out of Range

When a branch target is more than 127 bytes away:

```asm
    ; This fails if ab_next is too far:
    ; bcc ab_next

    ; Fix with a trampoline:
    bcc ab_near                 ; Short branch to nearby label
    jmp ab_far_code             ; This path for when carry is set

ab_near:
    jmp ab_next                 ; JMP has no range limit

ab_far_code:
    ; ... rest of code ...
```

JMP uses a 16-bit address so it can reach any location. Branch instructions only have an 8-bit signed offset (-128 to +127). The trampoline reverses the branch logic: instead of branching far, we branch short and JMP far.

## Chapter 13: Difficulty Progression

### Exercise 1: Vblank Timing Test

```asm
game_loop:
    jsr wait_vblank

    lda #$02                    ; Red
    sta $d020                   ; Start of game logic

    jsr read_input
    jsr animate_balls
    jsr check_collisions
    jsr update_bucket
    jsr check_level

    lda #$0e                    ; Light blue
    sta $d020                   ; End of game logic

    jmp game_loop
```

The red stripe on screen shows CPU time. A thin stripe means the game logic is fast (plenty of headroom). If the stripe ever reaches the bottom of the screen, the game loop takes more than one frame and animation will stutter. This technique is called a "raster time display" and is the standard way to profile C64 programs.

### Exercise 2: Speed Curve

```asm
check_level:
    lda score_lo                ; Only using low byte (0-255)
    lsr                         ; ÷2
    lsr                         ; ÷4
    lsr                         ; ÷8
    lsr                         ; ÷16
    clc
    adc #1                      ; Minimum speed = 1
    cmp #5                      ; Cap at 4
    bcc cl_ok
    lda #4
cl_ok:
    sta fall_speed

    ; Update level display (speed = level for simplicity)
    sta level
    jsr show_level
    rts
```

Four LSR instructions divide by 16, giving a smooth ramp: speed 1 for score 0-15, speed 2 for 16-31, speed 3 for 32-47, speed 4 for 48+. LSR (Logical Shift Right) moves every bit one position right — bit 0 is lost, bit 7 becomes 0. Each shift halves the value (integer division by 2).

## Chapter 14: The Complete Game

### Exercise 1: Sprite Priority

```asm
    ; During game initialization, after enabling sprites:
    lda #%00001110              ; Bits 1-3 = sprites 1-3 (balls)
    sta $d01b                   ; Put balls behind background
```

Bit 0 stays clear so the bucket (sprite 0) remains in front of everything. Bits 1-3 are set so the three balls draw behind background characters — they'll disappear behind the HUD text at the top of the screen. This is a subtle polish detail that makes the HUD feel like a solid overlay.

### Exercise 2: Animated Title

```asm
frame_count = $0f               ; Zero page: frame counter

    ; In title screen wait loop:
ts_wait:
    jsr wait_vblank
    inc frame_count

    ; Blink title every 32 frames
    lda frame_count
    and #%00010000              ; Check bit 4 (toggles every 16 frames)
    beq ts_white

    ; Dark gray phase
    ldx #0
    lda #$0b                    ; Dark gray
    jmp ts_set_color

ts_white:
    ldx #0
    lda #$01                    ; White

ts_set_color:
    sta $d800 + 5*40 + 13,x    ; Color RAM for title row
    inx
    cpx #14                     ; "BUCKET BRIGADE" is 14 chars
    bne ts_set_color

    lda $dc00
    and #%00010000
    bne ts_wait
```

The title text blinks between white and dark gray every 16 frames (~0.3 seconds at 50 Hz). Bit 4 of the frame counter toggles every 16 increments, giving a smooth blink rate. Only the color RAM changes — the characters stay in place.
