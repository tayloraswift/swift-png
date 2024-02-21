extension PNG
{
    /// A color format.
    ///
    /// This color format enumeration combines two sets of PNG color formats.
    /// It can represent the fifteen standard color formats from the core
    /// [PNG specification](http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.IHDR),
    /// as well as two iphone-optimized color formats from Apple’s PNG extensions.
    ///
    /// Some color formats contain a `palette`, an optional background `fill` color,
    /// and an optional chroma `key`. For most use cases, the background `fill`
    /// and chroma `key` can be set to `nil`. For the indexed color formats,
    /// a non-empty `palette` is mandatory. For all other color formats, the `palette`
    /// can be set to the empty array `[]`.
    ///
    /// Color format validation takes place when initializing a ``Layout`` instance,
    /// which stores the color format in a ``Image`` image.
    @frozen public
    enum Format
    {
        /// A 1-bit grayscale color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/v1``.
        /// -   Parameter fill:
        ///     An optional background color. The sample is unscaled, and must
        ///     be in the range `0 ... 1`. Most PNG viewers ignore this field.
        /// -   Parameter key:
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible. The sample is
        ///     unscaled, and must be in the range `0 ... 1`.
        case v1(fill:UInt8?, key:UInt8?)
        /// A 2-bit grayscale color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/v2``.
        /// -   Parameter fill:
        ///     An optional background color. The sample is unscaled, and must
        ///     be in the range `0 ... 3`. Most PNG viewers ignore this field.
        /// -   Parameter key:
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible. The sample is
        ///     unscaled, and must be in the range `0 ... 3`.
        case v2(fill:UInt8?, key:UInt8?)

        /// A 4-bit grayscale color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/v4``.
        /// -   Parameter fill:
        ///     An optional background color. The sample is unscaled, and must
        ///     be in the range `0 ... 15`. Most PNG viewers ignore this field.
        /// -   Parameter key:
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible. The sample is
        ///     unscaled, and must be in the range `0 ... 15`.
        case v4(fill:UInt8?, key:UInt8?)

        /// An 8-bit grayscale color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/v8``.
        /// -   Parameter fill:
        ///     An optional background color. Most PNG viewers ignore this field.
        /// -   Parameter key:
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible.
        case v8(fill:UInt8?, key:UInt8?)

        /// A 16-bit grayscale color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/v16``.
        /// -   Parameter fill:
        ///     An optional background color. Most PNG viewers ignore this field.
        /// -   Parameter key:
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible.
        case v16(fill:UInt16?, key:UInt16?)

        /// An 8-bit BGR color format.
        ///
        /// This color format is an iphone-optimized format.
        /// It has a ``pixel`` format of ``Pixel/rgb8``.
        /// -   Parameter palette:
        ///     An palette of suggested posterization values. Most PNG viewers
        ///     ignore this field.
        ///
        ///     This field is unrelated to, and should not be confused with a
        ///     ``SuggestedPalette``.
        /// -   Parameter fill:
        ///     An optional background color. Most PNG viewers ignore this field.
        /// -   Parameter key:
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible.
        case bgr8(palette:[(b:UInt8, g:UInt8, r:UInt8)],
            fill:(b:UInt8, g:UInt8, r:UInt8 )?,
            key:(b:UInt8, g:UInt8, r:UInt8 )?)

        /// An 8-bit RGB color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/rgb8``.
        /// -   Parameter palette:
        ///     An palette of suggested posterization values. Most PNG viewers
        ///     ignore this field.
        ///
        ///     This field is unrelated to, and should not be confused with a
        ///     ``SuggestedPalette``.
        /// -   Parameter fill:
        ///     An optional background color. Most PNG viewers ignore this field.
        /// -   Parameter key:
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible.
        case rgb8(palette:[(r:UInt8, g:UInt8, b:UInt8)],
            fill:(r:UInt8, g:UInt8, b:UInt8 )?,
            key:(r:UInt8, g:UInt8, b:UInt8)?)

        /// A 16-bit RGB color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/rgb16``.
        /// -   Parameter palette:
        ///     An palette of suggested posterization values. Most PNG viewers
        ///     ignore this field. Although the image color depth is `16`, the
        ///     palette atom type is ``UInt8``, not ``UInt16``.
        ///
        ///     This field is unrelated to, and should not be confused with a
        ///     ``SuggestedPalette``.
        /// -   Parameter fill:
        ///     An optional background color. Most PNG viewers ignore this field.
        /// -   Parameter key:
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible.
        case rgb16(palette:[(r:UInt8, g:UInt8, b:UInt8)],
            fill:(r:UInt16, g:UInt16, b:UInt16)?,
            key:(r:UInt16, g:UInt16, b:UInt16)?)

        /// A 1-bit indexed color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/indexed1``.
        /// -   Parameter palette:
        ///     The palette values referenced by an image with this color format.
        ///     This palette must be non-empty, and can have at most `2` entries.
        /// -   Parameter fill:
        ///     A palette index specifying an optional background color. This index
        ///     must be within the index range of the `palette` array.
        ///
        ///     Most PNG viewers ignore this field.
        case indexed1(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:Int?)

        /// A 2-bit indexed color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/indexed2``.
        /// -   Parameter palette:
        ///     The palette values referenced by an image with this color format.
        ///     This palette must be non-empty, and can have at most `4` entries.
        /// -   Parameter fill:
        ///     A palette index specifying an optional background color. This index
        ///     must be within the index range of the `palette` array.
        ///
        ///     Most PNG viewers ignore this field.
        case indexed2(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:Int?)

        /// A 4-bit indexed color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/indexed4``.
        /// -   Parameter palette:
        ///     The palette values referenced by an image with this color format.
        ///     This palette must be non-empty, and can have at most `16` entries.
        /// -   Parameter fill:
        ///     A palette index specifying an optional background color. This index
        ///     must be within the index range of the `palette` array.
        ///
        ///     Most PNG viewers ignore this field.
        case indexed4(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:Int?)

        /// An 8-bit indexed color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/indexed8``.
        /// -   Parameter palette:
        ///     The palette values referenced by an image with this color format.
        ///     This palette must be non-empty, and can have at most `256` entries.
        /// -   Parameter fill:
        ///     A palette index specifying an optional background color. This index
        ///     must be within the index range of the `palette` array.
        ///
        ///     Most PNG viewers ignore this field.
        case indexed8(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:Int?)

        /// An 8-bit grayscale-alpha color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/va8``.
        /// -   Parameter fill:
        ///     An optional background color. Most PNG viewers ignore this field.
        case va8(fill:UInt8?)

        /// A 16-bit grayscale-alpha color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/va16``.
        /// -   Parameter fill:
        ///     An optional background color. Most PNG viewers ignore this field.
        case va16(fill:UInt16?)

        /// An 8-bit BGRA color format.
        ///
        /// This color format is an iphone-optimized format.
        /// It has a ``pixel`` format of ``Pixel/rgba8``.
        /// -   Parameter palette:
        ///     An palette of suggested posterization values. Most PNG viewers
        ///     ignore this field.
        ///
        ///     This field is unrelated to, and should not be confused with a
        ///     ``SuggestedPalette``.
        /// -   Parameter fill:
        ///     An optional background color. Most PNG viewers ignore this field.
        case bgra8(palette:[(b:UInt8, g:UInt8, r:UInt8)], fill:(b:UInt8, g:UInt8, r:UInt8 )?)

        /// An 8-bit RGBA color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/rgba8``.
        /// -   Parameter palette:
        ///     An palette of suggested posterization values. Most PNG viewers
        ///     ignore this field.
        ///
        ///     This field is unrelated to, and should not be confused with a
        ///     ``SuggestedPalette``.
        /// -   Parameter fill:
        ///     An optional background color. Most PNG viewers ignore this field.
        case rgba8(palette:[(r:UInt8, g:UInt8, b:UInt8)], fill:(r:UInt8, g:UInt8, b:UInt8 )?)

        /// A 16-bit RGBA color format.
        ///
        /// This color format has a ``pixel`` format of ``Pixel/rgba16``.
        /// -   Parameter palette:
        ///     An palette of suggested posterization values. Most PNG viewers
        ///     ignore this field. Although the image color depth is `16`, the
        ///     palette atom type is ``UInt8``, not ``UInt16``.
        ///
        ///     This field is unrelated to, and should not be confused with a
        ///     ``SuggestedPalette``.
        /// -   Parameter fill:
        ///     An optional background color. Most PNG viewers ignore this field.
        case rgba16(palette:[(r:UInt8, g:UInt8, b:UInt8)], fill:(r:UInt16, g:UInt16, b:UInt16)?)
    }
}
extension PNG.Format
{
    // can’t use these in the enum cases because they are `internal` only
    typealias RGB<T>  = (r:T, g:T, b:T)
    typealias RGBA<T> = (r:T, g:T, b:T, a:T)

