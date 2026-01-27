; faller.asm - Falling object with moving bucket
; Ball falls from random positions, bucket catches with joystick

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2304
!byte $0c, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2304"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

; --- Sprite Data ---
* = $0840                       ; Bucket sprite (pointer = 33)

bucket_data:
    !fill 36, 0                 ; Rows 0-11: empty
    ; Row 12-13: rim (full width)
    !byte %11111111,%11111111,%11111111
    !byte %11111111,%11111111,%11111111
    ; Row 14-15: body tapers
    !byte %01111111,%11111111,%11111110
    !byte %01111111,%11111111,%11111110
    ; Row 16-17
    !byte %00111111,%11111111,%11111100
    !byte %00111111,%11111111,%11111100
    ; Row 18-19
    !byte %00011111,%11111111,%11111000
    !byte %00011111,%11111111,%11111000
    ; Row 20: bottom
    !byte %00001111,%11111111,%11110000

* = $0880                       ; Ball sprite (pointer = 34)

ball_data:
    !fill 21, 0                 ; Rows 0-6: empty
    ; Row 7: top of ball
    !byte %00000000,%00111100,%00000000
    ; Row 8
    !byte %00000000,%01111110,%00000000
    ; Rows 9-12: middle
    !byte %00000000,%11111111,%00000000
    !byte %00000000,%11111111,%00000000
    !byte %00000000,%11111111,%00000000
    !byte %00000000,%11111111,%00000000
    ; Row 13
    !byte %00000000,%01111110,%00000000
    ; Row 14: bottom of ball
    !byte %00000000,%00111100,%00000000
    ; Rows 15-20: empty
    !fill 18, 0

; --- Code ---
* = $0900                       ; Code start (2304 decimal)

sprite_x   = $02                ; Bucket X position, low byte
sprite_x_h = $03                ; Bucket X position, high byte (0 or 1)
ball_y     = $10                ; Ball Y position

    ; --- Initialize bucket sprite (sprite 0) ---

    lda #172                    ; X = 172 (center)
    sta sprite_x
    lda #0                      ; High byte = 0
    sta sprite_x_h

    lda #33                     ; Bucket data at $0840 (33 x 64)
    sta $07f8                   ; Sprite 0 pointer

    lda #224                    ; Near bottom of screen
    sta $d001                   ; Sprite 0 Y

    lda #$01                    ; White
    sta $d027                   ; Sprite 0 color

    ; --- Initialize ball sprite (sprite 1) ---

    lda #34                     ; Ball data at $0880 (34 x 64)
    sta $07f9                   ; Sprite 1 pointer

    lda #50                     ; Start near top of screen
    sta ball_y
    sta $d003                   ; Sprite 1 Y

    lda #172                    ; Start at center X
    sta $d002                   ; Sprite 1 X

    lda #$02                    ; Red
    sta $d028                   ; Sprite 1 color

    ; --- Enable sprites 0 and 1 ---

    lda $d015                   ; Read sprite enable register
    ora #%00000011              ; Set bits 0 and 1
    sta $d015

    ; --- Set up SID voice 3 for random numbers ---

    lda #$ff                    ; Maximum frequency
    sta $d40e                   ; Voice 3 frequency low
    sta $d40f                   ; Voice 3 frequency high
    lda #$80                    ; Noise waveform, gate off
    sta $d412                   ; Voice 3 control register

    ; --- Game loop ---

loop:
    ; --- Read joystick, move bucket ---

    lda $dc00                   ; Read joystick port 2
    and #%00000100              ; Test bit 2 (left)
    beq move_left

    lda $dc00                   ; Re-read
    and #%00001000              ; Test bit 3 (right)
    beq move_right

    jmp move_ball               ; No horizontal input

move_left:
    lda sprite_x
    sec
    sbc #1
    sta sprite_x
    lda sprite_x_h
    sbc #0
    sta sprite_x_h
    jmp move_ball

move_right:
    lda sprite_x
    clc
    adc #1
    sta sprite_x
    lda sprite_x_h
    adc #0
    sta sprite_x_h

move_ball:
    ; --- Animate ball: move down one pixel ---

    inc ball_y                  ; Increment Y position
    lda ball_y
    sta $d003                   ; Update sprite 1 Y register

    ; Check if ball reached bottom of screen
    cmp #250                    ; Past visible area?
    bcc update                  ; No: skip reset

    ; --- Reset ball to top with new random X ---

    lda #50                     ; Back to top
    sta ball_y
    sta $d003

    lda $d41b                   ; Read SID voice 3 random value
    sta $d002                   ; New X position for ball

    lda $d010                   ; Read X position MSB register
    and #%11111101              ; Clear bit 1 (sprite 1)
    sta $d010                   ; Keep ball in 0-255 X range

update:
    ; --- Update bucket X position ---

    lda sprite_x                ; Low 8 bits of X
    sta $d000                   ; Sprite 0 X position

    ; Update bucket X MSB (bit 8)
    lda sprite_x_h
    and #%00000001
    beq msb_clear

    lda $d010
    ora #%00000001              ; Set bit 0 (sprite 0)
    sta $d010
    jmp delay

msb_clear:
    lda $d010
    and #%11111110              ; Clear bit 0 (sprite 0)
    sta $d010

delay:
    ldx #$06                    ; Outer loop
delay_outer:
    ldy #$ff                    ; Inner loop
delay_inner:
    dey
    bne delay_inner
    dex
    bne delay_outer

    jmp loop                    ; Back to game loop
