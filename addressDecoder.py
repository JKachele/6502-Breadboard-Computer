# digits = bytearray([0x7e, 0x30, 0x6d, 0x79, 0x33, 0x5b, 0x5f, 0x70,
                    # 0x7f, 0x7b, 0x77, 0x1f, 0x4e, 0x3d, 0x4f, 0x47])
digits = bytearray([0xeb, 0x88, 0xb3, 0xba, 0xd8, 0x7a, 0x7b, 0xa8,
                    0xfb, 0xfa, 0xf9, 0x5b, 0x63, 0x9b, 0x73, 0x71])
testDigits = bytearray([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])

dec = bytearray()

for value in range(4096):
    dec.append(digits[value % 16])
for value in range(4096):
    dec.append(digits[(value // 16) % 16])
for value in range(4096):
    dec.append(digits[value // 256])
for value in range(4096):
    dec.append(0xff)

dec = dec + dec

with open("addDec.bin", "wb") as outFile:
    outFile.write(dec);
