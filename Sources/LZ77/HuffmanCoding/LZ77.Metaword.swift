extension LZ77
{
    struct Metaword:HuffmanPattern
    {
        //  8               0
        //  [c:c:c:s:s:s:s:s]
        //   ~~~~~^~~~~~~~~~^
        //   length    symbol
        private
        let storage:UInt8

        init(_ symbol:UInt8, length:Int)
        {
            self.storage = .init(length) << 5 | symbol
        }
    }
}
extension LZ77.Metaword
{
    var symbol:UInt8
    {
        self.storage & 0b0001_1111
    }
    var length:Int
    {
        .init(self.storage >> 5)
    }
}
