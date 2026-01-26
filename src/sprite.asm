; sprite.asm - Display a sprite on screen
; Your first C64 sprite!

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2064
!byte $0c, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2064"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

* = $0810                       ; Code start (2064 decimal)

    ; Set sprite 0 data pointer
    lda #33                     ; Sprite data at $0840 (33 x 64)
    sta $07f8                   ; Sprite 0 pointer

    ; Enable sprite 0
    lda $d015                   ; Read sprite enable register
    ora #%00000001              ; Set bit 0 (sprite 0)
    sta $d015                   ; Write back

    ; Position sprite (center bottom of screen)
    lda #172                    ; X position (~center)
    sta $d000                   ; Sprite 0 X
    lda #224                    ; Y position (near bottom)
    sta $d001                   ; Sprite 0 Y

    ; Set sprite color
    lda #$01                    ; White
    sta $d027                   ; Sprite 0 color

done:
    jmp done                    ; Loop forever (sprite stays visible)

; --- Sprite Data ---
* = $0840                       ; 64-byte aligned (pointer = 33)

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
