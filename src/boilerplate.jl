#===================================================================================================
Here we keep some macros for doing boilerplate code generation...
===================================================================================================#
# TODO deal with page crossings!!!

opfuncname(opcode::UInt8) = Symbol(string("op", hexstring(opcode), "!"))


function opdict(opcode::UInt8, nbytes::Int, ncycles::Int)
    :(OPCODES[$opcode] = ($(opfuncname(opcode)), $nbytes, $ncycles))
end


function opdef_Immediate(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset, bytes::AbstractVector{UInt8}) = $opname(cs.cpu, bytes[1])
    end
end

function opdef_ZeroPage(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset, bytes::AbstractVector{UInt8}) = $opname(cs.cpu, cs.ram, Π8(bytes))
    end
end

function opdef_ZeroPageX(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset, bytes::AbstractVector{UInt8}) = $opname(cs.cpu, cs.ram, DirectX, Π8(bytes))
    end
end

function opdef_ZeroPageY(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset, bytes::AbstractVector{UInt8}) = $opname(cs.cpu, cs.ram, DirectY, Π8(bytes))
    end
end

function opdef_Absolute(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset, bytes::AbstractVector{UInt8}) = $opname(cs.cpu, cs.ram, Π16(bytes))
    end
end

function opdef_AbsoluteX(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset, bytes::AbstractVector{UInt8}) = $opname(cs.cpu, cs.ram, DirectX, Π16(bytes))
    end
end

function opdef_AbsoluteY(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset, bytes::AbstractVector{UInt8}) = $opname(cs.cpu, cs.ram, DirectY, Π16(bytes))
    end
end

function opdef_IndirectX(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset, bytes::AbstractVector{UInt8}) = $opname(cs.cpu, cs.ram, IndirectX, Π8(bytes))
    end
end

function opdef_IndirectY(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset, bytes::AbstractVector{UInt8}) = $opname(cs.cpu, cs.ram, IndirectY, Π8(bytes))
    end
end




function opdef(mode::Symbol, opname::Symbol, opcode::UInt8)
    if mode == :Implicit
        return opdef_Implicit(opname, opcode)
    elseif mode == :Accumulator
        return opdef_Accumulator(opname, opcode)
    elseif mode == :Immediate
        return opdef_Immediate(opname, opcode)
    elseif mode == :ZeroPage
        return opdef_ZeroPage(opname, opcode)
    elseif mode == :ZeroPageX
        return opdef_ZeroPageX(opname, opcode)
    elseif mode == :ZeroPageY
        return opdef_ZeroPageY(opname, opcode)
    elseif mode == :Absolute
        return opdef_Absolute(opname, opcode)
    elseif mode == :AbsoluteX
        return opdef_AbsoluteX(opname, opcode)
    elseif mode == :AbsoluteY
        return opdef_AbsoluteY(opname, opcode)
    elseif mode == :IndirectX
        return opdef_IndirectX(opname, opcode)
    elseif mode == :IndirectY
        return opdef_IndirectY(opname, opcode)
    elseif mode == :Relative
        return opdef_Relative(opname, opcode)
    else
        throw(ArgumentError("Invalid oparation mode $mode."))
    end
end






macro opdef(opname::Symbol, defblock::Expr)
    @capture(defblock, begin defs__ end)
    defs = [tuple(ex.args...) for ex ∈ defs]
    funcdefs = [opdef(d[1], opname, d[2]) for d ∈ defs]
    dictries = [opdict(d[2], d[3], d[4]) for d ∈ defs]
    esc(quote
        $(funcdefs...)
        $(dictries...)
    end)
end

