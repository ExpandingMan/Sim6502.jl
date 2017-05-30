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

    # @program [0xaa, 0xa5, 0x00, 0xad, 0x01, 0xa0, 0xaa, 0xaa, 0xaa]
    @program [0xa9, 0xaa, 0xa9, 0xab, 0xa9, 0xac]

    cs
end

# TODO investigate allocs!!!

function runbenches()
    ref = @benchmarkable begin
        cs.cpu.A = 0xaa
        cs.cpu.A = 0xab
        cs.cpu.A = 0xac
    end setup=(cs = makechipset())

    b = @benchmarkable begin
        op!(cs)
        op!(cs)
        op!(cs)
    end setup=(cs = makechipset())

    run(ref), run(b)
end


ref, b = runbenches()
