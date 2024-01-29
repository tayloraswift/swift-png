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
        .init(self.storage & 0b0000_0000_1111_1111)
    }
    var length:Int
    {
        .init(self.storage >> 12)
    }
}
