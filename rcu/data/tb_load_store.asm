addi x1, x0, 1
addi x2, x0, 2
addi x3, x0, 3
addi x4, x0, 4
addi x5, x0, 5
addi x6, x0, 2000
sd x1, 0(x6)
sd x2, 8(x6)
sd x3, 16(x6)
sd x4, 24(x6)
sd x5, 32(x6)
ld x7, 0(x6)
ld x8, 8(x6)
ld x9, 16(x6)
ld x10, 24(x6)
ld x11, 32(x6)