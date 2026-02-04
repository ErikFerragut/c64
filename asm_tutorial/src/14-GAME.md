# Chapter 14: The Complete Game

Bucket Brigade is finished -- title screen, gameplay, game over, high score tracking, and press-fire-to-retry. This chapter introduces a **game state machine** and screen management to wrap our gameplay loop in a complete player experience.

## Building on Chapter 13

Copy the previous chapter's source as a starting point:

```bash
cp src/levels.asm src/game.asm
```

This chapter adds substantial new code. Here is a walkthrough of every change.

**New variables.** Add `game_state` and high score variables to zero page:

```asm
game_state = $0a                ; 0=title, 1=playing, 2=game over
hiscore_lo = $0b                ; High score low byte
hiscore_hi = $0c                ; High score high byte
```

**Restructured entry point.** The entry point now initializes the high score and SID once, then falls through to the title screen. Sprite setup moves into `start_game` so it runs at the beginning of each new game:

```asm
    lda #0
    sta hiscore_lo
    sta hiscore_hi

    ; SID setup (once at startup)
    ldx #$18
sid_clear:
    lda #0
    sta $d400,x
    dex
    bpl sid_clear
    lda #$0f
    sta $d418
    lda #$ff
    sta $d40e
    sta $d40f
    lda #$80
    sta $d412

    ; Fall through to title screen
```

**Title screen.** Clears the screen, draws text strings using `!scr` data, shows the high score, and waits for the fire button:

```asm
title_screen:
    lda #0
    sta game_state

    ; Disable all sprites
    lda #0
    sta $d015

    ; Set colors
    lda #$06                    ; Blue
    sta $d020
    lda #$06
    sta $d021

    ; Clear screen
    jsr clear_screen

    ; Draw title text
    ; Row 5: "BUCKET BRIGADE" centered (col 13)
    ldx #0
ts_title:
    lda title_text,x
    beq ts_hi                   ; Zero terminator
    sta $0400 + 5*40 + 13,x
    lda #$01                    ; White
    sta $d800 + 5*40 + 13,x
    inx
    jmp ts_title

    ; Row 10: "HIGH SCORE:" (col 12)
ts_hi:
    ldx #0
ts_hi_loop:
    lda hiscore_text,x
    beq ts_prompt
    sta $0400 + 10*40 + 12,x
    lda #$07                    ; Yellow
    sta $d800 + 10*40 + 12,x
    inx
    jmp ts_hi_loop

    ; Show high score digits at row 10, col 24
ts_prompt:
    jsr show_hiscore

    ; Row 15: "PRESS FIRE TO START" (col 10)
    ldx #0
ts_pr:
    lda press_text,x
    beq ts_wait
    sta $0400 + 15*40 + 10,x
    lda #$03                    ; Cyan
    sta $d800 + 15*40 + 10,x
    inx
    jmp ts_pr

    ; Wait for fire button
ts_wait:
    jsr wait_vblank
    lda $dc00
    and #%00010000              ; Fire button
    bne ts_wait                 ; Not pressed: keep waiting

    ; Debounce: wait for release
ts_release:
    lda $dc00
    and #%00010000
    beq ts_release              ; Still pressed: wait

    jmp start_game
```

**Start game.** Resets all game state, clears the screen, draws the HUD, and sets up all sprites. This runs at the start of every new game:

```asm
start_game:
    lda #1
    sta game_state

    ; Reset game state
    lda #3
    sta lives
    lda #0
    sta score_lo
    sta score_hi
    sta caught
    lda #1
    sta level
    sta fall_speed

    ; Clear screen and draw HUD
    jsr clear_screen
    jsr draw_hud
    jsr show_lives
    jsr show_score
    jsr show_level

    ; Set colors
    lda #$0e                    ; Light blue
    sta $d020
    lda #$06                    ; Blue
    sta $d021

    ; Setup bucket and ball sprites ...
    ; Enable sprites ...
    jsr update_bucket
```

**Game loop with state check.** Instead of halting on game over, the loop checks `game_state` each frame:

```asm
game_loop:
    jsr wait_vblank
    jsr read_input
    jsr animate_balls
    jsr check_collisions
    jsr update_bucket
    jsr check_level

    lda game_state
    cmp #2                      ; Game over?
    beq go_to_gameover
    jmp game_loop

go_to_gameover:
    jmp game_over_screen
```

**animate_balls game over change.** When lives reach zero, instead of an infinite halt loop, we set the state and return:

```asm
    lda lives
    bne ab_do_reset

    ; Game over -- set state and return
    lda #2
    sta game_state
    rts
```

**Game over screen.** Updates the high score, disables sprites, clears the screen, and displays the final score:

