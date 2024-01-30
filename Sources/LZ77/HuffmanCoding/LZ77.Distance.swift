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
        .init(self.storage & 0x00ff)
    }
    var length:Int
    {
        .init(self.storage >> 8)
    }
}
