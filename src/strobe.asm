; strobe.asm - Hold fire for color strobe effect
; Fire = cycle border colors, Release = stop

* = $0801                       ; BASIC start address

; BASIC stub: 10 SYS 2064
!byte $0c, $08                  ; Pointer to next BASIC line
!byte $0a, $00                  ; Line number 10
!byte $9e                       ; SYS token
!text "2064"                    ; Address as ASCII
!byte $00                       ; End of line
!byte $00, $00                  ; End of BASIC program

* = $0810                       ; Code start (2064 decimal)

loop:
    lda $dc00                   ; Read joystick port 2
    and #%00010000              ; Test fire (bit 4)
    bne loop                    ; Not pressed -> keep waiting

    inc $d020                   ; Next border color

    ldx #$20                    ; Outer loop: 32 iterations
delay_outer:
    ldy #$ff                    ; Inner loop: 255 iterations
delay_inner:
    dey                         ; Decrement Y
    bne delay_inner             ; Loop until Y = 0
    dex                         ; Decrement X
    bne delay_outer             ; Loop until X = 0

    jmp loop                    ; Back to main loop
