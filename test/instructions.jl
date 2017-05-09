using Sim6502
# using BenchmarkTools

c = CPU()
m = Memory()

macro p(expr)
    esc(:($expr; println(c)))
end

# @p ldx!(c, 0x80)
# @p stx!(c, m, Π(0x00))
# @p lda!(c, 0x40)
# @p bit!(c, m, Π(0x00))

@p ldx!(c, 0x40)
@p stx!(c, m, Π(0x00))

@p lda!(c, 0x80)
@p asl!(c, m, Π(0x00))

