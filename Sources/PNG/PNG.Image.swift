extension PNG
{
    /// A namespace containing the ``Image`` type.
    @available(*, deprecated)
    public
    enum Data
    {
        @available(*, deprecated, renamed: "PNG.Image")
        typealias Rectangular = PNG.Image
    }
}
extension PNG
{
    /// A rectangular image.
    @frozen public
    struct Image
    {
        /// The size of this image, measured in pixels.
        public
        let size:(x:Int, y:Int)
        /// The layout of this image.
        public
        let layout:PNG.Layout
        /// The metadata in this image.
        public
        var metadata:PNG.Metadata
        /// The raw backing storage of the image content.
        ///
        /// Depending on the bit depth of the image, it either stores a matrix
        /// of ``UInt8`` samples, or a matrix of big-endian ``UInt16``
        /// samples. The pixels are arranged in row-major order, where the
        /// beginning of the storage array corresponds to the visual top-left
        /// corner of the image, regardless of whether the ``layout`` is
        /// ``Layout/interlaced`` or not.
        public private(set)
        var storage:[UInt8]

        // make the trivial init usable from inline
        @usableFromInline
        init(size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata, storage:[UInt8])
        {
            self.size       = size
            self.layout     = layout
            self.metadata   = metadata
            self.storage    = storage
        }
    }
}
extension PNG.Image
{
    init?(standard:PNG.Standard, header:PNG.Header,
        palette:PNG.Palette?, background:PNG.Background?, transparency:PNG.Transparency?,
        metadata:PNG.Metadata,
        uninitialized:Bool)
    {
        guard
        let layout:PNG.Layout = PNG.Layout.init(standard: standard,
            pixel:          header.pixel,
            palette:        palette,
            background:     background,
            transparency:   transparency,
            interlaced:     header.interlaced)
        else
        {
            return nil
        }

        self.size       = header.size
        self.layout     = layout
        self.metadata   = metadata

        let count:Int   = header.size.x * header.size.y,
            bytes:Int   = count * (layout.format.pixel.volume + 7) >> 3
        if uninitialized
        {
            self.storage    = .init(unsafeUninitializedCapacity: bytes)
            {
                $1 = bytes
            }
        }
        else
        {
            self.storage    = .init(repeating: 0, count: bytes)
        }
    }

    /// Rebinds this image to a compatible layout.
    ///
    /// This interface can be used to switch image layouts without unpacking
    /// to and repacking from a color target array. Rebinding to an
    /// incompatible layout will result in a precondition failure.
    /// -   Parameter layout:
    ///     The new image layout.
    ///
    ///     Both the original color ``Layout/format`` and the new
    ///     color ``Layout/format`` must be of the same enumeration case, though the fields
    ///     may differ. The exceptions are the indexed color formats, which require
    ///     the lengths of their `palette` payloads to match exactly.
    /// -   Returns:
    ///     An image with the given layout. This image will share backing ``storage``
    ///     with the original image until it is copied-on-write.
    public
    func bindStorage(to layout:PNG.Layout) -> Self
    {
        switch (self.layout.format, layout.format)
        {
        case    (.indexed1(palette: let old, fill: _), .indexed1(palette: let new, fill: _)),
                (.indexed2(palette: let old, fill: _), .indexed2(palette: let new, fill: _)),
                (.indexed4(palette: let old, fill: _), .indexed4(palette: let new, fill: _)),
                (.indexed8(palette: let old, fill: _), .indexed8(palette: let new, fill: _)):
            guard old.count == new.count
            else
            {
                fatalError("new palette count (\(new.count)) must match old palette count (\(old.count))")
            }

        case    (.v1, .v1), (.v2, .v2), (.v4, .v4), (.v8, .v8 ), (.v16, .v16),
                ( .bgr8,  .bgr8),
                ( .rgb8,  .rgb8), ( .rgb16,  .rgb16),
                (  .va8,   .va8), (  .va16,   .va16),
                (.bgra8, .bgra8),
                (.rgba8, .rgba8), (.rgba16, .rgba16):
            break
        default:
            fatalError("new pixel format (\(layout.format.pixel)) must match old pixel format (\(self.layout.format.pixel))")
        }

        return .init(size: self.size, layout: layout, metadata: self.metadata,
            storage: self.storage)
    }

    mutating
    func overdraw(at base:(x:Int, y:Int), brush:(x:Int, y:Int))
    {
        guard brush.x * brush.y > 1
        else
        {
            return
        }

        switch self.layout.format
        {
        // 1-byte stride
        case .v1, .v2, .v4, .v8, .indexed1, .indexed2, .indexed4, .indexed8:
            self.overdraw(at: base, brush: brush, element: UInt8.self)
        // 2-byte stride
        case .v16, .va8:
            self.overdraw(at: base, brush: brush, element: UInt16.self)
        // 3-byte stride
        case .bgr8, .rgb8:
            self.overdraw(at: base, brush: brush, element: (UInt8, UInt8, UInt8).self)
        // 4-byte stride
        case .bgra8, .rgba8, .va16:
            self.overdraw(at: base, brush: brush, element: UInt32.self)
        // 6-byte stride
        case .rgb16:
            self.overdraw(at: base, brush: brush, element: (UInt16, UInt16, UInt16).self)
        // 8-byte stride
        case .rgba16:
            self.overdraw(at: base, brush: brush, element: UInt64.self)
        }
    }

