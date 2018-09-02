module Sim6502

using MacroTools

using FunctionWrappers: FunctionWrapper

include("utils.jl")
include("cpu.jl")
include("memory.jl")
include("boilerplate.jl")
include("instructions.jl")
include("chipset.jl")
include("opcodes.jl")
include("assembler.jl")

export CPU, store!, counter!, describe, status, status!, status_string
export Memory, Π, Π8, Π16, reset!, dereference, deref, ↦, ⇾, store!
export Chipset

export AddressingMode, DirectMode, IndirectMode, Direct, DirectX, DirectY, IndirectX,
    IndirectY

export op!, tick!, @assemble


# these are all instruction pieces which probably shouldn't be exported
export ld!, lda!, ldx!, ldy!, st!, sta!, stx!, sty!, t!, tax!, tay!, txa!, tya!,
    tsx!, txs!, pha!, php!, pla!, plp!
export and!, eor!, ora!, bit!, adc!, sbc!, compare!, cmp!, cpx!, cpy!
export increment!, inc!, inx!, iny!, decrement!, dec!, dex!, dey!
export arithmetic_shiftleft!, asl!, logical_shiftright!, lsr!, rotateleft!, rol!,
    rotateright!, ror!
export jmp!, jsr!, rts!
export bcc!, bcs!, beq!, bmi!, bne!, bpl!, bvc!, bvs!
export clc!, cld!, cli!, clv!, sec!, sed!, sei!, brk!, nop!, rti!


end # module
