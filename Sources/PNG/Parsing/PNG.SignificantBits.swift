extension PNG
{
    /// A color precision descriptor.
    ///
    /// This type models the information stored in an ``Chunk/sBIT`` chunk.
    @frozen public
    struct SignificantBits
    {
        /// The value of this color precision descriptor.
        let `case`:Case
    }
}
extension PNG.SignificantBits
{
    /// Creates a color precision descriptor.
    ///
    /// This initializer validates the precision information against the
    /// given pixel format.
    /// -   Parameter case:
    ///     A color precision case. Each precision value in the enumeration
    ///     payload must be greater than zero, and none of them
    ///     can be greater than the color depth of the image color format.
    /// -   Parameter pixel:
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
    /// Creates a color precision descriptor by parsing the given chunk data,
    /// interpreting and validating it according to the given `pixel` format.
    /// -   Parameter data:
    ///     The contents of an ``Chunk/sBIT`` chunk to parse.
    /// -   Parameter pixel:
    ///     The pixel format specifying how the chunk data is to be interpreted
    ///     and validated against.
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
    /// Encodes this color precision descriptor as the contents of an ``Chunk/sBIT`` chunk.
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
