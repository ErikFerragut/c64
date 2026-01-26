; game.asm - Bucket Brigade: Complete Game
; Title screen, gameplay, game over, high score

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2064
!byte $0c, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2064"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

* = $0810                       ; Code start (2064 decimal)

; --- Zero page variables ---

sprite_x   = $02                ; Bucket X low byte
sprite_x_h = $03                ; Bucket X high byte
lives      = $04
score_lo   = $05
score_hi   = $06
caught     = $07                ; Caught flags for balls
level      = $08
fall_speed = $09
game_state = $0a                ; 0=title, 1=playing, 2=game over
hiscore_lo = $0b                ; High score low byte
hiscore_hi = $0c                ; High score high byte

NUM_BALLS  = 3

; =============================================
; Main entry point
; =============================================

    lda #0
    sta hiscore_lo
    sta hiscore_hi

    ; SID setup
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

    ; Fall through to title screen

; =============================================
; Title Screen
; =============================================

title_screen:
    lda #0
    sta game_state

    ; Disable all sprites
    lda #0
    sta $d015

    ; Set colors
    lda #$06                    ; Blue
    sta $d020
    lda #$06
    sta $d021

    ; Clear screen
    jsr clear_screen

    ; Draw title text
    ; Row 5: "BUCKET BRIGADE" centered (col 13)
    ldx #0
ts_title:
    lda title_text,x
    beq ts_hi                   ; Zero terminator
    sta $0400 + 5*40 + 13,x
    lda #$01                    ; White
    sta $d800 + 5*40 + 13,x
    inx
    jmp ts_title

    ; Row 10: "HIGH SCORE:" (col 12)
ts_hi:
    ldx #0
ts_hi_loop:
    lda hiscore_text,x
    beq ts_prompt
    sta $0400 + 10*40 + 12,x
    lda #$07                    ; Yellow
    sta $d800 + 10*40 + 12,x
    inx
    jmp ts_hi_loop

    ; Show high score digits at row 10, col 24
ts_prompt:
    jsr show_hiscore

    ; Row 15: "PRESS FIRE TO START" (col 10)
    ldx #0
ts_pr:
    lda press_text,x
    beq ts_wait
    sta $0400 + 15*40 + 10,x
    lda #$03                    ; Cyan
    sta $d800 + 15*40 + 10,x
    inx
    jmp ts_pr

    ; Wait for fire button
ts_wait:
    jsr wait_vblank
    lda $dc00
    and #%00010000              ; Fire button
    bne ts_wait                 ; Not pressed: keep waiting

    ; Debounce: wait for release
ts_release:
    lda $dc00
    and #%00010000
    beq ts_release              ; Still pressed: wait

    jmp start_game

; =============================================
; Start Game
; =============================================

start_game:
    lda #1
    sta game_state

    ; Reset game state
    lda #3
    sta lives
    lda #0
    sta score_lo
    sta score_hi
    sta caught
    lda #1
    sta level
    sta fall_speed

    ; Clear screen and draw HUD
    jsr clear_screen
    jsr draw_hud
    jsr show_lives
    jsr show_score
    jsr show_level

    ; Set colors
    lda #$0e                    ; Light blue
    sta $d020
    lda #$06                    ; Blue
    sta $d021

    ; Setup bucket (sprite 0)
    lda #172
    sta sprite_x
    lda #0
    sta sprite_x_h

    lda #56                     ; Bucket at $0E00 (56 x 64)
    sta $07f8
    lda #224
    sta $d001
    lda #$01                    ; White
    sta $d027

    ; Setup balls (sprites 1-3)
    lda #57                     ; Ball at $0E40 (57 x 64)
    sta $07f9
    sta $07fa
    sta $07fb

    lda #$02
    sta $d028
    lda #$07
    sta $d029
    lda #$05
    sta $d02a

    lda #50
    sta ball_y_tbl
    sta $d003
    lda #120
    sta ball_y_tbl+1
    sta $d005
    lda #190
    sta ball_y_tbl+2
    sta $d007

    lda #80
    sta $d002
    lda #160
    sta $d004
    lda #120
    sta $d006

    ; Clear all MSBs
    lda #0
    sta $d010

    ; Enable sprites
    lda #%00001111
    sta $d015

    ; Update bucket position
    jsr update_bucket

    ; --- Main game loop ---

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

go_to_gameover:
    jmp game_over_screen

; =============================================
; Game Over Screen
; =============================================

