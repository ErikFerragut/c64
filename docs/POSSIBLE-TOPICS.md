# Possible Tutorial Topics

A comprehensive list of topics for C64 assembly tutorials, compiled from various sources. Topics are broken down into manageable pieces and roughly organized from beginner to advanced.


## Proposed Reorganization: Fun-First Approach

### The Problem with Traditional Tutorials

Most 6502/C64 tutorials follow this structure:
1. Number systems (hex, binary)
2. All the registers
3. All the addressing modes
4. Memory map
5. All the opcodes
6. ...finally, do something

This front-loads hours of dry reference material before any payoff. Readers lose motivation before reaching the fun parts.

### The Alternative: Just-in-Time Reference

Introduce reference material *when it's needed* for the next fun thing. Each chapter has:
- **A goal** - something visible/audible/interactive
- **The minimum reference** needed to achieve it
- **A working program** that does something satisfying

Reference material becomes a means to an end, not an end in itself.

### Fun Milestones (Dopamine Hits)

| Milestone | What Happens | Why It's Fun |
|-----------|--------------|--------------|
| Change colors with keyboard | Press key, screen changes | Immediate feedback, you control it |
| Joystick control | Move stick, colors change | Game-like interaction |
| Strobe effect | Hold fire, colors cycle | Animation! Visual reward |
| First sprite | Character appears on screen | Real graphics |
| Move sprite | Joystick moves character | You're making a game |
| Two sprites | Player and enemy | It looks like a game |
| Collision | Sprites react when touching | Game mechanics work |
| Sound effect | Beep on collision | Audio feedback |
| Simple game | Avoid enemies, score points | Playable! |
| Background music | Music while playing | Polish, accomplishment |

### Reference Topics Mapped to Milestones

| Milestone | Reference Introduced |
|-----------|---------------------|
| Hello (ch 2) | LDA, STA, registers (A), immediate addressing, BASIC stub |
| Keyboard input | CIA ports, CMP, BEQ/BNE, reading memory |
| Joystick | AND (bit masking), bit testing |
| Loops/strobe | X/Y registers, INX/DEX, branch instructions, delay loops |
| First sprite | VIC-II sprite registers, sprite memory layout, pointers |
| Move sprite | Absolute addressing, 16-bit values (X position MSB) |
| Multiple sprites | Indexed addressing, tables |
| Collision | Reading/clearing collision registers |
| Sound | SID registers, ADSR concept |
| Game loop | JSR/RTS, program structure |
| Music | Interrupts (IRQ), timing |

### Proposed Chapter Sequence

**Part 1: Foundations (Interactive)**

- Ch 1: Installation *(done)*
- Ch 2: Hello World *(done)* - colors, LDA/STA
- Ch 3: Keyboard Input - read keys, change colors, CMP/BNE
- Ch 4: Joystick Control - directions and fire, bit masking
- Ch 5: Loops and Timing - strobe effect, X/Y registers, delay loops

**Part 2: Graphics**

- Ch 6: Your First Sprite - display a sprite, sprite memory
- Ch 7: Moving Sprites - joystick moves sprite, 16-bit X position
- Ch 8: Multiple Sprites - player and enemies, indexed access
- Ch 9: Collision Detection - sprite-sprite and sprite-background

**Part 3: Sound**

- Ch 10: Sound Effects - beeps and boops, SID basics
- Ch 11: Better Sound - ADSR envelopes, waveforms

**Part 4: Putting It Together**

- Ch 12: Game Loop - structure, timing, state
- Ch 13: A Simple Game - combining everything
- Ch 14: Adding Music - interrupts, playing SID tunes

**Part 5: Going Deeper (Optional)**

- Character sets and custom fonts
- Bitmap graphics
- Scrolling
- Raster tricks
- Advanced SID

### Reference Material for Appendices

Some topics work better as appendices to consult as needed:

- **Full opcode reference** - too much to memorize, look up as needed
- **All addressing modes** - introduce basics early, full reference in appendix
- **Complete memory map** - introduce regions as we use them
- **Number systems** - quick reference for conversions
- **VIC-II complete register list** - we introduce pieces, appendix has all
- **SID complete register list** - same approach
- **CIA registers** - same approach

### Key Principles

