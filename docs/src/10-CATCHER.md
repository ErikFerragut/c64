# Chapter 10: Catch Game

The game gets a proper HUD. This chapter adds 16-bit scoring, "SCORE:" and "LIVES:" labels drawn to screen memory, and a binary-to-decimal conversion routine that displays the score as three digits.

## Building on Chapter 9

Before making changes, save a copy of your current file:

```bash
cp src/dodge.asm src/catcher.asm
```

Open `src/catcher.asm`. We are adding score tracking, a HUD, and a display routine. The game loop and subroutine structure stay the same -- we are extending what is already there.

### New Variables

Add `score_lo` and `score_hi` between `lives` and `caught`:

```asm
score_lo   = $05                ; Score low byte
score_hi   = $06                ; Score high byte
```

The score needs two bytes because each catch awards 10 points. After 26 catches, the score hits 260 -- beyond what a single byte can hold.

### Initialization

Initialize the score to zero alongside the existing lives and caught setup:

```asm
    lda #3
    sta lives
    lda #0
    sta score_lo
    sta score_hi
    sta caught
```

### Ball Color Change

The ball changes from red to yellow to signal the shift in game mechanics -- this is something you want to catch, not avoid:

```asm
    lda #$07                    ; Yellow
    sta $d028
```

### Drawing the HUD

After sprite initialization, call three subroutines to set up the display:

```asm
    jsr draw_hud
    jsr show_lives
    jsr show_score
```

The `draw_hud` subroutine writes text labels character by character to screen memory. Each letter is stored as its screen code (A=1, B=2, ... Z=26), not as PETSCII:

```asm
draw_hud:
    ; "SCORE:" at row 0, col 0 ($0400)
    lda #19                     ; S (screen code)
    sta $0400
    lda #3                      ; C
    sta $0401
    lda #15                     ; O
    sta $0402
    lda #18                     ; R
    sta $0403
    lda #5                      ; E
    sta $0404
    lda #58                     ; : (screen code)
    sta $0405

    ; "LIVES:" at row 0, col 34 ($0400 + 34)
    lda #12                     ; L
    sta $0422
    lda #9                      ; I
    sta $0423
    lda #22                     ; V
    sta $0424
    lda #5                      ; E
    sta $0425
    lda #19                     ; S
    sta $0426
    lda #58                     ; :
    sta $0427

    ; Set text color to white
    ldx #0
dh_color:
    lda #$01                    ; White
    sta $d800,x
    inx
    cpx #40                     ; First row only
    bne dh_color

    rts
```

The `show_lives` subroutine moves from `$0400` to `$0428` -- right after the "LIVES:" label:

```asm
show_lives:
    lda lives
    clc
    adc #$30                    ; Number to screen code
    sta $0428                   ; After "LIVES:"
    rts
```

### Scoring on Catch

In `check_collision`, after setting the caught flag, add 10 points using a 16-bit add and update the display:

```asm
    lda #1
    sta caught                  ; Mark as caught

    lda score_lo
    clc
    adc #10                     ; Add 10 points
    sta score_lo
    lda score_hi
    adc #0                      ; Add carry to high byte
    sta score_hi

    jsr show_score
```

### The Score Display Routine

The `show_score` subroutine converts the 16-bit binary score into three decimal digits using repeated subtraction. It copies the score to temporary locations `$0d`/`$0e` (since the conversion is destructive), then counts how many times it can subtract 100 for the hundreds digit, 10 for the tens digit, and uses the remainder as the ones digit:

```asm
show_score:
    ; Copy score to temp for destructive division
    lda score_lo
    sta $0d                     ; Temp low byte
    lda score_hi
    sta $0e                     ; Temp high byte

    ; --- Extract hundreds digit ---
    ldx #0                      ; Hundreds counter
ss_h_loop:
    lda $0d
    sec
    sbc #100                    ; Subtract 100 from low byte
    tay                         ; Save low result
    lda $0e
    sbc #0                      ; Subtract borrow from high byte
    bcc ss_h_done               ; Went negative? Done
    sta $0e                     ; Store new high byte
    sty $0d                     ; Store new low byte
    inx
    jmp ss_h_loop
ss_h_done:
    txa                         ; Hundreds digit
    clc
    adc #$30                    ; Convert to screen code
    sta $0406

    ; --- Extract tens digit from remainder in $0d ---
    lda $0d
    ldx #0                      ; Tens counter
ss_t_loop:
    cmp #10
    bcc ss_t_done
    sec
    sbc #10
    inx
    jmp ss_t_loop
ss_t_done:
    pha                         ; Save ones digit
    txa                         ; Tens digit
    clc
    adc #$30
    sta $0407

    pla                         ; Ones digit
    clc
    adc #$30
    sta $0408

    rts
```

The full source is in `src/catcher.asm`.

## Code Explanation

### The Caught Flag

The caught flag was introduced in [Chapter 9](09-DODGE.md) to prevent double-counting during the frames when the ball and bucket overlap. Here it gains an additional role: it controls whether the ball reset awards points or costs a life. When the ball reaches the bottom of the screen, `animate_ball` checks the caught flag. If it is set, the ball was already caught and we simply reset it to the top. If it is clear, the player missed -- lose a life and flash the border red. This single flag drives both the scoring and penalty logic.

### Screen Memory and the HUD

The C64's screen is a 40x25 grid of characters stored at `$0400`-`$07E7`. Each byte is a **screen code** that selects which character to display. Screen codes differ from PETSCII -- uppercase letters A-Z are codes 1-26, digits 0-9 are codes `$30`-`$39`, and the colon `:` is code 58.

We write each character individually with LDA/STA pairs:

