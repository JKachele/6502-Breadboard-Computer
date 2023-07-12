PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E = %10000000
RW = %01000000
RS = %00100000

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


message: .asciiz "Hello, World!"

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


