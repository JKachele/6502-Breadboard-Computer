PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600c
IFR = $600d
IER = $600e

E  = %01000000
RW = %00100000
RS = %00010000


value = $0200           ; 2 bytes
remainder = $0202       ; 2 bytes
message = $0204         ; 6 bytes
counter = $020a         ; 2 bytes


    .org $8000

reset:
    ldx #$ff
    txs                 ; initialize stack pointer
    cli                 ; Enable interrupts
    lda #%10000010      ; Set interrupt enable for CA1
    sta IER
    lda #0
    sta PCR

    lda #%11111111      ; Set all pins on Port B to output
    sta DDRB
    lda #%11100000      ; Set top 3 pins on Port A to output
    sta DDRA

    jsr lcd_init

    lda #0
    sta counter
    sta counter + 1

loop:
    lda #%00000010      ; Home Display
    jsr lcd_instruction

    ; Initialize message to 0 to form null terminated message
    lda #0
    sta message

    ; Initialize value to be the number to convert
    sei
    lda counter
    sta value
    lda counter + 1
    sta value + 1
    cli

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

    jmp loop


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

lcd_init:
    lda #%00000010 ; Set 4-bit mode
    jsr lcd_instruction
    lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
    jsr lcd_instruction
    lda #%00001110 ; Display on; cursor on; blink off
    jsr lcd_instruction
    lda #%00000110 ; Increment and shift cursor; don't shift display
    jsr lcd_instruction
    lda #%00000001 ; Clear display
    jsr lcd_instruction
    rts

lcd_clear:
    lda #%00000001 ; Clear display
    jsr lcd_instruction
    rts

lcd_wait:
    pha
    lda #%11110000  ; LCD data is input
    sta DDRB
lcd_busy:
    lda #RW
    sta PORTB
    lda #(RW | E)
    sta PORTB
    lda PORTB       ; Read high nibble
    pha             ; and put on stack since it has the busy flag
    lda #RW
    sta PORTB
    lda #(RW | E)
    sta PORTB
    lda PORTB       ; Read low nibble
    pla             ; Get high nibble off stack
    and #%00001000
    bne lcd_busy

    lda #RW
    sta PORTB
    lda #%11111111  ; LCD data is output
    sta DDRB
    pla
    rts

lcd_instruction:
    jsr lcd_wait
    pha
    lsr
    lsr
    lsr
    lsr            ; Send high 4 bits
    sta PORTB
    ora #E         ; Set E bit to send instruction
    sta PORTB
    eor #E         ; Clear E bit
    sta PORTB
    pla
    and #%00001111 ; Send low 4 bits
    sta PORTB
    ora #E         ; Set E bit to send instruction
    sta PORTB
    eor #E         ; Clear E bit
    sta PORTB
    rts

print_char:
    jsr lcd_wait
    pha
    lsr
    lsr
    lsr
    lsr             ; Send high 4 bits
    ora #RS         ; Set RS
    sta PORTB
    ora #E          ; Set E bit to send instruction
    sta PORTB
    eor #E          ; Clear E bit
    sta PORTB
    pla
    and #%00001111  ; Send low 4 bits
    ora #RS         ; Set RS
    sta PORTB
    ora #E          ; Set E bit to send instruction
    sta PORTB
    eor #E          ; Clear E bit
    sta PORTB
    rts

next_line:
    pha
    lda #%11000000
    jsr lcd_instruction
    pla
    rts


nmi:
irq:
    ; Push a, x, and y to stack
    pha
    txa
    pha
    tya
    pha

    inc counter
    bne exit_irq
    inc counter + 1
exit_irq:
    bit PORTA       ; Read Port A to clear Interrupt
    ; Pull y, x, and a from stack
    pla
    tay
    pla
    tax
    pla

    rti

    .org $fffa
    .word nmi
    .word reset
    .word irq



