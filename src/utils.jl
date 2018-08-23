
# little-endian
@inline bincat(x::UInt8, y::UInt8) = convert(UInt16, x) + (convert(UInt16, y) << 8)

hexstring(n::Unsigned) = string("0x", repeat("0", sizeof(n)<<1), bytes2hex([n]))

# as simple as this seems in retrospect, it was confusing to figure out, hence the shortcut
@inline overflow(a::T, b::T) where T<:Unsigned = b > typemax(T) - a


