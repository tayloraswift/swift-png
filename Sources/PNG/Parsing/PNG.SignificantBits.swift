extension PNG 
{
    /// struct PNG.SignificantBits 
    ///     A color precision descriptor.
    /// 
    ///     This type models the information stored in an [`(Chunk).sBIT`] chunk.
    /// # [Parsing and serialization](significantbits-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct SignificantBits 
    {
        /// enum PNG.SignificantBits.Case 
        ///     A color precision case.
        public 
        enum Case  
        {
            /// case PNG.SignificantBits.Case.v(_:)
            ///     A color precision descriptor for a grayscale image.
            /// - _ : Swift.Int 
            ///     The number of significant bits in each grayscale sample. 
            /// 
            ///     This value must be greater than zero, and can be no greater 
            ///     than the color depth of the image color format.
            /// ## ()
            case v(Int)
            /// case PNG.SignificantBits.Case.va(_:)
            ///     A color precision descriptor for a grayscale-alpha image.
            /// - _ : (v:Swift.Int, a:Swift.Int) 
            ///     The number of significant bits in each grayscale and alpha 
            ///     sample, respectively. 
            /// 
            ///     Both precision values must be greater than zero, and neither 
            ///     can be greater than the color depth of the image color format.
            /// ## ()
            case va((v:Int, a:Int))
            /// case PNG.SignificantBits.Case.rgb(_:)
            ///     A color precision descriptor for an RGB, BGR, or indexed image.
            /// - _ : (r:Swift.Int, g:Swift.Int, b:Swift.Int) 
            ///     The number of significant bits in each red, green, and blue 
            ///     sample, respectively. If the image uses an indexed color format, 
            ///     the precision values refer to the precision of the palette 
            ///     entries, not the indices. The [`(Chunk).sBIT`] chunk type is 
            ///     not capable of specifying the precision of the alpha component 
            ///     of the palette entries. If the image palette was augmented with 
            ///     alpha samples from a [`Transparency`] descriptor, the precision  
            ///     of those samples is left undefined.
            /// 
            ///     The meaning of a color precision descriptor is 
            ///     poorly-defined for BGR images. It is strongly recommended that 
            ///     iphone-optimized images use [`(PNG).SignificantBits`] only if all 
            ///     samples have the same precision.
            /// 
            ///     Each precision value must be greater than zero, and none of them 
            ///     can be greater than the color depth of the image color format.
            /// ## ()
            case rgb((r:Int, g:Int, b:Int))
            /// case PNG.SignificantBits.Case.rgba(_:)
            ///     A color precision descriptor for an RGBA or BGRA image.
            /// - _ : (r:Swift.Int, g:Swift.Int, b:Swift.Int, a:Swift.Int) 
            ///     The number of significant bits in each red, green, blue, and alpha 
            ///     sample, respectively. 
            ///
            ///     The meaning of a color precision descriptor is 
            ///     poorly-defined for BGRA images. It is strongly recommended that 
            ///     iphone-optimized images use [`(PNG).SignificantBits`] only if all 
            ///     samples have the same precision.
            /// 
            ///     Each precision value must be greater than zero, and none of them 
            ///     can be greater than the color depth of the image color format.
            /// ## ()
            case rgba((r:Int, g:Int, b:Int, a:Int))
        }
        /// let PNG.SignificantBits.case : Case 
        ///     The value of this color precision descriptor.
        let `case`:Case
    }
}
extension PNG.SignificantBits 
{
    /// init PNG.SignificantBits.init(case:pixel:)
    ///     Creates a color precision descriptor.
    /// 
    ///     This initializer validates the precision information against the 
    ///     given pixel format.
    /// - case      : Case 
    ///     A color precision case. Each precision value in the enumeration 
    ///     payload must be greater than zero, and none of them 
    ///     can be greater than the color depth of the image color format.
    /// - pixel     : Format.Pixel 
    ///     The pixel format of the image this color precision descriptor is to be 
    ///     used for. Passing a mismatched enumeration `case` will result in a 
    ///     precondition failure.
    public 
    init(case:Case, pixel:PNG.Format.Pixel) 
    {
        let precision:[Int] 
        switch `case` 
        {
        case .v   (let  v          ):   precision = [v]
        case .va  (let (v,       a)):   precision = [v, a]
        case .rgb (let (r, g, b   )):   precision = [r, g, b]
        case .rgba(let (r, g, b, a)):   precision = [r, g, b, a]
        }
        
        let max:Int
        switch pixel  
        {
        case .indexed1, .indexed2, .indexed4, .indexed8:    max = 8
        default:                                            max = pixel.depth 
        }
        for v:Int in precision where !(1 ... max ~= v)
        {
            PNG.ParsingError.invalidSignificantBitsPrecision(v, max: max).fatal
        }
        
        self.case = `case`
    }
    /// init PNG.SignificantBits.init(parsing:pixel:) 
    /// throws 
    ///     Creates a color precision descriptor by parsing the given chunk data, 
    ///     interpreting and validating it according to the given `pixel` format.
    /// - data      : [Swift.UInt8]
    ///     The contents of an [`(Chunk).sBIT`] chunk to parse. 
    /// - pixel     : Format.Pixel 
    ///     The pixel format specifying how the chunk data is to be interpreted 
    ///     and validated against.
    /// ## (significantbits-parsing-and-serialization)
    public 
    init(parsing data:[UInt8], pixel:PNG.Format.Pixel) throws
    {
        let arity:Int = (pixel.hasColor ? 3 : 1) + (pixel.hasAlpha ? 1 : 0)
        guard data.count == arity 
        else 
        {
            throw PNG.ParsingError.invalidSignificantBitsChunkLength(data.count, 
                expected: arity)
        }
        
        let precision:[Int]
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16:
            let v:Int = .init(data[0])
            self.case = .v(v)
            precision = [v]
        
        case .rgb8, .rgb16, .indexed1, .indexed2, .indexed4, .indexed8:
            let r:Int = .init(data[0]), 
                g:Int = .init(data[1]), 
                b:Int = .init(data[2])
            self.case = .rgb((r, g, b))
            precision = [r, g, b]
        
        case .va8, .va16:
            let v:Int = .init(data[0]), 
                a:Int = .init(data[1])
            self.case = .va((v, a))
            precision = [v, a]
        
        case .rgba8, .rgba16:
            let r:Int = .init(data[0]), 
                g:Int = .init(data[1]), 
                b:Int = .init(data[2]),
                a:Int = .init(data[3])
            self.case = .rgba((r, g, b, a))
            precision = [r, g, b, a]
        }
        
        let max:Int
        switch pixel  
        {
        case .indexed1, .indexed2, .indexed4, .indexed8:    max = 8
        default:                                            max = pixel.depth 
        }
        for v:Int in precision where !(1 ... max ~= v)
        {
            throw PNG.ParsingError.invalidSignificantBitsPrecision(v, max: max)
        }
    }
    /// var PNG.SignificantBits.serialized : [Swift.UInt8] { get }
    ///     Encodes this color precision descriptor as the contents of an 
    ///     [`(Chunk).sBIT`] chunk.
    /// ## (significantbits-parsing-and-serialization)
    public 
    var serialized:[UInt8]
    {
        switch self.case 
        {
        case .v(   let c):  return [c].map(UInt8.init(_:))
        case .va(  let c):  return [c.v, c.a].map(UInt8.init(_:))
        case .rgb( let c):  return [c.r, c.g, c.b].map(UInt8.init(_:))
        case .rgba(let c):  return [c.r, c.g, c.b, c.a].map(UInt8.init(_:))
        }
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
