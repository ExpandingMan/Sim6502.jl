#===================================================================================================
Here we keep some macros for doing boilerplate code generation...
===================================================================================================#
# TODO deal with page crossings!!!

opfuncname(opcode::UInt8) = Symbol(string("op", hexstring(opcode), "!"))


opdict(opcode::UInt8, nbytes::Int) = :(OPCODES[$opcode] = ($nbytes, $(opfuncname(opcode))))


function opdef_Immediate(opname::Symbol, opcode::UInt8, nbytes::Int, ncycles::Int)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset, bytes::AbstractVector{UInt8}) = ($opname(cs.cpu, bytes2arg(bytes)); $nbytes)
    end
end

function opdef_ZeroPage(opname::Symbol, opcode::UInt8, nbytes::Int, ncycles::Int)
    fname = opfuncname(opcode)
    quote
        function $fname(cs::Chipset, bytes::AbstractVector{UInt8})
            $opname(cs.cpu, cs.ram, Π8(bytes))
            $ncycles
        end
    end
end

function opdef_ZeroPageX(opname::Symbol, opcode::UInt8, nbytes::Int, ncycles::Int)
    fname = opfuncname(opcode)
    quote
        function $fname(cs::Chipset, bytes::AbstractVector{UInt8})
            $opname(cs.cpu, cs.ram, DirectX, Π8(bytes))
            $ncycles
        end
    end
end

function opdef_ZeroPageY(opname::Symbol, opcode::UInt8, nbytes::Int, ncycles::Int)
    fname = opfuncname(opcode)
    quote
        function $fname(cs::Chipset, bytes::AbstractVector{UInt8})
            $opname(cs.cpu, cs.ram, DirectY, Π8(bytes))
            $ncycles
        end
    end
end

function opdef_Absolute(opname::Symbol, opcode::UInt8, nbytes::Int, ncycles::Int)
    fname = opfuncname(opcode)
    quote
        function $fname(cs::Chipset, bytes::AbstractVector{UInt8})
            $opname(cs.cpu, cs.ram, Π16(bytes))
            $ncycles
        end
    end
end

function opdef_AbsoluteX(opname::Symbol, opcode::UInt8, nbytes::Int, ncycles::Int)
    fname = opfuncname(opcode)
    quote
        function $fname(cs::Chipset, bytes::AbstractVector{UInt8})
            $opname(cs.cpu, cs.ram, DirectX, Π16(bytes))
            $ncycles
        end
    end
end

function opdef_AbsoluteY(opname::Symbol, opcode::UInt8, nbytes::Int, ncycles::Int)
    fname = opfuncname(opcode)
    quote
        function $fname(cs::Chipset, bytes::AbstractVector{UInt8})
            $opname(cs.cpu, cs.ram, DirectY, Π16(bytes))
            $ncycles
        end
    end
end

function opdef_IndirectX(opname::Symbol, opcode::UInt8, nbytes::Int, ncycles::Int)
    fname = opfuncname(opcode)
    quote
        function $fname(cs::Chipset, bytes::AbstractVector{UInt8})
            $opname(cs.cpu, cs.ram, IndirectX, Π8(bytes))
            $ncycles
        end
    end
end

function opdef_IndirectY(opname::Symbol, opcode::UInt8, nbytes::Int, ncycles::Int)
    fname = opfuncname(opcode)
    quote
        function $fname(cs::Chipset, bytes::AbstractVector{UInt8})
            $opname(cs.cpu, cs.ram, IndirectY, Π8(bytes))
            $ncycles
        end
    end
end





function opdef(mode::Symbol, opname::Symbol, opcode::UInt8, nbytes::Int, ncycles::Int)
    if mode == :Implicit
        return opdef_Implicit(opname, opcode, nbytes, ncycles)
    elseif mode == :Accumulator
        return opdef_Accumulator(opname, opcode, nbytes, ncycles)
    elseif mode == :Immediate
        return opdef_Immediate(opname, opcode, nbytes, ncycles)
    elseif mode == :ZeroPage
        return opdef_ZeroPage(opname, opcode, nbytes, ncycles)
    elseif mode == :ZeroPageX
        return opdef_ZeroPageX(opname, opcode, nbytes, ncycles)
    elseif mode == :ZeroPageY
        return opdef_ZeroPageY(opname, opcode, nbytes, ncycles)
    elseif mode == :Absolute
        return opdef_Absolute(opname, opcode, nbytes, ncycles)
    elseif mode == :AbsoluteX
        return opdef_AbsoluteX(opname, opcode, nbytes, ncycles)
    elseif mode == :AbsoluteY
        return opdef_AbsoluteY(opname, opcode, nbytes, ncycles)
    elseif mode == :IndirectX
        return opdef_IndirectX(opname, opcode, nbytes, ncycles)
    elseif mode == :IndirectY
        return opdef_IndirectY(opname, opcode, nbytes, ncycles)
    elseif mode == :Relative
        return opdef_Relative(opname, opcode, nbytes, ncycles)
    else
        throw(ArgumentError("Invalid oparation mode $mode."))
    end
end






macro opdef(opname::Symbol, defblock::Expr)

end

