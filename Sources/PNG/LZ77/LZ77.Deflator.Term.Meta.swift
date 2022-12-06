extension LZ77.Deflator.Term
{
    struct Meta
    {
        // its possible to encode a metaterm in 8 bits, but it 
        // complicates the accessors so much it’s not worth it
        private 
        let storage:(symbol:UInt8, bits:UInt8)
    }
}
extension LZ77.Deflator.Term.Meta 
{
    var symbol:UInt8 
    {
        self.storage.symbol
    }
    var bits:UInt16 
    {
        .init(self.storage.bits)
    }
    
    static 
    func literal(_ literal:UInt8) -> Self
    {
        .init(storage: (symbol: literal, bits: 0))
    }
    static 
    func `repeat`(count:Int) -> Self
    {
        .init(storage: (symbol: 16, bits: .init(count - 3)))
    }
    static 
    func zeros(count:Int) -> Self
    {
        if count < 11 
        {
            return .init(storage: (symbol: 17, bits: .init(count - 3)))
        }
        else 
        {
            return .init(storage: (symbol: 18, bits: .init(count - 11)))
        }
    }
}
extension LZ77.Deflator.Term.Meta:CustomStringConvertible 
{
    var description:String 
    {
        if      self.symbol == 16 
        {
            return "repeat(\(self.bits + 3))"
        }
        else if self.symbol == 17
        {
            return "zeros(\(self.bits + 3))"
        }
        else if self.symbol == 18
        {
            return "zeros(\(self.bits + 11))"
        }
        else 
        {
            return "literal: \(self.symbol)"
        }
    }
}
