extension String 
{
    static 
    var bold:Self   = "\u{1B}[1m"
    static 
    var reset:Self  = "\u{1B}[0m"
    
    static 
    func pad(_ string:Self, left count:Int, with fill:Character = " ") -> Self 
    {
        .init(repeating: fill, count: Swift.max(0, count - string.count)) + string
    }
    static 
    func pad(_ string:String, right count:Int, with fill:Character = " ") -> Self 
    {
        string + .init(repeating: fill, count: Swift.max(0, count - string.count))
    }
    
    init<F>(_ x:F, places:Int) where F:BinaryFloatingPoint
    {
        let p:Int = (0 ..< places).reduce(1){ (a, _) in a * 10 }
        let i:Int = .init((x * .init(p)).rounded())
        let (a, b):(quotient:Int, remainder:Int) = i.quotientAndRemainder(dividingBy: p) 
        
        let tail:String = "\(b)"
        self = "\(a).\(String.init(repeating: "0", count: places - tail.count) + tail)"
    }
    
    public static 
    func swatch<T>(_ color:(r:T, g:T, b:T, a:T)) -> Self
        where T:FixedWidthInteger & UnsignedInteger
    {
        .swatch(" #\(Self.hex(color.r, color.g, color.b, color.a)) ", 
            color:  (color.r, color.g, color.b))
    }
    static 
    func swatch<T>(_ color:(r:T, g:T, b:T)) -> Self
        where T:FixedWidthInteger & UnsignedInteger
    {
        .swatch(" #\(Self.hex(color.r, color.g, color.b)) ", color: color)
    }
    
    static 
    func highlight<F>(_ string:Self, bg:(r:F, g:F, b:F), fg:(r:F, g:F, b:F)? = nil) 
        -> Self where F:BinaryFloatingPoint 
    {
        // if no foreground color specified, print dark colors with white text 
        // and light colors with black text
        let fg:(r:F, g:F, b:F) = fg ?? ((bg.r + bg.g + bg.b) / 3 < 0.5 ? (1, 1, 1) : (0, 0, 0))
        return "\(Self.bg(bg))\(Self.fg(fg))\(string)\(Self.fg(nil))\(Self.bg(nil))"
    }
    static 
    func highlight<T>(_ string:Self, bg:(r:T, g:T, b:T), fg:(r:T, g:T, b:T)? = nil) 
        -> Self where T:FixedWidthInteger & UnsignedInteger
    {
        .highlight(string, bg: Self.normalize(color: bg), fg: fg.map(Self.normalize(color:)))
    }
    
    static 
    func color<F>(_ string:Self, fg:(r:F, g:F, b:F)) 
        -> Self where F:BinaryFloatingPoint 
    {
        "\(Self.fg(fg))\(string)\(Self.fg(nil))"
    }
    static 
    func color<T>(_ string:Self, fg:(r:T, g:T, b:T)) 
        -> Self where T:FixedWidthInteger & UnsignedInteger
    {
        .color(string, fg: Self.normalize(color: fg))
    }
    
    private static 
    func fg(_ color:(r:UInt8, g:UInt8, b:UInt8)?) -> Self 
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
    private static 
    func bg(_ color:(r:UInt8, g:UInt8, b:UInt8)?) -> Self 
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
    private static 
    func fg<F>(_ color:(r:F, g:F, b:F)?) -> Self 
        where F:BinaryFloatingPoint
    {
        .fg(color.map(Self.quantize(color:)))
    }
    private static 
    func bg<F>(_ color:(r:F, g:F, b:F)?) -> Self 
        where F:BinaryFloatingPoint
    {
        .bg(color.map(Self.quantize(color:)))
    }
    private static 
    func quantize<F>(color:(r:F, g:F, b:F)) -> (r:UInt8, g:UInt8, b:UInt8) 
        where F:BinaryFloatingPoint 
    {
        let r:UInt8 = .init((.init(UInt8.max) * Swift.max(0, Swift.min(color.r, 1))).rounded()),
            g:UInt8 = .init((.init(UInt8.max) * Swift.max(0, Swift.min(color.g, 1))).rounded()),
            b:UInt8 = .init((.init(UInt8.max) * Swift.max(0, Swift.min(color.b, 1))).rounded())
        return (r, g, b)
    }
    private static 
    func normalize<T>(color:(r:T, g:T, b:T)) -> (r:Double, g:Double, b:Double) 
        where T:FixedWidthInteger & UnsignedInteger 
    {
        let r:Double    = .init(color.r) / .init(T.max),
            g:Double    = .init(color.g) / .init(T.max),
            b:Double    = .init(color.b) / .init(T.max) 
        return (r, g, b)
    }
    
    private static 
    func hex<T>(_ components:T...) -> Self 
        where T:FixedWidthInteger & UnsignedInteger
    {
        "\(components.map{ Self.pad(.init($0, radix: 16), left: T.bitWidth / 4, with: "0") }.joined())"
    }
    
    private static 
    func swatch<T>(_ description:Self, color:(r:T, g:T, b:T)) -> Self 
        where T:FixedWidthInteger & UnsignedInteger
    {
        .highlight(description, bg: color)
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
