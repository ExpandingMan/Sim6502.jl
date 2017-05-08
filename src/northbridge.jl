#===================================================================================================
This is a container type for bringing together CPU and Memory with a common clock

Northbridge is an archaic term coming from the days of FSB's and consisted of the FSB plus
a bunch of other stuff connecting the CPU.  I chose it because there isn't really an appropriate
term describing the CPU + Memory (plus nothing else).

There's a good chance this implementation will change, so try not to make functions written
for this thing as generic as possible!
===================================================================================================#


# this will serve as the default. Note this was the NES mater clock / 16
const NES_CLOCK_PERIOD = 1.0/1.662607 * 10.0^(-6)


mutable struct Northbridge
    cpu::CPU
    ram::Memory

    δt::Float64

    clock::Int64

    Northbridge(c::CPU, m::Memory, δt::AbstractFloat) = new(c, m, δt, 0)
    Northbridge(c::CPU, m::Memory) = Northbridge(c, m, NES_CLOCK_PERIOD)
    Northbridge() = Northbridge(CPU(), Memory())
end
export Northbridge


# this is a nu, not a v
ν(nb::Northbridge) = 1.0/nb.δt
ω(nb::Northbridge) = 2π/nb.δt

# a tick where the CPU is forced to sleep
idletick!(nb::Northbridge) = (nb.clock += 1)


