
struct Memory
    v::Vector{UInt8}

    Memory(v::AbstractVector{UInt8}) = new(v)

    Memory(ℓ::Integer=65536) = Memory(zeros(UInt8, ℓ))
end
export Memory



abstract type AbstractΠ end  # uses capital Π

# note that, somewhat confusingly, T is the type of the pointer, not the value being pointed to
type Π{T<:Unsigned} <: AbstractΠ
    addr::T

    Π{T}(addr::Unsigned) where T<:Unsigned = new(addr)
end
export Π

Π(addr::T) where T<:Unsigned = Π{T}(addr)

const Π8 = Π{UInt8}  # zero page pointer
const Π16 = Π{UInt16}  # standard 6502 memory pointer
export Π8, Π16

Π8(x::AbstractVector{UInt8}) = Π{UInt8}(x[1])

Π16(x::UInt8, y::UInt8) = Π{UInt16}(bincat(x, y))
Π16(x::AbstractVector{UInt8}) = Π16(x[1], x[2])


reset!(m::Memory) = (m.v .= zeros(UInt8, length(m.v)))
export reset!

fetch(m::Memory, idx::T) where T<:Unsigned = m.v[idx+one(T)]
fetch(m::Memory, idx::AbstractVector{T}) where T<:Unsigned = m.v[idx+one(T)]

Base.getindex(m::Memory, idx) = m.v[idx + 0x0001]
Base.getindex(m::Memory, ptr::Π) = fetch(m, ptr.addr)

Base.setindex!(m::Memory, val::UInt8, idx::T) where T<:Unsigned = (m.v[idx+one(T)] = val)
Base.setindex!(m::Memory, val::UInt8, ptr::Π) = setindex!(m, val, ptr.addr)

function Base.setindex!(m::Memory, v::AbstractVector{UInt8}, idx::AbstractVector{T}) where T <: Integer
    m.v[idx+one(T)] = v
end

Base.view(m::Memory, idx) = view(m.v, idx + 0x0001)
Base.view(m::Memory, ptr::Π) = view(m, ptr.addr)

#===================================================================================================
    <referencing>
===================================================================================================#
dereference{T}(ptr::Π{T}, m::Memory) = m[ptr]
deref(ptr::Π, m::Memory) = dereference(ptr, m)
(↦)(ptr::Π, m::Memory) = dereference(ptr, m)  # this symbol is \mapsto

# note that the views always return SubArray, even for a single element
derefview(ptr::Π, m::Memory) = view(m, ptr)

dereference(::Type{UInt8}, ptr::Π, m::Memory)::UInt8 = dereference(ptr, Π)
deref(::Type{UInt8}, ptr::Π, m::Memory) = dereference(ptr, Π)

# these are for dereferencing length 2 arrays into single UInt16's
function dereference{T}(::Type{UInt16}, ptr::Π{T}, m::Memory)::UInt16
    least_sig = deref(ptr, m)
    most_sig = deref(ptr + one(T), m)
    0x0100 * most_sig + least_sig
end
deref(::Type{UInt16}, ptr::Π, m::Memory) = dereference(UInt16, ptr, m)
(⇾)(ptr::Π, m::Memory) = dereference(UInt16, ptr, m)  # this symbol is \rightarrowtriangle

# dereference arrays
function dereference{T}(ptr::Π{T}, m::Memory, ℓ::Integer)
    start_idx = ptr.addr + one(T)
    end_idx = start_idx + ℓ - 1
    m.v[start_idx:end_idx]
end
deref(ptr::Π, m::Memory, ℓ::Integer) = dereference(ptr, m, ℓ)

# returns SubArray
function derefview{T}(ptr::Π{T}, m::Memory, ℓ::Integer)
    start_idx = ptr.addr + one(T)
    end_idx = start_idx + ℓ - 1
    view(m.v, start_idx:end_idx)
end

store!{T}(m::Memory, ptr::Π{T}, val::UInt8) = (m[ptr.addr] = val)
# this stores backwards from the supplied memory address
function storeback!{T}(m::Memory, ptr::Π{T}, val::UInt16)
    m[ptr] = UInt8(val >> 8)
    m[ptr - 0x01] = UInt8(0x00ff & val)
    val
end

(+){T}(ptr1::Π{T}, ptr2::Π{T}) = Π{T}(ptr1.addr + ptr2.addr)
(-){T}(ptr1::Π{T}, ptr2::Π{T}) = Π{T}(ptr1.addr - ptr2.addr)

(+){T}(ptr::Π{T}, val::Unsigned) = Π{T}(ptr.addr + convert(T, val))
(-){T}(ptr::Π{T}, val::Unsigned) = Π{T}(ptr.addr - convert(T, val))

export dereference, deref, ↦, ⇾, store!, +, -
#===================================================================================================
    </referencing>
===================================================================================================#


