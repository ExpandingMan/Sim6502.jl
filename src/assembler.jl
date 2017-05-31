
macro assemble(cs::Symbol, block::Expr)
    if @capture(block, begin instr__ end)

    else
        throw(ArgumentError("Assembly Error: Malformed instruction block."))
    end
end
export @assemble
