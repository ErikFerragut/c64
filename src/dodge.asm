; dodge.asm - Dodge falling objects
; Collision detection, subroutines, and game over

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
ball_y     = $04                ; Ball Y position
lives      = $05                ; Lives remaining
score      = $06                ; Score (balls dodged)

    ; --- Initialize game state ---

    lda #3
    sta lives
    lda #0
    sta score

    ; --- Initialize bucket sprite (sprite 0) ---

    lda #172
    sta sprite_x
    lda #0
    sta sprite_x_h

    lda #38                     ; Bucket data at $0980 (38 x 64)
    sta $07f8

    lda #224                    ; Near bottom
    sta $d001

    lda #$01                    ; White
    sta $d027

    ; --- Initialize ball sprite (sprite 1) ---

    lda #39                     ; Ball data at $09C0 (39 x 64)
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
    jsr check_collision         ; Test for hits
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

    ; Ball passed bucket without collision — score!
    inc score

    ; Reset ball to top with random X
    lda #50
    sta ball_y
    sta $d003

    lda $d41b                   ; Random X from SID
    sta $d002

    lda $d010
    and #%11111101              ; Clear ball MSB
    sta $d010

ab_done:
    rts

; --- Check sprite collision register ---

check_collision:
    lda $d01e                   ; Read collision register (clears on read)
    and #%00000011              ; Sprites 0 and 1 both involved?
    cmp #%00000011
    bne cc_done                 ; No collision

    ; Collision! Lose a life
    dec lives
    jsr show_lives

    ; Flash border to show hit
    lda #$02                    ; Red
    sta $d020
    ldx #$20
cc_flash:
    ldy #$ff
cc_flash_inner:
    dey
    bne cc_flash_inner
    dex
    bne cc_flash

    lda #$0e                    ; Light blue (default)
    sta $d020

    ; Reset ball position
    lda #50
    sta ball_y
    sta $d003

    lda $d41b
    sta $d002

    lda $d010
    and #%11111101
    sta $d010

    ; Check for game over
    lda lives
    bne cc_done                 ; Still alive

    ; Game over
    lda #$02                    ; Red border
    sta $d020
    lda #$00                    ; Black background
    sta $d021

game_over:
    jmp game_over               ; Halt

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

; --- Display lives as border flashes (simple) ---

show_lives:
    ; Write lives digit to top-left of screen
    lda lives
    clc
    adc #$30                    ; Convert number to screen code for digit
    sta $0400                   ; Screen position: row 0, column 0
    lda #$01                    ; White
    sta $d800                   ; Color RAM for that position
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

; --- Sprite Data ---
* = $0980                       ; Bucket sprite (pointer = 38)

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

* = $09c0                       ; Ball sprite (pointer = 39)

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
