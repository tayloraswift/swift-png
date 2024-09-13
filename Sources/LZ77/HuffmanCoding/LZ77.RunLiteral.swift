extension LZ77
{
    struct RunLiteral:HuffmanPattern
    {
        // 16               8               0
        //  [c:c:c:c: : : :s|s:s:s:s:s:s:s:s]
        //   ~~~~~~~^      ~~~~~~~~~~~~~~~~~^
        //     length                  symbol
        private
        let storage:UInt16

        init(_ symbol:UInt16, length:Int)
        {
            self.storage = .init(length) << 12 | symbol
        }
    }
}
extension LZ77.RunLiteral
{
    var symbol:UInt16
    {
        self.storage & 0b0000_0001_1111_1111
    }
    var literal:UInt8
    {
        .init(truncatingIfNeeded: self.storage)
    }
    var decade:Int
    {
        let value = self.storage & 0b0000_0000_1111_1111
        #if DEBUG
            // this hacky integer conversion makes this function about 12x faster in
            // debug mode. cause of Int, we have to handle both 32-bit and 64-bit
            // systems separately.
            if MemoryLayout<Int>.stride == 8 {
                let tuple:(UInt16, UInt16, UInt16, UInt16) = (value, 0, 0, 0)
                return unsafeBitCast(tuple, to: Int.self)
            } else {
                let tuple:(UInt16, UInt16) = (value, 0)
                return unsafeBitCast(tuple, to: Int.self)
            }
        #else
            return .init(value)
        #endif
    }
    var length:Int
    {
        let value = self.storage >> 12
        #if DEBUG
            // this hacky integer conversion makes this function about 27x faster in
            // debug mode. cause of Int, we have to handle both 32-bit and 64-bit
            // systems separately.
            if MemoryLayout<Int>.stride == 8 {
                let tuple:(UInt16, UInt16, UInt16, UInt16) = (value, 0, 0, 0)
                return unsafeBitCast(tuple, to: Int.self)
            } else {
                let tuple:(UInt16, UInt16) = (value, 0)
                return unsafeBitCast(tuple, to: Int.self)
            }
        #else
            return .init(value)
        #endif
    }
}