    private mutating
    func overdraw<T>(at base:(x:Int, y:Int), brush:(x:Int, y:Int), element:T.Type)
    {
        self.storage.withUnsafeMutableBytes
        {
            let storage:UnsafeMutableBufferPointer<T> = $0.bindMemory(to: T.self)
            for y:Int in base.y ..< min(base.y + brush.y, self.size.y)
            {
                for x:Int in stride(from: base.x, to: self.size.x, by: brush.x)
                {
                    let i:Int = base.y * self.size.x + x
                    for x:Int in x ..< min(x + brush.x, self.size.x)
                    {
                        storage[y * self.size.x + x] = storage[i]
                    }
                }
            }
        }
    }

    mutating
    func assign<C>(scanline:C, at base:(x:Int, y:Int), stride:Int)
        where C:RandomAccessCollection, C.Index == Int, C.Element == UInt8
    {
        let indices:EnumeratedSequence<StrideTo<Int>> =
            Swift.stride(from: base.x, to: self.size.x, by: stride).enumerated()
        switch self.layout.format
        {
        // 0 x 1
        case .v1, .indexed1:
            for (i, x):(Int, Int) in indices
            {
                let a:Int =   i >> 3 &+ scanline.startIndex,
                    b:Int =  ~i & 0b111
                self.storage[base.y &* self.size.x &+ x] = scanline[a] &>> b & 0b0001
            }

        case .v2, .indexed2:
            for (i, x):(Int, Int) in indices
            {
                let a:Int =   i >> 2 &+ scanline.startIndex,
                    b:Int = (~i & 0b011) << 1
                self.storage[base.y &* self.size.x &+ x] = scanline[a] &>> b & 0b0011
            }

        case .v4, .indexed4:
            for (i, x):(Int, Int) in indices
            {
                let a:Int =   i >> 1 &+ scanline.startIndex,
                    b:Int = (~i & 0b001) << 2
                self.storage[base.y &* self.size.x &+ x] = scanline[a] &>> b & 0b1111
            }

        // 1 x 1
        case .v8, .indexed8:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = i &+ scanline.startIndex,
                    d:Int = base.y &* self.size.x &+ x
                self.storage[d] = scanline[a]
            }
        // 1 x 2, 2 x 1
        case .va8, .v16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 2 &* i &+ scanline.startIndex,
                    d:Int = 2 &* (base.y &* self.size.x &+ x)
                self.storage[d     ] = scanline[a     ]
                self.storage[d &+ 1] = scanline[a &+ 1]
            }
        // 1 x 3
        case .rgb8, .bgr8:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 3 &* i &+ scanline.startIndex,
                    d:Int = 3 &* (base.y &* self.size.x &+ x)
                self.storage[d     ] = scanline[a     ]
                self.storage[d &+ 1] = scanline[a &+ 1]
                self.storage[d &+ 2] = scanline[a &+ 2]
            }
        // 1 x 4, 2 x 2
        case .rgba8, .bgra8, .va16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 4 &* i &+ scanline.startIndex,
                    d:Int = 4 &* (base.y &* self.size.x &+ x)
                self.storage[d     ] = scanline[a     ]
                self.storage[d &+ 1] = scanline[a &+ 1]
                self.storage[d &+ 2] = scanline[a &+ 2]
                self.storage[d &+ 3] = scanline[a &+ 3]
            }
        // 2 x 3
        case .rgb16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 6 &* i &+ scanline.startIndex,
                    d:Int = 6 &* (base.y &* self.size.x &+ x)
                self.storage[d     ] = scanline[a     ]
                self.storage[d &+ 1] = scanline[a &+ 1]
                self.storage[d &+ 2] = scanline[a &+ 2]
                self.storage[d &+ 3] = scanline[a &+ 3]
                self.storage[d &+ 4] = scanline[a &+ 4]
                self.storage[d &+ 5] = scanline[a &+ 5]
            }
        // 2 x 4
        case .rgba16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 8 &* i &+ scanline.startIndex,
                    d:Int = 8 &* (base.y &* self.size.x &+ x)
                self.storage[d     ] = scanline[a     ]
                self.storage[d &+ 1] = scanline[a &+ 1]
                self.storage[d &+ 2] = scanline[a &+ 2]
                self.storage[d &+ 3] = scanline[a &+ 3]
                self.storage[d &+ 4] = scanline[a &+ 4]
                self.storage[d &+ 5] = scanline[a &+ 5]
                self.storage[d &+ 6] = scanline[a &+ 6]
                self.storage[d &+ 7] = scanline[a &+ 7]
            }
        }
    }
}
extension PNG.Image
{
    /// Decompresses and decodes a PNG from the given bytestream.
    ///
    /// On appropriate platforms, the ``decompress(path:)`` function provides
    /// a file system-aware interface to this function.
    /// -   Parameter stream:
    ///     A bytestream providing the contents of a PNG file.
    /// -   Returns:
    ///     The decoded image.
    public static
    func decompress<Source>(stream:inout Source) throws -> Self
        where Source:PNG.BytestreamSource
    {
        try stream.signature()
        let (standard, header):(PNG.Standard, PNG.Header) = try
        {
            var chunk:(type:PNG.Chunk, data:[UInt8]) = try stream.chunk()
            let standard:PNG.Standard
            switch chunk.type
            {
            case .CgBI:
                standard    = .ios
                chunk       = try stream.chunk()
            default:
                standard    = .common
            }
            switch chunk.type
            {
            case .IHDR:
                return (standard, try .init(parsing: chunk.data, standard: standard))
            case let type:
                throw PNG.DecodingError.required(chunk: .IHDR, before: type)
            }
        }()

        var chunk:(type:PNG.Chunk, data:[UInt8]) = try stream.chunk()

        var context:PNG.Context = try
        {
            var palette:PNG.Palette?
            var background:PNG.Background?,
                transparency:PNG.Transparency?
            var metadata:PNG.Metadata = .init()
            while true
            {
                switch chunk.type
                {
                case .IHDR:
                    throw PNG.DecodingError.duplicate(chunk: .IHDR)

                case .PLTE:
                    guard palette == nil
                    else
                    {
                        throw PNG.DecodingError.duplicate(chunk: .PLTE)
                    }
                    guard background == nil
                    else
                    {
                        throw PNG.DecodingError.unexpected(chunk: .PLTE, after: .bKGD)
                    }
                    guard transparency == nil
                    else
                    {
                        throw PNG.DecodingError.unexpected(chunk: .PLTE, after: .tRNS)
                    }

                    palette = try .init(parsing: chunk.data, pixel: header.pixel)

                case .IDAT:
                    guard let context:PNG.Context = PNG.Context.init(
                        standard:       standard,
                        header:         header,
                        palette:        palette,
                        background:     background,
                        transparency:   transparency,
                        metadata:       metadata)
                    else
                    {
                        throw PNG.DecodingError.required(chunk: .PLTE, before: .IDAT)
                    }
                    return context

                case .IEND:
                    throw PNG.DecodingError.required(chunk: .IDAT, before: .IEND)

                default:
                    try metadata.push(ancillary: chunk, pixel: header.pixel,
                        palette:        palette,
                        background:     &background,
                        transparency:   &transparency)
                }

                chunk = try stream.chunk()
            }
        }()

        while chunk.type == .IDAT
        {
            try context.push(data: chunk.data)
            chunk = try stream.chunk()
        }

        while true
        {
            try context.push(ancillary: chunk)
            guard chunk.type != .IEND
            else
            {
                return context.image
            }
            chunk = try stream.chunk()
        }
    }
}

