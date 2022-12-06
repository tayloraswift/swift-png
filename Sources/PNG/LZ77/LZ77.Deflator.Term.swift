extension LZ77.Deflator 
{
    struct Term
    {
        let storage:UInt32
    }
}
extension LZ77.Deflator.Term 
{
    //  it takes about 28 bits to represent a length-distance pair, and  
    //  we can save ourselves some branching by using the remaining 4 
    //  bits to encode a literal as-is
    //  32              24              16              8               0
    //  [ : : : : :D:D:D|D:D:D:D:D:D:D:D|D:D:R:R:R:R:R: | : : : : : : : ]
    //   ~~~~~~~~~^                                    ~~~~~~~~~~~~~~~~~^
    //     distance                                            runliteral
    var symbol:(runliteral:UInt16, distance:UInt8) 
    {
        (.init(self.storage & 0x00_00_01_ff), .init(self.storage >> 27))
    }
    var bits:(run:UInt16, distance:UInt16) 
    {
        (.init(self.storage >> 9 & 0x00_1f), .init(self.storage >> 14 & 0x1f_ff))
    }
    
    init(literal:UInt8) 
    {
        // put bitpattern for 31 in distance field, to streamline 
        // frequency counting later on 
        self.storage = 0b11111000_00000000_00000000_00000000 | .init(literal)
    }
    
    static 
    let end:Self = .init(storage: 0b11111000_00000000_00000001_00000000)
    
    init(run:Int, distance:Int) 
    {
        let decade:(run:UInt8, distance:UInt8) = 
        (
            run:            LZ77.Decades[run:      run     ], 
            distance:       LZ77.Decades[distance: distance]
        )
        let base:(run:UInt32, distance:UInt32) = 
        (
            run:      .init(LZ77.Composites[run:      decade.run     ].base),
            distance: .init(LZ77.Composites[distance: decade.distance].base)
        )
        
        let symbols:UInt32 = 
            .init(decade.distance) << 27 | 0x0000_0100 | 
            .init(decade.run) 
        let bits:UInt32    = 
            (.init(distance) - base.distance) << 14 | 
            (.init(run     ) - base.run     ) <<  9
        self.storage = symbols | bits
    }
}
extension LZ77.Deflator.Term:CustomStringConvertible 
{
    var description:String 
    {
        let symbol:(runliteral:UInt16, distance:UInt8) = self.symbol 
        
        if symbol.runliteral < 256 
        {
            return "literal: \(symbol.runliteral)"
        }
        else if symbol.runliteral == 256 
        {
            return "end-of-block"
        }
        else 
        {
            let bits:(run:UInt16, distance:UInt16) = self.bits
            let base:(run:UInt16, distance:UInt16) = 
            (
                run:      LZ77.Composites[run: .init(truncatingIfNeeded: symbol.runliteral)].base,
                distance: LZ77.Composites[distance: symbol.distance].base
            )
            
            return "match(offset: -\(base.distance + bits.distance), count: \(base.run + bits.run))"
        }
    }
}
