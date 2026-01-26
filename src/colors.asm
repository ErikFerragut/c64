; colors.asm - Press keys to change the border color
; Keys: 1 = black, 2 = red, 3 = blue, Q = quit

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
    jsr $ffe4                   ; Call GETIN: read key into A
    beq loop                    ; No key pressed? Keep waiting

    cmp #$31                    ; Was it "1"?
    bne not_one                 ;   No: skip ahead
    lda #$00                    ;   Yes: load black
    sta $d020                   ;   Set border color
    jmp loop                    ;   Back to waiting

not_one:
    cmp #$32                    ; Was it "2"?
    bne not_two
    lda #$02                    ; Red
    sta $d020
    jmp loop

not_two:
    cmp #$33                    ; Was it "3"?
    bne not_three
    lda #$06                    ; Blue
    sta $d020
    jmp loop

not_three:
    cmp #$51                    ; Was it "Q"?
    beq done                    ;   Yes: quit

    jmp loop                    ; Unknown key, ignore it

done:
    rts                         ; Return to BASIC