// encoding
extension PNG.Image
{
    func encode() ->
    (
        header:PNG.Header,
        palette:PNG.Palette?,
        background:PNG.Background?,
        transparency:PNG.Transparency?,
        cgbi:[UInt8]?
    )
    {
        let cgbi:[UInt8]?,
            standard:PNG.Standard
        switch self.layout.format
        {
        case .bgr8:     cgbi = [48, 0, 32, 6]   ; standard = .ios
        case .bgra8:    cgbi = [48, 0, 32, 2]   ; standard = .ios
        default:        cgbi = nil              ; standard = .common
        }
        let header:PNG.Header = .init(size: self.size,
            pixel:      self.layout.format.pixel,
            interlaced: self.layout.interlaced,
            standard:   standard)
        return (header, self.layout.palette, self.layout.background, self.layout.transparency, cgbi)
    }

    func collect<C>(scanline:inout C, at base:(x:Int, y:Int), stride:Int)
        where   C:RandomAccessCollection & MutableCollection,
                C.Index == Int, C.Element == UInt8
    {
        let indices:EnumeratedSequence<StrideTo<Int>> =
            Swift.stride(from: base.x, to: self.size.x, by: stride).enumerated()
        switch self.layout.format
        {
        // 0 x 1
        case .v1, .indexed1:
            // need to initialize to 0 since we are using |=
            for a:Int in scanline.indices
            {
                scanline[a] = 0
            }
            for (i, x):(Int, Int) in indices
            {
                let a:Int    =   i >> 3 &+ scanline.startIndex,
                    b:Int    =  ~i & 0b111
                scanline[a] |= (self.storage[base.y &* self.size.x &+ x] & 0b0001) &<< b
            }

        case .v2, .indexed2:
            for a:Int in scanline.indices
            {
                scanline[a] = 0
            }
            for (i, x):(Int, Int) in indices
            {
                let a:Int    =   i >> 2 &+ scanline.startIndex,
                    b:Int    = (~i & 0b011) << 1
                scanline[a] |= (self.storage[base.y &* self.size.x &+ x] & 0b0011) &<< b
            }

        case .v4, .indexed4:
            for a:Int in scanline.indices
            {
                scanline[a] = 0
            }
            for (i, x):(Int, Int) in indices
            {
                let a:Int    =   i >> 1 &+ scanline.startIndex,
                    b:Int    = (~i & 0b001) << 2
                scanline[a] |= (self.storage[base.y &* self.size.x &+ x] & 0b1111) &<< b
            }

        // 1 x 1
        case .v8, .indexed8:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = i &+ scanline.startIndex,
                    d:Int = base.y &* self.size.x &+ x
                scanline[a] = self.storage[d]
            }
        // 1 x 2, 2 x 1
        case .va8, .v16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 2 &* i &+ scanline.startIndex,
                    d:Int = 2 &* (base.y &* self.size.x &+ x)
                scanline[a     ] = self.storage[d     ]
                scanline[a &+ 1] = self.storage[d &+ 1]
            }
        // 1 x 3
        case .rgb8, .bgr8:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 3 &* i &+ scanline.startIndex,
                    d:Int = 3 &* (base.y &* self.size.x &+ x)
                scanline[a     ] = self.storage[d     ]
                scanline[a &+ 1] = self.storage[d &+ 1]
                scanline[a &+ 2] = self.storage[d &+ 2]
            }
        // 1 x 4, 2 x 2
        case .rgba8, .bgra8, .va16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 4 &* i &+ scanline.startIndex,
                    d:Int = 4 &* (base.y &* self.size.x &+ x)
                scanline[a     ] = self.storage[d     ]
                scanline[a &+ 1] = self.storage[d &+ 1]
                scanline[a &+ 2] = self.storage[d &+ 2]
                scanline[a &+ 3] = self.storage[d &+ 3]
            }
        // 2 x 3
        case .rgb16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 6 &* i &+ scanline.startIndex,
                    d:Int = 6 &* (base.y &* self.size.x &+ x)
                scanline[a     ] = self.storage[d     ]
                scanline[a &+ 1] = self.storage[d &+ 1]
                scanline[a &+ 2] = self.storage[d &+ 2]
                scanline[a &+ 3] = self.storage[d &+ 3]
                scanline[a &+ 4] = self.storage[d &+ 4]
                scanline[a &+ 5] = self.storage[d &+ 5]
            }
        // 2 x 4
        case .rgba16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 8 &* i &+ scanline.startIndex,
                    d:Int = 8 &* (base.y &* self.size.x &+ x)
                scanline[a     ] = self.storage[d     ]
                scanline[a &+ 1] = self.storage[d &+ 1]
                scanline[a &+ 2] = self.storage[d &+ 2]
                scanline[a &+ 3] = self.storage[d &+ 3]
                scanline[a &+ 4] = self.storage[d &+ 4]
                scanline[a &+ 5] = self.storage[d &+ 5]
                scanline[a &+ 6] = self.storage[d &+ 6]
                scanline[a &+ 7] = self.storage[d &+ 7]
            }
        }
    }
}
// compression
extension PNG.Image
{
    /// Encodes and compresses a PNG to the given bytestream.
    ///
    /// Compression `level` `9` is roughly equivalent to *libpng*’s maximum
    /// compression setting in terms of compression ratio and encoding speed.
    /// The higher levels (`10` through `13`) are very computationally expensive,
    /// so they should only be used when optimizing for file size.
    ///
    /// On appropriate platforms, the ``compress(path:level:hint:)`` function
    /// provides a file system-aware interface to this function.
    /// -   Parameter stream:
    ///     A bytestream receiving the contents of a PNG file.
    /// -   Parameter level:
    ///     The compression level to use. It should be in the range `0 ... 13`,
    ///     where `13` is the most aggressive setting. The default value is `9`.
    ///
    ///     Setting this parameter to a value less than `0` is the same as
    ///     setting it to `0`. Likewise, setting it to a value greater than `13`
    ///     is the same as setting it to `13`.
    /// -   Parameter hint:
    ///     A size hint for the emitted ``Chunk/IDAT`` chunks. It should be in
    ///     the range `1 ... 2147483647`. Reasonable settings range from around
    ///     1\ K to 64\ K. The default value is `32768` (2^15^).
    ///
    ///     Setting this parameter to a value less than `1` is the same as setting
    ///     it to `1`. Likewise, setting it to a value greater than `2147483647`
    ///     (2^31^\ –\ 1) is the same as setting it to `2147483647`.
    public
    func compress<Destination>(stream:inout Destination, level:Int = 9, hint:Int = 1 << 15)
        throws
        where Destination:PNG.BytestreamDestination
    {
        try stream.signature()

        let header:PNG.Header,
            palette:PNG.Palette?,
            background:PNG.Background?,
            transparency:PNG.Transparency?,
            cgbi:[UInt8]?
        (header, palette, background, transparency, cgbi) = self.encode()

        if let cgbi:[UInt8] = cgbi
        {
            try stream.format(type: .CgBI, data: cgbi)
        }

        try stream.format(type: .IHDR, data: header.serialized)

        if let chromaticity:PNG.Chromaticity        = self.metadata.chromaticity
        {
            try stream.format(type: .cHRM, data: chromaticity.serialized)
        }
        if let gamma:PNG.Gamma                      = self.metadata.gamma
        {
            try stream.format(type: .gAMA, data: gamma.serialized)
        }
        if let colorRendering:PNG.ColorRendering    = self.metadata.colorRendering
        {
            try stream.format(type: .sRGB, data: colorRendering.serialized)
        }
        if let colorProfile:PNG.ColorProfile        = self.metadata.colorProfile
        {
            try stream.format(type: .iCCP, data: colorProfile.serialized)
        }
        if let significantBits:PNG.SignificantBits  = self.metadata.significantBits
        {
            try stream.format(type: .sBIT, data: significantBits.serialized)
        }


        if let palette:PNG.Palette                  = palette
        {
            try stream.format(type: .PLTE, data: palette.serialized)
        }
        if let background:PNG.Background            = background
        {
            try stream.format(type: .bKGD, data: background.serialized)
        }
        if let transparency:PNG.Transparency        = transparency
        {
            try stream.format(type: .tRNS, data: transparency.serialized)
        }
        if let histogram:PNG.Histogram              = self.metadata.histogram
        {
            try stream.format(type: .hIST, data: histogram.serialized)
        }


        if let dimensions:PNG.PhysicalDimensions    = self.metadata.physicalDimensions
        {
            try stream.format(type: .pHYs, data: dimensions.serialized)
        }
        if let time:PNG.TimeModified                = self.metadata.time
        {
            try stream.format(type: .tIME, data: time.serialized)
        }

        for text:PNG.Text in self.metadata.text
        {
            try stream.format(type: .iTXt, data: text.serialized)
        }
        for palette:PNG.SuggestedPalette in self.metadata.suggestedPalettes
        {
            try stream.format(type: .sPLT, data: palette.serialized)
        }
        for (type, data):(PNG.Chunk, [UInt8]) in self.metadata.application
        {
            try stream.format(type: type, data: data)
        }

        var encoder:PNG.Encoder = .init(standard: cgbi == nil ? .common : .ios,
            interlaced: self.layout.interlaced, level: level, hint: hint)
        while let data:[UInt8] = encoder.pull(size: self.size,
            pixel:      self.layout.format.pixel,
            delegate:   self.collect(scanline:at:stride:))
        {
            try stream.format(type: .IDAT, data: data)
        }

        try stream.format(type: .IEND)
    }
}

