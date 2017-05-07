using Sim6502

c = CPU()


tick!(c::CPU) = (adc!(c, 0xff); c)

println(c)
adc!(c, 0xff)
println(c)
adc!(c, 0x01)
println(c)
adc!(c, 0xff)
println(c)
adc!(c, 0xff)
println(c)


lda!(c, 0xa0)
println(c)
ldx!(c, 0x01)
println(c)
ldy!(c, 0x02)
println(c)

