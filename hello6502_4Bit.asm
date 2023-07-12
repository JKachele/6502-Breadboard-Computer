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

interrupt_count = $0200 ; 1 byte

    .org $8000

reset:
    ldx #$ff
    txs
    cli                 ; Enable interrupts
    lda #%10000010      ; Set interrupt enable for CA1
    sta IER
    lda #0
    sta PCR
    sta interrupt_count ; set interrupt counter to 0

    lda #%11111111 ; Set all pins on port B to output
    sta DDRB
    lda #%10111111 ; Set all pins except 6 on port A to output
    sta DDRA

    jsr lcd_init

    ldx #0
print_loop1:
    lda message, x
    beq end_print1
    jsr print_char
    inx
    jmp print_loop1
end_print1:

    jsr next_line
    ldx #0
print_loop2:
    lda message1, x
    beq end_print2
    jsr print_char
    inx
    jmp print_loop2
end_print2:

loop:
    jmp loop            ; infinite loop


message: .asciiz "Hello, World!"
message1: .asciiz "Hello, Justin!"
message2: .asciiz "Odd"
message3: .asciiz "Even"
message4: .asciiz "Interrupt!"


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

    jsr lcd_clear

    lda interrupt_count
    bne print2

    lda #1
    sta interrupt_count
    ldx #0
print_loop3:
    lda message2, x
    beq end_print3
    jsr print_char
    inx
    jmp print_loop3
end_print3:
    jmp end_print4

print2:
    lda #0
    sta interrupt_count
    ldx #0
print_loop4:
    lda message3, x
    beq end_print4
    jsr print_char
    inx
    jmp print_loop4
end_print4:
    jsr next_line
    ldx #0
print_loop5:
    lda message4, x
    beq end_print5
    jsr print_char
    inx
    jmp print_loop5
end_print5:
    
    bit PORTA       ; Read Port A to clear Interrupt
    ; Pull y, x, and a from stack
    pla
    tay
    pla
    tax
    pla

    rti

; Reset/IRQ vectors
    .org $fffa
    .word nmi
    .word reset
    .word irq


