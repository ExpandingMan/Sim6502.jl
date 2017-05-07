

checkNflag!(c::CPU, val::UInt8) = val ≥ 0x80 ? status!(c, :N, true) : status!(c, :N, false)
checkZflag!(c::CPU, val::UInt8) = val == 0x00 ? status!(c, :Z, true) : status!(c, :Z, false)


#===================================================================================================
    <load, store instructions>
===================================================================================================#
#-----------------------LDA, LDX, LDY----------------------------------------------
# template for ld instructions in immediate mode
function ld!(c::CPU, reg::Symbol, val::UInt8)
    v = store!(c, reg, val)
    checkNflag!(c, v)
    checkZflag!(c, v)
    counter!(c, 0x02)
    v
end

# immediate mode
lda!(c::CPU, val::UInt8) = ld!(c, :A, val)
ldx!(c::CPU, val::UInt8) = ld!(c, :X, val)
ldy!(c::CPU, val::UInt8) = ld!(c, :Y, val)

# template for ld instructions in zero page or absolute mode
ld!(c::CPU, m::Memory, reg::Symbol, ptr::Π) = ld!(c, reg, ptr ↦ m)

lda!(c::CPU, m::Memory, ptr::Π) = ld!(c, m, :A, ptr)
ldx!(c::CPU, m::Memory, ptr::Π) = ld!(c, m, :X, ptr)
ldy!(c::CPU, m::Memory, ptr::Π) = ld!(c, m, :Y, ptr)

# zero page,X,Y and absolute,X,Y; note this also works with A, even though that's not a real instruction!
ld!(c::CPU, m::Memory, reg::Symbol, ptr::Π, idx::Symbol) = ld!(c, m, reg, (ptr + fetch(c,idx)) ↦ m)

lda!(c::CPU, m::Memory, ptr::Π, idx::Symbol) = ld!(c, m, :A, ptr, idx)
ldx!(c::CPU, m::Memory, ptr::Π, idx::Symbol) = ld!(c, m, :X, ptr, idx)
ldy!(c::CPU, m::Memory, ptr::Π, idx::Symbol) = ld!(c, m, :Y, ptr, idx)

export ld!, lda!, ldx!, ldy!


#---------------------STA, STX, STY------------------------------------------------
# template for st in zero page or absolute mode
st!(c::CPU, m::Memory, reg::Symbol, ptr::Π) = store!(m, ptr, fetch(c, reg))

# zero page or absolute mode
sta!(c::CPU, m::Memory, ptr::Π) = st!(c, m, :A, ptr)
stx!(c::CPU, m::Memory, ptr::Π) = st!(c, m, :X, ptr)
sty!(c::CPU, m::Memory, ptr::Π) = st!(c, m, :Y, ptr)

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

