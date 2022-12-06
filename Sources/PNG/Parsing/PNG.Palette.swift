extension PNG 
{
    /// struct PNG.Palette 
    ///     An image palette.
    /// 
    ///     This type models the information stored in a [`(Chunk).PLTE`] chunk. 
    ///     This information is used to populate the non-alpha components of the 
    ///     `palette` field in an image color [`Format`], when appropriate.
    /// # [Parsing and serialization](palette-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct Palette 
    {
        /// let PNG.Palette.entries : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8)]
        ///     The entries in this palette.
        public 
        let entries:[(r:UInt8, g:UInt8, b:UInt8)]
    }
}
extension PNG.Palette 
{
    /// init PNG.Palette.init(entries:pixel:)
    ///     Creates an image palette.
    /// 
    ///     This initializer validates the palette information against the given 
    ///     `pixel` format.
    /// - entries   : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8)]
    ///     An array of palette entries. This array must be non-empty, and can 
    ///     contain at most `256`, or `1 << pixel.`[`(Format.Pixel).depth`] elements, 
    ///     whichever is lower.
    /// - pixel     : Format.Pixel 
    ///     The pixel format of the image this palette is to be used for. 
    ///     If this parameter is a grayscale or grayscale-alpha format, this 
    ///     initializer will suffer a precondition failure.
    public 
    init(entries:[(r:UInt8, g:UInt8, b:UInt8)], pixel:PNG.Format.Pixel) 
    {
        guard pixel.hasColor
        else
        {
            PNG.ParsingError.unexpectedPalette(pixel: pixel).fatal 
        }
        let max:Int = 1 << Swift.min(pixel.depth, 8)
        guard 1 ... max ~= entries.count 
        else
        {
            PNG.ParsingError.invalidPaletteCount(entries.count, max: max).fatal
        }
        
        self.entries = entries 
    }
    /// init PNG.Palette.init(parsing:pixel:) 
    /// throws 
    ///     Creates an image palette by parsing the given chunk data, interpreting 
    ///     and validating it according to the given `pixel` format.
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).PLTE`] chunk to parse. 
    /// - pixel     : Format.Pixel 
    ///     The pixel format specifying how the chunk data is to be interpreted.
    /// ## (palette-parsing-and-serialization)
    public 
    init(parsing data:[UInt8], pixel:PNG.Format.Pixel) throws
    {
        guard pixel.hasColor
        else
        {
            throw PNG.ParsingError.unexpectedPalette(pixel: pixel)
        }
        
        let (count, remainder):(Int, Int) = data.count.quotientAndRemainder(dividingBy: 3)
        guard remainder == 0
        else
        {
            throw PNG.ParsingError.invalidPaletteChunkLength(data.count)
        }
        
        // check number of palette entries
        let max:Int = 1 << Swift.min(pixel.depth, 8)
        guard 1 ... max ~= count 
        else
        {
            throw PNG.ParsingError.invalidPaletteCount(count, max: max)
        }

        self.entries = stride(from: data.startIndex, to: data.endIndex, by: 3).map
        {
            (base:Int) in (r: data[base], g: data[base + 1], b: data[base + 2])
        }
    }
    /// var PNG.Palette.serialized   : [Swift.UInt8] { get }
    ///     Encodes this image palette as the contents of a [`(Chunk).PLTE`] chunk.
    /// ## (palette-parsing-and-serialization)
    public 
    var serialized:[UInt8] 
    {
        .init(unsafeUninitializedCapacity: 3 * self.entries.count)
        {
            for (i, c):(Int, (r:UInt8, g:UInt8, b:UInt8)) in 
                zip(stride(from: $0.startIndex, to: $0.endIndex, by: 3), self.entries) 
            {
                $0[i    ] = c.r
                $0[i + 1] = c.g
                $0[i + 2] = c.b
            }
            $1 = $0.count
        }
    }
}