```asm
game_over_screen:
    ; Update high score if needed
    lda score_hi
    cmp hiscore_hi
    bcc go_no_hiscore           ; score_hi < hiscore_hi
    bne go_new_hiscore          ; score_hi > hiscore_hi

    lda score_lo
    cmp hiscore_lo
    bcc go_no_hiscore           ; score_lo < hiscore_lo

go_new_hiscore:
    lda score_lo
    sta hiscore_lo
    lda score_hi
    sta hiscore_hi

go_no_hiscore:
    ; Disable sprites
    lda #0
    sta $d015

    ; Set colors
    lda #$02                    ; Red
    sta $d020
    lda #$00                    ; Black
    sta $d021

    jsr clear_screen

    ; "GAME OVER" at row 5, col 15
    ldx #0
go_title:
    lda gameover_text,x
    beq go_score
    sta $0400 + 5*40 + 15,x
    lda #$02                    ; Red
    sta $d800 + 5*40 + 15,x
    inx
    jmp go_title

    ; "YOUR SCORE:" at row 9, col 14
go_score:
    ldx #0
go_sc_loop:
    lda yourscore_text,x
    beq go_show_sc
    sta $0400 + 9*40 + 14,x
    lda #$01                    ; White
    sta $d800 + 9*40 + 14,x
    inx
    jmp go_sc_loop

go_show_sc:
    jsr show_gameover_score

    ; "PRESS FIRE TO RETRY" at row 15, col 10
    ldx #0
go_pr:
    lda retry_text,x
    beq go_wait
    sta $0400 + 15*40 + 10,x
    lda #$03                    ; Cyan
    sta $d800 + 15*40 + 10,x
    inx
    jmp go_pr

go_wait:
    jsr wait_vblank
    lda $dc00
    and #%00010000
    bne go_wait

go_release:
    lda $dc00
    and #%00010000
    beq go_release

    jmp title_screen
```

**Text data.** Strings are stored using ACME's `!scr` directive with zero terminators:

```asm
title_text:
    !scr "BUCKET BRIGADE",0

hiscore_text:
    !scr "HIGH SCORE:",0

press_text:
    !scr "PRESS FIRE TO START",0

gameover_text:
    !scr "GAME OVER",0

yourscore_text:
    !scr "YOUR SCORE:",0

retry_text:
    !scr "PRESS FIRE TO RETRY",0
```

The full source is in `src/game.asm`.

## Code Explanation

### Game States

Every game cycles through states: title, playing, game over, back to title. We track this with a single variable:

| Value | State | What happens |
|-------|-------|-------------|
| 0 | Title | Show title screen, wait for fire |
| 1 | Playing | Game loop runs |
| 2 | Game over | Show score, wait for fire |

The game loop checks `game_state` at the end of each frame:

```asm
game_loop:
    ; ... game logic subroutines ...
    lda game_state
    cmp #2
    beq go_to_gameover
    jmp game_loop
```

When a ball misses and lives reach 0, `animate_balls` sets `game_state` to 2 and returns normally. The game loop detects this on the next state check and transitions to the game over screen. This is cleaner than the old `jmp ab_halt` infinite loop -- the game keeps control flowing through the same main loop structure, and the state variable determines what happens next.

### Screen Text with !scr

ACME's `!scr` directive converts ASCII text to C64 screen codes automatically:

```asm
title_text:
    !scr "BUCKET BRIGADE",0
```

The zero byte at the end is a **null terminator** -- it marks where the string ends. The display loop uses indexed addressing to copy characters to screen RAM one at a time:

```asm
    ldx #0
ts_title:
    lda title_text,x
    beq ts_hi                   ; Zero byte? String is finished
    sta $0400 + 5*40 + 13,x    ; Write to screen
    lda #$01                    ; White
    sta $d800 + 5*40 + 13,x    ; Set color
    inx
    jmp ts_title
```

The expression `$0400 + 5*40 + 13` calculates a screen position: base address (`$0400`) + row times 40 + column. ACME evaluates this arithmetic at assembly time, producing a fixed address in the generated code. The X register steps through each character, writing both the screen code and its color. When it hits the zero terminator, `BEQ` branches to the next section.

Each text block uses the same pattern with different screen positions and colors:
- Title at row 5, column 13 in white (`$01`)
- "HIGH SCORE:" at row 10, column 12 in yellow (`$07`)
- "PRESS FIRE TO START" at row 15, column 10 in cyan (`$03`)

### Clear Screen

Before drawing a new screen, we fill screen memory with spaces:

```asm
clear_screen:
    ldx #0
    lda #$20                    ; Space character (screen code)
cs_loop:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    dex
    bne cs_loop
    rts
```

Screen memory runs from `$0400` to `$07E7` (1000 bytes). We clear in four 256-byte blocks using X as a counter that wraps from 0 to 255 and back to 0. This clears 1024 bytes total -- slightly more than the 1000 bytes of visible screen. The extra 24 bytes fall into the sprite pointer area (`$07F8`-`$07FF`), which we overwrite during game setup anyway.

Starting X at 0 and using `DEX` / `BNE` is a common 6502 idiom. The first `DEX` wraps X to 255, and the loop counts down 255, 254, ... 1 before `BNE` falls through. That's 256 iterations (indices 255 down to 0), covering all 256 bytes in each page.

### High Score

The high score persists between games because it lives in zero page variables (`hiscore_lo`, `hiscore_hi`) that are initialized once at program start and never reset by `start_game`. After each game, we compare the current score with the high score using a **16-bit comparison**:

