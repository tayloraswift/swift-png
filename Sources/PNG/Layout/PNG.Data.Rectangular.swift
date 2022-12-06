extension PNG 
{
    /// enum PNG.Data 
    ///     A namespace containing the [`Data.Rectangular`] type.
    /// ## (0:images)
    public 
    enum Data 
    {
    }
    
    // Returns the value of the paeth filter function with the given parameters.
    static
    func paeth(_ a:UInt8, _ b:UInt8, _ c:UInt8) -> UInt8
    {
        // abs here is poorly-predicted so it benefits from this
        // branchless implementation
        func abs(_ x:Int16) -> Int16
        {
            let mask:Int16 = x >> 15
            return (x ^ mask) + (mask & 1)
        }
        
        let v:(Int16, Int16, Int16) = (.init(a), .init(b), .init(c))
        let d:(Int16, Int16)        = (v.1 - v.2, v.0 - v.2)
        let f:(Int16, Int16, Int16) = (abs(d.0), abs(d.1), abs(d.0 + d.1))
        
        let p:(UInt8, UInt8, UInt8) =
        (
            .init(truncatingIfNeeded: (f.1 - f.0) >> 15), // 0x00 if f.0 <= f.1 else 0xff
            .init(truncatingIfNeeded: (f.2 - f.0) >> 15),
            .init(truncatingIfNeeded: (f.2 - f.1) >> 15)
        )
        
        return ~(p.0 | p.1) &  a        |
                (p.0 | p.1) & (b & ~p.2 | c & p.2)
    }
}
extension PNG.Data 
{
    /// struct PNG.Data.Rectangular 
    ///     A rectangular image.
    /// # [Decoding an image](decoding)
    /// # [Encoding an image](encoding)
    /// # [Unpacking pixels](unpacking-pixels)
    /// # [Packing pixels](packing-pixels)
    /// ## (0:images)
    public 
    struct Rectangular 
    {
        /// let PNG.Data.Rectangular.size : (x:Swift.Int, y:Swift.Int)
        ///     The size of this image, measured in pixels.
        public 
        let size:(x:Int, y:Int)
        /// let PNG.Data.Rectangular.layout : Layout 
        ///     The layout of this image.
        public 
        let layout:PNG.Layout 
        /// var PNG.Data.Rectangular.metadata : Metadata 
        ///     The metadata in this image.
        public 
        var metadata:PNG.Metadata
        /// var PNG.Data.Rectangular.storage : [Swift.UInt8] { get }
        ///     The raw backing storage of the image content. 
        ///
        ///     Depending on the bit depth of the image, it either stores a matrix 
        ///     of [`Swift.UInt8`] samples, or a matrix of big-endian [`Swift.UInt16`]
        ///     samples. The pixels are arranged in row-major order, where the 
        ///     beginning of the storage array corresponds to the visual top-left 
        ///     corner of the image, regardless of whether the [`layout`] is 
        ///     [`(Layout).interlaced`] or not.
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
extension PNG.Data.Rectangular 
{
    internal 
    init?(standard:PNG.Standard, header:PNG.Header, 
        palette:PNG.Palette?, background:PNG.Background?, transparency:PNG.Transparency?, 
        metadata:PNG.Metadata, 
        uninitialized:Bool) 
    {
        guard let layout:PNG.Layout = PNG.Layout.init(standard: standard, 
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
    
    /// func PNG.Data.Rectangular.bindStorage(to:)
    ///     Rebinds this image to a compatible layout.
    /// 
    ///     This interface can be used to switch image layouts without unpacking 
    ///     to and repacking from a color target array. Rebinding to an 
    ///     incompatible layout will result in a precondition failure. 
    /// - layout : Layout 
    ///     The new image layout. 
    /// 
    ///     Both the original color [`(Layout).format`] and the new 
    ///     color [`(Layout).format`] must be of the same enumeration case, though the fields 
    ///     may differ. The exceptions are the indexed color formats, which require 
    ///     the lengths of their `palette` payloads to match exactly.  
    /// - -> : Self 
    ///     An image with the given layout. This image will share backing [`storage`] 
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
extension PNG.Data.Rectangular 
{
    /// static func PNG.Data.Rectangular.decompress<Source>(stream:)
    /// throws 
    /// where Source:Bytestream.Source 
    ///     Decompresses and decodes a PNG from the given bytestream. 
    /// 
    ///     On appropriate platforms, the [`decompress(path:)`] function provides 
    ///     a file system-aware interface to this function.
    /// - stream : inout Source 
    ///     A bytestream providing the contents of a PNG file.
    /// - -> : Self 
    ///     The decoded image.
    /// # [See also](encoding-and-decoding)
    /// ## (0:encoding-and-decoding)
    /// ## (0:decoding)
    public static 
    func decompress<Source>(stream:inout Source) throws -> Self 
        where Source:PNG.Bytestream.Source
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
extension PNG.Data.Rectangular 
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
extension PNG.Data.Rectangular 
{
    /// func PNG.Data.Rectangular.compress<Destination>(stream:level:hint:)
    /// throws 
    /// where Destination:Bytestream.Destination
    ///     Encodes and compresses a PNG to the given bytestream. 
    ///
    ///     Compression `level` `9` is roughly equivalent to *libpng*’s maximum 
    ///     compression setting in terms of compression ratio and encoding speed. 
    ///     The higher levels (`10` through `13`) are very computationally expensive, 
    ///     so they should only be used when optimizing for file size. 
    /// 
    ///     Experimental comparisons between *Swift PNG* and *libpng*’s 
    ///     compression settings can be found on 
    ///     [this page](https://github.com/kelvin13/swift-png/blob/master/benchmarks).
    /// 
    ///     On appropriate platforms, the [`compress(path:level:hint:)`] function 
    ///     provides a file system-aware interface to this function.
    /// - stream : inout Destination 
    ///     A bytestream receiving the contents of a PNG file.
    /// - level : Swift.Int 
    ///     The compression level to use. It should be in the range `0 ... 13`, 
    ///     where `13` is the most aggressive setting. The default value is `9`. 
    /// 
    ///     Setting this parameter to a value less than `0` is the same as 
    ///     setting it to `0`. Likewise, setting it to a value greater than `13` 
    ///     is the same as setting it to `13`.
    /// - hint : Swift.Int 
    ///     A size hint for the emitted [`(Chunk).IDAT`] chunks. It should be in 
    ///     the range `1 ... 2147483647`. Reasonable settings range from around 
    ///     1\ K to 64\ K. The default value is `32768` (2^15^). 
    /// 
    ///     Setting this parameter to a value less than `1` is the same as setting 
    ///     it to `1`. Likewise, setting it to a value greater than `2147483647` 
    ///     (2^31^\ –\ 1) is the same as setting it to `2147483647`.
    /// # [See also](encoding-and-decoding)
    /// ## (2:encoding-and-decoding)
    /// ## (0:encoding)
    public 
    func compress<Destination>(stream:inout Destination, level:Int = 9, hint:Int = 1 << 15) 
        throws
        where Destination:PNG.Bytestream.Destination
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
