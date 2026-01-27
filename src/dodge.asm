; dodge.asm - Catch the falling ball
; Collision detection, subroutines, and game over

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
sprite_x_h = $03                ; Bucket X position, high byte
lives      = $04                ; Lives remaining
caught     = $07                ; 1 = ball was caught this pass
ball_y     = $10                ; Ball Y position

    ; --- Initialize game state ---

    lda #3
    sta lives
    lda #0
    sta caught

    ; --- Initialize bucket sprite (sprite 0) ---

    lda #172
    sta sprite_x
    lda #0
    sta sprite_x_h

    lda #33                     ; Bucket data at $0840 (33 x 64)
    sta $07f8

    lda #224                    ; Near bottom
    sta $d001

    lda #$01                    ; White
    sta $d027

    ; --- Initialize ball sprite (sprite 1) ---

    lda #34                     ; Ball data at $0880 (34 x 64)
    sta $07f9

    lda #50
    sta ball_y
    sta $d003

    lda #172
    sta $d002

    lda #$02                    ; Red
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

    ; --- Display initial lives ---

    jsr show_lives

    ; --- Game loop ---

loop:
    jsr read_input              ; Handle joystick
    jsr animate_ball            ; Move ball down
    jsr check_collision         ; Test for catch
    jsr update_sprites          ; Write to VIC-II
    jsr delay_loop              ; Speed control
    jmp loop

; =============================================
; Subroutines
; =============================================

; --- Read joystick and move bucket ---

read_input:
    lda $dc00
    and #%00000100              ; Left?
    beq ri_left

    lda $dc00
    and #%00001000              ; Right?
    beq ri_right

    rts                         ; No input

ri_left:
    lda sprite_x
    sec
    sbc #1
    sta sprite_x
    lda sprite_x_h
    sbc #0
    sta sprite_x_h
    rts

ri_right:
    lda sprite_x
    clc
    adc #1
    sta sprite_x
    lda sprite_x_h
    adc #0
    sta sprite_x_h
    rts

; --- Animate ball: move down, reset at bottom ---

animate_ball:
    inc ball_y
    lda ball_y
    sta $d003

    cmp #250                    ; Past bottom?
    bcc ab_done                 ; No: return

    ; Ball reached bottom — was it caught?
    lda caught
    bne ab_reset                ; Yes: just reset

    ; Missed! Lose a life
    dec lives
    jsr show_lives

    ; Flash border red
    lda #$02
    sta $d020
    ldx #$18
ab_flash:
    ldy #$ff
ab_fi:
    dey
    bne ab_fi
    dex
    bne ab_flash
    lda #$0e
    sta $d020

    ; Check game over
    lda lives
    bne ab_reset

    lda #$02
    sta $d020
    lda #$00
    sta $d021
game_over:
    jmp game_over

ab_reset:
    ; Reset ball to top with random X
    lda #50
    sta ball_y
    sta $d003
    lda $d41b
    sta $d002
    lda $d010
    and #%11111101              ; Clear ball MSB
    sta $d010
    lda #0
    sta caught                  ; Clear caught flag

ab_done:
    rts

; --- Check sprite collision ---

check_collision:
    lda $d01e                   ; Read collision register (clears on read)
    and #%00000011              ; Sprites 0 and 1 both involved?
    cmp #%00000011
    bne cc_done                 ; No collision

    lda caught                  ; Already caught this pass?
    bne cc_done

    lda #1
    sta caught                  ; Mark as caught

    ; Flash border green briefly
    lda #$05
    sta $d020
    ldx #$08
cc_flash:
    ldy #$ff
cc_fi:
    dey
    bne cc_fi
    dex
    bne cc_flash
    lda #$0e
    sta $d020

cc_done:
    rts

; --- Update bucket position in VIC-II ---

update_sprites:
    lda sprite_x
    sta $d000

    lda sprite_x_h
    and #%00000001
    beq us_clear

    lda $d010
    ora #%00000001
    sta $d010
    rts

us_clear:
    lda $d010
    and #%11111110
    sta $d010
    rts

; --- Display lives at top-left of screen ---

show_lives:
    lda lives
    clc
    adc #$30                    ; Convert number to screen code
    sta $0400                   ; Screen position: row 0, col 0
    lda #$01                    ; White
    sta $d800                   ; Color RAM
    rts

; --- Delay loop ---

delay_loop:
    ldx #$06
dl_outer:
    ldy #$ff
dl_inner:
    dey
    bne dl_inner
    dex
    bne dl_outer
    rts
