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
    c.A = deref(m, Π(c.SP))
    checkNflag!(c, c.A)
    checkZflag!(c, c.A)
    c.SP += 0x01
    c.A
end

# in example this doesn't set the blank or B flags for some reason... wtf?
function plp!(c::CPU)  # pull stack onto P
    c.P = deref(m, Π(c.SP))
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

adc!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = adc!(c, pointer(T, ptr, c, m))
adc!(c::CPU, m::Memory, ptr::Π) = adc!(c, m, Direct, ptr)


function sbc!(c::CPU, val::UInt8)
    val -= ~UInt8(status(c, :C))
    checkCflag!(c, c.A, val)
    c.A -= val
    checkNflag!(c, c.A)
    checkZflag!(c, c.A)
    c.A
end

sbc!{T<:AddressingMode}(c::CPU, m::Memory, ::Type{T}, ptr::Π) = sbc!(c, pointer(T, ptr, c, m))
sbc!(c::CPU, m::Memory, ptr::Π) = sbc!(c, m, Direct, ptr)


function cmp!(c::CPU, val::UInt8)
    # TODO finish!!!!
end





export adc!, sbc!, cmp!
#===================================================================================================
    </arithmetic>
===================================================================================================#



