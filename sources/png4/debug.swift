extension PNG.Text:CustomStringConvertible 
{
    public 
    var description:String 
    {
        """
        png.text (tEXt | zTXt | iTXt) 
        {
            compressed  : \(self.compressed)
            language    : '\(self.language.joined(separator: "-"))'
            keyword     : '\(self.keyword.english)', '\(self.keyword.localized)'
            content     : \"\(self.content)\"
        }
        """
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
