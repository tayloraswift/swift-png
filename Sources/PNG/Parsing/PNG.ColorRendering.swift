extension PNG 
{
    /// enum PNG.ColorRendering 
    ///     A color rendering mode.
    /// 
    ///     This type models the information stored in an [`(Chunk).sRGB`] chunk.
    ///     It is not recommended for the same image to include both a `ColorRendering`
    ///     mode and a [`ColorProfile`].
    /// # [Parsing and serialization](colorrendering-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    enum ColorRendering
    {
        /// case PNG.ColorRendering.perceptual 
        ///     The perceptual rendering mode.
        /// ## ()
        case perceptual 
        /// case PNG.ColorRendering.relative 
        ///     The relative colorimetric rendering mode.
        /// ## ()
        case relative 
        /// case PNG.ColorRendering.saturation 
        ///     The saturation rendering mode.
        /// ## ()
        case saturation 
        /// case PNG.ColorRendering.absolute 
        ///     The absolute colorimetric rendering mode.
        /// ## ()
        case absolute 
    }
}
extension PNG.ColorRendering 
{
    /// init PNG.ColorRendering.init(parsing:) 
    /// throws 
    ///     Creates a color rendering mode by parsing the given chunk data.
    /// - data      : [Swift.UInt8]
    ///     The contents of an [`(Chunk).sRGB`] chunk to parse. 
    /// ## (colorrendering-parsing-and-serialization)
    public 
    init(parsing data:[UInt8]) throws 
    {
        guard data.count == 1
        else 
        {
            throw PNG.ParsingError.invalidColorRenderingChunkLength(data.count)
        }
        
        switch data[0] 
        {
        case 0:     self = .perceptual 
        case 1:     self = .relative 
        case 2:     self = .saturation 
        case 3:     self = .absolute 
        case let code:    
            throw PNG.ParsingError.invalidColorRenderingCode(code)
        }
    }
    /// var PNG.ColorRendering.serialized : [Swift.UInt8] { get }
    ///     Encodes this color rendering mode as the contents of an 
    ///     [`(Chunk).sRGB`] chunk.
    /// ## (colorrendering-parsing-and-serialization)
    public 
    var serialized:[UInt8]
    {
        switch self 
        {
        case .perceptual:   return [0]
        case .relative:     return [1]
        case .saturation:   return [2]
        case .absolute:     return [3]
        }
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
