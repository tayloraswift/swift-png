extension PNG
{
    /// A background descriptor.
    ///
    /// This type models the information stored in a ``Chunk/bKGD`` chunk.
    /// This information is used to populate the `fill` field in
    /// an image color ``Format``.
    ///
    /// The value of this descriptor is stored in the ``PNG.Background/case``
    /// property, after validation.
    public
    struct Background
    {
        /// The value of this background descriptor.
        public
        let `case`:Case
    }
}
extension PNG.Background
{
    /// Creates a background descriptor.
    ///
    /// This initializer validates the background information against the
    /// given pixel format and image palette. Some `pixel` formats imply
    /// that `palette` must be `nil`. This initializer does not check this
    /// assumption, as it is expected to have been verified by
    /// ``Palette.init(entries:pixel:)``.
    /// -   Parameter case:
    ///     A background descriptor value.
    ///
    ///     If this parameter is a ``Case/v(_:)`` or ``Case/rgb(_:)`` case,
    ///     the samples in its background color payload must fall within the
    ///     range determined by the image color depth. Passing an enumeration
    ///     case with an invalid background sample will result in a precondition
    ///     failure.
    /// -   Parameter pixel:
    ///     The pixel format of the image this background descriptor is to be
    ///     used for. Passing a mismatched enumeration `case` will result in a
    ///     precondition failure.
    /// -   Parameter palette:
    ///     The palette of the image this background descriptor is to be
    ///     used for.
    ///
    ///     If `case` is a ``Case/palette(index:)`` case, this palette must
    ///     not be `nil`, and the number of entries in it must be at least `1`
    ///     greater than the value of the ``Case/palette(index:)`` payload.
    ///     If the index payload is out of range, this function will suffer a
    ///     precondition failure.
    ///
    ///     If `case` is a ``Case/v(_:)`` or ``Case/rgb(_:)`` case,
    ///     this parameter is ignored.
    public
    init(case:Case, pixel:PNG.Format.Pixel, palette:PNG.Palette?)
    {
        switch pixel
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
            guard case .v(let v) = `case`
            else
            {
                fatalError("expected background of case `v` for pixel format `\(pixel)`")
            }
            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            guard v <= max
            else
            {
                PNG.ParsingError.invalidBackgroundSample(v, max: max).fatal
            }

        case .rgb8, .rgb16, .rgba8, .rgba16:
            guard case .rgb(let (r, g, b)) = `case`
            else
            {
                fatalError("expected background of case `v` for pixel format `\(pixel)`")
            }
            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            guard r <= max, g <= max, b <= max
            else
            {
                PNG.ParsingError.invalidBackgroundSample(Swift.max(r, g, b), max: max).fatal
            }

        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let palette:PNG.Palette = palette
            else
            {
                PNG.DecodingError.required(chunk: .PLTE, before: .bKGD).fatal
            }
            guard case .palette(index: let index) = `case`
            else
            {
                fatalError("expected background of case `palette` for pixel format `\(pixel)`")
            }
            guard index < palette.entries.count
            else
            {
                PNG.ParsingError.invalidBackgroundIndex(index, max: palette.entries.count - 1).fatal
            }
        }

        self.case = `case`
    }
    /// Creates a background descriptor by parsing the given chunk data,
    /// interpreting and validating it according to the given `pixel` format and
    /// image `palette`.
    ///
    /// Some `pixel` formats imply that `palette` must be `nil`. This
    /// initializer does not check this assumption, as it is expected to have
    /// been verified by ``Palette.init(parsing:pixel:)``.
    /// -   Parameter data:
    ///     The contents of a ``Chunk/bKGD`` chunk to parse.
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
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
            guard data.count == 2
            else
            {
                throw PNG.ParsingError.invalidBackgroundChunkLength(data.count, expected: 2)
            }

            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            let v:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0)
            guard v <= max
            else
            {
                throw PNG.ParsingError.invalidBackgroundSample(v, max: max)
            }
            self.case = .v(v)

        case .rgb8, .rgb16, .rgba8, .rgba16:
            guard data.count == 6
            else
            {
                throw PNG.ParsingError.invalidBackgroundChunkLength(data.count, expected: 6)
            }

            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            let r:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0),
                g:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 2),
                b:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 4)
            guard r <= max, g <= max, b <= max
            else
            {
                throw PNG.ParsingError.invalidBackgroundSample(Swift.max(r, g, b), max: max)
            }
            self.case = .rgb((r, g, b))

        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let palette:PNG.Palette = palette
            else
            {
                throw PNG.DecodingError.required(chunk: .PLTE, before: .bKGD)
            }
            guard data.count == 1
            else
            {
                throw PNG.ParsingError.invalidBackgroundChunkLength(data.count, expected: 1)
            }
            let index:Int = .init(data[0])
            guard index < palette.entries.count
            else
            {
                throw PNG.ParsingError.invalidBackgroundIndex(index, max: palette.entries.count - 1)
            }
            self.case = .palette(index: index)
        }
    }
    /// Encodes this background descriptor as the contents of a
    /// ``Chunk/bKGD`` chunk.
    public
    var serialized:[UInt8]
    {
        switch self.case
        {
        case .palette(index: let i):
            return [.init(i)]
        case .rgb(let c):
            return .init(unsafeUninitializedCapacity: 6)
            {
                $0.store(c.r, asBigEndian: UInt16.self, at: 0)
                $0.store(c.g, asBigEndian: UInt16.self, at: 2)
                $0.store(c.b, asBigEndian: UInt16.self, at: 4)
                $1 = $0.count
            }
        case .v(let v):
            return .init(unsafeUninitializedCapacity: 2)
            {
                $0.store(v, asBigEndian: UInt16.self, at: 0)
                $1 = $0.count
            }
        }
    }
}