game_over_screen:
    ; Update high score if needed
    lda score_hi
    cmp hiscore_hi
    bcc go_no_hiscore           ; score_hi < hiscore_hi
    bne go_new_hiscore          ; score_hi > hiscore_hi
    lda score_lo
    cmp hiscore_lo
    bcc go_no_hiscore           ; score_lo < hiscore_lo

go_new_hiscore:
    lda score_lo
    sta hiscore_lo
    lda score_hi
    sta hiscore_hi

go_no_hiscore:
    ; Disable sprites
    lda #0
    sta $d015

    ; Set colors
    lda #$02                    ; Red
    sta $d020
    lda #$00                    ; Black
    sta $d021

    jsr clear_screen

    ; "GAME OVER" at row 5, col 15
    ldx #0
go_title:
    lda gameover_text,x
    beq go_score
    sta $0400 + 5*40 + 15,x
    lda #$02                    ; Red
    sta $d800 + 5*40 + 15,x
    inx
    jmp go_title

    ; "YOUR SCORE:" at row 9, col 14
go_score:
    ldx #0
go_sc_loop:
    lda yourscore_text,x
    beq go_show_sc
    sta $0400 + 9*40 + 14,x
    lda #$01                    ; White
    sta $d800 + 9*40 + 14,x
    inx
    jmp go_sc_loop

go_show_sc:
    ; Show final score at row 9, col 26
    jsr show_gameover_score

    ; "PRESS FIRE TO RETRY" at row 15, col 10
    ldx #0
go_pr:
    lda retry_text,x
    beq go_wait
    sta $0400 + 15*40 + 10,x
    lda #$03                    ; Cyan
    sta $d800 + 15*40 + 10,x
    inx
    jmp go_pr

go_wait:
    jsr wait_vblank
    lda $dc00
    and #%00010000
    bne go_wait

go_release:
    lda $dc00
    and #%00010000
    beq go_release

    jmp title_screen

; =============================================
; Subroutines
; =============================================

; --- Wait for vertical blank ---

wait_vblank:
    lda $d011
    and #%10000000
    bne wait_vblank
wv_low:
    lda $d012
    cmp #251
    bcc wv_low
    rts

; --- Clear screen ---

clear_screen:
    ldx #0
    lda #$20                    ; Space character
cs_loop:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    dex
    bne cs_loop
    rts

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
    sbc #2
    sta sprite_x
    lda sprite_x_h
    sbc #0
    sta sprite_x_h
    rts

ri_right:
    lda sprite_x
    clc
    adc #2
    sta sprite_x
    lda sprite_x_h
    adc #0
    sta sprite_x_h
    rts

; --- Animate balls ---

animate_balls:
    ldx #0
    stx $10                     ; VIC register offset

ab_loop:
    lda ball_y_tbl,x
    clc
    adc fall_speed
    sta ball_y_tbl,x

    ldy $10
    sta $d003,y

    cmp #250
    bcc ab_next

    lda caught
    and bit_mask,x
    bne ab_do_reset

    ; Missed
    txa
    pha
    lda $10
    pha

    dec lives
    jsr show_lives
    jsr sfx_miss

    pla
    sta $10
    pla
    tax

    lda lives
    bne ab_do_reset

    ; Game over — set state and return
    lda #2
    sta game_state
    rts

ab_do_reset:
    lda bit_mask,x
    eor #$ff
    and caught
    sta caught

    lda #50
    sta ball_y_tbl,x

    ldy $10
    sta $d003,y

    lda $d41b
    sta $d002,y

    lda $d010
    and msb_clear_tbl,x
    sta $d010

ab_next:
    inx
    inc $10
    inc $10
    cpx #NUM_BALLS
    bne ab_loop
    rts

; --- Check collisions ---

check_collisions:
    lda $d01e
    sta $11
    and #%00000001
    beq cc_done

    ldx #0
cc_loop:
    lda $11
    and bit_mask_spr,x
    beq cc_next

    lda caught
    and bit_mask,x
    bne cc_next

    lda caught
    ora bit_mask,x
    sta caught

    txa
    pha

    lda score_lo
    clc
    adc #10
    sta score_lo
    lda score_hi
    adc #0
    sta score_hi
    jsr show_score
    jsr sfx_catch

    pla
    tax

cc_next:
    inx
    cpx #NUM_BALLS
    bne cc_loop

cc_done:
    rts

; --- Check level ---

check_level:
    lda score_hi
    bne cl_4

    lda score_lo
    cmp #150
    bcs cl_4
    cmp #100
    bcs cl_3
    cmp #50
    bcs cl_2

    lda #1
    sta fall_speed
    lda #1
    jmp cl_set
