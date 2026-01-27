; levels.asm - Difficulty progression
; Speed increases with score, raster-timed game loop

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
caught     = $07                ; Caught flags (bits 0-2)
level      = $08                ; Current level (1-4)
fall_speed = $09                ; Pixels per frame for balls

NUM_BALLS  = 3

    ; --- Initialize game state ---

    lda #3
    sta lives
    lda #0
    sta score_lo
    sta score_hi
    sta caught
    lda #1
    sta level
    sta fall_speed              ; Start: 1 pixel per frame

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

    ; --- Initialize ball sprites (sprites 1-3) ---

    lda #34                     ; Ball data at $0880 (34 x 64)
    sta $07f9
    sta $07fa
    sta $07fb

    lda #$02                    ; Red
    sta $d028
    lda #$07                    ; Yellow
    sta $d029
    lda #$05                    ; Green
    sta $d02a

    ; Staggered start positions
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
    sta ball_x_tbl
    sta $d002
    lda #160
    sta ball_x_tbl+1
    sta $d004
    lda #120
    sta ball_x_tbl+2
    sta $d006

    ; --- Enable sprites 0-3 ---

    lda $d015
    ora #%00001111
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
    jsr show_level

    ; --- Game loop ---

loop:
    ; Wait for vertical blank (raster line 251)
    jsr wait_vblank

    jsr read_input
    jsr animate_balls
    jsr check_collisions
    jsr update_bucket
    jsr check_level
    jmp loop

; =============================================
; Subroutines
; =============================================

; --- Wait for vertical blank ---
; Synchronizes game loop to display refresh (~60 Hz on NTSC, ~50 Hz on PAL)

wait_vblank:
    lda $d011                   ; Read control register (bit 7 = raster bit 8)
    and #%10000000              ; Isolate raster high bit
    bne wait_vblank             ; Wait if raster > 255

wv_low:
    lda $d012                   ; Read raster line (low 8 bits)
    cmp #251                    ; Reached line 251?
    bcc wv_low                  ; Not yet: keep waiting
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
    sbc #2                      ; Move 2 pixels (faster bucket)
    sta sprite_x
    lda sprite_x_h
    sbc #0
    sta sprite_x_h
    rts

ri_right:
    lda sprite_x
    clc
    adc #2                      ; Move 2 pixels
    sta sprite_x
    lda sprite_x_h
    adc #0
    sta sprite_x_h
    rts

; --- Animate all balls ---

animate_balls:
    ldx #0                      ; Ball index
    stx $10                     ; VIC register offset

ab_loop:
    ; Move ball down by fall_speed pixels
    lda ball_y_tbl,x
    clc
    adc fall_speed              ; Add speed (1, 2, 3, or 4)
    sta ball_y_tbl,x

    ; Write Y to VIC-II
    ldy $10
    sta $d003,y

    ; Check if past bottom
    cmp #250
    bcc ab_next

    ; Check caught flag
    lda caught
    and bit_mask,x
    bne ab_do_reset

    ; Missed — save registers, then handle
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

    jsr sfx_gameover
    lda #$02
    sta $d020
    lda #$00
    sta $d021
ab_halt:
    jmp ab_halt

ab_do_reset:
    ; Clear caught flag
    lda bit_mask,x
    eor #$ff
    and caught
    sta caught

    ; Reset to top
    lda #50
    sta ball_y_tbl,x

    ldy $10
    sta $d003,y

    ; Random X
    lda $d41b
    sta $d002,y
    sta ball_x_tbl,x

    ; Clear MSB
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

    ; Save X before subroutine calls
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

; --- Check if score triggers new level ---

check_level:
    ; Level 1: 0-49    speed 1
    ; Level 2: 50-99   speed 2
    ; Level 3: 100-149 speed 2
    ; Level 4: 150+    speed 3

    lda score_hi
    bne cl_high                 ; Score >= 256? Level 4

    lda score_lo
    cmp #150
    bcs cl_4
    cmp #100
    bcs cl_3
    cmp #50
    bcs cl_2

    ; Level 1
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

cl_high:
cl_4:
    lda #3
    sta fall_speed
    lda #4

cl_set:
    cmp level                   ; Changed?
    beq cl_done
    sta level
    jsr show_level
    jsr sfx_level               ; Level-up sound
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
    ; Quick ascending beep
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

; =============================================
; Data tables
; =============================================

bit_mask:
    !byte %00000001, %00000010, %00000100

bit_mask_spr:
    !byte %00000010, %00000100, %00001000

msb_clear_tbl:
    !byte %11111101, %11111011, %11110111

ball_y_tbl:
    !byte 50, 120, 190

ball_x_tbl:
    !byte 80, 160, 120
