; bucket.asm - Move a sprite with the joystick
; Left/right controls the bucket at the bottom of the screen

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2064
!byte $0c, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2064"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

* = $0810                       ; Code start (2064 decimal)

sprite_x   = $02                ; Sprite X position, low byte
sprite_x_h = $03                ; Sprite X position, high byte (0 or 1)

    ; --- Initialize sprite ---

    ; Store starting position in zero page
    lda #172                    ; X = 172 (center)
    sta sprite_x
    lda #0                      ; High byte = 0 (X < 256)
    sta sprite_x_h

    ; Set sprite 0 data pointer
    lda #35                     ; Sprite data at $08C0 (35 x 64)
    sta $07f8                   ; Sprite 0 pointer

    ; Enable sprite 0
    lda $d015                   ; Read sprite enable register
    ora #%00000001              ; Set bit 0 (sprite 0)
    sta $d015                   ; Write back

    ; Set Y position (fixed at bottom)
    lda #224                    ; Y position (near bottom)
    sta $d001                   ; Sprite 0 Y

    ; Set sprite color
    lda #$01                    ; White
    sta $d027                   ; Sprite 0 color

    ; --- Game loop ---

loop:
    lda $dc00                   ; Read joystick port 2
    and #%00000100              ; Test bit 2 (left)
    beq move_left

    lda $dc00                   ; Re-read
    and #%00001000              ; Test bit 3 (right)
    beq move_right

    jmp update                  ; No movement input

move_left:
    lda sprite_x                ; Load X low byte
    sec                         ; Set carry (prepare to subtract)
    sbc #1                      ; Subtract 1
    sta sprite_x                ; Store result
    lda sprite_x_h              ; Load X high byte
    sbc #0                      ; Subtract borrow
    sta sprite_x_h              ; Store result
    jmp update

move_right:
    lda sprite_x                ; Load X low byte
    clc                         ; Clear carry (prepare to add)
    adc #1                      ; Add 1
    sta sprite_x                ; Store result
    lda sprite_x_h              ; Load X high byte
    adc #0                      ; Add carry
    sta sprite_x_h              ; Store result

update:
    ; Write X position to VIC-II
    lda sprite_x                ; Low 8 bits of X
    sta $d000                   ; Sprite 0 X position

    ; Update X position MSB (bit 8)
    lda sprite_x_h              ; High byte (0 or 1)
    and #%00000001              ; Isolate bit 0
    beq msb_clear

    lda $d010                   ; Read MSB register
    ora #%00000001              ; Set bit 0 (sprite 0)
    sta $d010                   ; Write back
    jmp delay

msb_clear:
    lda $d010                   ; Read MSB register
    and #%11111110              ; Clear bit 0 (sprite 0)
    sta $d010                   ; Write back

delay:
    ldx #$08                    ; Outer loop: 8 iterations
delay_outer:
    ldy #$ff                    ; Inner loop: 255 iterations
delay_inner:
    dey                         ; Decrement Y
    bne delay_inner             ; Loop until Y = 0
    dex                         ; Decrement X
    bne delay_outer             ; Loop until X = 0

    jmp loop                    ; Back to game loop

; --- Sprite Data ---
* = $08c0                       ; 64-byte aligned (pointer = 35)

sprite_data:
    ; Rows 0-11: empty
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    ; Row 12-13: rim (full width)
    !byte $ff,$ff,$ff
    !byte $ff,$ff,$ff
    ; Row 14-15: body tapers
    !byte $7f,$ff,$fe
    !byte $7f,$ff,$fe
    ; Row 16-17
    !byte $3f,$ff,$fc
    !byte $3f,$ff,$fc
    ; Row 18-19
    !byte $1f,$ff,$f8
    !byte $1f,$ff,$f8
    ; Row 20: bottom
    !byte $0f,$ff,$f0
