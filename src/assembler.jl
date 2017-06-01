
# TODO currently the program is dynamically allocated


_mode(instr::Symbol) = (:Implicit, instr, nothing)

function _mode(instr::Expr, line::Integer=-1)
    if @capture(instr, (op_,))
        return (:Implicit, op, nothing)
    elseif @capture(instr, (op_, arg_UInt8))
        return (:Immediate, op, arg)
    elseif @capture(instr, (op_, Π(arg_UInt8)))
        return (:ZeroPage, op, arg)
    elseif @capture(instr, (op_, Π(arg_UInt16)))
        return (:Absolute, op, arg)
    elseif @capture(instr, (op_, Π(arg_UInt8), X))
        return (:ZeroPageX, op, arg)
    elseif @capture(instr, (op_, Π(arg_UInt8), Y))
        return (:ZeroPageY, op, arg)
    elseif @capture(instr, (op_, Π(arg_UInt16), X))
        return (:AbsoluteX, op, arg)
    elseif @capture(instr, (op_, Π(arg_UInt16), Y))
        return (:AbsoluteY, op, arg)
    elseif @capture(instr, (op_, (Π(arg_UInt16),)))
        return (:Indirect, op, arg)
    elseif @capture(instr, (op_, (Π(arg_UInt8),X)))
        return (:IndirectX, op, arg)
    elseif @capture(instr, (op_, (Π(arg_UInt8),Y)))
        return (:IndirectY, op, arg)
    end
    throw(ArgumentError("Assembly Error: Unparsable instruction at line $line: `$instr`."))
end

_assembly_lookup(op::String, mode::Symbol) = ASSEMBLY_DICT[(op,mode)]

_assembly_args(::Void) = nothing
_assembly_args(x::UInt8) = x
_assembly_args(x::UInt16) = reinterpret(UInt8, [x])

function assemble!(program::Vector{UInt8}, instr::Union{Expr,Symbol})
    mode, op, arg = _mode(instr)
    op = lowercase(string(op))
    opcode = _assembly_lookup(op, mode)
    args = _assembly_args(arg)
    if args == nothing
        push!(program, opcode)
    else
        append!(program, UInt8[opcode; args])
    end
end


macro assemble(block::Expr)
    program = Vector{UInt8}()  # for now we'll dynamically allocate
    if @capture(block, begin instrs__ end)
        for instr ∈ instrs
            assemble!(program, instr)
        end
    else
        throw(ArgumentError("Assembly Error: Malformed instruction block."))
    end
    :($program)
end
export @assemble
