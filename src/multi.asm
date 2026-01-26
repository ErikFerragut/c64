; multi.asm - Multiple falling objects
; Three balls fall simultaneously using indexed addressing

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2064
!byte $0c, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2064"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

* = $0810                       ; Code start (2064 decimal)

sprite_x   = $02                ; Bucket X position, low byte
sprite_x_h = $03                ; Bucket X position, high byte
lives      = $04                ; Lives remaining
score_lo   = $05                ; Score low byte
score_hi   = $06                ; Score high byte
caught     = $07                ; Caught flags (bits 0-2 for balls 0-2)

NUM_BALLS  = 3                  ; Number of falling balls

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

    lda #52                     ; Bucket data at $0D00 (52 x 64)
    sta $07f8

    lda #224
    sta $d001

    lda #$01                    ; White
    sta $d027

    ; --- Initialize ball sprites (sprites 1-3) ---

    lda #53                     ; Ball data at $0D40 (53 x 64)
    sta $07f9                   ; Sprite 1 pointer
    sta $07fa                   ; Sprite 2 pointer
    sta $07fb                   ; Sprite 3 pointer

    ; Set ball colors
    lda #$02                    ; Red
    sta $d028                   ; Sprite 1
    lda #$07                    ; Yellow
    sta $d029                   ; Sprite 2
    lda #$05                    ; Green
    sta $d02a                   ; Sprite 3

    ; Set initial Y positions (staggered)
    lda #50
    sta ball_y_tbl
    lda #120
    sta ball_y_tbl+1
    lda #190
    sta ball_y_tbl+2

    ; Set initial X positions using SID random
    lda #$ff
    sta $d40e
    sta $d40f
    lda #$80
    sta $d412

    ; Write initial positions to VIC-II
    lda ball_y_tbl
    sta $d003                   ; Sprite 1 Y
    lda ball_y_tbl+1
    sta $d005                   ; Sprite 2 Y
    lda ball_y_tbl+2
    sta $d007                   ; Sprite 3 Y

    lda ball_x_tbl
    sta $d002                   ; Sprite 1 X
    lda ball_x_tbl+1
    sta $d004                   ; Sprite 2 X
    lda ball_x_tbl+2
    sta $d006                   ; Sprite 3 X

    ; --- Enable sprites 0-3 ---

    lda $d015
    ora #%00001111              ; Sprites 0-3
    sta $d015

    ; --- SID setup ---

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

    ; --- Draw HUD ---

    jsr draw_hud
    jsr show_lives
    jsr show_score

    ; --- Game loop ---

loop:
    jsr read_input
    jsr animate_balls
    jsr check_collisions
    jsr update_bucket
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

; --- Animate all balls using indexed loop ---

animate_balls:
    ldx #0                      ; Ball index (0, 1, 2)
    stx $0a                     ; VIC register offset (0, 2, 4)

ab_loop:
    ; Increment Y position for this ball
    inc ball_y_tbl,x
    lda ball_y_tbl,x

    ; Write Y to VIC-II (sprite 1+x Y register)
    ldy $0a                     ; VIC register offset
    sta $d003,y                 ; $D003, $D005, $D007

    ; Check if past bottom
    cmp #250
    bcc ab_next

    ; Check if this ball was caught
    lda caught
    and bit_mask,x              ; Test this ball's caught bit
    bne ab_do_reset

    ; Missed! Lose a life — save registers before subroutine calls
    txa
    pha                         ; Save ball index
    lda $0a
    pha                         ; Save VIC offset

    dec lives
    jsr show_lives
    jsr sfx_miss

    pla
    sta $0a                     ; Restore VIC offset
    pla
    tax                         ; Restore ball index

    lda lives
    bne ab_do_reset

    ; Game over
    jsr sfx_gameover
    lda #$02
    sta $d020
    lda #$00
    sta $d021
ab_halt:
    jmp ab_halt

ab_do_reset:
    ; Clear caught flag for this ball
    lda bit_mask,x
    eor #$ff                    ; Invert: create clear mask
    and caught                  ; Clear just this ball's bit
    sta caught

    ; Reset Y to top (staggered slightly)
    lda #50
    sta ball_y_tbl,x

    ldy $0a
    sta $d003,y                 ; Update VIC Y register

    ; Random X position
    lda $d41b
    sta $d002,y                 ; Update VIC X register
    sta ball_x_tbl,x

    ; Clear this ball's MSB
    lda $d010
    and msb_clear_tbl,x
    sta $d010

