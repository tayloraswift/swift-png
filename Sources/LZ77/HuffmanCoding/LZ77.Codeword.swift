extension LZ77
{
    struct Codeword
    {
        private
        let shape:(length:UInt8, extra:UInt8)
        // bits are stored starting from least-significant bit to most-significant bit
        let bits:UInt16

        init(shape:(length:UInt8, extra:UInt8), bits:UInt16)
        {
            self.shape = shape
            self.bits = bits
        }
    }
}
extension LZ77.Codeword
{
    init(counter:UInt16, shape:(length:UInt8, extra:UInt8))
    {
        // this branch should be well-predicted
        if  shape.length <= 8
        {
            let low:UInt16  = LZ77.Reversed[counter]
            self.init(shape: shape, bits:         low  &>> ( 8 - shape.length))
        }
        else
        {
            let high:UInt16 = LZ77.Reversed[counter & 0xff] << 8,
                low:UInt16  = LZ77.Reversed[counter >> 8]
            self.init(shape: shape, bits: (high | low) &>> (16 - shape.length))
        }
    }
}
extension LZ77.Codeword
{
    var length:Int { .init(self.shape.length) }
    var extra:Int { .init(self.shape.extra) }
}
