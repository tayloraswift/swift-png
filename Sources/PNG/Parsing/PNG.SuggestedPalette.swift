extension PNG
{
    /// struct PNG.SuggestedPalette
    ///     A suggested image palette.
    ///
    ///     This type models the information stored in an ``Chunk/sPLT`` chunk.
    ///     It should not be confused with the suggested palette stored in the
    ///     color ``Format`` of an RGB, BGR, RGBA, or BGRA image.
    /// # [Parsing and serialization](suggestedpalette-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public
    struct SuggestedPalette
    {
        /// enum PNG.SuggestedPalette.Entries
        ///     A variant array of palette colors and frequencies.
        public
        enum Entries
        {
            /// case PNG.SuggestedPalette.Entries.rgba8(_:)
            ///     A suggested palette with an 8-bit color depth.
            /// - _ : [(color:(r:Swift.UInt8,  g:Swift.UInt8,  b:Swift.UInt8,  a:Swift.UInt8),  frequency:Swift.UInt16)]
            ///     An array of 8-bit palette colors and frequencies.
            /// ## ()
            case rgba8( [(color:(r:UInt8,  g:UInt8,  b:UInt8,  a:UInt8),  frequency:UInt16)])
            /// case PNG.SuggestedPalette.Entries.rgba16(_:)
            ///     A suggested palette with a 16-bit color depth.
            /// - _ : [(color:(r:Swift.UInt16,  g:Swift.UInt16,  b:Swift.UInt16,  a:Swift.UInt16),  frequency:Swift.UInt16)]
            ///     An array of 16-bit palette colors and frequencies.
            /// ## ()
            case rgba16([(color:(r:UInt16, g:UInt16, b:UInt16, a:UInt16), frequency:UInt16)])
        }
        /// let PNG.SuggestedPalette.name : Swift.String
        ///     The name of this suggested palette.
        public
        let name:String
        /// let PNG.SuggestedPalette.entries : Entries
        ///     The colors in this suggested palette, and their frequencies.
        public
        var entries:Entries

        /// init PNG.SuggestedPalette.init(name:entries:)
        ///     Creates a suggested palette.
        /// - name : Swift.String
        ///     The palette name.
        ///
        ///     This string must contain only unicode scalars
        ///     in the ranges `"\u{20}" ... "\u{7d}"` or `"\u{a1}" ... "\u{ff}"`.
        ///     Leading, trailing, and consecutive spaces are not allowed.
        ///     Passing an invalid string will result in a precondition failure.
        /// - entries : Entries
        ///     A variant array of palette colors and frequencies.
        public
        init(name:String, entries:Entries)
        {
            guard PNG.Text.validate(name: name.unicodeScalars)
            else
            {
                PNG.ParsingError.invalidSuggestedPaletteName(name).fatal
            }

            self.name       = name
            self.entries    = entries

            guard self.descendingFrequency
            else
            {
                PNG.ParsingError.invalidSuggestedPaletteFrequency.fatal
            }
        }
    }
}
extension PNG.SuggestedPalette
{
    /// init PNG.SuggestedPalette.init(parsing:)
    /// throws
    ///     Creates a suggested palette by parsing the given chunk data.
    /// - data      : [Swift.UInt8]
    ///     The contents of an ``Chunk/sPLT`` chunk to parse.
    /// ## (suggestedpalette-parsing-and-serialization)
    public
    init(parsing data:[UInt8]) throws
    {
        let k:Int

        (self.name, k) = try PNG.Text.name(parsing: data[...])
        {
            PNG.ParsingError.invalidSuggestedPaletteName($0)
        }

        guard k + 1 < data.count
        else
        {
            throw PNG.ParsingError.invalidSuggestedPaletteChunkLength(data.count, min: k + 2)
        }

        let bytes:Int = data.count - k - 2
        switch data[k + 1]
        {
        case 8:
            guard bytes % 6 == 0
            else
            {
                throw PNG.ParsingError.invalidSuggestedPaletteDataLength(bytes, stride: 6)
            }

            self.entries = .rgba8(stride(from: k + 2, to: data.endIndex, by: 6).map
            {
                (base:Int) -> (color:(r:UInt8, g:UInt8, b:UInt8, a:UInt8), frequency:UInt16) in
                (
                    (
                        data[base    ],
                        data[base + 1],
                        data[base + 2],
                        data[base + 3]
                    ),
                    data.load(bigEndian: UInt16.self, as: UInt16.self, at: base + 4)
                )
            })

        case 16:
            guard bytes % 10 == 0
            else
            {
                throw PNG.ParsingError.invalidSuggestedPaletteDataLength(bytes, stride: 10)
            }

            self.entries = .rgba16(stride(from: k + 2, to: data.endIndex, by: 10).map
            {
                (base:Int) -> (color:(r:UInt16, g:UInt16, b:UInt16, a:UInt16), frequency:UInt16) in
                (
                    (
                        data.load(bigEndian: UInt16.self, as: UInt16.self, at: base    ),
                        data.load(bigEndian: UInt16.self, as: UInt16.self, at: base + 2),
                        data.load(bigEndian: UInt16.self, as: UInt16.self, at: base + 4),
                        data.load(bigEndian: UInt16.self, as: UInt16.self, at: base + 6)
                    ),
                    data.load(bigEndian: UInt16.self, as: UInt16.self, at: base + 8)
                )
            })

        case let code:
            throw PNG.ParsingError.invalidSuggestedPaletteDepthCode(code)
        }

        guard self.descendingFrequency
        else
        {
            throw PNG.ParsingError.invalidSuggestedPaletteFrequency
        }
    }

