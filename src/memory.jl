
struct Memory
    v::Vector{UInt8}

    Memory(v::AbstractVector{UInt8}) = new(v)

    Memory(ℓ::Integer=65536) = Memory(zeros(UInt8, ℓ))
end

reset!(m::Memory) = (m.v .= zeros(UInt8, length(m.v)))



#===================================================================================================
    <pointers>
===================================================================================================#
abstract type AbstractMPtr end

type MPtr{T<:Unsigned} <: AbstractMPtr
    addr::T

    MPtr{T}(addr::Unsigned) where T<:Unsigned = new(addr)
end
export MPtr

dereference{T}(ptr::MPtr{T}, m::Memory) = m.v[ptr.addr+one(T)]
deref(ptr::MPtr, m::Memory) = dereference(ptr, m)
↦(ptr::MPtr, m::Memory) = dereference(ptr, m)

export dereference, deref, ↦
#===================================================================================================
    </pointers>
===================================================================================================#


