; VIA Addresses
PORTB = $6000
PORTA = $6001
DDRB  = $6002
DDRA  = $6003
T1CL  = $6004
T1CH  = $6005
PCR   = $600c
IFR   = $600d
IER   = $600e

; ACIA Addresses
ACIA_DATA   =   $5000
ACIA_Status =   $5001
ACIA_CMD    =   $5002
ACIA_CTRL   =   $5003

; LCD Instructions
E  = %01000000
RW = %00100000
RS = %00010000

    .org $8000

reset:
    ldx #$ff
    txs                 ; initialize stack pointer
    cli                 ; Enable interrupts
    lda #%10000010      ; Set interrupt enable for CA1
    sta IER
    lda #0
    sta PCR

    lda #%11111111 ; Set all pins on port B to output
    sta DDRB
    lda #%10111111 ; Set all pins except 6 on port A to output
    sta DDRA

    jsr lcd_init
    jsr acia_init
    
    ldx #0
send_message:
    lda message,x
    beq done
    jsr send_char
    inx
    jmp send_message
done:

rx_wait:
    lda ACIA_Status
    and #$08        ; check rx buffer status flag
    beq rx_wait     ; Loop if rx buffer empty (no data receved)

    lda ACIA_DATA
    jsr send_char   ; Echo
    jsr print_char
    jmp rx_wait

message: .asciiz "Hello, World!"

send_char:
    sta ACIA_DATA
    pha
tx_wait:
    lda ACIA_Status
    and #$10        ; Check tx buffer status flag
    beq tx_wait     ; loop if tx buffer not empty
    pla
    rts

acia_init:
    lda #0
    sta ACIA_Status ; Soft reset (value is not important)
    lda #%00010000  ; 1 Stop bit; 8 bit word; 9600 baud rate
    sta ACIA_CTRL
    lda #%00001011  ; no parity; no echo; no interrupt
    sta ACIA_CMD

lcd_init:
    lda #%00000010 ; Set 4-bit mode
    jsr lcd_instruction
    lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
    jsr lcd_instruction
    lda #%00001110 ; Display on; cursor on; blink off
    jsr lcd_instruction
    lda #%00000110 ; Increment and shift cursor; don't shift display
    jsr lcd_instruction
    jsr lcd_clear
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
    lda PORTB       ; Read high 4 Bits
    pha             ; and put on stack since it has the busy flag
    lda #RW
    sta PORTB
    lda #(RW | E)
    sta PORTB
    lda PORTB       ; Read low 4 Bits
    pla             ; Get high 4 Bits off stack
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
    jsr lcd_clear
    bit PORTA
    rti

; Reset/IRQ vectors
    .org $fffa
    .word nmi
    .word reset
    .word irq

