

cs = Chipset()


@assemble cs begin
    LDA, 0x01
    STA, 0x0200
    LDA, 0x05
    STA, 0x0201
    LDA, 0x08
    STA, 0x0202
    BRK
end

