; joystick.asm - Read joystick port 2 and change border color
; Up = white, Down = black, Left = red, Right = cyan, Fire = green

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
    and #%00000001              ; Test bit 0 (up)
    beq up                      ; Bit clear = pressed

    lda $dc00                   ; Re-read (AND destroyed A)
    and #%00000010              ; Test bit 1 (down)
    beq down

    lda $dc00                   ; Re-read
    and #%00000100              ; Test bit 2 (left)
    beq left

    lda $dc00                   ; Re-read
    and #%00001000              ; Test bit 3 (right)
    beq right

    lda $dc00                   ; Re-read
    and #%00010000              ; Test bit 4 (fire)
    beq fire

    jmp loop                    ; No input, keep polling

up:
    lda #$01                    ; White
    sta $d020                   ; Set border
    jmp loop

down:
    lda #$00                    ; Black
    sta $d020
    jmp loop

left:
    lda #$02                    ; Red
    sta $d020
    jmp loop

right:
    lda #$03                    ; Cyan
    sta $d020
    jmp loop

fire:
    lda #$05                    ; Green
    sta $d020                   ; Set border
    sta $d021                   ; Set background too
    jmp loop
