extension LZ77
{
    struct Codeword
    {
        // bits are stored starting from least-significant bit to most-significant bit
        let bits:UInt16
        @General.Storage<UInt8>
        var length:Int
        @General.Storage<UInt8>
        var extra:Int
    }
}
extension LZ77.Codeword
{
    init(counter:UInt16, length:Int, extra:Int)
    {
        // this branch should be well-predicted
        if length <= 8
        {
            let low:UInt16  = LZ77.Reversed[counter]
            self.init(bits:         low  &>> ( 8 - length), length: length, extra: extra)
        }
        else
        {
            let high:UInt16 = LZ77.Reversed[counter & 0xff] << 8,
                low:UInt16  = LZ77.Reversed[counter >> 8]
            self.init(bits: (high | low) &>> (16 - length), length: length, extra: extra)
        }
    }
}
