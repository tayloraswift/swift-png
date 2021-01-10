extension PNG.Percentmille:CustomStringConvertible 
{
    public 
    var description:String 
    {
        "\(self.points) / 100000"
    }
}

extension PNG.Metadata:CustomStringConvertible 
{
    public 
    var description:String 
    {
        [
            // singletons 
            [
                self.time.map               (\.description),
                self.chromaticity.map       (\.description),
                self.colorProfile.map       (\.description),
                self.colorRendering.map     (\.description),
                self.gamma.map              (\.description),
                self.histogram.map          (\.description),
                self.physicalDimensions.map (\.description),
                self.significantBits.map    (\.description),
            ].compactMap{ $0 },
            self.suggestedPalettes.map      (\.description),
            self.text.map                   (\.description),
            self.application.map 
            {
                """
                <unknown> (\($0.type)) 
                {
                    data        : <\($0.data.count) bytes>
                }
                """
            },
        ].flatMap{ $0 }.joined(separator: "\n")
    }
}

extension PNG.TimeModified:CustomStringConvertible
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.tIME)) 
        {
            year        : \(self.year) 
            month       : \(self.month) 
            day         : \(self.day) 
            hour        : \(self.hour) 
            minute      : \(self.minute) 
            second      : \(self.second) 
        }
        """
    }
}
extension PNG.Chromaticity:CustomStringConvertible
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.cHRM)) 
        {
            w           : \(self.w) 
            r           : \(self.r) 
            g           : \(self.g) 
            b           : \(self.b) 
        }
        """
    }
}
extension PNG.ColorProfile:CustomStringConvertible
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.iCCP)) 
        {
            name        : '\(self.name)' 
            profile     : <\(self.profile.count) bytes>
        }
        """
    }
}
extension PNG.ColorRendering:CustomStringConvertible
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.sRGB)) 
        {
            \(self)
        }
        """
    }
}
extension PNG.Gamma:CustomStringConvertible
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.gAMA)) 
        {
            value       : \(self.value) 
        }
        """
    }
}
extension PNG.Histogram:CustomStringConvertible
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.hIST)) 
        {
            frequencies : <\(self.frequencies.count) entries> 
        }
        """
    }
}
extension PNG.PhysicalDimensions:CustomStringConvertible
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.pHYs)) 
        {
            density     : (x: \(self.density.x), y: \(self.density.y)) \(self.density.unit.map{ "/ \($0)" } ?? "(no units)")
        }
        """
    }
}
extension PNG.SignificantBits:CustomStringConvertible
{
    public 
    var description:String 
    {
        let channels:[(String, Int)] 
        switch self.case 
        {
        case .v(let v):
            channels = [("v", v)]
        case .va(let (v, a)):
            channels = [("v", v), ("a", a)]
        case .rgb(let (r, g, b)):
            channels = [("r", r), ("g", g), ("b", b)]
        case .rgba(let (r, g, b, a)):
            channels = [("r", r), ("g", g), ("b", b), ("a", a)]
        }
        return """
        PNG.\(Self.self) (\(PNG.Chunk.sBIT)) 
        {
        \(channels.map{ "    \($0.0)           : \($0.1)" }.joined(separator: "\n"))
        }
        """
    }
}
extension PNG.SuggestedPalette:CustomStringConvertible 
{
    public 
    var description:String 
    {
        let swatches:[String] 
        switch self.entries 
        {
        case .rgba8(let entries):
            swatches = entries.enumerated().map{ "        [\(String.pad("\($0.0)", left: 3))]: \(String.swatch($0.1.color)) (\($0.1.frequency))" } 
        case .rgba16(let entries):
            swatches = entries.enumerated().map{ "        [\(String.pad("\($0.0)", left: 5))]: \(String.swatch($0.1.color)) (\($0.1.frequency))" } 
        }
        return """
        PNG.\(Self.self) (\(PNG.Chunk.sPLT)) 
        {
            name        : '\(self.name)' 
            entries     : 
            [
        \(swatches.joined(separator: "\n"))
            ]
        }
        """
    }
}
extension PNG.Text:CustomStringConvertible 
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.tEXt) | \(PNG.Chunk.zTXt) | \(PNG.Chunk.iTXt)) 
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

extension String 
{
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
        
        let head:Self = (0 ..< size.x).map
        { 
            (dr:Int) in 
            "\(Self.bold)\(Self.pad("\(dr)", left: 4))\(Self.reset)" 
        }.joined(separator: " ")
        let body:Self = (0 ..< size.y).map
        {
            (dd:Int) in
            let row:Self = (0 ..< size.x).map
            { 
                (dr:Int) in 
                let x:Int = Swift.min(histogram[size.x * dd + dr], 9999)
                return Self.highlight(Self.pad("\(x)", left: 4), bg: gradient(x), fg: (1, 1, 1))
            }.joined(separator: " ")
            return "\(Self.bold)\(Self.pad("\(dd)", left: 2))\(Self.reset) │ \(row)"
        }.joined(separator: "\n")
        
        self = 
        """
             \(head)
           ┌\(Self.init(repeating: "─", count: 5 * size.x))
        \(body)
        """
    }
}
