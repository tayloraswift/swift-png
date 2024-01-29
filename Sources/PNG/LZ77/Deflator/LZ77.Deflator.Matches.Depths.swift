extension LZ77.Deflator.Matches
{
    struct Depths
    {
        private
        var storage:[UInt8]
        private(set)
        var generic:Bool
    }
}
extension LZ77.Deflator.Matches.Depths
{
    //  depth table layout:
    //
    //    0 ┌───────────────────────┐   0
    //      │                       │
    //      │     256 literals      │
    //      │                       │
    //  256 ├───────────────────────┤ 256/3
    //      │                       │
    //      │     256 lengths       │
    //      │                       │
    //  512 ├───────────────────────┤ 258/0
    //      │  30 distance decades  │
    //  542 └───────────────────────┘  30
    //
    //  to take full advantage of the 8-bit storage space, we use 0.125-bit
    //  fixed-point fractional bit lengths

    private static // literal cost: 8.25 bps
    let `default`:[UInt8] = .init(repeating: 33, count: 256)
    // base run composite cost: 7.5 bps
    + (3 ... 258).map
    {
        (run:Int) -> UInt8 in
        30 + .init(LZ77.Composites[run: LZ77.Decades[run: run]].extra) << 2
    }
    // base distance composite cost: 4.75 bps
    + (0 ... 29).map
    {
        (decade:UInt8) -> UInt8 in
        19 + .init(LZ77.Composites[distance: decade           ].extra) << 2
    }

    init()
    {
        self.storage = Self.default
        self.generic = true
    }

    mutating
    func update(runliteral:LZ77.Huffman<UInt16>, distance:LZ77.Huffman<UInt8>)
    {
        for (length, level):(UInt8, Range<Int>) in zip(1 ... 15, runliteral.levels)
        {
            for symbol:UInt16 in runliteral.symbols[level]
            {
                if      symbol < 256
                {
                    self.storage[.init(symbol)] = length << 2
                }
                else if symbol > 256
                {
                    let decade:(extra:UInt16, base:UInt16) =
                        LZ77.Composites[run: .init(truncatingIfNeeded: symbol)]
                    let length:UInt8    = length + .init(decade.extra)
                    let base:Int        = 253 +    .init(decade.base ),
                        count:Int       =   1 <<         decade.extra
                    for l:Int in base ..< base + count
                    {
                        self.storage[l] = length << 2
                    }
                }
            }
        }
        for (length, level):(UInt8, Range<Int>) in zip(1 ... 15, distance.levels)
        {
            for symbol:UInt8 in distance.symbols[level]
            {
                let extra:UInt8 = .init(LZ77.Composites[distance: symbol].extra)
                self.storage[512 + .init(symbol)] = (length + extra) << 2
            }
        }
        self.generic = false
    }
    mutating
    func generalize()
    {
        for i:Int in self.storage.indices
        {
            let specialized:UInt8 = self.storage[i],
                generalized:UInt8 = Self.default[i]
            self.storage[i] = (specialized & generalized) &+ (specialized ^ generalized) >> 1
        }
        // don’t reset self.generic because the depths still contain some
        // specialized information
    }

    subscript(literal literal:UInt8) -> UInt32
    {
        .init(self.storage[.init(literal)])
    }
    subscript(run run:Int) -> UInt32
    {
        .init(self.storage[253 + run])
    }
    subscript(distance decade:UInt8) -> UInt32
    {
        .init(self.storage[512 + .init(decade)])
    }
}
