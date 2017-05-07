
hexstring(n::Unsigned) = string("0x", hex(n, sizeof(n)<<1))

# as simple as this seems in retrospect, it was confusing to figure out, hence the shortcut
overflow(a::T, b::T) where T<:Unsigned = b > typemax(T) - a


