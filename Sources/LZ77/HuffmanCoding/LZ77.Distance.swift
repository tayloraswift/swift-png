extension LZ77
{
    struct Distance:HuffmanPattern
    {
        // 16               8               0
        //  [ : : : :c:c:c:c| : : :s:s:s:s:s]
        //           ~~~~~~~^      ~~~~~~~~~^
        //             length          symbol
        // length goes here because it is probably slightly faster to
        // address the high byte than do a UInt16 bit shift
        private
        let storage:UInt16

        init(_ symbol:UInt8, length:Int)
        {
            self.storage = .init(length) << 8 | .init(symbol)
        }
    }
}
extension LZ77.Distance
{
    var decade:Int
    {
        let value = self.storage & 0x00ff
        #if DEBUG
            // this hacky integer conversion makes this function about 17x faster in
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
        let value = self.storage >> 8
        #if DEBUG
            // this hacky integer conversion makes this function about 24x faster in
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
