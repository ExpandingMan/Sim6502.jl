
# this doesn't need to be exact, used for setting the dict size
const N_OPCODES = 256


instruction(c::CPU, m::Memory) = deref(Π(c.PC), m)
instruction(cs::Chipset) = instruction(cs.cpu, cs.ram)


# this doesn't do the sleeping
function compute!(cs::Chipset)
    nbytes, ncycles = op!(cs, Π(c.PC))
    cs.cpu.PC += nbytes
    ncycles
end


function op!(cs::Chipset, ptr::Π)
    opcode = deref(ptr, cs.ram)
    exe!, nbytes = OPCODES[opcode]
    ncycles = exe!(cs, deref_opargs(cs, ptr, nbytes))
    nbyes, ncycles
end



#===================================================================================================
    <opcodes>
===================================================================================================#
const OPCODES = Dict{Int,Tuple{Function, Int}}();  sizehint!(OPCODES, N_OPCODES)


# TODO this is a mock-up of what this should ultimately look like
@opdef lda! begin
    Immediate, 0x69, 2, 2
    ZeroPage,  0x65, 2, 3
    ZeroPageX, 0x75, 2, 4
    Absolute,  0x6d, 3, 4
    AbsoluteX, 0x7d, 3, 4  # should automatically take care of page crossings
    AbsoluteY, 0x79, 3, 4
    IndirectX, 0x61, 2, 6
    IndirectY, 0x71, 2, 5
end


#===================================================================================================
    </opcodes>
===================================================================================================#
