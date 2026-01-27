# Chapter 11: Sound Effects

The SID chip comes alive — a bright ding when you catch the ball, a low buzz when you miss, and a descending wail on game over. This chapter introduces the C64's legendary sound chip.

## Building on Chapter 10

Before making changes, save a copy of your current file:

```bash
cp src/catcher.asm src/sound.asm
```

Open `src/sound.asm`. We'll add full SID initialization and three sound effect subroutines, then remove the border flash effects from `check_collision` and `animate_ball` — sound replaces the visual feedback.

### SID Initialization

In Chapter 10, we set up SID voice 3 as a random number generator with just three writes. Now we need voice 1 for sound effects, so we initialize the entire SID properly. Replace the voice 3 setup block with a full SID clear followed by the voice 3 configuration:

```asm
    ; --- Initialize SID ---

    ; Clear all SID registers
    ldx #$18
sid_clear:
    lda #0
    sta $d400,x
    dex
    bpl sid_clear

    ; Set master volume
    lda #$0f                    ; Max volume (15)
    sta $d418

    ; Voice 3: random number generator (not audible)
    lda #$ff
    sta $d40e                   ; Voice 3 frequency high
    sta $d40f
    lda #$80                    ; Noise waveform, gate off
    sta $d412
```

The loop clears all 25 registers (`$D400`-`$D418`) to zero, giving us a clean slate. Then we set master volume to maximum and reconfigure voice 3 for random numbers exactly as before.

### Remove Border Flashes

In `check_collision`, remove the green border flash after scoring — sound will replace it. Delete this block:

```asm
    ; Flash border green        ← DELETE
    lda #$05                    ← DELETE
    sta $d020                   ← DELETE
    ldx #$08                    ← DELETE
cc_flash:                       ← DELETE
    ldy #$ff                    ← DELETE
cc_fi:                          ← DELETE
    dey                         ← DELETE
    bne cc_fi                   ← DELETE
    dex                         ← DELETE
    bne cc_flash                ← DELETE
    lda #$0e                    ← DELETE
    sta $d020                   ← DELETE
```

Add a call to the catch sound after `jsr show_score`:

```asm
    jsr show_score
    jsr sfx_catch               ; Play catch sound
```

In `animate_ball`, remove the red border flash after `jsr show_lives` and replace it with the miss sound:

```asm
    ; Missed!
    dec lives
    jsr show_lives
    jsr sfx_miss                ; Play miss sound

    lda lives
    bne ab_reset
```

And add the game over sound before the halt:

```asm
    ; Game over
    jsr sfx_gameover
    lda #$02
    sta $d020
    lda #$00
    sta $d021
game_over:
    jmp game_over
```

### Sound Effect Subroutines

Add these three subroutines after `update_sprites`:

```asm
; --- Sound effect: catch (high-pitched ding) ---

sfx_catch:
    pha                         ; Save A on stack
    ; Voice 1: triangle wave, high pitch
    lda #$25                    ; Frequency low  (C5 ~523 Hz)
    sta $d400
    lda #$1c                    ; Frequency high
    sta $d401
    lda #$09                    ; Attack=0, Decay=9
    sta $d405
    lda #$00                    ; Sustain=0, Release=0
    sta $d406
    lda #$11                    ; Triangle waveform + gate on
    sta $d404
    lda #$10                    ; Gate off (release)
    sta $d404
    pla                         ; Restore A
    rts

; --- Sound effect: miss (low buzz) ---

sfx_miss:
    pha
    ; Voice 1: sawtooth wave, low pitch
    lda #$00                    ; Frequency low  (~200 Hz)
    sta $d400
    lda #$08                    ; Frequency high
    sta $d401
    lda #$09                    ; Attack=0, Decay=9
    sta $d405
    lda #$00                    ; Sustain=0, Release=0
    sta $d406
    lda #$21                    ; Sawtooth waveform + gate on
    sta $d404
    lda #$20                    ; Gate off
    sta $d404
    pla
    rts

; --- Sound effect: game over (descending tone) ---

sfx_gameover:
    ; Play a descending sequence
    lda #$09
    sta $d405
    lda #$00
    sta $d406

    lda #$1c                    ; Start high
    sta $d401
    lda #$00
    sta $d400
    lda #$11                    ; Triangle + gate
    sta $d404

    ldx #$1c                    ; Start frequency high byte
go_descend:
    stx $d401
    ldy #$ff
go_delay:
    dey
    bne go_delay
    dex
    cpx #$04                    ; Stop at low frequency
    bne go_descend

    lda #$10                    ; Gate off
    sta $d404
    rts
```

See `src/sound.asm` for the complete listing.

## Code Explanation

### The SID Chip

The **SID** (Sound Interface Device, MOS 6581) is the C64's sound chip — the chip that gave the C64 its reputation for remarkable audio. It has **three independent voices**, each capable of producing one of four waveforms. Its registers live at `$D400`-`$D418`.

Each voice has 7 registers:

| Offset | Register | Purpose |
|--------|----------|---------|
| +0 | Frequency Low | Lower 8 bits of frequency |
| +1 | Frequency High | Upper 8 bits of frequency |
| +2 | Pulse Width Low | Pulse duty cycle (low) |
| +3 | Pulse Width High | Pulse duty cycle (high) |
| +4 | Control | Waveform and gate |
| +5 | Attack/Decay | Envelope timing |
| +6 | Sustain/Release | Envelope levels |

Voice 1 starts at `$D400`, voice 2 at `$D407`, voice 3 at `$D40E`. We use voice 1 for sound effects and voice 3 as a random number generator (from [Chapter 8](08-FALLER.md)).

### Frequency

