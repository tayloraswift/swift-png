extension PNG
{
    /// A transparency descriptor.
    ///
    /// This type models the information stored in a ``Chunk/tRNS`` chunk.
    /// This information either used to populate the `key` field in
    /// an image color ``Format``, or augment its `palette` field, when appropriate.
    ///
    /// The value of this descriptor is stored in the ``PNG.Transparency/case``
    /// property, after validation.
    public
    struct Transparency
    {
        /// The value of this transparency descriptor.
        public
        let `case`:Case
    }
}
extension PNG.Transparency
{
    /// Creates a transparency descriptor.
    ///
    /// This initializer validates the transparency information against the
    /// given pixel format and image palette. Some `pixel` formats imply
    /// that `palette` must be `nil`. This initializer does not check this
    /// assumption, as it is expected to have been verified by
    /// ``Palette.init(entries:pixel:)``.
    /// -   Parameter case:
    ///     A transparency descriptor value.
    ///
    ///     If this parameter is a ``Case/v(key:)`` or ``Case/rgb(key:)`` case,
    ///     the samples in its chroma key payload must fall within the
    ///     range determined by the image color depth. Passing an enumeration
    ///     case with an invalid chroma key sample will result in a precondition
    ///     failure.
    /// -   Parameter pixel:
    ///     The pixel format of the image this transparency descriptor is to be
    ///     used for. Passing a mismatched enumeration `case` will result in a
    ///     precondition failure.
    ///
    ///     Transparency descriptors are not allowed for grayscale-alpha or RGBA
    ///     images, so setting `pixel` to one of those pixel formats will always
    ///     result in a precondition failure.
    /// -   Parameter palette:
    ///     The palette of the image this transparency descriptor is to be
    ///     used for.
    ///
    ///     If `case` is a ``Case/palette(alpha:)`` case, this palette must
    ///     not be `nil`, and must contain at least as many entries as the
    ///     number of alpha samples in the ``Case/palette(alpha:)`` payload.
    ///     Otherwise, this initializer will suffer a precondition failure.
    ///
    ///     If `case` is a ``Case/v(key:)`` or ``Case/rgb(key:)`` case,
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
    /// Creates a transparency descriptor by parsing the given chunk data,
    /// interpreting and validating it according to the given `pixel` format and
    /// image `palette`.
    ///
    /// Some `pixel` formats imply that `palette` must be `nil`.
    /// This initializer does not check this assumption, as it is expected
    /// to have been verified by ``Palette.init(parsing:pixel:)``.
    /// -   Parameter data:
    ///     The contents of a ``Chunk/tRNS`` chunk to parse.
    /// -   Parameter pixel:
    ///     The pixel format specifying how the chunk data is to be interpreted
    ///     and validated against.
    /// -   Parameter palette:
    ///     The image palette the chunk data is to be validated against, if
    ///     applicable.
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
    /// Encodes this transparency descriptor as the contents of a ``Chunk/tRNS`` chunk.
    public
    var serialized:[UInt8]
    {
        switch self.case
        {
        case .palette(alpha: let alpha):
            return .init(unsafeUninitializedCapacity: alpha.count)
            {
                $0.baseAddress?.update(from: alpha, count: $0.count)
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
