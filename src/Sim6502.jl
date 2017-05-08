__precompile__(true)

# Note that I expect to use `import` instead of `using` when making the NES sim

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
include("northbridge.jl")

end # module