```asm
    lda score_hi
    cmp hiscore_hi
    bcc go_no_hiscore           ; score_hi < hiscore_hi: not a new record
    bne go_new_hiscore          ; score_hi > hiscore_hi: definitely new record

    ; High bytes equal -- compare low bytes
    lda score_lo
    cmp hiscore_lo
    bcc go_no_hiscore           ; score_lo < hiscore_lo: not a new record

go_new_hiscore:
    lda score_lo
    sta hiscore_lo
    lda score_hi
    sta hiscore_hi
```

The logic is: compare the high bytes first. If the high byte of the score is less (`BCC`), the whole 16-bit value is less -- no new record. If the high byte is greater (`BNE` after the `BCC` didn't branch), the whole value is greater -- new record. Only when the high bytes are equal do we need to compare the low bytes. This two-step pattern is the standard way to compare multi-byte values on the 6502.

The title screen calls `show_hiscore` to display the high score digits at row 10, column 24. This uses the same repeated-subtraction algorithm as `show_score` but writes to the title screen position instead of the HUD.

### Fire Button with Debouncing

The title and game over screens wait for the fire button with a two-phase check:

```asm
    ; Phase 1: wait for press
ts_wait:
    jsr wait_vblank
    lda $dc00
    and #%00010000              ; Fire button (bit 4, active low)
    bne ts_wait                 ; Not pressed: keep waiting

    ; Phase 2: wait for release
ts_release:
    lda $dc00
    and #%00010000
    beq ts_release              ; Still pressed: wait for release
```

The fire button is bit 4 of `$DC00`. It reads 0 when pressed and 1 when released (active low, like all joystick lines).

Without the release wait (**debouncing**), a single button press could trigger multiple transitions. The player presses fire on the title screen, the game starts, and the very next frame reads the button as still held -- which could register as input during gameplay. Waiting for release ensures the button is in a clean state before the next screen begins.

The title screen also calls `jsr wait_vblank` in its wait loop. This isn't strictly necessary for button reading, but it prevents the loop from running thousands of times per frame, which would poll the joystick port excessively.

## Compiling

```bash
acme -f cbm -o src/game.prg src/game.asm
```

The compiled program is **1608 bytes** -- the largest in the tutorial, but still comfortably under 2 KB.

## Running

```bash
vice-jz.x64sc -autostart src/game.prg
```

The complete Bucket Brigade experience:

1. **Title screen** -- "BUCKET BRIGADE" in white on a blue background, high score in yellow, "PRESS FIRE TO START" in cyan. No sprites are visible.
2. **Gameplay** -- light blue border, three colored balls falling, HUD with score, level, and lives. Balls accelerate as your score increases.
3. **Game over** -- red border, black background. "GAME OVER" in red, your final score in white, "PRESS FIRE TO RETRY" in cyan. The game over sound plays once.
4. **Back to title** -- the high score updates if you beat it. Press fire to play again.

The cycle repeats indefinitely. The high score persists as long as the program is running.

## Exercises

### Exercise 1: Sprite Priority

By default, sprites are drawn in front of background characters. Register `$D01B` controls **sprite-to-background priority** -- setting a bit puts that sprite *behind* background characters. Try putting the ball sprites behind the HUD text so they pass underneath it:

```asm
    lda #%00001110              ; Sprites 1-3 behind background
    sta $d01b
```

Add this in `start_game` after enabling sprites. The bucket (sprite 0, bit 0 clear) stays in front of everything, while the balls slide behind the score text. This makes the game feel more polished.

**Hint:** Bit 0 = sprite 0 (bucket), bits 1-3 = sprites 1-3 (balls). Setting bits 1-3 puts balls behind background characters. The HUD text becomes a visual "overlay."

### Exercise 2: Animated Title

Add a simple animation to the title screen: blink the title text between white and dark gray. Use a frame counter and toggle the color every 32 frames:

```asm
    lda #0
    sta $0f                     ; Frame counter

ts_wait:
    jsr wait_vblank
    inc $0f

    lda $0f
    and #%00010000              ; Check bit 4 (toggles every 16 frames)
    beq ts_white
    lda #$0b                    ; Dark gray
    jmp ts_setcol
ts_white:
    lda #$01                    ; White
ts_setcol:
    ldx #0
ts_blink:
    sta $d800 + 5*40 + 13,x
    inx
    cpx #14                     ; Length of "BUCKET BRIGADE"
    bne ts_blink

    lda $dc00
    and #%00010000
    bne ts_wait
```

**Hint:** Bit 4 of the counter toggles every 16 frames, giving roughly a half-second blink rate on PAL. For a slower blink, check bit 5 instead (toggles every 32 frames).

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

You have built a complete game from scratch in 6502 assembly. Starting with "Hello, World" and ending with a full title-to-gameplay-to-gameover loop, every byte is something you wrote and understand. The [next chapter](15-NEXT.md) surveys where to go from here -- new techniques, new projects, and resources for going deeper into the C64.
