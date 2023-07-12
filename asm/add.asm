PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E = %10000000
RW = %01000000
RS = %00100000

value = $0200           ; 2 bytes
remainder = $0202       ; 2 bytes
message = $0204         ; 6 bytes


    .org $8000

reset:
    ldx #$ff
    txs

    lda #%11111111      ; Set all pins on Port B to output
    sta DDRB
    lda #%11100000      ; Set top 3 pins on Port A to output
    sta DDRA

    lda #%00111000      ; set 8 bit mode, 2 line display, 5x8 font
    jsr lcd_instruction
    lda #%00001110      ; Display on; cursor on; blink off
    jsr lcd_instruction
    lda #%00000110      ; Increment; no scroll
    jsr lcd_instruction
    lda #%00000001      ; Clear Display
    jsr lcd_instruction

    ; Initialize message to 0 to form null terminated message
    lda #0
    sta message

    ; Initialize value to be the number to convert
    lda number
    sta value
    lda number + 1
    sta value + 1

divide:
    ; Initialize the remainder to zero
    lda #0
    sta remainder
    sta remainder + 1
    clc

    ldx #16
divloop:
    ; Rotate value and remainder left with carry
    rol value
    rol value + 1
    rol remainder
    rol remainder + 1

    ; a and y register have result of subtraction
    sec
    lda remainder
    sbc #10
    tay ; save low byte in y
    lda remainder + 1
    sbc #0
    bcc ignore_result   ; branch if dividend < divisor
    sty remainder
    sta remainder + 1

ignore_result:
    dex
    bne divloop

    rol value
    rol value + 1
    
    lda remainder
    clc
    adc #"0"
    jsr push_char
    
    ; if value != 0, then continue dividing
    lda value
    ora value + 1
    bne divide  ; branch if value is not zero

    ldx #0
print_loop:
    lda message, x
    beq end_print
    jsr print_char
    inx
    jmp print_loop
end_print:


loop:
    jmp loop

number: .word 0

; add the character in a reg to the beginning of the
; null-terminated string 'message'
push_char:
    pha ; push new first char on stack
    ldx #0

char_loop:
    lda message, x  ; get char on string and put on a reg
    tay
    pla
    sta message, x  ; pull char off stack and add to message
    inx
    tya
    pha             ; Push char from string onto stack
    bne char_loop
    
    pla
    sta message, x  ; pull null and add to end of string

    rts


lcd_wait:
    pha             ; push current a reg onto stack
    lda #0          ; set Port B as all inputs
    sta DDRB
lcd_busy:
    lda #RW
    sta PORTA
    lda #(RW|E)
    sta PORTA
    lda PORTB       ; read busy flag

    and #%10000000  ; Only check busy flag
    bne lcd_busy    ; Branch if busy flag is set

    lda #RW
    sta PORTA
    lda #$ff        ; set Port B as all outputs
    sta DDRB
    pla             ; pull original a reg from stack
    rts


lcd_instruction:
    jsr lcd_wait
    sta PORTB
    lda #0              ; Clear RS/RW/E bits
    sta PORTA
    lda #E              ; Set E bit to send instruction
    sta PORTA
    lda #0              ; Clear RS/RW/E bits
    sta PORTA
    rts


print_char:
    jsr lcd_wait
    sta PORTB
    lda #RS             ; Clear RW/E bits; Set RS to 1
    sta PORTA
    lda #(RS|E)         ; Set E bit to send instruction
    sta PORTA
    lda #RS             ; Clear RW/E bits; Set RS to 1
    sta PORTA
    rts


next_line:
    pha
    lda #%11000000
    jsr lcd_instruction
    pla
    rts



    .org $fffc
    .word reset
    .word $0000


