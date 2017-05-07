#=====================================================================================================
Some conventions:
    All instructions are based on methods where arguments are passed explicitly (rather than from
    the stack). These base methods affect the registers (or memory) as they should, but do not
    affect the program counter as they are not reading from the stack.

    Zero-argument instruction methods read memory from the stack, and affect the PC register as
    they should.
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

export AddressingMode, DirectMode, IndirectMode, Direct, DirectX, DirectY, IndirectX, IndirectY


# utility functions used frequently in instructions
checkNflag!(c::CPU, val::UInt8) = val ≥ 0x80 ? status!(c, :N, true) : status!(c, :N, false)
checkZflag!(c::CPU, val::UInt8) = val == 0x00 ? status!(c, :Z, true) : status!(c, :Z, false)

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







# immediate mode
function adc!(c::CPU, val::UInt8)
    val += UInt8(status(c, :C))  # carry bit gets added in this instruction
    checkNflag!(c, val)
    overflow(val, c.A) && status!(c, :C, true)
    c.A += val
    checkZflag!(c, c.A)
    counter!(c, 0x02)
    c.A
end
export adc!

