

checkNflag!(c::CPU, val::UInt8) = val ≥ 0x80 ? status!(c, :N, true) : status!(c, :N, false)
checkZflag!(c::CPU, val::UInt8) = val == 0x00 ? status!(c, :Z, true) : status!(c, :Z, false)


#===================================================================================================
    <load, store instructions>
===================================================================================================#
# template for ld instructions in immediate mode
function ld!(c::CPU, register::Symbol, val::UInt8)
    v = setfield!(c, register, val)
    checkNflag!(c, v)
    checkZflag!(c, v)
    counter!(c, 0x02)
    v
end

# immediate mode
lda!(c::CPU, val::UInt8) = ld!(c, :A, val)
ldx!(c::CPU, val::UInt8) = ld!(c, :X, val)
ldy!(c::CPU, val::UInt8) = ld!(c, :Y, val)

export ld!, lda!, ldx!, ldy!
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

