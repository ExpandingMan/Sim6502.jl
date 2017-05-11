#===================================================================================================
This is a container type for bringing together CPU and Memory with a common clock

There's a good chance this implementation will change, so try not to make functions written
for this thing as generic as possible!
===================================================================================================#


# this will serve as the default. Note this was the NES mater clock / 16
const NES_CLOCK_PERIOD = 1.0/1.662607 * 10.0^(-6)


mutable struct Chipset
    cpu::CPU
    ram::Memory

    δt::Float64

    clock::Int64

    Chipset(c::CPU, m::Memory, δt::AbstractFloat) = new(c, m, δt, 0)
    Chipset(c::CPU, m::Memory) = Chipset(c, m, NES_CLOCK_PERIOD)
    Chipset() = Chipset(CPU(), Memory())
end
export Chipset


# this is a nu, not a v
ν(cs::Chipset) = 1.0/cs.δt
ω(cs::Chipset) = 2π/cs.δt

# a tick where the CPU is forced to sleep
idletick!(cs::Chipset) = (cs.clock += 1)


