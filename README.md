# Sim6502

[![Build Status](https://travis-ci.org/ExpandingMan/Sim6502.jl.svg?branch=master)](https://travis-ci.org/ExpandingMan/Sim6502.jl)

[![Coverage Status](https://coveralls.io/repos/ExpandingMan/Sim6502.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/ExpandingMan/Sim6502.jl?branch=master)

[![codecov.io](http://codecov.io/github/ExpandingMan/Sim6502.jl/coverage.svg?branch=master)](http://codecov.io/github/ExpandingMan/Sim6502.jl?branch=master)

A simulator of the venerable MOS 6502 microprocessor written in pure Julia.

A couple of things to note:

- This program simulates the full internal state of the 6502.  It is, therefore, less performant than programs which are designed specifically for fast
    emulations.  Currently `Sim6502` achieves a little over 10 times the rate of instruction execution as the original 6502 chip on a 2 GHz Intel x86 processor.
    I suspect this is within a factor of 2 or 3 of the theoretical maximum (again, while achieving a full simulation).  Note that executing any 6502 instruction
    involves 0 hash-table look-ups.
- Currently I'm making no effort to make this simulation generic.  It is designed only for the 6502.