cl_2:
    lda #2
    sta fall_speed
    lda #2
    jmp cl_set
cl_3:
    lda #2
    sta fall_speed
    lda #3
    jmp cl_set
cl_4:
    lda #3
    sta fall_speed
    lda #4
cl_set:
    cmp level
    beq cl_done
    sta level
    jsr show_level
    jsr sfx_level
cl_done:
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
    lda #$11
    sta $d404
    lda #$10
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
    lda #$21
    sta $d404
    lda #$20
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

sfx_level:
    lda #$09
    sta $d405
    lda #$00
    sta $d406
    lda #$10
    sta $d401
    lda #$11
    sta $d404
    ldx #$10
sl_asc:
    stx $d401
    ldy #$80
sl_d:
    dey
    bne sl_d
    inx
    cpx #$20
    bne sl_asc
    lda #$10
    sta $d404
    rts

; --- Draw HUD ---

draw_hud:
    lda #19                     ; S
    sta $0400
    lda #3                      ; C
    sta $0401
    lda #15                     ; O
    sta $0402
    lda #18                     ; R
    sta $0403
    lda #5                      ; E
    sta $0404
    lda #58                     ; :
    sta $0405

    lda #12                     ; L
    sta $0410
    lda #22                     ; V
    sta $0411
    lda #12                     ; L
    sta $0412
    lda #58                     ; :
    sta $0413

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

show_level:
    lda level
    clc
    adc #$30
    sta $0414
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

; --- Show high score on title screen (row 10, col 24) ---

show_hiscore:
    lda hiscore_lo
    sta $0d
    lda hiscore_hi
    sta $0e
    ldx #0
sh_h:
    lda $0d
    sec
    sbc #100
    tay
    lda $0e
    sbc #0
    bcc sh_hd
    sta $0e
    sty $0d
    inx
    jmp sh_h
sh_hd:
    txa
    clc
    adc #$30
    sta $0400 + 10*40 + 24
    lda #$07                    ; Yellow
    sta $d800 + 10*40 + 24
    lda $0d
    ldx #0
sh_t:
    cmp #10
    bcc sh_td
    sec
    sbc #10
    inx
    jmp sh_t
sh_td:
    pha
    txa
    clc
    adc #$30
    sta $0400 + 10*40 + 25
    lda #$07
    sta $d800 + 10*40 + 25
    pla
    clc
    adc #$30
    sta $0400 + 10*40 + 26
    lda #$07
    sta $d800 + 10*40 + 26
    rts

; --- Show score on game over screen (row 9, col 26) ---

show_gameover_score:
    lda score_lo
    sta $0d
    lda score_hi
    sta $0e
    ldx #0
sg_h:
    lda $0d
    sec
    sbc #100
    tay
    lda $0e
    sbc #0
    bcc sg_hd
    sta $0e
    sty $0d
    inx
    jmp sg_h
sg_hd:
    txa
    clc
    adc #$30
    sta $0400 + 9*40 + 26
    lda #$01
    sta $d800 + 9*40 + 26
    lda $0d
    ldx #0
sg_t:
    cmp #10
    bcc sg_td
    sec
    sbc #10
    inx
    jmp sg_t
sg_td:
    pha
    txa
    clc
    adc #$30
    sta $0400 + 9*40 + 27
    lda #$01
    sta $d800 + 9*40 + 27
    pla
    clc
    adc #$30
    sta $0400 + 9*40 + 28
    lda #$01
    sta $d800 + 9*40 + 28
    rts

; =============================================
; Data
; =============================================

bit_mask:
    !byte %00000001, %00000010, %00000100

bit_mask_spr:
    !byte %00000010, %00000100, %00001000

msb_clear_tbl:
    !byte %11111101, %11111011, %11110111

ball_y_tbl:
    !byte 50, 120, 190

; Text strings (screen codes, zero-terminated)
title_text:
    !scr "BUCKET BRIGADE",0

hiscore_text:
    !scr "HIGH SCORE:",0

press_text:
    !scr "PRESS FIRE TO START",0

gameover_text:
    !scr "GAME OVER",0

yourscore_text:
    !scr "YOUR SCORE:",0

retry_text:
    !scr "PRESS FIRE TO RETRY",0

; --- Sprite Data ---
* = $0e00                       ; Bucket sprite (pointer = 56)

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

* = $0e40                       ; Ball sprite (pointer = 57)

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