    private
    var descendingFrequency:Bool
    {
        var previous:UInt16 = .max
        switch self.entries
        {
        case .rgba8(let entries):
            for current:UInt16 in entries.lazy.map(\.frequency)
            {
                guard current <= previous
                else
                {
                    return false
                }

                previous = current
            }
        case .rgba16(let entries):
            for current:UInt16 in entries.lazy.map(\.frequency)
            {
                guard current <= previous
                else
                {
                    return false
                }

                previous = current
            }
        }

        return true
    }
    /// var PNG.SuggestedPalette.serialized : [Swift.UInt8] { get }
    ///     Encodes this suggested palette as the contents of an
    ///     ``Chunk/sPLT`` chunk.
    /// ## (suggestedpalette-parsing-and-serialization)
    public
    var serialized:[UInt8]
    {
        let head:Int = self.name.unicodeScalars.count
        let tail:Int
        switch self.entries
        {
        case .rgba8( let entries):  tail =  6 * entries.count
        case .rgba16(let entries):  tail = 10 * entries.count
        }

        return .init(unsafeUninitializedCapacity: head + 2 + tail)
        {
            for (i, u):(Int, Unicode.Scalar) in
                zip($0.indices, self.name.unicodeScalars)
            {
                $0[i] = .init(u.value)
            }
            $0[head] = 0

            switch self.entries
            {
            case .rgba8( let entries):
                $0[head + 1] = 8
                for (base, (color, frequency)):
                (
                    Int,
                    ((r:UInt8,  g:UInt8,  b:UInt8,  a:UInt8), UInt16)
                )
                    in zip(stride(from: head + 2, to: $0.endIndex, by: 6), entries)
                {
                    $0[base    ]    = color.r
                    $0[base + 1]    = color.g
                    $0[base + 2]    = color.b
                    $0[base + 3]    = color.a
                    $0.store(frequency, asBigEndian: UInt16.self, at: base + 4)
                }
            case .rgba16(let entries):
                $0[head + 1] = 16
                for (base, (color, frequency)):
                (
                    Int,
                    ((r:UInt16, g:UInt16, b:UInt16, a:UInt16), UInt16)
                )
                    in zip(stride(from: head + 2, to: $0.endIndex, by: 10), entries)
                {
                    $0.store(color.r,   asBigEndian: UInt16.self, at: base    )
                    $0.store(color.g,   asBigEndian: UInt16.self, at: base + 2)
                    $0.store(color.b,   asBigEndian: UInt16.self, at: base + 4)
                    $0.store(color.a,   asBigEndian: UInt16.self, at: base + 6)
                    $0.store(frequency, asBigEndian: UInt16.self, at: base + 8)
                }
            }
            $1 = $0.count
        }
    }
}
