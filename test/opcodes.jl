using Sim6502
using BenchmarkTools


macro program(vec)
    esc(quote
        cs.ram[0x0600:(0x0600+length($vec)-1)] = $vec
    end)
end

macro p(expr)
    esc(:($expr; println(cs.cpu)))
end


function makechipset()
    cs = Chipset()

    cs.ram[0x00] = 0x01
    cs.ram[0x01] = 0x02

    cs.ram[0xa000] = 0x05
    cs.ram[0xa001] = 0x06

    # @p Sim6502.op0xa5!(cs, [0x00])
    # @p Sim6502.op0xad!(cs, [0x01, 0xa0])
    # @p Sim6502.op0xaa!(cs, UInt8[])
    @program [0xaa, 0xa5, 0x00, 0xad, 0x01, 0xa0, 0xaa, 0xaa, 0xaa]

    cs
end

# TODO investigate allocs!!!

function makebenches()
    ref = @benchmarkable begin
        # cs.cpu.A = 0x00
        # Sim6502.checkNflag!(cs.cpu, cs.cpu.A)
        # Sim6502.checkZflag!(cs.cpu, cs.cpu.A)
        # cs.cpu.A = cs.ram[0xa001]
        cs.cpu.X = cs.cpu.A
        Sim6502.checkNflag!(cs.cpu, cs.cpu.X)
        Sim6502.checkZflag!(cs.cpu, cs.cpu.X)
    end setup=(cs = makechipset())

    b = @benchmarkable begin
        tick!(cs)
        tick!(cs)
        tick!(cs)
        tick!(cs)
    end setup=(cs = makechipset())

    ref, b
end


ref, b = makebenches()
