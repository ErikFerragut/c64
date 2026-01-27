; sound.asm - Catch game with sound effects
; Beep on catch, buzz on miss, SID programming

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
score_lo   = $05                ; Score low byte
score_hi   = $06                ; Score high byte
caught     = $07                ; Caught flag
ball_y     = $10                ; Ball Y position

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

    lda #33                     ; Bucket data at $0840 (33 x 64)
    sta $07f8

    lda #224
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

    lda #$07                    ; Yellow
    sta $d028

    ; --- Enable sprites ---

    lda $d015
    ora #%00000011
    sta $d015

    ; --- Initialize SID ---

    ; Clear all SID registers
    ldx #$18
sid_clear:
    lda #0
    sta $d400,x
    dex
    bpl sid_clear

    ; Set master volume
    lda #$0f                    ; Max volume
    sta $d418

    ; Voice 3: random number generator (not audible)
    lda #$ff
    sta $d40e                   ; Voice 3 frequency high
    sta $d40f
    lda #$80                    ; Noise waveform, gate off
    sta $d412

    ; --- Draw HUD ---

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

; =============================================
; Subroutines
; =============================================

; --- Read joystick ---

read_input:
    lda $dc00
    and #%00000100
    beq ri_left
    lda $dc00
    and #%00001000
    beq ri_right
    rts

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

; --- Animate ball ---

animate_ball:
    inc ball_y
    lda ball_y
    sta $d003

    cmp #250
    bcc ab_done

    ; Ball reached bottom
    lda caught
    bne ab_reset

    ; Missed!
    dec lives
    jsr show_lives
    jsr sfx_miss                ; Play miss sound

    lda lives
    bne ab_reset

    ; Game over
    jsr sfx_gameover
    lda #$02
    sta $d020
    lda #$00
    sta $d021
game_over:
    jmp game_over

ab_reset:
    lda #50
    sta ball_y
    sta $d003
    lda $d41b
    sta $d002
    lda $d010
    and #%11111101
    sta $d010
    lda #0
    sta caught

ab_done:
    rts

; --- Check collision ---

check_collision:
    lda $d01e
    and #%00000011
    cmp #%00000011
    bne cc_done

    lda caught
    bne cc_done

    lda #1
    sta caught

    ; Add 10 points
    lda score_lo
    clc
    adc #10
    sta score_lo
    lda score_hi
    adc #0
    sta score_hi

    jsr show_score
    jsr sfx_catch               ; Play catch sound

cc_done:
    rts

; --- Update bucket position ---

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

; --- Draw HUD ---

draw_hud:
    lda #19
    sta $0400
    lda #3
    sta $0401
    lda #15
    sta $0402
    lda #18
    sta $0403
    lda #5
    sta $0404
    lda #58
    sta $0405

    lda #12
    sta $0422
    lda #9
    sta $0423
    lda #22
    sta $0424
    lda #5
    sta $0425
    lda #19
    sta $0426
    lda #58
    sta $0427

    ldx #0
dh_color:
    lda #$01
    sta $d800,x
    inx
    cpx #40
    bne dh_color
    rts

; --- Show lives ---

show_lives:
    lda lives
    clc
    adc #$30
    sta $0428
    rts

; --- Show score ---

show_score:
    lda score_lo
    sta $0d                     ; Temp low
    lda score_hi
    sta $0e                     ; Temp high

    ldx #0
ss_h_loop:
    lda $0d
    sec
    sbc #100
    tay
    lda $0e
    sbc #0
    bcc ss_h_done
    sta $0e
    sty $0d
    inx
    jmp ss_h_loop
ss_h_done:
    txa
    clc
    adc #$30
    sta $0406

    lda $0d
    ldx #0
ss_t_loop:
    cmp #10
    bcc ss_t_done
    sec
    sbc #10
    inx
    jmp ss_t_loop
ss_t_done:
    pha
    txa
    clc
    adc #$30
    sta $0407
    pla
    clc
    adc #$30
    sta $0408
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
