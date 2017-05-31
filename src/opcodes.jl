
# this doesn't need to be exact, used for setting the dict size
const N_OPCODES = 256


instruction(c::CPU, m::Memory) = deref(Π(c.PC), m)
instruction(cs::Chipset) = instruction(cs.cpu, cs.ram)

# this doesn't do any checking
bytes2arg(bytes::AbstractVector{UInt8}) = bincat(bytes[1], bytes[2])

# this gets the arguments to the op given the pointer to the instruction and nbytes total
deref_opargs(cs::Chipset, ptr::Π, nbytes::Integer) = deref(ptr+0x01, cs.ram, nbytes-1)

# this has been tested and so far yields inferior performance
function derefview_opargs(cs::Chipset, ptr::Π, nbytes::Integer)
    derefview(ptr+0x01, cs.ram, nbytes-1)
end

# note that now we very much depend on the instruction pointer being set correctly
# at the time the instructions execute
@inline opargs(cs::Chipset, n::Integer) = cs.ram[cs.cpu.PC+n]



#===================================================================================================
    <execution>
===================================================================================================#

# TODO figure out how ops handle instruction pointer, think ok now?

# this doesn't do the sleeping
function op!(cs::Chipset)
    exe!, nbytes, ncycles = OPCODES[deref(Π(cs.cpu.PC), cs.ram)]
    exe!(cs)
    cs.cpu.PC += nbytes
    cs.clock += ncycles
    nbytes, ncycles
end

# TODO eventually this should employ timing
function run!(cs::Chipset)
    while !cs.cpu.flags.B
        op!(cs)
        println(cs)
    end
end

export op!, tick!
#===================================================================================================
    </execution>
===================================================================================================#



#===================================================================================================
    <opcodes>
===================================================================================================#
# this is an (efficient) function pointer type for the instructions
# note this works even though ops take AbstractVector
const OpFunc = FunctionWrapper{UInt8,Tuple{Chipset}}

# for the time being opcode 0x00 would throw an error
const OPCODES = Vector{Tuple{OpFunc,Int,Int}}(N_OPCODES)

# this is for the assembler
# TODO NEEDS TO SEE MODES!!! FIX!
const ASSEMBLY_DICT = Dict{Tuple{String,Symbol},UInt8}(); sizehint!(ASSEMBLY_DICT, N_OPCODES)

# format is
#    mode, opcode, nbytes, ncycles, (increment)
#
# the last arg is optional and tells it whether or not to increment the instruction pointer

# we treat "Accumulator" mode as "Implicit"


@opdef lda! begin
    Immediate, 0xa9, 2, 2
    ZeroPage,  0xa5, 2, 3
    ZeroPageX, 0xb5, 2, 4
    Absolute,  0xad, 3, 4
    AbsoluteX, 0xbd, 3, 4  # TODO should automatically take care of page crossings
    AbsoluteY, 0xb9, 3, 4
    IndirectX, 0xa1, 2, 6
    IndirectY, 0xb1, 2, 5
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

@opdef tax! begin
    Implicit,  0xaa, 1, 2
end

@opdef tay! begin
    Implicit,  0xa8, 1, 2
end

@opdef txa! begin
    Implicit,  0x8a, 1, 2
end

@opdef tya! begin
    Implicit,  0x98, 1, 2
end

@opdef tsx! begin
    Implicit,  0xba, 1, 2
end

@opdef txs! begin
    Implicit,  0x9a, 1, 2
end

@opdef pha! begin
    Implicit,  0x48, 1, 2
end

@opdef php! begin
    Implicit,  0x08, 1, 3
end

@opdef pla! begin
    Implicit,  0x68, 1, 4
end

@opdef plp! begin
    Implicit,  0x28, 1, 4
end

@opdef and! begin
    Immediate, 0x29, 2, 2
    ZeroPage,  0x25, 2, 3
    ZeroPageX, 0x35, 2, 4
    Absolute,  0x2d, 3, 4
    AbsoluteX, 0x3d, 3, 4
    AbsoluteY, 0x39, 3, 4
    IndirectX, 0x21, 2, 6
    IndirectY, 0x31, 2, 5
end

@opdef eor! begin
    Immediate, 0x49, 2, 2
    ZeroPage,  0x45, 2, 3
    ZeroPageX, 0x55, 2, 4
    Absolute,  0x4d, 3, 4
    AbsoluteX, 0x5d, 3, 4
    AbsoluteY, 0x59, 3, 4
    IndirectX, 0x41, 2, 6
    IndirectY, 0x51, 2, 5
end

@opdef ora! begin
    Immediate, 0x09, 2, 2
    ZeroPage,  0x05, 2, 3
    ZeroPageX, 0x15, 2, 4
    Absolute,  0x0d, 3, 4
    AbsoluteX, 0x1d, 3, 4
    AbsoluteY, 0x19, 3, 4
    IndirectX, 0x01, 2, 6
    IndirectY, 0x11, 2, 5
end

@opdef bit! begin
    ZeroPage,  0x24, 2, 3
    Absolute,  0x2c, 3, 4
end

