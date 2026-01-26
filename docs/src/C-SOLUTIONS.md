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

Add these checks after the port 2 fire test (before `jmp loop`), and add the corresponding handlers:

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

And the handlers:

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
