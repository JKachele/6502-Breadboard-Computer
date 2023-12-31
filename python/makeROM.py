code = bytearray([
    # Load ff to Data Direction Register B
    0xa9, 0xff,         # lda #$ff
    0x8d, 0x02, 0x60,   # sta $6002

    # Load 55 to Output Register B
    0xa9, 0x55,         # lda #$55
    0x8d, 0x00, 0x60,   # sta $6000

    # Load aa to Output Register B
    0xa9, 0xaa,         # lda #$55
    0x8d, 0x00, 0x60,   # sta $6000

    # Loop to line 7
    0x4c, 0x05, 0x80    # jmp $8005
])

rom = code + bytearray([0xea] * (32768 - len(code)))

rom[0x7ffc] = 0x00
rom[0x7ffd] = 0x80

with open("rom.bin", "wb") as outFile:
    outFile.write(rom);
