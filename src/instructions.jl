#=====================================================================================================
Some conventions:
    All instructions are based on methods where arguments are passed from an external source
    (i.e. they do not come from the CPU's memory).

    **These calls do not affect the program counter.**

    TODO add methods for running instructions from Memory.

    TODO symbols passed for lookup should be implemented through macros !!! (i.e. at compile time)

    TODO investigate inlining
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
checkNflag!(c::CPU, val::UInt8) = val ≥ 0x80 ? status!(c, :N, true) : status!(c, :N, false)
checkZflag!(c::CPU, val::UInt8) = val == 0x00 ? status!(c, :Z, true) : status!(c, :Z, false)
function checkCflag!(c::CPU, val1::UInt8, val2::UInt8)
    overflow(val1, val2) ? status!(c, :C, true) : status!(c, :C, false)
end

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

# TODO get rid of boilerplate stuff
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

function pha!(c::CPU)  # push A to stack
    store!(m, Π(c.SP), c.A)
    c.SP -= 0x01
end

function php!(c::CPU)  # push P (processor status) to stack
    store!(m, Π(c.SP), c.P)
    c.SP -= 0x01
end

function pla!(c::CPU)  # pull stack onto A
    c.A = deref(Π(c.SP), m)
    checkNflag!(c, c.A)
    checkZflag!(c, c.A)
    c.SP += 0x01
    c.A
end

# in example this doesn't set the blank or B flags for some reason... wtf?
function plp!(c::CPU)  # pull stack onto P
    c.P = deref(Π(c.SP), m)
    c.SP += 0x01
end
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

# TODO RETEST ARITHMETIC AND INCREMENTS!!!! ESPECIALLY POINTERS!!!

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

function inc!{T<:DirectXModes}(c::CPU, m::Memroy, ::Type{T}, ptr::Π)
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