@opdef adc! begin
    Immediate, 0x69, 2, 2
    ZeroPage,  0x65, 2, 3
    ZeroPageX, 0x75, 2, 4
    Absolute,  0x6d, 3, 4
    AbsoluteX, 0x7d, 3, 4
    AbsoluteY, 0x79, 3, 4
    IndirectX, 0x61, 2, 6
    IndirectY, 0x71, 2, 5
end

@opdef sbc! begin
    Immediate, 0xe9, 2, 2
    ZeroPage,  0xe5, 2, 3
    ZeroPageX, 0xf5, 2, 4
    Absolute,  0xed, 3, 4
    AbsoluteX, 0xfd, 3, 4
    AbsoluteY, 0xf9, 3, 4
    IndirectX, 0xe1, 2, 6
    IndirectY, 0xf1, 2, 5
end

@opdef cmp! begin
    Immediate, 0xc9, 2, 2
    ZeroPage,  0xc5, 2, 3
    ZeroPageX, 0xd5, 2, 4
    Absolute,  0xcd, 3, 4
    AbsoluteX, 0xdd, 3, 4
    AbsoluteY, 0xd9, 3, 4
    IndirectX, 0xc1, 2, 6
    IndirectY, 0xd1, 2, 5
end

@opdef cpx! begin
    Immediate, 0xe0, 2, 2
    ZeroPage,  0xe4, 2, 3
    Absolute,  0xec, 3, 4
end

@opdef cpy! begin
    Immediate, 0xc0, 2, 2
    ZeroPage,  0xc4, 2, 3
    Absolute,  0xcc, 3, 4
end

@opdef inc! begin
    ZeroPage,  0xe6, 2, 5
    ZeroPageX, 0xf6, 2, 6
    Absolute,  0xee, 3, 6
    AbsoluteX, 0xfe, 3, 7
end

@opdef inx! begin
    Implicit,  0xe8, 1, 2
end

@opdef iny! begin
    Implicit,  0xc8, 1, 2
end

@opdef dec! begin
    ZeroPage,  0xc6, 2, 5
    ZeroPageX, 0xd6, 2, 6
    Absolute,  0xce, 3, 6
    AbsoluteX, 0xde, 3, 7
end

@opdef dex! begin
    Implicit,  0xca, 1, 2
end

@opdef dey! begin
    Implicit,  0x88, 1, 2
end

@opdef asl! begin
    Implicit,  0x0a, 1, 2
    ZeroPage,  0x06, 2, 5
    ZeroPageX, 0x16, 2, 6
    Absolute,  0x0e, 3, 6
    AbsoluteX, 0x1e, 3, 7
end

@opdef lsr! begin
    Implicit,  0x4a, 1, 2
    ZeroPage,  0x46, 2, 5
    ZeroPageX, 0x56, 2, 6
    Absolute,  0x4e, 3, 6
    AbsoluteX, 0x5e, 3, 7
end

@opdef rol! begin
    Implicit,  0x2a, 1, 2
    ZeroPage,  0x26, 2, 5
    ZeroPageX, 0x36, 2, 6
    Absolute,  0x2e, 3, 6
    AbsoluteX, 0x3e, 3, 7
end

@opdef ror! begin
    Implicit,  0x6a, 1, 2
    ZeroPage,  0x66, 2, 5
    ZeroPageX, 0x76, 2, 6
    Absolute,  0x6e, 3, 6
    AbsoluteX, 0x7e, 3, 7
end

# note that these get 0's because they don't increment the instruction pointer
@opdef jmp! begin
    Immediate, 0x4c, 0, 3
    Absolute,  0x6c, 0, 5
end

@opdef jsr! begin
    Immediate, 0x20, 0, 6
end

# TODO not sure if implicit works with cpu and ram arguments
@opdef rts! begin
    Implicit,  0x60, 0, 6
end

# TODO check if instruction pointer is handled correctly in branches
@opdef bcc! begin
    Immediate, 0x90, 2, 2 
end

@opdef bcs! begin
    Immediate, 0xb0, 2, 2
end

@opdef beq! begin
    Immediate, 0xf0, 2, 2
end

@opdef bmi! begin
    Immediate, 0x30, 2, 2
end

@opdef bne! begin
    Immediate, 0xd0, 2, 2  
end

@opdef bpl! begin
    Immediate, 0x10, 2, 2
end

@opdef bvc! begin
    Immediate, 0x50, 2, 2
end

@opdef bvs! begin
    Immediate, 0x70, 2, 2
end

@opdef clc! begin
    Implicit,  0x18, 1, 2
end

@opdef cld! begin
    Implicit,  0xd8, 1, 2
end

@opdef cli! begin
    Implicit,  0x58, 1, 2
end

@opdef clv! begin
    Implicit,  0xb8, 1, 2
end

@opdef sec! begin
    Implicit,  0x38, 1, 2
end

@opdef sed! begin
    Implicit,  0xf8, 1, 2
end

@opdef sei! begin
    Implicit,  0x78, 1, 2
end

@opdef brk! begin
    Implicit,  0x00, 1, 7
end

@opdef nop! begin
    Implicit,  0xea, 1, 2
end

@opdef rti! begin
    Implicit,  0x40, 1, 6
end
#===================================================================================================
    </opcodes>
===================================================================================================#
