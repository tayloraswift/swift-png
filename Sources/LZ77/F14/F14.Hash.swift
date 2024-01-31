extension F14
{
    struct Hash
    {
        private
        let value:Int
    }
}
extension F14.Hash
{
    // stackoverflow.com/questions/664014/what-integer-hash-function-are-good-that-accepts-an-integer-hash-key
    init(_ x:UInt32)
    {
        let a:UInt32 = ((x >> 16) ^ x) &* 0x04_5d_9f_3b,
            b:UInt32 = ((a >> 16) ^ a) &* 0x04_5d_9f_3b,
            c:UInt32 =  (b >> 16) ^ b
        self.value = .init(c)
    }

    //  we use the following bits in the hash:
    //
    // 64        32    28            19                 7         0
    //  ┌─ ╶ ╶ ╶ ╶┬─────┬─────┬─────┬─┬───┬─────┬─────┬─┬───┬─────┐
    //  │         ╎     ╎   probe   ╎1╎    district     ╎   tag   │
    //  └─ ╶ ╶ ╶ ╶┴─────┴─────┴─────┴─┴───┴─────┴─────┴─┴───┴─────┘
    //                                |<-<- self.mask ->|
    var tag:UInt8
    {
        .init(self.value & 0x7f | 0x80)
    }

    func startIndex(mask:Int) -> F14.District.Index
    {
        .init(offset: self.value & mask)
    }
    func index(before current:F14.District.Index, mask:Int) -> F14.District.Index
    {
        .init(offset: (current.offset &- self.probe) & mask)
    }
    func index(after current:F14.District.Index, mask:Int) -> F14.District.Index
    {
        .init(offset: (current.offset &+ self.probe) & mask)
    }

    private
    var probe:Int
    {
        (self.value >> 12 | 0x00_80) & 0xff_80
    }
}