1. **Every chapter produces something** - no pure theory chapters
2. **Reference serves the goal** - don't teach CMP until we need to compare something
3. **Build on previous code** - each chapter extends what we built before
4. **Exercises are fun** - "make it turn red" not "explain addressing modes"
5. **Appendices for lookup** - don't memorize, know where to find it
6. **Working code always** - never leave reader with broken state

### What Makes This Different

Traditional: "Here are 56 opcodes. Memorize them. Now here are 13 addressing modes..."

This approach: "Want to make the screen flash when you press fire? Here's how to read the joystick (just these 3 instructions). Here's a loop (2 more instructions). Done, it flashes!"

The reader learns the same material, but:
- Motivated by visible progress
- Information arrives when relevant
- Each session ends with something working
- Reference material has context ("I used this for X")

This is essentially "project-based learning" applied to assembly language.

---

## Detailed Project Progression: Building "Bucket Brigade"

A Kaboom!-style catching game built incrementally across the tutorial. Each demo is a complete, working program that builds toward the final game.

### Why Kaboom!-Style?

| Game Type | Complexity | Tutorial Fit |
|-----------|------------|--------------|
| BurgerTime/Patty Panic | Platforms, ladders, multiple enemy AI, ingredient physics | Too complex for early chapters |
| Kaboom!/Avalanche | Single axis movement, falling objects, simple collision | Perfect incremental build |
| Space Invaders | Grid movement, shooting, formations | Good but shooting adds complexity |
| Frogger | Multi-directional, lanes, timing | Good second project |

Kaboom! mechanics isolate perfectly:
- One player sprite (horizontal only)
- Falling objects (vertical only)
- Simple collision (overlapping rectangles)
- Clear win/lose conditions

### Classic References

