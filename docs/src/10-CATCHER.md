# Chapter 10: Catch Game

The game mechanics reverse — now you *want* to catch the falling object. Miss it and you lose a life. Catch it and you score 10 points. This chapter adds a HUD with score display and 16-bit score arithmetic.

## The Code

Create `src/catcher.asm`:

```asm
; catcher.asm - Catch falling objects for points
; Miss = lose a life, catch = score points

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
score_lo   = $06                ; Score low byte
score_hi   = $07                ; Score high byte
caught     = $08                ; Flag: 1 = ball was caught this pass

    ; --- Initialize game state ---

    lda #3
    sta lives
    lda #0
    sta score_lo
    sta score_hi
    sta caught

    ; --- Initialize bucket sprite (sprite 0) ---

    lda #172
    sta sprite_x
    lda #0
    sta sprite_x_h

    lda #41                     ; Bucket data at $0A40 (41 x 64)
    sta $07f8

    lda #224
    sta $d001

    lda #$01
    sta $d027

    ; --- Initialize ball sprite (sprite 1) ---

    lda #42                     ; Ball data at $0A80 (42 x 64)
    sta $07f9

    lda #50
    sta ball_y
    sta $d003

    lda #172
    sta $d002

    lda #$07                    ; Yellow
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

    ; --- Draw labels on screen ---

    jsr draw_hud
    jsr show_lives
    jsr show_score

    ; --- Game loop ---

loop:
    jsr read_input
    jsr animate_ball
    jsr check_collision
    jsr update_sprites
    jsr delay_loop
    jmp loop
```

The full source continues with subroutines for input, animation, collision, HUD drawing, and a 16-bit score display routine. See `src/catcher.asm` for the complete listing.

## Code Explanation

### The Caught Flag

A subtle problem arises: the ball overlaps the bucket for multiple frames as it falls through. Without protection, we'd score points every frame of overlap. The `caught` flag prevents this:

```asm
check_collision:
    lda $d01e                   ; Read collision register
    and #%00000011
    cmp #%00000011
    bne cc_done

    lda caught                  ; Already caught this pass?
    bne cc_done                 ; Yes: don't double-count

    lda #1
    sta caught                  ; Mark as caught
    ; ... add points ...
```

When the ball resets to the top, we clear the flag:

```asm
    lda #0
    sta caught                  ; Ready for next ball
```

This pattern — a flag that prevents repeated triggers — is common in game programming. It's sometimes called a "one-shot" or "edge detector."

### Screen Memory and the HUD

The C64's screen is a 40x25 grid of characters stored at `$0400`-`$07E7`. Each byte is a **screen code** that selects which character to display. Screen codes differ from PETSCII — letters A-Z are codes 1-26, digits 0-9 are codes $30-$39, and `:` is code 58:

```asm
draw_hud:
    lda #19                     ; S (screen code)
    sta $0400                   ; Row 0, col 0
    lda #3                      ; C
    sta $0401                   ; Row 0, col 1
    ; ... etc for "SCORE:" and "LIVES:" ...
```

Each character also needs a color set in **color RAM** at `$D800`:

```asm
    ldx #0
dh_color:
    lda #$01                    ; White
    sta $d800,x                 ; Set color for first row
    inx
    cpx #40                     ; 40 columns
    bne dh_color
```

This loop sets all 40 characters in the top row to white. Without this, characters would be invisible against the background.

### 16-Bit Score Display

Each catch adds 10 points. After 26 catches, the score exceeds 255 — a single byte isn't enough. We store the score as two bytes (`score_lo` and `score_hi`) and add 10 using the familiar carry chain from [Chapter 7](07-BUCKET.md):

```asm
    lda score_lo
    clc
    adc #10                     ; Add 10 to low byte
    sta score_lo
    lda score_hi
    adc #0                      ; Add carry to high byte
    sta score_hi
```

Displaying the score is harder — we need to convert a binary number to decimal digits. The approach is **repeated subtraction**: subtract 100 repeatedly to find the hundreds digit, then subtract 10 for the tens, and whatever remains is the ones:

```asm
show_score:
    ; Copy score to temp variables (destructive operation)
    lda score_lo
    sta $09
    lda score_hi
    sta $0a

    ; Count hundreds
    ldx #0                      ; Hundreds counter
ss_h_loop:
    lda $09
    sec
    sbc #100                    ; Try subtracting 100
    tay                         ; Save low result
    lda $0a
    sbc #0                      ; Subtract borrow from high byte
    bcc ss_h_done               ; Went negative? Done counting
    sta $0a                     ; Store new high byte
    sty $09                     ; Store new low byte
    inx                         ; One more hundred
    jmp ss_h_loop
```

This is 16-bit division by repeated subtraction. We subtract 100 from the full 16-bit value (low byte with carry into high byte) until the result goes negative. The count in X is our hundreds digit. The remainder in `$09` contains the tens and ones, which we extract the same way by subtracting 10.

Each digit is converted to a screen code by adding `$30` and stored directly to screen memory:

```asm
    txa                         ; Hundreds digit
    clc
    adc #$30                    ; Convert to screen code
    sta $0406                   ; Screen position after "SCORE:"
```

## Compiling

```bash
acme -f cbm -o src/catcher.prg src/catcher.asm
```

## Running

```bash
vice-jz.x64sc -autostart src/catcher.prg
```

The HUD shows "SCORE:" and "LIVES:" at the top of the screen. Catch the yellow ball with the bucket to score 10 points. Miss it and lose a life. The border flashes green on a catch and red on a miss. When lives reach 0, the game halts.

## Exercises

### Exercise 1: Catch and Avoid

Add a second falling object (sprite 2) in a different color that you must *avoid*. Getting hit by sprite 2 costs a life instead of scoring points. Use a separate caught flag for each ball and check both collision bits in `$D01E`.

**Hint:** Set up sprite 2 with its own pointer (`$07FA`), color (`$D029`), and position registers (`$D004`/`$D005`). In `check_collision`, check bit 2 of the saved collision value for the avoid-ball.

### Exercise 2: BCD Score Display

The 6502 has a **decimal mode** (SED/CLD instructions) where ADC/SBC operate in Binary-Coded Decimal — each nibble holds one decimal digit (0-9). Replace the repeated-subtraction display with BCD: use `sed` before adding to the score and `cld` after. The score bytes now hold decimal digits directly, making display trivial (just split the nibbles). Note: always CLD after you're done — leaving decimal mode on will break all other arithmetic.

**Hint:** `sed` / `lda score_lo` / `clc` / `adc #$10` / `sta score_lo` / `lda score_hi` / `adc #$00` / `sta score_hi` / `cld`. Then display: `lda score_lo` / `lsr` / `lsr` / `lsr` / `lsr` gives the tens digit, `lda score_lo` / `and #$0f` gives the ones.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

The catch game works, but it's silent. In the next chapter, we'll program the SID chip to play sound effects — a ding when you catch and a buzz when you miss.
