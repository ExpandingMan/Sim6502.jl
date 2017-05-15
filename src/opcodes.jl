
# this doesn't need to be exact, used for setting the dict size
const N_OPCODES = 256


instruction(c::CPU, m::Memory) = deref(Π(c.PC), m)
instruction(cs::Chipset) = instruction(cs.cpu, cs.ram)

# this doesn't do any checking
bytes2arg(bytes::AbstractVector{UInt8}) = bincat(bytes[1], bytes[2])

# this gets the arguments to the op given the pointer to the instruction and nbytes total
deref_opargs(cs::Chipset, ptr::Π, nbytes::Integer) = deref(ptr+0x01, cs.ram, nbytes-1)


#===================================================================================================
    <execution>
===================================================================================================#
# this doesn't do the sleeping
function tick!(cs::Chipset)
    nbytes, ncycles = op!(cs, Π(cs.cpu.PC))
    cs.cpu.PC += nbytes
    cs.clock += ncycles
    nbytes, ncycles
end


# op! doesn't increment clock or instruction pointer
function op!(cs::Chipset, bytes::AbstractVector{UInt8})
    exe!, nbytes, ncycles = OPCODES[bytes[1]]
    exe!(cs, bytes[2:end])
    nbytes, ncycles
end

function op!(cs::Chipset, ptr::Π)
    exe!, nbytes, ncycles = OPCODES[deref(ptr, cs.ram)]
    exe!(cs, deref_opargs(cs, ptr, nbytes))
    nbytes, ncycles
end


export op!, tick!
#===================================================================================================
    </execution>
===================================================================================================#



#===================================================================================================
    <opcodes>
===================================================================================================#
# returns func, nbytes, ncycles
const OPCODES = Dict{UInt8,Tuple{Function,Int,Int}}();  sizehint!(OPCODES, N_OPCODES)


@opdef lda! begin
    Immediate, 0x69, 2, 2
    ZeroPage,  0x65, 2, 3
    ZeroPageX, 0x75, 2, 4
    Absolute,  0x6d, 3, 4
    AbsoluteX, 0x7d, 3, 4  # TODO should automatically take care of page crossings
    AbsoluteY, 0x79, 3, 4
    IndirectX, 0x61, 2, 6
    IndirectY, 0x71, 2, 5
end

@opdef ldx! begin
    Immediate, 0xa2, 2, 2
    ZeroPage,  0xa6, 2, 3
    ZeroPageY, 0xb6, 2, 4
    Absolute,  0xae, 3, 4
    AbsoluteY, 0xbe, 3, 4
end

@opdef ldy! begin
    Immediate, 0xa0, 2, 2
    ZeroPage,  0xa4, 2, 3
    ZeroPageX, 0xb4, 2, 4
    Absolute,  0xac, 3, 4
    AbsoluteX, 0xbc, 3, 4
end

@opdef sta! begin
    ZeroPage,  0x85, 2, 3
    ZeroPageX, 0x95, 2, 4
    Absolute,  0x8d, 3, 4
    AbsoluteX, 0x9d, 3, 5
    AbsoluteY, 0x99, 3, 5
    IndirectX, 0x81, 2, 6
    IndirectX, 0x91, 2, 6
end

@opdef stx! begin
    ZeroPage,  0x86, 2, 3
    ZeroPageY, 0x96, 2, 4
    Absolute,  0x8e, 3, 4
end

@opdef sty! begin
    ZeroPage,  0x84, 2, 3
    ZeroPageX, 0x94, 2, 4
    Absolute,  0x8c, 2, 4
end

#===================================================================================================
    </opcodes>
===================================================================================================#
