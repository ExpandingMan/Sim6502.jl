
# little-endian
bincat(x::UInt8, y::UInt8)::UInt16 = convert(UInt16, x) + (convert(UInt16, y) << 8)

hexstring(n::Unsigned) = string("0x", hex(n, sizeof(n)<<1))

# as simple as this seems in retrospect, it was confusing to figure out, hence the shortcut
overflow(a::T, b::T) where T<:Unsigned = b > typemax(T) - a


