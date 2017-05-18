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
        # cs.cpu.A = deref(Π(0x01), cs.ram)
        cs.cpu.A = 0xab
        # Sim6502.ldaa!(cs.cpu, view(cs.ram, 0x0601:0x0601))
        # Sim6502.op0xa9!(cs, view(cs.ram.v, 0x0601:0x0601))
    end setup=(cs = makechipset())

    b = @benchmarkable begin
        op!(cs)
        # tick!(cs)
        # tick!(cs)
    end setup=(cs = makechipset())

    run(ref), run(b)
end


ref, b = runbenches()