    /// The pixel format used by an image with this color format.
    @inlinable public
    var pixel:Pixel
    {
        switch self
        {
        case .v1:       return .v1
        case .v2:       return .v2
        case .v4:       return .v4
        case .v8:       return .v8
        case .v16:      return .v16
        case .bgr8:     return .rgb8
        case .rgb8:     return .rgb8
        case .rgb16:    return .rgb16
        case .indexed1: return .indexed1
        case .indexed2: return .indexed2
        case .indexed4: return .indexed4
        case .indexed8: return .indexed8
        case .va8:      return .va8
        case .va16:     return .va16
        case .bgra8:    return .rgba8
        case .rgba8:    return .rgba8
        case .rgba16:   return .rgba16
        }
    }

    // enum case constructors can’t perform validation, so we need to check
    // the range of the sample values with this function.
    func validate() -> Self
    {
        let max:(sample:UInt16, count:Int, index:Int)
        max.sample  = .max >> (UInt16.bitWidth - self.pixel.depth)
        max.count   = 1    <<                min(self.pixel.depth, 8)
        // palette cannot contain more entries than bit depth allows
        switch self
        {
        case    .bgr8    (palette: let palette, fill: _, key: _),
                .bgra8   (palette: let palette, fill: _):
            max.index = palette.count - 1
        case
                .rgb8    (palette: let palette, fill: _, key: _),
                .rgb16   (palette: let palette, fill: _, key: _),
                .rgba8   (palette: let palette, fill: _),
                .rgba16  (palette: let palette, fill: _):
            max.index = palette.count - 1
        case    .indexed1(palette: let palette, fill: _),
                .indexed2(palette: let palette, fill: _),
                .indexed4(palette: let palette, fill: _),
                .indexed8(palette: let palette, fill: _):
            guard !palette.isEmpty
            else
            {
                PNG.ParsingError.invalidPaletteCount(0, max: max.count).fatal
            }
            max.index = palette.count - 1
        default:
            max.index =                -1
        }

        guard max.index < max.count
        else
        {
            PNG.ParsingError.invalidPaletteCount(max.index + 1, max: max.count).fatal
        }

        switch self
        {
        case    .v1(fill: let fill?, key: _),
                .v2(fill: let fill?, key: _),
                .v4(fill: let fill?, key: _):
            let fill:UInt16 = .init(fill)
            guard fill <= max.sample
            else
            {
                PNG.ParsingError.invalidBackgroundSample(fill, max: max.sample).fatal
            }
        case    .indexed1(palette: _, fill: let i?),
                .indexed2(palette: _, fill: let i?),
                .indexed4(palette: _, fill: let i?),
                .indexed8(palette: _, fill: let i?):
            guard i <= max.index
            else
            {
                PNG.ParsingError.invalidBackgroundIndex(i, max: max.index).fatal
            }
        default:
            break
        }

        switch self
        {
        case    .v1(fill: _?, key: let key?),
                .v2(fill: _?, key: let key?),
                .v4(fill: _?, key: let key?):
            let key:UInt16 = .init(key)
            guard key <= max.sample
            else
            {
                PNG.ParsingError.invalidTransparencySample(key, max: max.sample).fatal
            }
        default:
            break
        }

        return self
    }

