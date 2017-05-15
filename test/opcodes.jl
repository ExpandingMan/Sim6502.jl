using Sim6502

cs = Chipset()


macro p(expr)
    esc(:($expr; println(cs.cpu)))
end

macro program(vec)
    esc(quote
        cs.ram[0x0600:(0x0600+length($vec)-1)] = $vec
    end)
end

cs.ram[0x00] = 0x01
cs.ram[0x01] = 0x02

cs.ram[0xa000] = 0x05
cs.ram[0xa001] = 0x06

# @p Sim6502.op0x65!(cs, [0x00])
# @p Sim6502.op0x6d!(cs, [0x01, 0xa0])
# @p Sim6502.op0xaa!(cs, UInt8[])
@program [0x65, 0x00, 0x6d, 0x01, 0xa0, 0xaa]

@p tick!(cs)
@p tick!(cs)
@p tick!(cs)

