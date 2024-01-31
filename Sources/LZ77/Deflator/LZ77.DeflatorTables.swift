extension LZ77
{
    struct DeflatorTables
    {
        private
        let storage:ManagedBuffer<Void, LZ77.Codeword>

        //                heap
        //    0 ┌───────────────────────┐
        //      │                       │
        //      │                       │
        //      │                       │
        //      │  runliteral codewords │ : 288 * Codeword
        //      │                       │
        //      │                       │
        //      │                       │
        //  288 ├───────────────────────┤
        //      │   distance codewords  │ :  32 * Codeword
        //  320 ├───────────────────────┤
        //      │     meta codewords    │ :  19 * Codeword
        //  339 └───────────────────────┘
    }
}
extension LZ77.DeflatorTables
{
    init(runliteral:LZ77.HuffmanTree<UInt16>,
        distance:LZ77.HuffmanTree<UInt8>,
        meta:LZ77.HuffmanTree<UInt8>? = nil)
    {
        self.storage = .create(minimumCapacity: 339){ _ in () }
        self.storage.withUnsafeMutablePointerToElements
        {
            runliteral.codewords(initializing: $0,       count: 288)
            {
                $0 > 256 ?
                .init(LZ77.Composites[run: .init(truncatingIfNeeded: $0)].extra) : 0
            }
            distance.codewords(  initializing: $0 + 288, count:  32)
            {
                .init(LZ77.Composites[distance: $0].extra)
            }
            meta?.codewords(     initializing: $0 + 320, count:  19)
            {
                switch $0
                {
                case 18: return 7
                case 17: return 3
                case 16: return 2
                default: return 0
                }
            }
        }
    }

    subscript(runliteral symbol:UInt16) -> LZ77.Codeword
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            ($0      )[.init(symbol)]
        }
    }
    subscript(distance symbol:UInt8) -> LZ77.Codeword
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            ($0 + 288)[.init(symbol)]
        }
    }
    subscript(meta symbol:UInt8) -> LZ77.Codeword
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            ($0 + 320)[.init(symbol)]
        }
    }

    static
    let fixed:Self = .init(runliteral: .runliteral, distance: .distance)
}