    // this function assumes all inputs have been validated for consistency,
    // except for the presence of the palette argument itself.
    static
    func recognize(standard:PNG.Standard, pixel:PNG.Format.Pixel,
        palette:PNG.Palette?, background:PNG.Background?, transparency:PNG.Transparency?)
        -> Self?
    {
        let format:Self
        switch pixel
        {
        case .v1, .v2, .v4, .v8, .v16:
            guard palette == nil
            else
            {
                PNG.ParsingError.unexpectedPalette(pixel: pixel).fatal
            }
            let f:UInt16?,
                k:UInt16?
            switch background?.case
            {
            case .v(let v)?:    f = v
            case nil:           f = nil
            default:
                fatalError("expected background of case `v` for pixel format `\(pixel)`")
            }
            switch transparency?.case
            {
            case .v(let v)?:    k = v
            case nil:           k = nil
            default:
                fatalError("expected transparency of case `v` for pixel format `\(pixel)`")
            }

            switch pixel
            {
            case .v1:
                format = .v1(fill: f.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v2:
                format = .v2(fill: f.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v4:
                format = .v4(fill: f.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v8:
                format = .v8(fill: f.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v16:
                format = .v16(fill: f,                    key: k)
            default:
                fatalError("unreachable")
            }

        case .rgb8, .rgb16:
            let palette:[RGB<UInt8>] = palette?.entries ?? []
            let f:RGB<UInt16>?,
                k:RGB<UInt16>?
            switch background?.case
            {
            case .rgb(let c)?:  f = c
            case nil:           f = nil
            default:
                fatalError("expected background of case `rgb` for pixel format `\(pixel)`")
            }
            switch transparency?.case
            {
            case .rgb(let c)?:  k = c
            case nil:           k = nil
            default:
                fatalError("expected transparency of case `rgb` for pixel format `\(pixel)`")
            }

            switch (standard, pixel)
            {
            case (.common,  .rgb8):
                format = .rgb8(palette: palette,
                    fill: f.map{ (.init($0.r), .init($0.g), .init($0.b)) },
                    key:  k.map{ (.init($0.r), .init($0.g), .init($0.b)) })
            case (.ios,     .rgb8):
                format = .bgr8(palette: palette.map{ ($0.b, $0.g, $0.r) },
                    fill: f.map{ (.init($0.b), .init($0.g), .init($0.r)) },
                    key:  k.map{ (.init($0.b), .init($0.g), .init($0.r)) })
            case (_,        .rgb16):
                format = .rgb16(palette: palette, fill: f, key: k)
            default:
                fatalError("unreachable")
            }

        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let solid:PNG.Palette = palette
            else
            {
                return nil
            }
            let f:Int?
            switch background?.case
            {
            case .palette(let i):   f = i
            case nil:               f = nil
            default:
                fatalError("expected background of case `palette` for pixel format `\(pixel)`")
            }

            let palette:[RGBA<UInt8>]
            switch transparency?.case
            {
            case nil:
                palette =          solid.entries.map        { (  $0.r,   $0.g,   $0.b, .max) }
            case .palette(let alpha):
                guard alpha.count <= solid.entries.count
                else
                {
                    PNG.ParsingError.invalidTransparencyCount(alpha.count,
                        max: solid.entries.count).fatal
                }

                palette =      zip(solid.entries, alpha).map{ ($0.0.r, $0.0.g, $0.0.b, $0.1) } +
                    solid.entries.dropFirst(alpha.count).map{ (  $0.r,   $0.g,   $0.b, .max) }
            default:
                fatalError("expected transparency of case `palette` for pixel format `\(pixel)`")
            }

            switch pixel
            {
            case .indexed1:
                format = .indexed1(palette: palette, fill: f)
            case .indexed2:
                format = .indexed2(palette: palette, fill: f)
            case .indexed4:
                format = .indexed4(palette: palette, fill: f)
            case .indexed8:
                format = .indexed8(palette: palette, fill: f)
            default:
                fatalError("unreachable")
            }

        case .va8, .va16:
            guard palette == nil
            else
            {
                PNG.ParsingError.unexpectedPalette(pixel: pixel).fatal
            }
            guard transparency == nil
            else
            {
                PNG.ParsingError.unexpectedTransparency(pixel: pixel).fatal
            }

            let f:UInt16?
            switch background?.case
            {
            case .v(let v)?:    f = v
            case nil:           f = nil
            default:
                fatalError("expected background of case `v` for pixel format `\(pixel)`")
            }

            switch pixel
            {
            case .va8:
                format = .va8( fill: f.map(UInt8.init(_:)))
            case .va16:
                format = .va16(fill: f)
            default:
                fatalError("unreachable")
            }

        case .rgba8, .rgba16:
            guard transparency == nil
            else
            {
                PNG.ParsingError.unexpectedTransparency(pixel: pixel).fatal
            }

            let palette:[RGB<UInt8>] = palette?.entries ?? []
            let f:RGB<UInt16>?
            switch background?.case
            {
            case .rgb(let c)?:  f = c
            case nil:           f = nil
            default:
                fatalError("expected background of case `rgb` for pixel format `\(pixel)`")
            }

            switch (standard, pixel)
            {
            case (.common,  .rgba8):
                format = .rgba8(palette: palette,
                    fill: f.map{ (.init($0.r), .init($0.g), .init($0.b)) })
            case (.ios,     .rgba8):
                format = .bgra8(palette: palette.map{ ($0.b, $0.g, $0.r) },
                    fill: f.map{ (.init($0.b), .init($0.g), .init($0.r)) })
            case (_,        .rgba16):
                format = .rgba16(palette: palette, fill: f)
            default:
                fatalError("unreachable")
            }
        }
        // do not call `.validate()` on `format` because this will be done when
        // the `PNG.Layout` struct is initialized
        return format
    }
}
