# Appendix B: VIC-II Register Reference

The VIC-II (Video Interface Chip II) handles all graphics on the C64. Its registers are memory-mapped to `$d000-$d3ff`.

## Color Registers

| Address | Hex | Register | Description |
|---------|-----|----------|-------------|
| 53280 | $d020 | Border Color | Color of the screen border (0-15) |
| 53281 | $d021 | Background 0 | Main background color (0-15) |
| 53282 | $d022 | Background 1 | Extra background color 1 (multicolor modes) |
| 53283 | $d023 | Background 2 | Extra background color 2 (multicolor modes) |
| 53284 | $d024 | Background 3 | Extra background color 3 (multicolor modes) |

## Sprite Colors

| Address | Hex | Register | Description |
|---------|-----|----------|-------------|
| 53285 | $d025 | Sprite MC 0 | Sprite multicolor 0 (shared) |
| 53286 | $d026 | Sprite MC 1 | Sprite multicolor 1 (shared) |
| 53287 | $d027 | Sprite 0 Color | Individual color for sprite 0 |
| 53288 | $d028 | Sprite 1 Color | Individual color for sprite 1 |
| 53289 | $d029 | Sprite 2 Color | Individual color for sprite 2 |
| 53290 | $d02a | Sprite 3 Color | Individual color for sprite 3 |
| 53291 | $d02b | Sprite 4 Color | Individual color for sprite 4 |
| 53292 | $d02c | Sprite 5 Color | Individual color for sprite 5 |
| 53293 | $d02d | Sprite 6 Color | Individual color for sprite 6 |
| 53294 | $d02e | Sprite 7 Color | Individual color for sprite 7 |

## Screen Control

| Address | Hex | Register | Description |
|---------|-----|----------|-------------|
| 53265 | $d011 | Control 1 | Vertical scroll, screen height, display enable, bitmap mode, raster bit 8 |
| 53270 | $d016 | Control 2 | Horizontal scroll, screen width, multicolor mode |
| 53272 | $d018 | Memory Setup | Screen memory and character set location |

## Raster

| Address | Hex | Register | Description |
|---------|-----|----------|-------------|
| 53266 | $d012 | Raster | Current raster line (bits 0-7) |
| 53273 | $d019 | IRQ Status | Interrupt status register |
| 53274 | $d01a | IRQ Enable | Interrupt control register |

## Sprite Position

| Address | Hex | Register | Description |
|---------|-----|----------|-------------|
| 53248 | $d000 | Sprite 0 X | Sprite 0 X position (bits 0-7) |
| 53249 | $d001 | Sprite 0 Y | Sprite 0 Y position |
| 53250-53263 | $d002-$d00f | Sprites 1-7 | X,Y pairs for sprites 1-7 |
| 53264 | $d010 | X MSB | Bit 8 of X position for all sprites |

## Sprite Control

| Address | Hex | Register | Description |
|---------|-----|----------|-------------|
| 53269 | $d015 | Sprite Enable | Enable sprites (bit per sprite) |
| 53271 | $d017 | Sprite Y Expand | Double sprite height (bit per sprite) |
| 53277 | $d01d | Sprite X Expand | Double sprite width (bit per sprite) |
| 53275 | $d01b | Sprite Priority | Sprite behind background (bit per sprite) |
| 53276 | $d01c | Sprite Multicolor | Enable multicolor mode (bit per sprite) |

## Collision Detection

| Address | Hex | Register | Description |
|---------|-----|----------|-------------|
| 53278 | $d01e | Sprite-Sprite | Sprite collision flags (read clears) |
| 53279 | $d01f | Sprite-Background | Sprite-background collision (read clears) |
