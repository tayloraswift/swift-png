extension String 
{
    static 
    func pad(_ string:String, left count:Int) -> Self 
    {
        .init(repeating: " ", count: count - string.count) + string
    }
    static 
    func pad(_ string:String, right count:Int) -> Self 
    {
        string + .init(repeating: " ", count: count - string.count)
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
    func highlight<F>(_ string:String, _ color:(r:F, g:F, b:F)) -> String 
        where F:BinaryFloatingPoint 
    {
        return Self.highlight(string, Self.quantize(color))
    }
    static 
    func highlight(_ string:String, _ bg:(r:UInt8, g:UInt8, b:UInt8)) -> String 
    {
        let fg:(r:UInt8, g:UInt8, b:UInt8) = 
            (bg.r / 3 + bg.g / 3 + bg.b / 3) < 128 ? (.max, .max, .max) : (0, 0, 0)
        
        return "\(Self.bg(bg))\(Self.fg(fg))\(string)\(Self.fg(nil))\(Self.bg(nil))"
    }
    static 
    func swatch<F>(_ color:(r:F, g:F, b:F)) -> String 
        where F:BinaryFloatingPoint 
    {
        let v:(String, String, String) = 
        (
            String.pad("\(color.r)", left: 3),
            String.pad("\(color.g)", left: 3),
            String.pad("\(color.b)", left: 3)
        )
        return Self.highlight(" \(v.0)\(v.1)\(v.2) ", color)
    }
    static 
    func square<F>(_ color:(r:F, g:F, b:F)) -> String 
        where F:BinaryFloatingPoint 
    {
        return Self.highlight("  ", color)
    }
    static 
    func square(_ color:(r:UInt8, g:UInt8, b:UInt8)) -> String 
    {
        return Self.highlight("  ", color)
    }
    
    static 
    func bits<I>(_ x:I) -> String where I:FixedWidthInteger 
    {
        return (0 ..< I.bitWidth).reversed().map
        { 
            (x >> $0) & 1 == 0 ? Self.highlight("0", (0.2, 0.2, 0.2)) : Self.highlight("1", (1, 1, 1))
        }.joined(separator: "")
    }
    
    static 
    func print<F>(_ string:String, highlight color:(r:F, g:F, b:F))  
        where F:BinaryFloatingPoint 
    {
        Swift.print(Self.highlight(string, color))
    }
    static 
    func print<F>(_ string:String, color:(r:F, g:F, b:F))  
        where F:BinaryFloatingPoint 
    {
        Swift.print(Self.color(string, color))
    }
}