extension PNG.Image
{
    // factoring out the specialized entry point reduces module overhead, because
    // the emitted entry point can make use of the specialized function bodies
    @usableFromInline
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    static
    func unpack<T>(_ interleaved:[UInt8], of format:PNG.Format, as _:T.Type,
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> UInt8)
        -> [T]
        where T:FixedWidthInteger & UnsignedInteger
    {
        let depth:Int = format.pixel.depth
        switch format
        {
        case    .indexed1(palette: let palette, fill: _),
                .indexed2(palette: let palette, fill: _),
                .indexed4(palette: let palette, fill: _),
                .indexed8(palette: let palette, fill: _):
            return PNG.convolve(interleaved, dereference: deindexer(palette))
            {
                (c) in c
            }

        case    .v1(fill: _, key: _),
                .v2(fill: _, key: _),
                .v4(fill: _, key: _),
                .v8(fill: _, key: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:T, _) in c
            }
        case    .v16(fill: _, key: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:T, _) in c
            }

        case    .va8(fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T))       in c.0
            }
        case    .va16(fill: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T))       in c.0
            }

        case    .bgr8(palette: _, fill: _, key: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), _) in c.2
            }

        case    .rgb8(palette: _, fill: _, key: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), _) in c.0
            }
        case    .rgb16(palette: _, fill: _, key: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T), _) in c.0
            }

        case    .bgra8(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T, T)) in c.2
            }

        case    .rgba8(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T, T)) in c.0
            }
        case    .rgba16(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T, T)) in c.0
            }
        }
    }

    @usableFromInline
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    static
    func pack<T>(_ pixels:[T], as format:PNG.Format,
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (UInt8) -> Int)
        -> [UInt8]
        where T:FixedWidthInteger & UnsignedInteger
    {
        let depth:Int = format.pixel.depth
        switch format
        {
        case    .indexed1(palette: let palette, fill: _),
                .indexed2(palette: let palette, fill: _),
                .indexed4(palette: let palette, fill: _),
                .indexed8(palette: let palette, fill: _):
            return PNG.deconvolve(pixels, reference: indexer(palette))
            {
                (v) in v
            }

        case    .v1(fill: _, key: _),
                .v2(fill: _, key: _),
                .v4(fill: _, key: _),
                .v8(fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (v) in v
            }
        case    .v16(fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (v) in v
            }

        case    .va8(fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (v) in (v, .max)
            }
        case    .va16(fill: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (v) in (v, .max)
            }

        case    .bgr8(palette: _, fill: _, key: _),
                .rgb8(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (v) in (v, v, v)
            }
        case    .rgb16(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (v) in (v, v, v)
            }

        case    .bgra8(palette: _, fill: _),
                .rgba8(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (v) in (v, v, v, .max)
            }
        case    .rgba16(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (v) in (v, v, v, .max)
            }
        }
    }
}

