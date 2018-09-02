
# this is the default stack page
# ultimately this should be a property of either the CPU or Chipset
const STACK_PAGE = 0x0100

# TODO WTF is with the break (B) flag?
mutable struct FlagsRegister
    C::Bool
    Z::Bool
    I::Bool
    D::Bool
    B::Bool
    Ω::Bool
    V::Bool
    N::Bool

    FlagsRegister() = new(false, false, false, false, false, false, false, false)
end


mutable struct CPU
    A::UInt8  # accumulator register
    X::UInt8  # index registers
    Y::UInt8
    SP::UInt8  # stack pointer register, I'm tempted to make this 16-bit
    PC::UInt16  # program counter register
    flags::FlagsRegister

    function CPU(A::UInt8=0x00, X::UInt8=0x00, Y::UInt8=0x00,
                 SP::UInt8=0xff, PC::UInt16=0x0600, flags::FlagsRegister=FlagsRegister())
        new(A, X, Y, SP, PC, flags)
    end
end


@inline Base.fetch(c::CPU, reg::Symbol) = getfield(c, reg)
@inline store!(c::CPU, reg::Symbol, val::Integer) = setfield!(c, reg, val)

counter!(c::CPU, ℓ::Unsigned) = (c.PC += ℓ)


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

Base.show(io::IO, c::CPU) = print(describe(c))


#==============================================================================================
    <status register access>
==============================================================================================#
status(fr::FlagsRegister, flag::Symbol)::Bool = getfield(fr, flag)
status(c::CPU, flag::Symbol)::Bool = getfield(fr, flag)

# these are toggles
status!(fr::FlagsRegister, flag::Symbol) = setfield!(fr, ~getfield(fr, flag))
status!(c::CPU, flag::Symbol) = status!(c.flags, flag)

status!(fr::FlagsRegister, flag::Symbol, val::Bool) = setfield!(fr, flag, val)
status!(c::CPU, flag::Symbol, val::Bool) = status!(c.flags, flag, val)

function status_string(fr::FlagsRegister)
    string((Int(getfield(fr, f)) for f ∈ reverse(fieldnames(typeof(fr))))...)
end
status_string(c::CPU) = status_string(c.flags)

#==============================================================================================
    </status register access>
==============================================================================================#


#==============================================================================================
    <special pointers>
==============================================================================================#
stackpointer(c::CPU) = Π(STACK_PAGE + c.SP)
#==============================================================================================
    </special pointers>
==============================================================================================#

