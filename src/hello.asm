; hello.asm - Minimal C64 program
; Changes border color to black and returns to BASIC

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2064
!byte $0c, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2064"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

* = $0810                       ; Code start (2064 decimal)

    lda #$00                    ; Load black (0) into accumulator
    sta $d020                   ; Store to border color register
    sta $d021                   ; Store to background color too
    rts                         ; Return to BASIC
