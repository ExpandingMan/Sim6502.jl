module Sim6502

import Base.fetch
import Base: +, -

include("utils.jl")
include("cpu.jl")
include("memory.jl")
include("instructions.jl")

end # module
