using Sim6502
using BenchmarkTools

c = CPU()
m = Memory()

macro p(expr)
    esc(:($expr; println(c)))
end

@p ldx!(c, 0x01)
@p lda!(c, 0x05)
@p sta!(c, m, Π(0x01))
@p lda!(c, 0x06)
@p sta!(c, m, Π(0x02))
@p ldy!(c, 0x0a)
@p sty!(c, m, Π(0x0605))
@p lda!(c, m, IndirectX, Π(0x00))