ab_next:
    inx
    inc $0a
    inc $0a                     ; VIC offset += 2
    cpx #NUM_BALLS
    bne ab_loop
    rts

; --- Check collisions for all balls ---

check_collisions:
    lda $d01e                   ; Read collision register (clears on read)
    sta $0b                     ; Save collision state
    and #%00000001              ; Was sprite 0 involved?
    beq cc_done                 ; No collision with bucket

    ; Check each ball
    ldx #0
cc_loop:
    lda $0b
    and bit_mask_spr,x          ; Check if sprite 1+x collided
    beq cc_next

    ; This ball hit the bucket — was it already caught?
    lda caught
    and bit_mask,x
    bne cc_next                 ; Already counted

    ; Mark as caught
    lda caught
    ora bit_mask,x
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
    jsr sfx_catch

cc_next:
    inx
    cpx #NUM_BALLS
    bne cc_loop

cc_done:
    rts

; --- Update bucket position ---

update_bucket:
    lda sprite_x
    sta $d000
    lda sprite_x_h
    and #%00000001
    beq ub_clear
    lda $d010
    ora #%00000001
    sta $d010
    rts
ub_clear:
    lda $d010
    and #%11111110
    sta $d010
    rts

; --- Sound effects ---

sfx_catch:
    lda #$25
    sta $d400
    lda #$1c
    sta $d401
    lda #$09
    sta $d405
    lda #$00
    sta $d406
    lda #$11                    ; Triangle + gate
    sta $d404
    lda #$10                    ; Gate off
    sta $d404
    rts

sfx_miss:
    lda #$00
    sta $d400
    lda #$08
    sta $d401
    lda #$09
    sta $d405
    lda #$00
    sta $d406
    lda #$21                    ; Sawtooth + gate
    sta $d404
    lda #$20                    ; Gate off
    sta $d404
    rts

sfx_gameover:
    lda #$09
    sta $d405
    lda #$00
    sta $d406
    lda #$11
    sta $d404
    ldx #$1c
go_desc:
    stx $d401
    ldy #$ff
go_d:
    dey
    bne go_d
    dex
    cpx #$04
    bne go_desc
    lda #$10
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

show_lives:
    lda lives
    clc
    adc #$30
    sta $0428
    rts

show_score:
    lda score_lo
    sta $0d
    lda score_hi
    sta $0e
    ldx #0
ss_h:
    lda $0d
    sec
    sbc #100
    tay
    lda $0e
    sbc #0
    bcc ss_hd
    sta $0e
    sty $0d
    inx
    jmp ss_h
ss_hd:
    txa
    clc
    adc #$30
    sta $0406
    lda $0d
    ldx #0
ss_t:
    cmp #10
    bcc ss_td
    sec
    sbc #10
    inx
    jmp ss_t
ss_td:
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
    ldx #$04                    ; Shorter delay (more balls = more action)
dl_outer:
    ldy #$ff
dl_inner:
    dey
    bne dl_inner
    dex
    bne dl_outer
    rts

; =============================================
; Data tables
; =============================================

; Bit masks for ball index 0-2
bit_mask:
    !byte %00000001, %00000010, %00000100

; Bit masks for sprite collision (sprites 1-3)
bit_mask_spr:
    !byte %00000010, %00000100, %00001000

; MSB clear masks (clear bits 1-3 for sprites 1-3)
msb_clear_tbl:
    !byte %11111101, %11111011, %11110111

; Ball Y positions
ball_y_tbl:
    !byte 50, 120, 190

; Ball X positions
ball_x_tbl:
    !byte 80, 160, 120

; --- Sprite Data ---
* = $0d00                       ; Bucket sprite (pointer = 52)

bucket_data:
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $ff,$ff,$ff
    !byte $ff,$ff,$ff
    !byte $7f,$ff,$fe
    !byte $7f,$ff,$fe
    !byte $3f,$ff,$fc
    !byte $3f,$ff,$fc
    !byte $1f,$ff,$f8
    !byte $1f,$ff,$f8
    !byte $0f,$ff,$f0

* = $0d40                       ; Ball sprite (pointer = 53)

ball_data:
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$3c,$00
    !byte $00,$7e,$00
    !byte $00,$ff,$00
    !byte $00,$ff,$00
    !byte $00,$ff,$00
    !byte $00,$ff,$00
    !byte $00,$7e,$00
    !byte $00,$3c,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
