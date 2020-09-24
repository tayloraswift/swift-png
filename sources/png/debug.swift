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

enum Highlight 
{
    static 
    var bold:String     = "\u{1B}[1m"
    static 
    var reset:String    = "\u{1B}[0m"
    
    static 
    func fg(_ color:(r:UInt8, g:UInt8, b:UInt8)?) -> String 
    {
        if let color:(r:UInt8, g:UInt8, b:UInt8) = color
        {
            return "\u{1B}[38;2;\(color.r);\(color.g);\(color.b)m"
        }
        else 
        {
            return "\u{1B}[39m"
        }
    }
    static 
    func bg(_ color:(r:UInt8, g:UInt8, b:UInt8)?) -> String 
    {
        if let color:(r:UInt8, g:UInt8, b:UInt8) = color
        {
            return "\u{1B}[48;2;\(color.r);\(color.g);\(color.b)m"
        }
        else 
        {
            return "\u{1B}[49m"
        }
    }
    
    static 
    func quantize<F>(_ color:(r:F, g:F, b:F)) -> (r:UInt8, g:UInt8, b:UInt8) 
        where F:BinaryFloatingPoint 
    {
        let r:UInt8 = .init((.init(UInt8.max) * max(0, min(color.r, 1))).rounded()),
            g:UInt8 = .init((.init(UInt8.max) * max(0, min(color.g, 1))).rounded()),
            b:UInt8 = .init((.init(UInt8.max) * max(0, min(color.b, 1))).rounded())
        return (r, g, b)
    }
    static 
    func color<F>(_ string:String, _ color:(r:F, g:F, b:F)) -> String 
        where F:BinaryFloatingPoint 
    {
        return Self.color(string, Self.quantize(color))
    }
    static 
    func color(_ string:String, _ fg:(r:UInt8, g:UInt8, b:UInt8)) -> String 
    {
        return "\(Self.fg(fg))\(string)\(Self.fg(nil))"
    }
    
    static 
    func highlight<F>(_ string:String, _ color:(r:F, g:F, b:F), fg:(r:F, g:F, b:F)? = nil) -> String 
        where F:BinaryFloatingPoint 
    {
        return Self.highlight(string, Self.quantize(color), fg: fg.map(Self.quantize(_:)))
    }
    static 
    func highlight(_ string:String, _ bg:(r:UInt8, g:UInt8, b:UInt8), fg:(r:UInt8, g:UInt8, b:UInt8)? = nil) -> String 
    {
        let fg:(r:UInt8, g:UInt8, b:UInt8) = fg ??
            ((bg.r / 3 + bg.g / 3 + bg.b / 3) < 128 ? (.max, .max, .max) : (0, 0, 0))
        
        return "\(Self.bg(bg))\(Self.fg(fg))\(string)\(Self.fg(nil))\(Self.bg(nil))"
    }
}
extension String 
{
    static 
    func pad(_ string:String, left count:Int) -> Self 
    {
        .init(repeating: " ", count: count - string.count) + string
    }
    
    init(histogram:[Int], size:(x:Int, y:Int), pad:Int) 
    {
        func lerp(_ a:(r:Double, g:Double, b:Double), _ b:(r:Double, g:Double, b:Double), t:Double) 
            -> (r:Double, g:Double, b:Double) 
        {
            (
                a.r * (1.0 - t) + b.r * t,
                a.g * (1.0 - t) + b.g * t,
                a.b * (1.0 - t) + b.b * t
            )
        }
        func gradient(_ x:Int) -> (r:Double, g:Double, b:Double) 
        {
            let stops:
            (
                (r:Double, g:Double, b:Double), 
                (r:Double, g:Double, b:Double), 
                (r:Double, g:Double, b:Double), 
                (r:Double, g:Double, b:Double), 
                (r:Double, g:Double, b:Double)
            ) 
            = 
            (
                (0.0, 0.0, 0.0), 
                (0.1, 0.1, 0.1), 
                (1.0, 0.2, 0.3), 
                (1.0, 0.3, 0.2),
                (1.0, 0.4, 0.3)
            )
            switch x 
            {
            case    0 ..<   10:
                return lerp(stops.0, stops.1, t: .init(x       ) /   10.0)
            case   10 ..<  200:
                return lerp(stops.1, stops.2, t: .init(x -   10) /  190.0)
            case  200 ..< 1000:
                return lerp(stops.2, stops.3, t: .init(x -  200) /  800.0)
            case 1000 ..< 2000:
                return lerp(stops.3, stops.4, t: .init(x - 1000) / 1000.0)
            default:
                return stops.4
            }
        }
        
        let head:String = (0 ..< size.x).map
        { 
            (dr:Int) in 
            "\(Highlight.bold)\(String.pad("\(dr)", left: 4))\(Highlight.reset)" 
        }.joined(separator: " ")
        let body:String = (0 ..< size.y).map
        {
            (dd:Int) in
            let row:String = (0 ..< size.x).map
            { 
                (dr:Int) in 
                let x:Int = Swift.min(histogram[size.x * dd + dr], 9999)
                let color:(r:Double, g:Double, b:Double) = gradient(x)
                return Highlight.highlight(String.pad("\(x)", left: 4), color, fg: (1, 1, 1))
            }.joined(separator: " ")
            return "\(Highlight.bold)\(String.pad("\(dd)", left: 2))\(Highlight.reset) │ \(row)"
        }.joined(separator: "\n")
        
        self = 
        """
             \(head)
           ┌\(String.init(repeating: "─", count: 5 * size.x))
        \(body)
        """
    }
}
