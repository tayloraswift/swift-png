extension PNG 
{
    /// struct PNG.Transparency 
    ///     A transparency descriptor.
    /// 
    ///     This type models the information stored in a [`(Chunk).tRNS`] chunk.
    ///     This information either used to populate the `key` field in 
    ///     an image color [`Format`], or augment its `palette` field, when appropriate.
    /// 
    ///     The value of this descriptor is stored in the [`(PNG.Transparency).case`] 
    ///     property, after validation.
    /// # [Parsing and serialization](transparency-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct Transparency 
    {
        /// enum PNG.Transparency.Case 
        ///     A transparency case.
        public 
        enum Case 
        {
            /// case PNG.Transparency.Case.palette(alpha:)
            ///     A transparency descriptor for an indexed image.
            /// - alpha     : [Swift.UInt8]
            ///     An array of alpha samples, where each sample augments an 
            ///     RGB triple in an image [`Palette`]. This array can contain no 
            ///     more elements than entries in the image palette, but it can 
            ///     contain fewer. 
            /// 
            ///     It is acceptable (though pointless) for the `alpha` array to be 
            ///     empty.
            case palette(alpha:[UInt8])
            /// case PNG.Transparency.Case.rgb(key:)
            ///     A transparency descriptor for an RGB or BGR image.
            /// - key     : (r:Swift.UInt16, g:Swift.UInt16, b:Swift.UInt16)
            ///     A chroma key used to display transparency. Pixels 
            ///     matching this key will be displayed as transparent, if possible.
            /// 
            ///     Note that the chroma key components are unscaled samples. If 
            ///     the image color depth is less than `16`, only the least-significant 
            ///     bits of each sample are inhabited.
            case rgb(key:(r:UInt16, g:UInt16, b:UInt16))
            /// case PNG.Transparency.Case.v(key:)
            ///     A transparency descriptor for a grayscale image.
            /// - key     : Swift.UInt16
            ///     A chroma key used to display transparency. Pixels 
            ///     matching this key will be displayed as transparent, if possible.
            /// 
            ///     Note that the chroma key is an unscaled sample. If 
            ///     the image color depth is less than `16`, only the least-significant 
            ///     bits are inhabited.
            case v(key:UInt16)
        }
        
        /// let PNG.Transparency.case : Case 
        ///     The value of this transparency descriptor.
        public 
        let `case`:Case
    }
}
extension PNG.Transparency 
{
    /// init PNG.Transparency.init(case:pixel:palette:)
    ///     Creates a transparency descriptor.
    /// 
    ///     This initializer validates the transparency information against the 
    ///     given pixel format and image palette. Some `pixel` formats imply 
    ///     that `palette` must be `nil`. This initializer does not check this 
    ///     assumption, as it is expected to have been verified by 
    ///     [`Palette.init(entries:pixel:)`].
    /// - case      : Case 
    ///     A transparency descriptor value.
    /// 
    ///     If this parameter is a [`(Case).v(key:)`] or [`(Case).rgb(key:)`] case, 
    ///     the samples in its chroma key payload must fall within the 
    ///     range determined by the image color depth. Passing an enumeration 
    ///     case with an invalid chroma key sample will result in a precondition 
    ///     failure.
    /// - pixel     : Format.Pixel 
    ///     The pixel format of the image this transparency descriptor is to be 
    ///     used for. Passing a mismatched enumeration `case` will result in a 
    ///     precondition failure. 
    /// 
    ///     Transparency descriptors are not allowed for grayscale-alpha or RGBA 
    ///     images, so setting `pixel` to one of those pixel formats will always 
    ///     result in a precondition failure.
    /// - palette   : PNG.Palette? 
    ///     The palette of the image this transparency descriptor is to be 
    ///     used for. 
    /// 
    ///     If `case` is a [`(Case).palette(alpha:)`] case, this palette must 
    ///     not be `nil`, and must contain at least as many entries as the  
    ///     number of alpha samples in the [`(Case).palette(alpha:)`] payload. 
    ///     Otherwise, this initializer will suffer a precondition failure. 
    /// 
    ///     If `case` is a [`(Case).v(key:)`] or [`(Case).rgb(key:)`] case, 
    ///     this parameter is ignored.
    public 
    init(case:Case, pixel:PNG.Format.Pixel, palette:PNG.Palette?) 
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16: 
            guard case .v(key: let v) = `case` 
            else 
            {
                fatalError("expected transparency of case `v` for pixel format `\(pixel)`")
            }

            let max:UInt16 = .max >> (UInt16.bitWidth - pixel.depth)
            guard v <= max 
            else 
            {
                PNG.ParsingError.invalidTransparencySample(v, max: max).fatal
            }
        
