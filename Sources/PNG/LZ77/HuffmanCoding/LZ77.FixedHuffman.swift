extension LZ77
{
    enum FixedHuffman
    {
    }
}
extension LZ77.FixedHuffman
{
    static
    let runliteral:LZ77.Huffman<UInt16> = .init(
        symbols: [256 ... 279, 0 ... 143, 280 ... 287, 144 ... 255].flatMap{ $0 },
        levels:
            .init(repeating:   0 ..<   0, count: 6) + // L1 ... L6
            [0 ..< 24, 24 ..< 176, 176 ..< 288]     + // L7, L8, L9
            .init(repeating: 288 ..< 288, count: 6)   // L10 ... L15
        )
    static
    let distance:LZ77.Huffman<UInt8> = .init(
        symbols: .init(0 ... 31),
        levels:
            .init(repeating:  0 ..<  0, count:  4)  +
            [0 ..< 32]                              +
            .init(repeating: 32 ..< 32, count: 10)
        )
}
