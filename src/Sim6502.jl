__precompile__(true)

module Sim6502

using MacroTools

import Base.fetch
import Base.pointer
import Base: +, -

include("utils.jl")
include("cpu.jl")
include("memory.jl")
include("boilerplate.jl")
include("instructions.jl")

end # module
