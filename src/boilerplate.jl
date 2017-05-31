#===================================================================================================
Here we keep some macros for doing boilerplate code generation...
===================================================================================================#
# TODO deal with page crossings!!!

opfuncname(opcode::UInt8) = Symbol(string("op", hexstring(opcode), "!"))
opstring(fname::Symbol) = strip(string(fname), '!')

function assemblydict(opname::Symbol, mode::Symbol, opcode::UInt8)
    :(ASSEMBLY_DICT[($(opstring(opname)),$(QuoteNode(mode)))] = $opcode)
end


function opdict(opcode::UInt8, nbytes::Int, ncycles::Int)
    :(OPCODES[$opcode] = ($(opfuncname(opcode)), $nbytes, $ncycles))
end


function opdef_Implicit(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset) = $opname(cs.cpu)
    end
end

function opdef_Immediate(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset) = $opname(cs.cpu, opargs(cs, 1))
    end
end

function opdef_ZeroPage(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset) = $opname(cs.cpu, cs.ram, Π8(opargs(cs, 1)))
    end
end

function opdef_ZeroPageX(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset) = $opname(cs.cpu, cs.ram, DirectX, Π8(opargs(cs, 1)))
    end
end

function opdef_ZeroPageY(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset) = $opname(cs.cpu, cs.ram, DirectY, Π8(opargs(cs, 1)))
    end
end

function opdef_Absolute(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset) = $opname(cs.cpu, cs.ram, Direct, Π16(opargs(cs,1), opargs(cs,2)))
    end
end

function opdef_AbsoluteX(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset) = $opname(cs.cpu, cs.ram, DirectX, Π16(opargs(cs,1), opargs(cs,2)))
    end
end

function opdef_AbsoluteY(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset) = $opname(cs.cpu, cs.ram, DirectY, Π16(opargs(cs,1), opargs(cs,2)))
    end
end

function opdef_Indirect(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset) = $opname(cs.cpu, cs.ram, Indirect, Π16(opargs(cs,1), opargs(cs,2)))
    end
end

function opdef_IndirectX(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset) = $opname(cs.cpu, cs.ram, IndirectX, Π8(opargs(cs,1)))
    end
end

function opdef_IndirectY(opname::Symbol, opcode::UInt8)
    fname = opfuncname(opcode)
    quote
        $fname(cs::Chipset) = $opname(cs.cpu, cs.ram, IndirectY, Π8(opargs(cs,1)))
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
    elseif mode == :Indirect
        return opdef_Indirect(opname, opcode)
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
    if @capture(defblock, begin defs__ end)
        defs = [ex.args for ex ∈ defs]
        funcdefs = [opdef(d[1], opname, d[2]) for d ∈ defs]
        dictries = [opdict(d[2], d[3], d[4]) for d ∈ defs]
        assemblies = [assemblydict(opname, d[1], d[2]) for d ∈ defs]
    else
        throw(AssertionError("Improper op definition for $opname."))
    end
    esc(quote
        $(funcdefs...)
        $(dictries...)
        $(assemblies...)
    end)
end