// custom-indexer APIs
extension PNG.Image
{
    /// Unpacks this image to a pixel array, using a custom deindexing function.
    ///
    /// -   Parameter _:
    ///     A color target type. This type provides the ``_PNGColor/unpack(_:of:deindexer:)``
    ///     implementation used to unpack the image data.
    /// -   Parameter deindexer:
    ///     A function which uses the palette entries in the color ``Layout/format`` to
    ///     generate a dereferencing function. This function is only expected to
    ///     be invoked if `layout.format` is an indexed format.
    ///
    ///     See the [indexed color tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#using-indexed-images)
    ///     for more about the semantics of this function.
    ///
    /// -   Returns:
    ///     A pixel array. Its elements are arranged in row-major order. The
    ///     first pixel in this array corresponds to the top-left corner of
    ///     the image. Its length is equal to `size.x` multiplied by `size.y`.
    @inlinable
    public
    func unpack<Color>(as _:Color.Type,
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> Color.Aggregate)
        -> [Color]
        where Color:PNG.Color
    {
        Color.unpack(self.storage, of: self.layout.format, deindexer: deindexer)
    }
    /// Unpacks this image to a scalar pixel array, using a custom deindexing function.
    ///
    /// For an image with a grayscale-alpha color ``Layout/format``,
    /// this function selects the *v* component from pixels of the form (*v*, *a*)
    ///
    /// For an image with an RGB color ``Layout/format``,
    /// this function selects the *r* component from pixels of the form (*r*, *g*, *b*).
    ///
    /// For an image with an RGBA color ``Layout/format``, this function selects the *r* component from
    /// pixels of the form (*r*, *g*, *b*, *a*).
    ///
    /// For an image with a BGR color ``Layout/format``,
    /// this function selects the *r* component from pixels of the form (*b*, *g*, *r*).
    ///
    /// For an image with a BGRA color ``Layout/format``,
    /// this function selects the *r* component from pixels of the form (*b*, *g*, *r*, *a*).
    ///
    /// This function ignores chroma keys, as its scalar color target is not
    /// capable of representing transparency. The unpacked components
    /// are scaled to fill the range of `T`, according to the color depth
    /// computed from the color ``Layout/format``.
    ///
    /// -   Parameter _:
    ///     A scalar color target type.
    /// -   Parameter deindexer:
    ///     A function which uses the palette entries in the color ``Layout/format`` to
    ///     generate a dereferencing function. This function will only
    ///     be invoked if `layout.format` is an indexed format.
    ///
    ///     See the [indexed color tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#using-indexed-images)
    ///     for more about the semantics of this function.
    /// -   Returns:
    ///     A scalar pixel array. Its elements are arranged in row-major order. The
    ///     first pixel in this array corresponds to the top-left corner of
    ///     the image. Its length is equal to `size.x` multiplied by `size.y`.
    @inlinable
    public
    func unpack<T>(as _:T.Type,
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> UInt8)
        -> [T]
        where T:FixedWidthInteger & UnsignedInteger
    {
        Self.unpack(self.storage, of: self.layout.format, as: T.self, deindexer: deindexer)
    }
    /// Creates an image from a pixel array, using a custom indexing function.
    ///
    /// -   Parameter pixels:
    ///     A pixel array. Its elements are arranged in row-major order. The
    ///     first pixel in this array corresponds to the top-left corner of
    ///     the image. The `Color` type provides the ``_PNGColor/pack(_:as:indexer:)``
    ///     implementation used to pack the image data.
    ///
    ///     The length of this array must match `size.x * size.y`. Passing an
    ///     array of the wrong length will result in a precondition failure.
    /// -   Parameter size:
    ///     The size of the image. Both dimensions must be greater than zero.
    ///     Passing an invalid image size will result in a precondition failure.
    /// -   Parameter layout:
    ///     An image layout.
    /// -   Parameter metadata:
    ///     A metadata structure. The default value is an empty metadata structure.
    /// -   Parameter indexer:
    ///     A function which uses the palette entries in the color ``Layout/format`` to
    ///     generate a referencing function. This function is only expected to
    ///     be invoked if the image color ``Layout/format`` is an indexed format.
    ///
    /// See the [indexed color tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#using-indexed-images)
    /// for more about the semantics of this function.
    @inlinable
    public
    init<Color>(packing pixels:[Color],
        size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata = .init(),
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Color.Aggregate) -> Int)
        where Color:PNG.Color
    {
        precondition(size.x > 0 && size.y > 0,
            "image dimensions must be greater than zero")
        precondition(pixels.count == size.x * size.y,
            "pixel array `count` must be equal to `size.x * size.y`")
        self.init(size: size, layout: layout, metadata: metadata,
            storage: Color.pack(pixels, as: layout.format, indexer: indexer))
    }
    /// Creates an image from a scalar pixel array, using a custom indexing function.
    ///
    /// For an image with a grayscale-alpha color ``Layout/format``,
    /// this function assigns the gray channel to the given scalars, and
    /// sets the alpha channel to `T.max`.
    ///
    /// For an image with an RGB or BGR color ``Layout/format``,
    /// this function assigns all channels to the given scalars, replicating
    /// each scalar three times.
    ///
    /// For an image with an RGBA or BGRA color ``Layout/format``, this
    /// function assigns all opaque channels to the given scalars, replicating
    /// each scalar three times, and sets the alpha channel to `T.max`.
    ///
    /// The scalar values are assumed to fill the entire range of `T`.
    /// -   Parameter pixels:
    ///     A scalar pixel array. Its elements are arranged in row-major order. The
    ///     first pixel in this array corresponds to the top-left corner of
    ///     the image.
    ///
    ///     The length of this array must match `size.x * size.y`. Passing an
    ///     array of the wrong length will result in a precondition failure.
    /// -   Parameter size:
    ///     The size of the image. Both dimensions must be greater than zero.
    ///     Passing an invalid image size will result in a precondition failure.
    /// -   Parameter layout:
    ///     An image layout.
    /// -   Parameter metadata:
    ///     A metadata structure. The default value is an empty metadata structure.
    /// -   Parameter indexer:
    ///     A function which uses the palette entries in the color ``Layout/format`` to
    ///     generate a referencing function. This function will only
    ///     be invoked if the image color ``Layout/format`` is an indexed format.
    ///
    /// See the [indexed color tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#using-indexed-images)
    /// for more about the semantics of this function.
    @inlinable
    public
    init<T>(packing pixels:[T],
        size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata = .init(),
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (UInt8) -> Int)
        where T:FixedWidthInteger & UnsignedInteger
    {
        precondition(size.x > 0 && size.y > 0,
            "image dimensions must be greater than zero")
        precondition(pixels.count == size.x * size.y,
            "pixel array `count` must be equal to `size.x * size.y`")
        self.init(size: size, layout: layout, metadata: metadata,
            storage: Self.pack(pixels, as: layout.format, indexer: indexer))
    }
}
extension PNG.Image
{
    /// Unpacks this image to a pixel array.
    ///
    /// -   Parameter _:
    ///     A color target type. This type provides the ``_PNGColor/unpack(_:of:) [4GV17]``
    ///     implementation used to unpack the image data.
    /// -   Returns:
    ///     A pixel array. Its elements are arranged in row-major order. The
    ///     first pixel in this array corresponds to the top-left corner of
    ///     the image. Its length is equal to `size.x` multiplied by `size.y`.
    @inlinable
    public
    func unpack<Color>(as _:Color.Type) -> [Color] where Color:PNG.Color
    {
        Color.unpack(self.storage, of: self.layout.format)
    }
    /// Creates an image from a pixel array.
    ///
    /// -   Parameter pixels:
    ///     A pixel array. Its elements are arranged in row-major order. The
    ///     first pixel in this array corresponds to the top-left corner of
    ///     the image. The `Color` type provides the ``_PNGColor/pack(_:as:) [52RHU]``
    ///     implementation used to pack the image data.
    ///
    ///     The length of this array must match `size.x * size.y`. Passing an
    ///     array of the wrong length will result in a precondition failure.
    /// -   Parameter size:
    ///     The size of the image. Both dimensions must be greater than zero.
    ///     Passing an invalid image size will result in a precondition failure.
    /// -   Parameter layout:
    ///     An image layout.
    /// -   Parameter metadata:
    ///     A metadata structure. The default value is an empty metadata structure.
    @inlinable
    public
    init<Color>(packing pixels:[Color],
        size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata = .init())
        where Color:PNG.Color
    {
        precondition(size.x > 0 && size.y > 0,
            "image dimensions must be greater than zero")
        precondition(pixels.count == size.x * size.y,
            "pixel array `count` must be equal to `size.x * size.y`")
        self.init(size: size, layout: layout, metadata: metadata,
            storage: Color.pack(pixels, as: layout.format))
    }
    /// Unpacks this image to a scalar pixel array.
    ///
    /// For an image with a grayscale-alpha color ``Layout/format``,
    /// this function selects the *v* component from pixels of the form (*v*, *a*)
    ///
    /// For an image with an RGB color ``Layout/format``,
    /// this function selects the *r* component from pixels of the form (*r*, *g*, *b*).
    ///
    /// For an image with an indexed color ``Layout/format``,
    /// this function selects the *r* component from palette entries of the
    /// form (*r*, *g*, *b*, *a*). The palette entry is chosen by taking the
    /// i*th element in the palette, from pixels of the form (*i*).
    ///
    /// For an image with an RGBA color ``Layout/format``, this function
    /// selects the *r* component from pixels of the form (*r*, *g*, *b*, *a*).
    ///
    /// For an image with a BGR color ``Layout/format``,
    /// this function selects the *r* component from pixels of the form (*b*, *g*, *r*).
    ///
    /// For an image with a BGRA color ``Layout/format``,
    /// this function selects the *r* component from pixels of the form (*b*, *g*, *r*, *a*).
    ///
    /// This function ignores chroma keys, as its scalar color target is not
    /// capable of representing transparency. The unpacked components
    /// are scaled to fill the range of `T`, according to the color depth
    /// computed from the color ``Layout/format``.
    ///
    /// -   Parameter _:
    ///     A scalar color target type.
    /// -   Returns:
    ///     A scalar pixel array. Its elements are arranged in row-major order. The
    ///     first pixel in this array corresponds to the top-left corner of
    ///     the image. Its length is equal to `size.x` multiplied by `size.y`.
    @inlinable public
    func unpack<T>(as _:T.Type) -> [T] where T:FixedWidthInteger & UnsignedInteger
    {
        self.unpack(as: T.self)
        {
            (palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) in
            {
                (i:Int) in palette[i].r
            }
        }
    }
    /// Creates an image from a scalar pixel array.
    ///
    /// For an image with a grayscale-alpha color ``Layout/format``,
    /// this function assigns the gray channel to the given scalars, and
    /// sets the alpha channel to `T.max`.
    ///
    /// For an image with an indexed color ``Layout/format``,
    /// this function expands the given scalars, each of the form (*v*), to
    /// RGBA quadruplets (*v*, *v*, *v*, `T.max`), and assigns the index
    /// channel to the index of a matching palette entry. If more than one
    /// palette entry matches, the matching entry is chosen arbitrarily.
    /// If no palette entries match, the first palette entry is chosen.
    ///
    /// For an image with an RGB or BGR color ``Layout/format``,
    /// this function assigns all channels to the given scalars, replicating
    /// each scalar three times.
    ///
    /// For an image with an RGBA or BGRA color ``Layout/format``, this
    /// function assigns all opaque channels to the given scalars, replicating
    /// each scalar three times, and sets the alpha channel to `T.max`.
    ///
    /// The scalar values are assumed to fill the entire range of `T`.
    /// -   Parameter pixels:
    ///     A scalar pixel array. Its elements are arranged in row-major order. The
    ///     first pixel in this array corresponds to the top-left corner of
    ///     the image.
    ///
    ///     The length of this array must match `size.x * size.y`. Passing an
    ///     array of the wrong length will result in a precondition failure.
    /// -   Parameter size:
    ///     The size of the image. Both dimensions must be greater than zero.
    ///     Passing an invalid image size will result in a precondition failure.
    /// -   Parameter layout:
    ///     An image layout.
    /// -   Parameter metadata:
    ///     A metadata structure. The default value is an empty metadata structure.
    @inlinable public
    init<T>(packing pixels:[T],
        size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata = .init())
        where T:FixedWidthInteger & UnsignedInteger
    {
        self.init(packing: pixels, size: size, layout: layout, metadata: metadata)
        {
            (palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) in
            // currently blocked by the issue discussed at
            // https://github.com/apple/swift/pull/28833
            // as a workaround, we box the UInt8s into an RGBA<UInt8> struct
            let lookup:[PNG.RGBA<UInt8>: Int] = .init(uniqueKeysWithValues:
                zip(palette.map{ .init($0.r, $0.g, $0.b, $0.a) }, palette.indices))
            return
                {
                    (v:UInt8) in
                    lookup[.init(v, v, v, .max), default: 0]
                }
        }
    }
}
