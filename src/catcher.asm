; catcher.asm - Catch falling objects for points
; Miss = lose a life, catch = score points

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
caught     = $07                ; 1 = ball was caught this pass
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

    lda #$07                    ; Yellow
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

    ; --- Draw labels on screen ---

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

; --- Read joystick and move bucket ---

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

    cmp #250                    ; Past bottom?
    bcc ab_done

    ; Ball reached bottom — was it caught?
    lda caught
    bne ab_reset                ; Yes: already scored

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
    ; Reset ball to top
    lda #50
    sta ball_y
    sta $d003
    lda $d41b
    sta $d002
    lda $d010
    and #%11111101
    sta $d010
    lda #0
    sta caught                  ; Clear caught flag

ab_done:
    rts

; --- Check collision ---

check_collision:
    lda $d01e                   ; Read sprite collision (clears on read)
    and #%00000011              ; Both sprite 0 and 1?
    cmp #%00000011
    bne cc_done

    ; Caught! Add 10 points
    lda caught                  ; Already caught this pass?
    bne cc_done                 ; Yes: don't double-count

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

    ; Flash border green
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

; --- Draw HUD labels ---

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

; --- Show lives digit ---

show_lives:
    lda lives
    clc
    adc #$30                    ; Number to screen code
    sta $0428                   ; After "LIVES:"
    rts

; --- Show score (16-bit, displays up to 999) ---

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
