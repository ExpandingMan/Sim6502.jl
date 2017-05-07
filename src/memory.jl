
struct Memory
    v::Vector{UInt8}

    Memory(v::AbstractVector{UInt8}) = new(v)

    Memory(ℓ::Integer=65536) = Memory(zeros(UInt8, ℓ))
end

reset!(m::Memory) = (m.v .= zeros(UInt8, length(m.v)))



#===================================================================================================
    <pointers>
===================================================================================================#
abstract type AbstractΠ end  # uses capital Π

type Π{T<:Unsigned} <: AbstractΠ
    addr::T

    Π{T}(addr::Unsigned) where T<:Unsigned = new(addr)
end
export Π

const Π8 = Π{UInt8}  # zero page pointer
const Π16 = Π{UInt16}  # standard 6502 memory pointer
export Π8, Π16

dereference{T}(ptr::Π{T}, m::Memory) = m.v[ptr.addr+one(T)]
deref(ptr::Π, m::Memory) = dereference(ptr, m)
↦(ptr::Π, m::Memory) = dereference(ptr, m)  # this symbol is \mapsto

store!(m::Memory, ptr::Π{T}, val::UInt8) = (m.v[ptr.addr+one(T)] = val)

(+){T}(ptr1::Π{T}, ptr2::Π{T}) = Π{T}(ptr1.addr + ptr2.addr)
(-){T}(ptr1::Π{T}, ptr2::Π{T}) = Π{T}(ptr1.addr - ptr2.addr)

(+){T}(ptr::Π{T}, val::Unsigned) = Π{T}(ptr.addr + convert(T, val))
(-){T}(ptr::Π{T}, val::Unsigned) = Π{T}(ptr.addr - convert(T, val))

export dereference, deref, ↦, store!, +, -
#===================================================================================================
    </pointers>
===================================================================================================#