- **[Kaboom!](https://en.wikipedia.org/wiki/Kaboom!_(video_game))** (Activision 1981) - The definitive catching game
- **[Avalanche](https://en.wikipedia.org/wiki/Avalanche_(video_game))** (Atari 1978) - Kaboom!'s inspiration
- **Eggomania** (1983) - Catch eggs, throw them back
- **Lost Luggage** (1982) - Catch falling suitcases

### Demo Progression

#### Demo 0: Color Cycling (Chapter 3-4)
**What it does:** Border color changes with keyboard/joystick input
**New concepts:** Reading input, responding to events
**Sprites:** None yet
**Fun factor:** Immediate feedback, "I control this"
**Exercise:** Press 1-8 to also change the background color ($d021)

```
[Press 1-8 to change border color]
[Joystick: up=lighter, down=darker]
```

#### Demo 1: Strobe Effect (Chapter 5)
**What it does:** Hold fire button, colors cycle rapidly
**New concepts:** (For) Loops, delays, animation timing
**Sprites:** None yet
**Fun factor:** Trippy visual effect
**Exercise:** Control color-change speed with joystick

```
[Hold FIRE for strobe effect]
[Release to stop]
```

#### Demo 2: Static Sprite (Chapter 6)
**What it does:** Display a bucket/catcher sprite at bottom of screen
**New concepts:** Sprite data, VIC-II sprite registers, enabling sprites
**Sprites:** 1 (player)
**Fun factor:** "I made graphics appear!"
**Exercise:** Make the bucket slide in from the left edge and stop at center (while-loop)
**Sidebar:** Introduce a sprite editor (SpritePad or spritemate.com) so readers don't hand-calculate all future sprite data

```
    +------------------------+
    |                        |
    |                        |
    |                        |
    |                        |
    |          [=]           |  <-- bucket sprite
    +------------------------+
```


**Design note:** Add a simple PETSCII title ("BUCKET BRIGADE") by writing to screen
memory ($0400). Gives the game visual context without custom character sets.
Full graphical title screen comes at Demo 10.


#### Demo 3: Moving Bucket (Chapter 7)
**What it does:** Joystick moves bucket left/right
**New concepts:** Reading joystick in game loop, updating sprite X position
**Sprites:** 1 (player)
**Fun factor:** Direct control, game-like feel
**Exercise:** Add boundary checking so the bucket can't leave the screen (CMP against min/max X)
**Bonus exercise:** Sprite momentum — accelerates while stick is held, decelerates on release, caps at max speed

```
    +------------------------+
    |                        |
    |                        |
    |                        |
    |                        |
    |  ←  [=]  →             |  <-- moves with joystick
    +------------------------+
```

#### Demo 4: Falling Object (Chapter 8)
**What it does:** Ball falls from random X position, resets at bottom
**New concepts:** Second sprite, Y position animation, randomness
**Sprites:** 2 (player + 1 falling)
**Fun factor:** Something is happening!
**Exercise:** Vary the falling speed randomly — sometimes fast, sometimes slow

```
    +------------------------+
    |          O             |  <-- ball falls
    |          ↓             |
    |          O             |
    |          ↓             |
    |          [=]           |
    +------------------------+
```

#### Demo 5: Dodge Game (Chapter 9)
**What it does:** Dodge falling objects, game over if hit
**New concepts:** Sprite collision detection, game over state
**Sprites:** 2
**Fun factor:** Challenge! Stakes! Tension!
**Exercise:** Use the sprite 2x size on some dropped objects

```
    +------------------------+
    |     O                  |
    |     ↓    SCORE: 15     |
    |                        |
    |          O             |
    |     [=]  ↓   LIVES: 3  |
    +------------------------+

    [Collision = lose a life]
```

#### Demo 6: Catch Game (Chapter 10)
**What it does:** Catch objects for points, miss = lose life
**New concepts:** Two collision zones (catch vs miss), scoring
**Sprites:** 2
**Fun factor:** Core gameplay loop complete!
**Exercise:** Include both items to catch & items to avoid

```
    +------------------------+
    |          O             |
    |          ↓  SCORE: 150 |
    |                        |
    |          O             |
    |         [=]  LIVES: 3  |
    +------------------------+

    [Catch = +10 points]
    [Miss = lose life]
```

#### Demo 7: Sound Effects (Chapter 11)
**What it does:** Beep on catch, buzz on miss
**New concepts:** SID basics, simple sound effects, music tones
**Sprites:** 2
**Fun factor:** Audio feedback, satisfaction

```
    CATCH: "ding!" (high pitch)
    MISS:  "buzz!" (low pitch)
    DIE:   "womp womp" (descending)
```

#### Demo 8: Multiple Fallers (Chapter 12)
**What it does:** 2-3 objects falling simultaneously
**New concepts:** Managing multiple sprites, varied timing
**Sprites:** 4 (player + 3 falling)
**Fun factor:** Real challenge, hectic gameplay

```
    +------------------------+
    |  O       O      O      |
    |  ↓       ↓      ↓      |
    |     O              O   |
    |     ↓              ↓   |
    |         [=]            |
    +------------------------+
```

#### Demo 9: Difficulty Progression (Chapter 13)
**What it does:** Speed increases as score increases
**New concepts:** Game state, difficulty curves, level transitions
**Sprites:** 4
**Fun factor:** "One more try" addiction

```
    LEVEL 1: Slow falling (1 pixel/frame)
    LEVEL 2: Medium (2 pixels/frame)
    LEVEL 3: Fast (3 pixels/frame)
    LEVEL 4: Very fast + more objects
```

#### Demo 10: Complete Game (Chapter 14)
**What it does:** Title screen, gameplay, game over, high score
**New concepts:** Game structure, state machine, text display
**Sprites:** 4
**Fun factor:** A real, complete game!

```
    === TITLE SCREEN ===

      BUCKET BRIGADE

      HIGH SCORE: 2450

      PRESS FIRE TO START

    === GAME OVER ===

      YOUR SCORE: 1280

      PRESS FIRE TO RETRY
```

#### Demo 11: Music (Chapter 15 - Optional)
**What it does:** Background music during gameplay
**New concepts:** Interrupts, playing SID tunes, timing
**Sprites:** 4
**Fun factor:** Polish, feels "real"

### Summary: What Each Demo Teaches

| Demo | Chapter | New Concepts | Lines of Code (est) |
|------|---------|--------------|---------------------|
| 0 | 3-4 | Input, branching | ~40 |
| 1 | 5 | Loops, delays | ~60 |
| 2 | 6 | Sprite basics | ~80 |
| 3 | 7 | Sprite movement, joystick | ~100 |
| 4 | 8 | Second sprite, animation | ~130 |
| 5 | 9 | Collision detection | ~160 |
| 6 | 10 | Scoring, game logic | ~200 |
| 7 | 11 | SID sound effects | ~240 |
| 8 | 12 | Multiple sprites | ~280 |
| 9 | 13 | Difficulty, levels | ~320 |
| 10 | 14 | Complete game structure | ~400 |
| 11 | 15 | Interrupts, music | ~450 |

### Possible Second Project: Frogger-Style

After completing Bucket Brigade, a Frogger-style game would introduce:
- Multi-directional movement
- Multiple "lanes" with different speeds
- Timing-based gameplay
- More complex collision (safe zones)

This reuses skills from Bucket Brigade while adding new challenges.

### Possible Third Project: Space Invaders-Style

Adds:
- Shooting mechanics
- Enemy formations
- Bullet collision
- Shields/destructible environment

### Reference Coverage Map

Each demo draws from specific reference topics (§ numbers refer to sections below). Exercise ideas marked with ✎.

#### Ch 2: Hello World
**From §1:** Memory map basics (1.2), Accumulator (1.4)
**From §2:** LDA/STA (2.1), Immediate vs absolute addressing (2.1)
**From §3:** Immediate, absolute, implied modes (3.1)
**From §4:** BASIC stub (4.1), program location (4.2)
**From §5:** Border/background colors (5.1)
**From §12:** Assembler setup (12.1), build system (12.5)

#### Demo 0 (Ch 3-4): Color Cycling
**From §1:** Status register and flags (1.4)
**From §2:** CMP, BEQ/BNE (2.4), AND bit masking (2.3)
**From §3:** Relative mode — branches use offsets (3.4)
**From §9:** CIA keyboard matrix (9.1), joystick ports and direction bits (9.2)
✎ EOR to toggle color on/off (from §2.3)

#### Demo 1 (Ch 5): Strobe Effect
**From §1:** X/Y registers (1.4), clock speed relevance (1.3)
**From §2:** LDX/LDY (2.1), INX/DEX/DEY (2.2), JMP (2.5)
**From §4:** Counted loops, infinite loops (4.3)
**From §11:** Basic cycle timing for delay loops (11.3)
✎ CPX to compare loop counter against a variable instead of zero (from §2.4)
✎ Use EOR to toggle between two colors instead of incrementing (from §2.3)

#### Demo 2 (Ch 6): Static Sprite
**From §1:** RAM vs ROM regions (1.2)
**From §2:** ORA for enabling sprite bits (2.3)
**From §4:** Avoiding ROM/IO conflicts for sprite data (4.2)
**From §5:** Sprite data format, pointers, enabling, colors (5.5), screen memory layout (5.2)
**From §12:** VICE monitor sidebar (12.2), sprite editor sidebar (12.3)
✎ Change sprite color using $D027 (from §5.5)

#### Demo 3 (Ch 7): Moving Bucket
**From §1:** Zero page for game variables (1.2)
**From §2:** ADC/SBC and carry flag (2.2), ASL for X MSB bit (2.7), BCC/BCS for boundary checks (2.4), BMI/BPL for signed checks (2.4)
**From §3:** Zero page addressing (3.1)
**From §5:** Sprite X position + MSB register $D010 (5.5)
**From §11:** 16-bit X position when sprite crosses X=255 (11.6)
**From §13:** First game loop structure (13.1)
✎ Change BNE boundary check to BCS for unsigned comparison (from §2.4)
✎ Use BMI/BPL to detect signed underflow — leads into momentum bonus exercise (from §2.4)

#### Demo 4 (Ch 8): Falling Object
**From §2:** INC/DEC for Y position (2.2), LSR for random position (2.7)
**From §4:** Lookup table for fall speeds (4.5)
**From §5:** Second sprite setup (5.5)
**From §13:** Animation basics (13.3)
✎ Use a data table of starting X positions instead of random (from §4.5)

#### Demo 5 (Ch 9): Dodge Game
**From §2:** JSR/RTS — break game logic into subroutines (2.5)
**From §4:** Subroutine design (4.4)
**From §5:** Collision register $D01E (5.6), sprite expansion 2x (5.5)
**From §13:** Collision detection (13.2), basic game over state (13.4)
✎ Read collision register twice to observe clear-on-read behavior (from §5.6)

#### Demo 6 (Ch 10): Catch Game
**From §2:** ROL for 16-bit score math (2.7)
**From §4:** Parameter passing to subroutines (4.4)
**From §5:** Screen memory for score display, PETSCII characters (5.2)
**From §11:** 16-bit arithmetic for score > 255 (11.6)
**From §13:** Scoring and number-to-string display (13.5)
✎ ASL to double points for streak catches (from §2.7)
✎ Use BCD mode for easier decimal score display (from §11.6)

#### Demo 7 (Ch 11): Sound Effects
**From §2:** PHA/PLA to preserve A across subroutine calls (2.6)
**From §4:** Register preservation patterns (4.4)
**From §8:** SID basics, waveforms, ADSR, frequency tables, sound effects (8.1-8.5)
✎ Different waveform per event: triangle=catch, noise=miss, pulse=die (from §8.2)

#### Demo 8 (Ch 12): Multiple Fallers
**From §3:** Absolute,X / Absolute,Y / Zero page,X (3.2)
**From §4:** Indexed table access, lo/hi byte tables (4.5)
**From §5:** Multicolor sprites for visual variety (5.5)
✎ When a branch goes out of range, fix with JMP trampoline — encounter range limits firsthand (from §3.4)

#### Demo 9 (Ch 13): Difficulty Progression
**From §6:** Raster basics, reading raster position, vblank wait (6.1)
**From §11:** Frame timing for consistent speed (11.3)
**From §13:** Frame timing (13.1)
✎ Time game loop to vblank for smooth, consistent animation (from §6.1)

#### Demo 10 (Ch 14): Complete Game
**From §3:** Indirect JMP for state machine (3.3), indirect indexed for screen memory writes (3.3)
**From §4:** Pointer-based screen access (4.5)
**From §5:** Color RAM $D800 (5.1), sprite priority (5.5), screen memory (5.2)
**From §13:** Title screen, game over, full state machine (13.4)
✎ Sprite priority: bucket in front or behind objects? Try both. (from §5.5)

#### Demo 11 (Ch 15): Music
**From §2:** PHP/PLP in interrupt handler (2.6)
**From §6:** IRQ setup, ISR, acknowledging interrupts, SEI/CLI (6.2)
**From §8:** Music playback, calling SID driver in IRQ (8.6)
**From §12:** SID tracker tools sidebar (12.4)

#### Not Covered — Part 5 / Appendix

These don't naturally arise in Bucket Brigade (~34% of subsections). They belong in Part 5 advanced chapters, appendices, or a second project:

| Category | Topics | Notes |
|----------|--------|-------|
| Graphics | Custom character sets (5.3), bitmap mode (5.4), sprite-bg collision (5.6), screen control 38/40 col (5.7) | Character sets and bitmap are natural Part 5 chapters |
| Raster | Split-screen effects (6.3), sprite multiplexing (6.4), stable rasters (6.5) | All advanced demo-scene techniques |
| Scrolling | All of section 7 | Natural fit for Frogger project |
| Input | Paddle/mouse (9.3) | Paddle would actually be a fun Bucket Brigade variant! |
| Disk/Tape | All of section 10 | Sidebar idea: save high scores with Kernal SAVE |
| Advanced | Self-modifying code (11.1), NMI (11.2), memory banking (11.4), compression (11.5), mult/div/fixed-point (11.6 partial) | Self-modifying code could be a Demo 8 bonus teaser |
| Addressing | Indexed indirect ($xx,X) (3.3) | Rarely needed in practice |
| Instructions | BVS/BVC (2.4), TXS/TSX (2.6) | Rarely used in games |
| Theory | 6502 vs 6510 details (1.3), PC register (1.4), instruction execution (1.3), loop unrolling (4.3) | Appendix reference material |

**Coverage: ~42 of 64 subsections = ~66%**

---

## Original Reference Sections

> These sections catalog all C64 assembly topics. See the **Reference Coverage Map** above
> for how each topic maps into the demo progression. ~66% is covered by Bucket Brigade;
> the rest belongs in Part 5, appendices, or a second project.

## 1. Fundamentals

### 1.1 Number Systems → Appendix (hex in Ch 2, binary in Demo 0)
- Binary representation
- Hexadecimal notation
- Converting between decimal, hex, and binary
- Why hex is used in assembly

### 1.2 C64 Architecture Overview
- Memory map ($0000-$FFFF)
- RAM vs ROM areas
- I/O regions
- Zero page importance

### 1.3 The 6502/6510 CPU → Appendix (cycles in Demo 1)
- Difference between 6502 and 6510
- Clock speed and cycles
- How instructions execute

### 1.4 Registers
- Accumulator (A)
- Index registers (X, Y)
- Stack pointer (SP)
- Program counter (PC)
- Status register (P) and flags

---

## 2. Core Instructions

### 2.1 Load and Store
- LDA, LDX, LDY (load)
- STA, STX, STY (store)
- Immediate vs absolute addressing

### 2.2 Arithmetic
- ADC (add with carry)
- SBC (subtract with carry)
- The carry flag's role
- INC, DEC (increment/decrement memory)
- INX, INY, DEX, DEY (register increment/decrement)

### 2.3 Logical Operations
- AND, ORA, EOR
- Bit masking techniques
- Setting and clearing bits

### 2.4 Comparison and Branching
- CMP, CPX, CPY
- Status flags (Z, N, C, V)
- BEQ, BNE (branch equal/not equal)
- BCC, BCS (branch carry clear/set)
- BMI, BPL (branch minus/plus)
- BVS, BVC (branch overflow)

### 2.5 Jumps and Subroutines
- JMP (unconditional jump)
- JSR (jump to subroutine)
- RTS (return from subroutine)
- The stack and return addresses

### 2.6 Stack Operations
- PHA, PLA (push/pull accumulator)
- PHP, PLP (push/pull processor status)
- TXS, TSX (transfer stack pointer)

### 2.7 Shifts and Rotates
- ASL (arithmetic shift left)
- LSR (logical shift right)
- ROL, ROR (rotate through carry)
- Multiplication/division by 2

---

## 3. Addressing Modes

### 3.1 Basic Modes
- Immediate (#$xx)
- Absolute ($xxxx)
- Zero page ($xx)
- Implied/Implicit

### 3.2 Indexed Modes
- Absolute,X and Absolute,Y
- Zero page,X and Zero page,Y
- Using indexes for arrays/tables

### 3.3 Indirect Modes
- Indirect (JMP only)
- Indexed indirect (($xx,X))
- Indirect indexed (($xx),Y)
- Pointers and indirection

### 3.4 Relative Mode
- Branch offset calculation
- Range limitations (-128 to +127)

---

## 4. Program Structure

### 4.1 BASIC Stub
- Why it's needed
- SYS command encoding
- Load addresses

### 4.2 Memory Layout
- Choosing program location
- Avoiding ROM/IO conflicts
- Bank switching basics

### 4.3 Loops
- Counted loops with X/Y
- Infinite loops
- Loop unrolling

### 4.4 Subroutine Design
- Parameter passing
- Return values
- Preserving registers

### 4.5 Data Tables
- Lookup tables
- Indexed access
- Low/high byte tables for 16-bit values

---

## 5. VIC-II Graphics

### 5.1 Color Registers
- Border and background colors
- Color RAM at $D800

### 5.2 Character Mode
- Default character set
- Screen memory layout
- PETSCII

### 5.3 Custom Character Sets
- Creating character graphics
- Switching character sets
- Character set location in memory

### 5.4 Bitmap Mode
- Hi-res bitmap (320x200)
- Multicolor bitmap (160x200)
- Memory requirements

### 5.5 Sprites
- Sprite data format (63 bytes)
- Sprite pointers
- Enabling sprites
- Positioning (including MSB)
- Sprite colors
- Multicolor sprites
- Sprite priority (behind/front)
- Sprite expansion (2x)

### 5.6 Sprite Collisions
- Sprite-to-sprite detection
- Sprite-to-background detection
- Reading collision registers

### 5.7 Screen Control
- 38/40 column modes
- 24/25 row modes
- Horizontal/vertical scroll registers

---

## 6. Raster Techniques

### 6.1 Raster Basics
- What the raster is
- Reading raster position
- Vertical blank (vblank)

### 6.2 Raster Interrupts
- Setting up IRQ
- Interrupt service routine (ISR)
- Acknowledging interrupts
- SEI/CLI

### 6.3 Split-Screen Effects
- Multiple screen modes
- Color splits
- Raster bars

### 6.4 Sprite Multiplexing
- More than 8 sprites
- Timing constraints
- Sorting sprites

### 6.5 Stable Rasters
- Jitter problem
- Double IRQ technique
- Cycle-exact timing

---

## 7. Scrolling

### 7.1 Hardware Scrolling
- Fine scroll registers ($D016, $D011)
- 0-7 pixel offset

### 7.2 Coarse Scrolling
- Shifting screen memory
- Color RAM challenges

### 7.3 Full-Screen Scrolling
- Combining fine and coarse
- Double buffering
- Timing with raster

### 7.4 Parallax Scrolling
- Multiple scroll speeds
- Split-screen scrolling

---

## 8. SID Sound

### 8.1 SID Basics
- Three voices
- Register layout ($D400-$D418)
- Initializing SID

### 8.2 Waveforms
- Triangle, sawtooth, pulse, noise
- Pulse width modulation

### 8.3 ADSR Envelope
- Attack, Decay, Sustain, Release
- Envelope registers

### 8.4 Playing Notes
- Frequency calculation
- Note tables

### 8.5 Sound Effects
- Simple SFX
- Reserving voice for SFX

### 8.6 Music Playback
- Music driver basics
- Playing SID files
- Calling music in IRQ

---

## 9. Input → Demo 0 (Ch 3-4)

### 9.1 Keyboard
- Reading the keyboard matrix
- Scanning for keys
- CIA #1 ports

### 9.2 Joystick
- Reading joystick ports
- CIA registers for joystick
- Directional bits and fire button

### 9.3 Other Input
- Paddle/mouse
- User port

---

## 10. Disk and Tape

### 10.1 Kernal Routines
- LOAD, SAVE
- File operations
- Channel I/O

### 10.2 Fast Loaders
- Why they're needed
- Basic principles

### 10.3 Direct Disk Access
- Bypassing Kernal
- Speed advantages

---

## 11. Advanced Techniques

### 11.1 Self-Modifying Code
- Why and when to use
- Performance benefits
- Dangers

### 11.2 NMI (Non-Maskable Interrupt)
- Difference from IRQ
- RESTORE key
- Timer-based NMI

### 11.3 Timing and Cycles
- Instruction cycle counts
- Cycle-exact code
- Badlines

### 11.4 Memory Banking
- Switching ROM in/out
- $01 processor port
- VIC bank switching

### 11.5 Compression
- RLE basics
- Depackers

### 11.6 Math Routines
- 16-bit arithmetic
- Multiplication tables
- Division
- Fixed-point math

---

## 12. Tools and Workflow

### 12.1 Assemblers
- ACME, 64tass, ca65, Kick Assembler
- Cross-assembly workflow

### 12.2 Emulator Features → Demo 2 sidebar
- VICE monitor
- Breakpoints
- Memory inspection

### 12.3 Graphics Tools
- Sprite editors
- Character set editors
- Screen editors

### 12.4 Music Tools
- SID trackers
- Converting music

### 12.5 Build Systems
- Makefiles
- Automated testing

---

## 13. Game Development

### 13.1 Game Loop Structure
- Main loop design
- Frame timing

### 13.2 Collision Detection
- Bounding boxes
- Sprite collision registers
- Background collision

### 13.3 Animation
- Frame cycling
- Sprite animation

### 13.4 Game State
- Title screen
- Game over
- State machines

### 13.5 Scoring and Display
- Number to string conversion
- Displaying scores

---

## Notes

- Topics should be taught with working code examples
- Each topic should build on previous knowledge
- Include exercises with solutions
- Reference appendices for details (colors, registers, etc.)

---









## References Used

- [Easy 6502](https://skilldrick.github.io/easy6502/) - Interactive 6502 tutorial
- [Retro64 6502 Overview](https://retro64.altervista.org/blog/6502-assembly-language-quick-overview-with-commodore-64-programming-examples/)
- [C64 Assembly Coding Guide (GitHub)](https://github.com/spiroharvey/c64/blob/main/asm/C64%20Assembly%20Coding%20Guide.md)
- [ChibiAkumas 6510 Programming](https://www.chibiakumas.com/6502/c64.php)
- [6502.org Tutorials](http://www.6502.org/tutorials/6502opcodes.html)
- [Masswerk 6502 Instruction Set](https://www.masswerk.at/6502/6502_instruction_set.html)
- [Lemon64 Assembly Tutorial](https://www.lemon64.com/page/chapter-1-building-a-game-prototype)
- [C64-Wiki](https://www.c64-wiki.com/)
- [Codebase64](https://codebase64.org/)

---