```asm
    lda #19                     ; S (screen code)
    sta $0400                   ; Row 0, col 0
    lda #3                      ; C
    sta $0401                   ; Row 0, col 1
```

This is tedious but straightforward. The C64 has no "print string" instruction -- everything goes to memory one byte at a time. In later chapters we will use a loop with indexed addressing to write strings more efficiently, but for short labels the direct approach is clear and costs no extra code.

[COMMENT: Not entirely true if you consider C64 BASIC, whose subroutines can be called from assembly, too. I believe there's a print routine.]

Each character also needs a color set in **color RAM** at `$D800`. The layout mirrors screen memory: `$D800` corresponds to `$0400`, `$D801` to `$0401`, and so on. We color the entire first row white with a loop:

```asm
    ldx #0
dh_color:
    lda #$01                    ; White
    sta $d800,x
    inx
    cpx #40                     ; 40 columns
    bne dh_color
```

Without this, characters would appear in whatever color was left over from the BASIC startup screen -- typically light blue, which is readable but inconsistent. Setting white explicitly ensures the HUD is always visible regardless of what happened before our program ran.

The "SCORE:" label occupies columns 0-5 and the score digits go at columns 6-8 (`$0406`-`$0408`). The "LIVES:" label starts at column 34 (`$0422`-`$0427`) and the lives digit goes at column 40 (`$0428`). This layout keeps both pieces of information visible without overlapping.

### 16-Bit Score Display

Each catch adds 10 points using the same carry-chain addition from [Chapter 7](07-BUCKET.md):

```asm
    lda score_lo
    clc
    adc #10                     ; Add 10 to low byte
    sta score_lo
    lda score_hi
    adc #0                      ; Add carry to high byte
    sta score_hi
```

When `score_lo` is 250 and we add 10, it wraps to 4 (260 - 256) and the carry flag is set. The `adc #0` on `score_hi` adds 0 + 1 (the carry), so `score_hi` becomes 1. The score is now stored as `$01:$04` = 260 in binary. This two-byte representation can hold scores up to 65,535.

Displaying the score requires converting this binary value to decimal digits. The CPU does not have a divide instruction, so we use **repeated subtraction** -- the same algorithm you would use to divide by hand. To find the hundreds digit, subtract 100 repeatedly until the result goes negative, counting how many times you succeeded:

```asm
    ldx #0                      ; Hundreds counter
ss_h_loop:
    lda $0d
    sec
    sbc #100                    ; Subtract 100 from low byte
    tay                         ; Save low result in Y
    lda $0e
    sbc #0                      ; Subtract borrow from high byte
    bcc ss_h_done               ; Went negative? Done counting
    sta $0e                     ; Commit the subtraction
    sty $0d
    inx                         ; One more hundred
    jmp ss_h_loop
```

This is 16-bit subtraction: we subtract 100 from the low byte, and the SBC on the high byte propagates the borrow. If the high byte goes negative (carry clear after SBC means a borrow occurred), we have subtracted too many times -- the count in X is our hundreds digit and the value in `$0d` (before the last subtraction) is the remainder.

The tens digit uses the same approach but only needs 8-bit subtraction since the remainder is always less than 100. Whatever is left after extracting tens is the ones digit. Each digit is converted to a screen code by adding `$30` and written directly to the screen positions after "SCORE:".

[COMMENT: There are faster approaches. Also, we could probably have just stored the number of catches and then written the 0 after it. Third option is BCD encoding, which makes addition harder but printing easier -- ah, I see this is exercise 2.]

[QUESTION: If the score goes multiple digits and then we restart, are we left with old digits to the right of the new 0 score? I suppose we avoid this by not allowing a game to restart.]

## Compiling

```bash
acme -f cbm -o src/catcher.prg src/catcher.asm
```

Your .prg file should be **732 bytes**.

## Running

```bash
vice-jz.x64sc -autostart src/catcher.prg
```

The HUD shows "SCORE:" and "LIVES:" across the top of the screen. Catch the yellow ball with the bucket to score 10 points -- the border flashes green and the score updates immediately. Miss it and lose a life -- the border flashes red and the lives digit decreases. When lives reach 0, the screen turns red and black and the game halts.

## Exercises

### Exercise 1: Catch and Avoid

Add a second falling object (sprite 2) in a different color that you must *avoid*. Getting hit by sprite 2 costs a life instead of scoring points. Set up sprite 2 with its own pointer (`$07FA`), color (`$D029`), and position registers (`$D004`/`$D005`). Use a separate caught flag and check the appropriate collision bits in `$D01E`.

**Hint:** Enable sprite 2 by ORing `%00000100` into `$D015`. In `check_collision`, save the `$D01E` value to a variable first (remember, it clears on read). Then check bit 2 for the avoid-ball collision separately from the catch-ball collision in bits 0 and 1.

### Exercise 2: BCD Score Display

The 6502 has a **decimal mode** (SED/CLD instructions) where ADC and SBC operate in Binary-Coded Decimal -- each nibble holds one decimal digit (0-9). Replace the repeated-subtraction display with BCD: use `sed` before adding to the score and `cld` after. The score bytes now hold decimal digits directly, making display trivial (just split the nibbles with shifts and masks). Note: always CLD after you are done -- leaving decimal mode on will break all other arithmetic in your program.

**Hint:** `sed` / `lda score_lo` / `clc` / `adc #$10` / `sta score_lo` / `lda score_hi` / `adc #$00` / `sta score_hi` / `cld`. Then to display: `lda score_lo` / `lsr` / `lsr` / `lsr` / `lsr` gives the tens digit, `lda score_lo` / `and #$0f` gives the ones.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

The catch game works, but it is silent. In the next chapter, we will program the SID chip to play sound effects -- a ding when you catch and a buzz when you miss.
