extension LZ77 {
    protocol HuffmanPattern<Symbol> {
        associatedtype Symbol

        init(_ symbol: Symbol, length: Int)
    }
}

@available(*, deprecated, renamed: "LZ77.HuffmanPattern")
typealias _LZ77HuffmanPattern = LZ77.HuffmanPattern

extension LZ77 {
    @available(*, deprecated, message: "Namespace no longer in use.")
    enum Symbol {
        @available(*, deprecated, renamed: "LZ77.HuffmanPattern")
        typealias Pattern = LZ77.HuffmanPattern

        @available(*, deprecated)
        typealias Meta = LZ77.Metaword
        @available(*, deprecated)
        typealias RunLiteral = LZ77.RunLiteral
        @available(*, deprecated)
        typealias Distance = LZ77.Distance
    }
}