        case .rgb8, .rgb16: 
            guard case .rgb(key: let (r, g, b)) = `case` 
            else 
            {
                fatalError("expected transparency of case `rgb` for pixel format `\(pixel)`")
            }
            let max:UInt16 = .max >> (UInt16.bitWidth - pixel.depth)
            guard r <= max, g <= max, b <= max 
            else 
            {
                PNG.ParsingError.invalidTransparencySample(Swift.max(r, g, b), max: max).fatal
            }
            
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let palette:PNG.Palette = palette 
            else 
            {
                PNG.DecodingError.required(chunk: .PLTE, before: .tRNS).fatal 
            }
            guard case .palette(alpha: let alpha) = `case` 
            else 
            {
                fatalError("expected transparency of case `palette` for pixel format `\(pixel)`")
            }
            guard alpha.count <= palette.entries.count  
            else 
            {
                PNG.ParsingError.invalidTransparencyCount(alpha.count, max: palette.entries.count).fatal
            }
            
        case .va8, .va16, .rgba8, .rgba16:
            PNG.ParsingError.unexpectedTransparency(pixel: pixel).fatal
        }
        
        self.case = `case`
    }
    /// init PNG.Transparency.init(parsing:pixel:palette:) 
    /// throws 
    ///     Creates a transparency descriptor by parsing the given chunk data, 
    ///     interpreting and validating it according to the given `pixel` format and 
    ///     image `palette`. 
    /// 
    ///     Some `pixel` formats imply that `palette` must be `nil`. 
    ///     This initializer does not check this assumption, as it is expected 
    ///     to have been verified by [`Palette.init(parsing:pixel:)`].
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).tRNS`] chunk to parse. 
    /// - pixel     : Format.Pixel 
    ///     The pixel format specifying how the chunk data is to be interpreted 
    ///     and validated against.
    /// - palette   : Palette?
    ///     The image palette the chunk data is to be validated against, if 
    ///     applicable. 
    /// ## (transparency-parsing-and-serialization)
    public 
    init(parsing data:[UInt8], pixel:PNG.Format.Pixel, palette:PNG.Palette?) throws 
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16:
            guard data.count == 2 
            else 
            {
                throw PNG.ParsingError.invalidTransparencyChunkLength(data.count, expected: 2)
            }
            
            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            let v:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0)
            guard v <= max 
            else 
            {
                throw PNG.ParsingError.invalidTransparencySample(v, max: max)
            }
            self.case =  .v(key: v)
        
        case .rgb8, .rgb16:
            guard data.count == 6 
            else 
            {
                throw PNG.ParsingError.invalidTransparencyChunkLength(data.count, expected: 6)
            }
            
            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            let r:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0),
                g:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 2),
                b:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 4)
            guard r <= max, g <= max, b <= max 
            else 
            {
                throw PNG.ParsingError.invalidTransparencySample(Swift.max(r, g, b), max: max)
            }
            self.case =  .rgb(key: (r, g, b))
        
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let palette:PNG.Palette = palette 
            else 
            {
                throw PNG.DecodingError.required(chunk: .PLTE, before: .tRNS)
            }
            guard data.count <= palette.entries.count  
            else 
            {
                throw PNG.ParsingError.invalidTransparencyCount(data.count, max: palette.entries.count)
            }
            self.case =  .palette(alpha: data)
        
        case .va8, .va16, .rgba8, .rgba16:
            throw PNG.ParsingError.unexpectedTransparency(pixel: pixel)
        }
    }
    /// var PNG.Transparency.serialized : [Swift.UInt8] { get }
    ///     Encodes this transparency descriptor as the contents of a 
    ///     [`(Chunk).tRNS`] chunk.
    /// ## (transparency-parsing-and-serialization)
    public 
    var serialized:[UInt8] 
    {
        switch self.case 
        {
        case .palette(alpha: let alpha):
            return .init(unsafeUninitializedCapacity: alpha.count)
            {
                $0.baseAddress?.assign(from: alpha, count: $0.count)
                $1 = $0.count
            }
        case .rgb(key: let c):
            return .init(unsafeUninitializedCapacity: 6)
            {
                $0.store(c.r, asBigEndian: UInt16.self, at: 0)
                $0.store(c.g, asBigEndian: UInt16.self, at: 2)
                $0.store(c.b, asBigEndian: UInt16.self, at: 4)
                $1 = $0.count
            }
        case .v(key: let v):
            return .init(unsafeUninitializedCapacity: 2)
            {
                $0.store(v, asBigEndian: UInt16.self, at: 0)
                $1 = $0.count
            }
        }
    }
}
