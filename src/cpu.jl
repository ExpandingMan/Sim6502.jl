

# TODO WTF is with the break (B) flag?

mutable struct CPU
    A::UInt8  # accumulator register
    X::UInt8  # index registers
    Y::UInt8
    SP::UInt8  # stack pointer register, I'm tempted to make this 16-bit
    PC::UInt16  # program counter register
    P::UInt8  # processor status register

    function CPU(A::UInt8=0x00, X::UInt8=0x00, Y::UInt8=0x00,
                 SP::UInt8=0xff, PC::UInt16=0x0600, P::UInt8=0x00)
        new(A, X, Y, SP, PC, P)
    end
end
export CPU


fetch(c::CPU, reg::Symbol) = getfield(c, reg)
store!(c::CPU, reg::Symbol, val::Integer) = setfield!(c, reg, val)
export fetch, store!

counter!(c::CPU, ℓ::Unsigned) = (c.PC += ℓ)
export counter!



function describe(c::CPU)
    st = status_string(c)
    A = hexstring(c.A); X = hexstring(c.X); Y = hexstring(c.Y)
    SP = hexstring(c.SP); PC = hexstring(c.PC)
    """
    MOS6502 CPU
        Registers:
            A=$A  X=$X  Y=$Y
            SP=$SP  PC=$PC
        Status: NV-BDIZC
                $st
    """
end
export descripbe

import Base.show
Base.show(io::IO, c::CPU) = print(describe(c))


#===================================================================================================
    <status register access>
===================================================================================================#
const REGISTER_DICT = Dict(:C=>0x01,
                           :Z=>0x02,
                           :I=>0x04,
                           :D=>0x08,
                           :B=>0x10,
                           :V=>0x40,
                           :N=>0x80)
status(c::CPU, flag::UInt8) = Bool(flag & c.P)
status(c::CPU, flag::Symbol) = status(c, REGISTER_DICT[flag])

# these are toggles; note they return the P register, not just the one bit
status!(c::CPU, flag::UInt8) = (c.P = c.P ⊻ flag)
status!(c::CPU, flag::Symbol) = status!(c, REGISTER_DICT[flag])

function status!(c::CPU, flag::UInt8, val::Bool)
    if val
        c.P = c.P | flag
    else
        c.P = ~(~c.P | flag)
    end
end
status!(c::CPU, flag::Symbol, val::Bool) = status!(c, REGISTER_DICT[flag], val)

status_string(c::CPU) = bits(c.P)

export status, status!, status_string
#===================================================================================================
    </status register access>
===================================================================================================#

