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
        let symbol:(runliteral:Int, distance:Int) = self.symbol 
        
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
            let decade:(run:UInt8, distance:UInt8) = self.decade,
                bits:(run:UInt16, distance:UInt16) = self.bits
            let base:(run:UInt16, distance:UInt16) = 
            (
                run:      LZ77.Composites[run:      decade.run     ].base,
                distance: LZ77.Composites[distance: decade.distance].base
            )
            
            return "match(offset: -\(base.distance + bits.distance), count: \(base.run + bits.run))"
        }
    }
}
