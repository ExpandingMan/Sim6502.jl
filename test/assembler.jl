using Sim6502

cs = Chipset()


program = @assemble begin
    LDA, 0x01
    STA, Π(0x0200)
    LDA, 0x05
    STA, Π(0x0201)
    LDA, 0x08
    STA, Π(0x0202)
    BRK
end