The SID's frequency value is a 16-bit number that determines the pitch. Higher values = higher pitch. Some common note frequencies:

| Note | Frequency Value | Hex |
|------|----------------|-----|
| C3 | $0712 | Low C |
| C4 | $0E24 | Middle C |
| C5 | $1C48 | High C |
| C6 | $3890 | Very high |

Our catch sound uses `$1C25` (approximately C5, a bright ding) and the miss sound uses `$0800` (a low growl around 200 Hz).

### Waveforms

The control register (`$D404` for voice 1) selects the waveform in its upper 4 bits:

| Bit | Waveform | Sound character |
|-----|----------|-----------------|
| 4 | Triangle | Smooth, flute-like |
| 5 | Sawtooth | Bright, buzzy |
| 6 | Pulse | Hollow, variable |
| 7 | Noise | Static, percussive |

Bit 0 is the **gate** — it triggers the sound:

```asm
    lda #$11                    ; Triangle (bit 4) + gate on (bit 0)
    sta $d404
    lda #$10                    ; Triangle (bit 4) + gate off (bit 0 = 0)
    sta $d404
```

Setting the gate starts the Attack/Decay phase. Clearing it triggers Release. For short sound effects, we gate on and immediately gate off — the ADSR envelope handles the sound's shape.

### ADSR Envelope

Every sound has a volume shape over time called an **envelope**:

```
Volume
  ^
  |   /\
  |  /  \___
  | /       \
  |/         \
  +-----------> Time
   A   D  S  R
```

- **Attack** — how quickly volume rises from 0 to max
- **Decay** — how quickly it drops from max to the sustain level
- **Sustain** — the volume held while the gate is on
- **Release** — how quickly volume fades to 0 after gate off

Register `$D405` packs Attack (high nibble) and Decay (low nibble). Register `$D406` packs Sustain (high nibble) and Release (low nibble):

```asm
    lda #$09                    ; Attack=0 (instant), Decay=9 (medium)
    sta $d405
    lda #$00                    ; Sustain=0, Release=0 (instant)
    sta $d406
```

With Attack=0 and Sustain=0, the sound hits full volume instantly and decays to silence. Decay=9 gives a medium-length fade. This produces a short "ping" — perfect for a catch effect. Lower Decay values (1-3) make shorter clicks; higher values (12-15) make longer tones.

### PHA and PLA -- Saving the Accumulator

Our sound subroutines modify the accumulator, but the caller might still need its value. **PHA** (Push Accumulator) saves A onto the stack, and **PLA** (Pull Accumulator) retrieves it:

```asm
sfx_catch:
    pha                         ; Save A
    ; ... modify A for SID registers ...
    pla                         ; Restore A
    rts
```

The stack is the same one JSR/RTS use for return addresses. PHA/PLA add one byte each time (vs. 2 for JSR). They nest correctly — the stack is LIFO (last in, first out), so the last value pushed is the first pulled:

```asm
    pha                         ; Push first value
    txa
    pha                         ; Push second value (X, via A)
    ; ... do work ...
    pla                         ; Pull second value
    tax                         ; Back to X
    pla                         ; Pull first value (back in A)
```

The order matters. If you push A then X, you must pull X then A. Mixing up the order corrupts both values — and if a JSR's return address is on the stack too, pulling in the wrong order will crash the program.

### The Game Over Sound

The descending tone is a loop that plays a triangle wave while decreasing the frequency register:

```asm
sfx_gameover:
    lda #$11                    ; Triangle + gate on
    sta $d404
    ldx #$1c                    ; Start frequency high byte
go_descend:
    stx $d401                   ; Set frequency
    ldy #$ff                    ; Brief delay
go_delay:
    dey
    bne go_delay
    dex                         ; Lower frequency
    cpx #$04                    ; Stop at low pitch
    bne go_descend
    lda #$10                    ; Gate off
    sta $d404
```

This sweeps the frequency from `$1C` (high) to `$04` (low) over about a second, creating a classic descending tone. The gate stays on throughout so the envelope sustains, and we gate off at the end.

## Compiling

```bash
acme -f cbm -o src/sound.prg src/sound.asm
```

Your .prg file should be **828 bytes**.

## Running

```bash
vice-jz.x64sc -autostart src/sound.prg
```

Make sure VICE's SID emulation is enabled (it is by default). You'll hear a bright triangle ding when catching the ball and a low sawtooth buzz on a miss. Game over plays a descending tone.

## Exercises

### Exercise 1: Different Waveforms per Event

Change the catch sound to use the pulse waveform (`$41` for control) with a pulse width of `$0800` (50% duty cycle — write `$00` to `$D402` and `$08` to `$D403`). Change the miss sound to noise (`$81`). Compare how each waveform sounds. Triangle is smooth, pulse is hollow, sawtooth is bright, and noise is harsh — each suits different game events.

**Hint:** For pulse: set `$D402`/`$D403` before the control register. For noise: just change the control byte to `$81` (noise + gate).

### Exercise 2: Voice 2 for Simultaneous Sounds

Use voice 2 (`$D407`-`$D40D`) for the miss sound so it can play simultaneously with a catch sound. Voice 2's registers are identical to voice 1's but offset by 7. Set its ADSR at `$D40C`/`$D40D` and control at `$D40B`.

**Hint:** Copy the `sfx_miss` routine but change all `$D40x` addresses to `$D40x+7`: frequency at `$D407`/`$D408`, ADSR at `$D40C`/`$D40D`, control at `$D40B`.

Solutions are in [Appendix C](C-SOLUTIONS.md).

## Next Steps

Sound brings the game to life, but one ball isn't much of a challenge. In the next chapter, we'll add multiple falling objects using indexed addressing — the same instruction processes all three balls through a data table.
