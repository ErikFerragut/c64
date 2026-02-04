# Chapter 15: Where to Go From Here

You've built a complete game from scratch in 6502 assembly — from "change the border color" to a polished game with sprites, sound, scoring, and difficulty progression. Along the way you learned register operations, memory-mapped I/O, bit manipulation, 16-bit arithmetic, indexed addressing, subroutines, raster timing, and SID programming. These skills cover roughly two-thirds of what the C64 hardware has to offer. Here's what's left.

## Techniques We Didn't Cover

**Raster interrupts** are the biggest missing piece. We used polling (`wait_vblank`) to synchronize with the display, but the C64 can trigger an interrupt (IRQ) at any specific raster line. This lets you run code at precise points during the screen draw — changing colors mid-screen, playing music in the background while the game runs, or splitting the screen between different graphics modes. Interrupts are what separate "programs" from "demos."

**Custom character sets** let you replace the C64's built-in font with your own 8x8 pixel designs. This is how games create custom title screens, map tiles, and status bar graphics without using sprites. The VIC-II can point to character data anywhere in its 16K bank, and each character is just 8 bytes — the same bit-per-pixel format as sprites but smaller.

**Scrolling** uses the VIC-II's hardware scroll registers (`$D016` for horizontal, `$D011` for vertical) to shift the entire screen by 0-7 pixels. Combined with shifting screen memory when the offset wraps, this creates smooth full-screen scrolling — the foundation of platformers and shoot-'em-ups.

**Sprite multiplexing** breaks the 8-sprite hardware limit. Since the VIC-II draws sprites as the raster scans downward, you can reposition a sprite to a lower screen location after the raster has passed its original position. Timed correctly, this lets you display 16, 24, or even more sprites on screen — though it requires careful raster interrupt programming.

**Advanced SID** goes far beyond our simple sound effects. The SID's filter can shape sounds dramatically, pulse width modulation creates evolving timbres, and ring modulation between oscillators produces metallic and bell-like tones. SID tracker software (like GoatTracker or SID-Wizard) lets you compose full music that plays from an interrupt handler.

## Project Ideas

**A Frogger-style game** would reuse everything from Bucket Brigade while adding multi-directional movement, multiple "lanes" with objects moving at different speeds, and timing-based gameplay. The new challenge is managing many independent moving objects — a natural application for the indexed addressing and data tables from Chapter 12.

**A Space Invaders-style shooter** introduces projectile mechanics (the player fires bullets upward), enemy formations that move as a group, and destructible shields. Bullet-to-enemy collision requires checking one sprite against many targets, which pushes you toward more sophisticated collision systems beyond the VIC-II's hardware register.

**A scrolling platformer** combines character set graphics for the level map, hardware scrolling for smooth camera movement, and sprite-to-background collision for platforms and walls. This is significantly more complex than Bucket Brigade but produces the most visually impressive results.

## Resources

The C64 community is large and active. A few starting points:

- **Codebase 64** (codebase64.org) — a wiki of C64 programming techniques, code snippets, and tutorials covering everything from beginner to demo-scene level
- **VICE Monitor** — the emulator's built-in debugger; learn to set breakpoints, inspect memory, and single-step through code — invaluable for tracking down bugs
- **Sprite editors** like SpriteMate (spritemate.com) for designing sprites visually instead of hand-calculating bytes
- **SID trackers** like GoatTracker for composing music that plays from an interrupt routine
- **The C64 Wiki** (c64-wiki.com) — comprehensive hardware documentation, memory maps, and register references

The skills from this tutorial transfer directly to other 6502 systems (NES, Atari 2600, Apple II) and the underlying concepts — registers, memory-mapped hardware, interrupts, bit manipulation — apply to assembly programming on any architecture. The C64 is a particularly good platform to learn on because the hardware is simple enough to understand completely, the community has documented everything thoroughly, and the results are immediately visible and audible.

Happy coding.
