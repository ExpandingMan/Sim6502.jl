__precompile__(true)

# Note that I expect to use `import` instead of `using` when making the NES emulator

module Sim6502

using MacroTools

import FunctionWrappers: FunctionWrapper

import Base.fetch
import Base.pointer
import Base: +, -

include("utils.jl")
include("cpu.jl")
include("memory.jl")
include("boilerplate.jl")
include("instructions.jl")
include("chipset.jl")
include("opcodes.jl")

end # module
