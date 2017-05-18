#=====================================================================================================
Some conventions:
    All instructions are based on methods where arguments are passed from an external source
    (i.e. they do not come from the CPU's memory).

    Note that many functions are explicitly inlined, but probably none of them have to be.

    **These calls do not affect the program counter.**

    TODO investigate inlining

    TODO warn about the stack doing weird things
=====================================================================================================#

# these can be passed to instructions to specify addressing modes when appropriate
abstract type AddressingMode end
abstract type DirectMode <: AddressingMode end
abstract type IndirectMode <: AddressingMode end
struct Direct <: DirectMode end
struct DirectX <: DirectMode end
struct DirectY <: DirectMode end
struct IndirectX <: IndirectMode end
struct IndirectY <: IndirectMode end

# some instructions only have these modes
const DirectXModes = Union{Direct,DirectX}
const DirectYModes = Union{Direct,DirectY}

export AddressingMode, DirectMode, IndirectMode, Direct, DirectX, DirectY, IndirectX, IndirectY


# utility functions used frequently in instructions
@inline checkNflag!(c::CPU, val::UInt8) = (c.flags.N = val ≥ 0x80)
@inline checkZflag!(c::CPU, val::UInt8) = (c.flags.Z = val == 0x00)
@inline checkCflag!(c::CPU, val1::UInt8, val2::UInt8) = (c.flags.C = overflow(val1, val2))

# pointers that occur in different addressing modes
pointer(::Type{Direct}, ptr::Π, c::CPU, m::Memory) = ptr
pointer(::Type{DirectX}, ptr::Π, c::CPU, m::Memory) = ptr + c.X
pointer(::Type{DirectY}, ptr::Π, c::CPU, m::Memory) = ptr + c.Y
pointer(::Type{IndirectX}, ptr::Π, c::CPU, m::Memory) = Π(deref(UInt16, ptr + c.X, m))
pointer(::Type{IndirectY}, ptr::Π, c::CPU, m::Memory) = Π(deref(UInt16, ptr, m) + c.Y)

# these dereference in a way appropriate for Indirect
deref{T<:AddressingMode}(::Type{T}, ptr::Π, c::CPU, m::Memory) = deref(pointer(T, ptr, c, m), m)

function store!{T<:AddressingMode}(::Type{T}, ptr::Π, c::CPU, m::Memory, val::UInt8)
    store!(m, pointer(T, ptr, c, m), val)
end

stackpush!(c::CPU, m::Memory, val::UInt8) = (store!(m, stackpointer(c), val); c.SP -= 1)
stackpush!(c::CPU, m::Memory, val::UInt16) = (storeback!(m, stackpointer(c), val); c.SP -= 2)

stackpull!(c::CPU, m::Memory) = (ξ = deref(stackpointer(c), val); c.SP += 1; ξ)
stackpull!(::Type{UInt16}, c::CPU, m::Memory) = (stackpull!(c, m) + 0x0100 * stackpull!(c, m))


# this is for the weird arithmetic of the branching instructions (\boxplus)
⊞(x::Unsigned, y::Unsigned) = unsigned(signed(x) + signed(y))


#===================================================================================================
    <load, store instructions>
===================================================================================================#
#-----------------------LDA, LDX, LDY----------------------------------------------
# template for ld instructions in immediate mode
function ld!(c::CPU, reg::Symbol, val::UInt8)
    v = store!(c, reg, val)
    checkNflag!(c, v)
    checkZflag!(c, v)
    v
end

function ld!{T<:AddressingMode}(c::CPU, m::Memory, reg::Symbol, ::Type{T}, ptr::Π)
    ld!(c, reg, deref(T, ptr, c, m))
end
ld!(c::CPU, m::Memory, reg::Symbol, ptr::Π) = ld!(c, m, reg, Direct, ptr)

# TODO  TESTING!!!! REVERT!!!!
ldaa!(c::CPU, v::AbstractVector{UInt8}) = (c.A = v[1])
lda!(c::CPU, val::UInt8) = ld!(c, :A, val)
ldx!(c::CPU, val::UInt8) = ld!(c, :X, val)
ldy!(c::CPU, val::UInt8) = ld!(c, :Y, val)

lda!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = ld!(c, m, :A, T, ptr)
ldx!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = ld!(c, m, :X, T, ptr)
ldy!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = ld!(c, m, :Y, T, ptr)

lda!(c::CPU, m::Memory, ptr::Π) = ld!(c, m, :A, Direct, ptr)
ldx!(c::CPU, m::Memory, ptr::Π) = ld!(c, m, :X, Direct, ptr)
ldy!(c::CPU, m::Memory, ptr::Π) = ld!(c, m, :Y, Direct, ptr)

export ld!, lda!, ldx!, ldy!


#---------------------STA, STX, STY------------------------------------------------
# template for st in zero page or absolute mode
function st!(c::CPU, m::Memory, reg::Symbol, ::Type{T}, ptr::Π) where T<:AddressingMode
    store!(m, pointer(T, ptr, c, m), fetch(c, reg))
end
st!(c::CPU, m::Memory, reg::Symbol, ptr::Π) = st!(c, m, reg, Direct, ptr)

sta!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = st!(c, m, :A, T, ptr)
stx!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = st!(c, m, :X, T, ptr)
sty!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = st!(c, m, :Y, T, ptr)

sta!(c::CPU, m::Memory, ptr::Π) = st!(c, m, :A, Direct, ptr)
stx!(c::CPU, m::Memory, ptr::Π) = st!(c, m, :X, Direct, ptr)
sty!(c::CPU, m::Memory, ptr::Π) = st!(c, m, :Y, Direct, ptr)

export st!, sta!, stx!, sty!
#===================================================================================================
    </load, store instructions>
===================================================================================================#


#===================================================================================================
    <register transfers>
===================================================================================================#
function t!(c::CPU, reg1::Symbol, reg2::Symbol)
    v = store!(c, reg2, fetch(c, reg1))
    checkNflag!(c, v)
    checkZflag!(c, v)
end

tax!(c::CPU) = t!(c, :A, :X)
tay!(c::CPU) = t!(c, :A, :Y)
txa!(c::CPU) = t!(c, :X, :A)
tya!(c::CPU) = t!(c, :Y, :A)

export t!, tax!, tay!, txa!, tya!
#===================================================================================================
    </register transfers>
===================================================================================================#


# TODO check effect of other instructions on stack!!!
#===================================================================================================
    <stack operations>
===================================================================================================#
function tsx!(c::CPU)
    c.X = c.SP
    checkNflag!(c, c.X)
    checkZflag!(c, c.X)
    c.X
end

txs!(c::CPU) = (c.SP = c.X)

pha!(c::CPU, m::Memory) = stackpush!(c, m, c.A)

php!(c::CPU, m::Memory) = stackpush!(c, m, c.P)


function pla!(c::CPU, m::Memory)  # pull stack onto A
    c.A = stackpull!(c, m)
    checkNflag!(c, c.A)
    checkZflag!(c, c.A)
    c.A
end

# in example this doesn't set the blank or B flags for some reason... wtf?
plp!(c::CPU, m::Memory) = (c.P = stackpull!(c, m))


export tsx!, txs!, pha!, php!, pla!, plp!
#===================================================================================================
    </stack operations>
===================================================================================================#



#===================================================================================================
    <logical operations>
===================================================================================================#
# template for logical operations
function logical!(logical_op::Function, c::CPU, val::UInt8)
    c.A = logical_op(c.A, val)
    checkNflag!(c, c.A)
    checkZflag!(c, c.A)
    c.A
end

and!(c::CPU, val::UInt8) = logical!(&, c, val)
and!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = and!(c, deref(T, ptr, c, m))
and!(c::CPU, m::Memory, ptr::Π) = and!(c, m, Direct, ptr)

eor!(c::CPU, val::UInt8) = logical!(⊻, c, val)
eor!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = eor!(c, deref(T, ptr, c, m))
eor!(c::CPU, m::Memory, ptr::Π) = eor!(c, m, Direct, ptr)

ora!(c::CPU, val::UInt8) = logical!(|, c, val)
ora!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = ora!(c, deref(T, ptr, c, m))
ora!(c::CPU, m::Memory, ptr::Π) = ora!(c, m, Direct, ptr)

function bit!(c::CPU, m::Memory, ptr::Π)
    v = deref(ptr, m)
    c.A & v == 0 ? status!(c, :Z, true) : status!(c, :Z, false)
    status!(c, :V, Bool((0x40 & v) >> 6))
    status!(c, :N, Bool((0x80 & v) >> 7))
    v
end
bit!(c::CPU, m::Memory, ::Type{Direct}, ptr::Π) = bit!(c, m, ptr)

export and!, eor!, ora!, bit!
#===================================================================================================
    </logical operations>
===================================================================================================#


#===================================================================================================
    <arithmetic>
===================================================================================================#
function adc!(c::CPU, val::UInt8)
    val += UInt8(status(c, :C))
    checkCflag!(c, c.A, val)
    c.A += val
    checkNflag!(c, c.A)
    checkZflag!(c, c.A)
    c.A
end

adc!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = adc!(c, deref(pointer(T, ptr, c, m), m))
adc!(c::CPU, m::Memory, ptr::Π) = adc!(c, m, Direct, ptr)


function sbc!(c::CPU, val::UInt8)
    val -= ~UInt8(status(c, :C))
    checkCflag!(c, c.A, val)
    c.A -= val
    checkNflag!(c, c.A)
    checkZflag!(c, c.A)
    c.A
end

sbc!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = sbc!(c, deref(pointer(T, ptr, c, m), m))
sbc!(c::CPU, m::Memory, ptr::Π) = sbc!(c, m, Direct, ptr)


function compare!(c::CPU, reg::Symbol, val::UInt8)
    r = fetch(c, reg)
    r ≥ val ? status!(c, :C, true) : status!(c, :C, false)
    ξ = r - val
    checkNflag!(c, ξ)
    checkZflag!(c, ξ)
    r
end
function compare!{T<:AddressingMode}(c::CPU, m::Memory, reg::Symbol, ::Type{T}, ptr::Π)
    compare!(c, reg, deref(pointer(T, ptr, c, m), m))
end
compare!(c::CPU, m::Memory, reg::Symbol, ptr::Π) = compare!(c, m, reg, Direct, ptr)

cmp!(c::CPU, val::UInt8) = compare!(c, :A, val)
cmp!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = compare!(c, m, :A, T, ptr)
cmp!(c::CPU, m::Memory, ptr::Π) = compare!(c, m, :A, ptr)

# this instruction only has direct mode
cpx!(c::CPU, val::UInt8) = compare!(c, :X, val)
cpx!(c::CPU, m::Memory, ::Type{Direct}, ptr::Π) = compare!(c, m, :X, T, ptr)
cpx!(c::CPU, m::Memory, ptr::Π) = compare!(c, m, :X, ptr)

# this instruction only has direct mode
cpy!(c::CPU, val::UInt8) = compare!(c, :Y, val)
cpy!(c::CPU, m::Memory, ::Type{Direct}, ptr::Π) = compare!(c, m, :Y, T, ptr)
cpy!(c::CPU, m::Memory, ptr::Π) = compare!(c, m, :Y, ptr)

export adc!, sbc!, compare!, cmp!, cpx!, cpy!
#===================================================================================================
    </arithmetic>
===================================================================================================#


#===================================================================================================
    <increments and decrements>
===================================================================================================#
# note that the result of this needs to be stored
function increment!(c::CPU, val::UInt8)
    ξ = val + 1
    checkZflag!(c, ξ)
    checkNflag!(c, ξ)
    ξ
end

function inc!{T<:DirectXModes}(c::CPU, m::Memory, ::Type{T}, ptr::Π)
    C.x = increment!(c, deref(pointer(T, ptr, c, m), m))
end
inc!(c::CPU, m::Memory, ptr::Π) = inc!(c, m, Direct, ptr)

inx!(c::CPU) = (c.X = increment!(c, c.X))

iny!(c::CPU) = (c.Y = increment!(c, c.Y))


function decrement!(c::CPU, val::UInt8)
    ξ = val - 1
    checkZflag!(c, ξ)
    checkNflag!(c, ξ)
    ξ
end

function dec!{T<:DirectXModes}(c::CPU, m::Memory, ::Type{T}, ptr::Π)
    C.x = decrement!(c, deref(pointer(T, ptr, c, m), m))
end
dec!(c::CPU, m::Memory, ptr::Π) = dec!(c, m, Direct, ptr)

dex!(c::CPU, m::Memory, ptr::Π) = (c.X = decrement!(c, c.X))

dey!(c::CPU, m::Memory, ptr::Π) = (c.Y = decrement!(c, c.Y))


export increment!, inc!, inx!, iny!, decrement!, dec!, dex!, dey!
#===================================================================================================
    </increments and decrements>
===================================================================================================#


#===================================================================================================
    <shifts>
===================================================================================================#
# checkZflag! must be called from outside!
# WTF? why is this inconsistent with the other ops???
function arithmetic_shiftleft!(c::CPU, val::UInt8)
    val & 0x80 > 0x00 ? status!(c, :C, true) : status!(c, :C, false)
    ξ = val << 1
    checkNflag!(c, ξ)
    ξ
end

asl!(c::CPU) = (c.A = arithmetic_shiftleft!(c, c.A); checkZflag!(c, c.A); c.A)
function asl!{T<:DirectXModes}(c::CPU, m::Memory, ::Type{T}, ptr::Π)
    ξ = arithmetic_shiftleft!(c, deref(pointer(T, ptr, c, m), m))
    store!(m, ptr, ξ)
    # we neglect checking A == 0 since it didn't change
    ξ
end
asl!(c::CPU, m::Memory, ptr::Π) = asl!(c, m, Direct, ptr)


function logical_shiftright!(c::CPU, val::UInt8)
    val & 0x01 > 0x00 ? status!(c, :C, true) : status!(c, :C, false)
    ξ = val >> 1
    checkZflag!(c, ξ)
    checkNflag!(c, ξ)
    ξ
end

lsr!(c::CPU) = (c.A = logical_shiftright!(c, c.A))
function lsr!{T<:DirectXModes}(c::CPU, m::Memory, ::Type{T}, ptr::Π)
    ξ = logical_shiftright!(c, deref(pointer(T, ptr, c, m), m))
    store!(m, ptr, ξ)
    ξ
end
lsr!(c::CPU, m::Memory, ptr::Π) = lsr!(c, m, Direct, ptr)


# again, checkZflag! must be called from outside!
function rotateleft!(c::CPU, val::UInt8)
    val & 0x80 > 0x00 ? status!(c, :C, true) : status!(c, :C, false)
    ξ = (val << 1) + (0x01 * convert(UInt8, status(c, :C)))
    checkNflag!(c, ξ)
    ξ
end

rol!(c::CPU) = (c.A = rotateleft!(c, c.A); checkZflag!(c, c.A); c.A)
function rol!{T<:DirectXModes}(c::CPU, m::Memory, ::Type{T}, ptr::Π)
    ξ = rotateleft!(c, deref(pointer(T, ptr, c, m), m))
    store!(m, ptr, ξ)
    # we neglect checking A == 0 since it didn't change
    ξ
end
rol!(c::CPU, m::Memory, ptr::Π) = rol!(c, m, Direct, ptr)


# again, checkZflag! must be called from outside!
function rotateright!(c::CPU, val::UInt8)
    val & 0x01 > 0x00 ? status!(c, :C, true) : status!(c, :C, false)
    ξ = (val >> 1) + (0x80 * convert(UInt8, status(c, :C)))
    checkNflag!(c, ξ)
    ξ
end

ror!(c::CPU) = (c.A = rotateright!(c, c.A); checkZflag!(c.A); c.A)
function ror!{T<:DirectXModes}(c::CPU, m::Memory, ::Type{T}, ptr::Π)
    ξ = rotateright!(c, deref(pointer(T, ptr, c, m), m))
    store!(m, ptr, ξ)
    # we neglect checking A == 0 since it didn't change
    ξ
end
ror!(c::CPU, m::Memory, ptr::Π) = ror!(c, m, Direct, ptr)


export arithmetic_shiftleft!, asl!, logical_shiftright!, lsr!, rotateleft!, rol!, rotateright!, ror!
#===================================================================================================
    </shifts>
===================================================================================================#


#===================================================================================================
    <jumps and calls>

    TODO be __very__ careful about how you implement the byte counting of these!!!
===================================================================================================#
# note that this takes UInt16 arguments
jmp!(c::CPU, val::UInt16) = (c.PC = val)

# note, the assembly syntax for this function is really fucking weird
# confusingly, the references call this indirect mode
jmp!(c::CPU, m::Memory, ::Type{Direct}, ptr::Π{UInt16}) = jmp!(c, deref(UInt16, ptr, m))
jmp!(c::CPU, m::Memory, ptr::Π{UInt16}) = jmp!(c, m, Direct, ptr)

function jsr!(c::CPU, m::Memory, val::UInt16)
    stackpush!(c, m, c.PC + 0x0002)
    c.PC = val
end


rts!(c::CPU, m::Memory) = (c.PC = stackpull!(UInt16, c, m))


export jmp!, jsr!, rts!
#===================================================================================================
    </jumps and calls>
===================================================================================================#


#===================================================================================================
    <branches>

    # TODO again be __very__ careful about how you implement byte counting for these!!!
===================================================================================================#
bcc!(c::CPU, m::Memory, val::UInt8) = (!status(c, :C) && (c.PC = c.PC ⊞ val); val)

bcs!(c::CPU, m::Memory, val::UInt8) = (status(c, :C) && (c.PC = c.PC ⊞ val); val)

beq!(c::CPU, m::Memory, val::UInt8) = (status(c, :Z) && (c.PC = c.PC ⊞ val); val)

bmi!(c::CPU, m::Memory, val::UInt8) = (status(c, :N) && (c.PC = c.PC ⊞ val); val)

bne!(c::CPU, m::Memory, val::UInt8) = (!status(c, :Z) && (c.PC = c.PC ⊞ val); val)

bpl!(c::CPU, m::Memory, val::UInt8) = (!status(c, :N) && (c.PC = c.PC ⊞ val); val)

bvc!(c::CPU, m::Memory, val::UInt8) = (!status(c, :V) && (c.PC = c.PC ⊞ val); val)

bvs!(c::CPU, m::Memory, val::UInt8) = (status(c, :V) && (c.PC = c.PC ⊞ val); val)


export bcc!, bcs!, beq!, bmi!, bne!, bpl!, bvc!, bvs!
#===================================================================================================
    </branches>
===================================================================================================#


#===================================================================================================
    <status flag changes>
===================================================================================================#
clc!(c::CPU) = status!(c, :C, false)

cld!(c::CPU) = status!(c, :D, false)

cli!(c::CPU) = status!(c, :I, false)

clv!(c::CPU) = status!(c, :V, false)

sec!(c::CPU) = status!(c, :C, true)

sed!(c::CPU) = status!(c, :D, true)

sei!(c::CPU) = status!(c, :I, true)

export clc!, cld!, cli!, clv!, sec!, sed!, sei!
#===================================================================================================
    <status flag changes>
===================================================================================================#


#===================================================================================================
    <system functions>
===================================================================================================#
# TODO this will require some special handling
brk!(c::CPU) = status!(c, :B, true)

nop!(c::CPU) = ()

# __NOTE!!__ that PC is also incremented the normal way afterwards from reading the instruction
function rti!(c::CPU, m::Memory)
    ptr = stackpointer(c) + 0x01  # are you sure about this?
    c.P = deref(ptr, m)
    ptr = ptr + 0x01
    pc_small = deref(ptr, m)
    ptr = ptr + 0x01
    pc_big = deref(ptr, m)
    c.PC = 0x0100*pc_big + pc_small
    c.SP += 0x03  # not completely confident in this either
end

export brk!, nop!, rti!
#===================================================================================================
    </system functions>
===================================================================================================#


