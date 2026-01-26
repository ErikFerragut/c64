# Chapter 14: The Complete Game

Bucket Brigade is finished — title screen, gameplay, game over, high score tracking, and press fire to retry. This chapter introduces game states and screen management.

## The Code

Create `src/game.asm`:

The program is the largest yet — the full source is in `src/game.asm`. It combines every concept from the tutorial into a complete, polished game. Here's the overall structure:

```asm
; Main entry point
    ; Initialize SID, high score
    jmp title_screen

title_screen:
    ; Show "BUCKET BRIGADE", high score, "PRESS FIRE"
    ; Wait for fire → start_game

start_game:
    ; Reset lives, score, level, sprites
    ; Fall through to game_loop

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

game_over_screen:
    ; Update high score, show final score
    ; "PRESS FIRE TO RETRY" → title_screen
```

## Code Explanation

### Game States

Every game cycles through states: title → playing → game over → title. We track this with a `game_state` variable:

| Value | State | What happens |
|-------|-------|-------------|
| 0 | Title | Show title, wait for fire |
| 1 | Playing | Game loop runs |
| 2 | Game over | Show score, wait for fire |

The game loop checks `game_state` each frame:

```asm
game_loop:
    ; ... game logic ...
    lda game_state
    cmp #2
    beq go_to_gameover
    jmp game_loop
```

When a ball misses and lives reach 0, `animate_balls` sets `game_state` to 2 and returns (instead of halting with `jmp game_over` like before). The game loop detects this and transitions to the game over screen.

### Screen Text with !scr

ACME's `!scr` directive converts ASCII text to C64 screen codes automatically:

```asm
title_text:
    !scr "BUCKET BRIGADE",0

press_text:
    !scr "PRESS FIRE TO START",0
```

The zero byte at the end is a **null terminator** — it marks where the string ends. We use it in the display loop:

```asm
ts_title:
    lda title_text,x
    beq ts_done                 ; Zero byte? String is finished
    sta $0400 + 5*40 + 13,x    ; Write to screen (row 5, col 13)
    lda #$01                    ; White
    sta $d800 + 5*40 + 13,x    ; Set color
    inx
    jmp ts_title
```

The expression `$0400 + 5*40 + 13` calculates a screen position: base address + (row × 40) + column. ACME evaluates this at assembly time, so the instruction uses a fixed address. The X register steps through each character.

### Clear Screen

Before drawing a new screen, we fill all of screen memory with spaces:

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

Screen memory is 1000 bytes ($0400-$07E7). We clear in four 256-byte blocks using X as a counter. This clears slightly more than needed (1024 vs 1000 bytes), but the extra 24 bytes are harmless — they're in the sprite pointer area, which we overwrite during game setup anyway.

### High Score

The high score persists between games because it lives in zero page variables that aren't reset:

```asm
game_over_screen:
    ; Compare current score with high score (16-bit)
    lda score_hi
    cmp hiscore_hi
    bcc go_no_hiscore           ; score < hiscore
    bne go_new_hiscore          ; score_hi > hiscore_hi (definitely higher)
    lda score_lo
    cmp hiscore_lo
    bcc go_no_hiscore           ; same high byte, but low byte is less

go_new_hiscore:
    lda score_lo
    sta hiscore_lo
    lda score_hi
    sta hiscore_hi
```

This is a **16-bit comparison**: compare the high bytes first. If the high byte is less, the whole value is less. If the high byte is greater, the whole value is greater. Only if the high bytes are equal do we need to compare the low bytes.

### Fire Button with Debouncing

The title screen waits for the fire button to be pressed *and then released*:

```asm
ts_wait:
    jsr wait_vblank
    lda $dc00
    and #%00010000              ; Fire button (bit 4)
    bne ts_wait                 ; Not pressed: keep waiting

ts_release:
    lda $dc00
    and #%00010000
    beq ts_release              ; Still pressed: wait for release
```

Without the release wait (debouncing), a single button press could trigger multiple transitions — the game would start and immediately register another fire press in the game loop. Waiting for release ensures the button is in a clean state before gameplay begins.

## Compiling

```bash
acme -f cbm -o src/game.prg src/game.asm
```

## Running

```bash
vice-jz.x64sc -autostart src/game.prg
```

The complete Bucket Brigade experience:

1. **Title screen** — "BUCKET BRIGADE" in white, high score in yellow, "PRESS FIRE TO START" in cyan
2. **Gameplay** — catch falling balls, score points, level up, lose lives
3. **Game over** — red border, "GAME OVER" text, your final score, "PRESS FIRE TO RETRY"
4. **Back to title** — with updated high score

## Exercises

### Exercise 1: Sprite Priority

By default, sprites are drawn in front of the background. Register `$D01B` controls **sprite-to-background priority** — setting a bit puts that sprite *behind* background characters. Try `lda #%00001110` / `sta $d01b` to put the balls behind the HUD text while keeping the bucket in front. This makes the game feel more polished.

**Hint:** Bit 0 = sprite 0 (bucket), bits 1-3 = sprites 1-3 (balls). Setting bits 1-3 puts balls behind background.

### Exercise 2: Animated Title

Add a simple animation to the title screen — make the title text blink by toggling its color between white and another color every 30 frames. Use a frame counter variable and check it with `and #%00011111` (gives 0 every 32 frames). Set all title character colors to white or dark gray alternately.

**Hint:** Add a counter that increments each vblank. Check bit 4: `lda counter` / `and #%00010000` / `beq use_white` / `lda #$0b` (dark gray) for a slow blink.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

You've built a complete game. The [final chapter](15-NEXT.md) surveys where to go from here — new techniques, new projects, and resources for going deeper.
