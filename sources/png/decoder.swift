extension PNG 
{
    /// struct PNG.Metadata 
    ///     The metadata in an image.
    /// ## (2:images)
    public 
    struct Metadata 
    {
        /// var PNG.Metadata.time : TimeModified?
        ///     The image modification time. 
        public 
        var time:PNG.TimeModified?, 
        /// var PNG.Metadata.chromaticity : Chromaticity? 
        ///     The image chromaticity.
            chromaticity:PNG.Chromaticity?,
        /// var PNG.Metadata.colorProfile : ColorProfile? 
        ///     The image color profile.
            colorProfile:PNG.ColorProfile?,
        /// var PNG.Metadata.colorRendering : ColorRendering? 
        ///     The image color rendering mode. 
            colorRendering:PNG.ColorRendering?,
        /// var PNG.Metadata.gamma : Gamma? 
        ///     The image gamma. 
            gamma:PNG.Gamma?,
        /// var PNG.Metadata.histogram : Histogram? 
        ///     The frequency histogram of the image palette.
            histogram:PNG.Histogram?,
        /// var PNG.Metadata.physicalDimensions : PhysicalDimensions? 
        ///     The physical dimensions of the image.
            physicalDimensions:PNG.PhysicalDimensions?,
        /// var PNG.Metadata.significantBits : SignificantBits? 
        ///     The image color precision.
            significantBits:PNG.SignificantBits?
        /// var PNG.Metadata.suggestedPalettes : [SuggestedPalette]
        ///     The suggested palettes of the image.
        public 
        var suggestedPalettes:[PNG.SuggestedPalette]        = [],
        /// var PNG.Metadata.text : [Text]
        ///     The text comments in the image.
            text:[PNG.Text]                                 = [],
        /// var PNG.Metadata.application : [(type:Chunk, data:[Swift.UInt8])] 
        ///     An array containing any unparsed application-specific chunks 
        ///     in the image.
            application:[(type:PNG.Chunk, data:[UInt8])]    = []
        
        /// init PNG.Metadata.init(time:chromaticity:colorProfile:colorRendering:gamma:histogram:physicalDimensions:significantBits:suggestedPalettes:text:application:)
        ///     Creates a metadata structure. 
        /// - time : TimeModified?
        ///     An optional modification time. 
        /// - chromaticity : Chromaticity? 
        ///     An optional chromaticity descriptor.
        /// - colorProfile : ColorProfile? 
        ///     An optional color profile.
        /// - colorRendering : ColorRendering? 
        ///     An optional color rendering mode. 
        /// - gamma : Gamma? 
        ///     An optional gamma descriptor. 
        /// - histogram : Histogram? 
        ///     An optional palette frequency histogram.
        /// - physicalDimensions : PhysicalDimensions? 
        ///     An optional physical dimensions descriptor.
        /// - significantBits : SignificantBits? 
        ///     An optional color precision descriptor.
        /// - suggestedPalettes : [SuggestedPalette]
        ///     An array of suggested palettes.
        /// - text : [Text]
        ///     An array of text comments.
        /// - application : [(type:Chunk, data:[Swift.UInt8])] 
        ///     An array of unparsed application-specific chunks.
        /// 
        ///     This array is allowed to contain public PNG chunks, though it 
        ///     is recommended to use the library’s strongly-typed interfaces 
        ///     instead for such chunks.
        public 
        init(time:PNG.TimeModified?                     = nil,
            chromaticity:PNG.Chromaticity?              = nil,
            colorProfile:PNG.ColorProfile?              = nil,
            colorRendering:PNG.ColorRendering?          = nil,
            gamma:PNG.Gamma?                            = nil,
            histogram:PNG.Histogram?                    = nil,
            physicalDimensions:PNG.PhysicalDimensions?  = nil,
            significantBits:PNG.SignificantBits?        = nil, 
            
            
            suggestedPalettes:[PNG.SuggestedPalette]        = [], 
            text:[PNG.Text]                                 = [], 
            application:[(type:PNG.Chunk, data:[UInt8])]    = [])
        {
            self.time               = time
            self.chromaticity       = chromaticity
            self.colorProfile       = colorProfile
            self.colorRendering     = colorRendering
            self.gamma              = gamma
            self.histogram          = histogram
            self.physicalDimensions = physicalDimensions
            self.significantBits    = significantBits
            self.suggestedPalettes  = suggestedPalettes
            self.text               = text
            self.application        = application
        }
    }
    
    /// enum PNG.Standard 
    ///     A PNG standard.
    /// ## (contextual-decoding)
    public 
    enum Standard 
    {
        /// case PNG.Standard.common 
        ///     The core PNG color formats.
        case common
        /// case PNG.Standard.ios 
        ///     The iphone-optimized PNG color formats.
        case ios
    }
    
    /// struct PNG.Layout 
    ///     An image layout. 
    /// 
    ///     This type stores all the information in an image that is not strictly 
    ///     metadata, or image content.
    /// ## (1:images)
    public 
    struct Layout 
    {
        /// let PNG.Layout.format : Format 
        ///     The image color format.
        public 
        let format:PNG.Format 
        /// let PNG.Layout.interlaced : Swift.Bool 
        ///     Indicates if the image uses interlacing or not.
        public 
        let interlaced:Bool
        
        /// init PNG.Layout.init(format:interlaced:)
        ///     Creates an image layout. 
        /// 
        ///     This initializer will validate the fields of the given color 
        ///     `format`. Passing an invalid `format` will result in a 
        ///     precondition failure.
        /// - format : Format 
        ///     A color format. 
        /// - interlaced : Swift.Bool 
        ///     Specifies if the image uses interlacing. The default value is 
        ///     `false`.
        public 
        init(format:PNG.Format, interlaced:Bool = false) 
        {
            self.format     = format.validate()
            self.interlaced = interlaced
        }
    }
}
extension PNG.Layout 
{
    init?(standard:PNG.Standard, pixel:PNG.Format.Pixel, 
        palette:PNG.Palette?, 
        background:PNG.Background?, 
        transparency:PNG.Transparency?, 
        interlaced:Bool) 
    {
        guard let format:PNG.Format = .recognize(standard: standard, pixel: pixel, 
            palette: palette, background: background, transparency: transparency) 
        else 
        {
            // if all the inputs have been consistently validated by the parsing 
            // APIs, the only error condition is a missing palette for an indexed 
            // image. otherwise, it returns `nil` on any input chunk inconsistency
            return nil 
        }
        
        self.init(format: format, interlaced: interlaced)
    }
}

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

extension PNG.Metadata 
{
    static 
    func unique<T>(assign type:PNG.Chunk, to destination:inout T?, 
        parser:() throws -> T) throws 
    {
        guard destination == nil 
        else 
        {
            throw PNG.DecodingError.duplicate(chunk: type)
        }
        destination = try parser()
    }
    /// mutating func PNG.Metadata.push(ancillary:pixel:palette:background:transparency:)
    /// throws 
    ///     Parses an ancillary chunk, and either adds it to this metadata instance, 
    ///     or stores it in one of the two `inout` parameters. 
    /// 
    ///     If the given `chunk` is a [`(Chunk).bKGD`] or [`(Chunk).tRNS`] chunk, 
    ///     it will be stored in its respective `inout` variable. Otherwise it 
    ///     will be stored within this metadata instance.
    /// 
    ///     This function parses and validates the given `chunk` according to the 
    ///     image `pixel` format and `palette`. It also validates its multiplicity, and 
    ///     its chunk ordering with respect to the [`(Chunk).PLTE`] chunk. 
    /// - chunk : (type:Chunk, data:[Swift.UInt8])
    ///     The chunk to process. 
    /// 
    ///     The `type` identifier of this chunk must not be a critical chunk type. 
    ///     (Critical chunk types are [`(Chunk).CgBI`], [`(Chunk).IHDR`], 
    ///     [`(Chunk).PLTE`], [`(Chunk).IDAT`], and [`(Chunk).IEND`].) Passing 
    ///     a critical chunk to this function will result in a precondition 
    ///     failure. 
    /// - pixel : Format.Pixel 
    ///     The image pixel format.
    /// - palette : Palette? 
    ///     The image palette, if available. Client applications are expected to 
    ///     set this parameter to `nil` if the [`(Chunk).PLTE`] chunk has not 
    ///     yet been encountered.
    /// - background : inout Background? 
    ///     The background descriptor, if available. If this function receives 
    ///     a [`(Chunk).bKGD`] chunk, it will be parsed and stored in this 
    ///     variable. Client applications are expected to initialize it to `nil`, 
    ///     and should not overwrite it between subsequent calls while processing 
    ///     the same image.
    /// - transparency : inout Transparency? 
    ///     The transparency descriptor, if available. If this function receives 
    ///     a [`(Chunk).tRNS`] chunk, it will be parsed and stored in this 
    ///     variable. Client applications are expected to initialize it to `nil`, 
    ///     and should not overwrite it between subsequent calls while processing 
    ///     the same image.
    public mutating 
    func push(ancillary chunk:(type:PNG.Chunk, data:[UInt8]), 
        pixel:PNG.Format.Pixel, palette:PNG.Palette?, 
        background:inout PNG.Background?, 
        transparency:inout PNG.Transparency?) throws 
    {
        switch chunk.type 
        {
        // check before-palette chunk ordering 
        case .cHRM, .gAMA, .sRGB, .iCCP, .sBIT:
            guard palette == nil 
            else 
            {
                throw PNG.DecodingError.unexpected(chunk: chunk.type, after: .PLTE)
            } 
        // check that chunk is not a critical chunk 
        case .CgBI, .IHDR, .PLTE, .IDAT, .IEND: 
            fatalError("Metadata.push(ancillary:pixel:palette:background:transparency:) cannot be used with critical chunk type '\(chunk.type)'")
        default:
            break 
        }
        
        switch chunk.type 
        {
        case .bKGD:
            try Self.unique(assign: chunk.type, to: &background) 
            {
                try .init(parsing: chunk.data, pixel: pixel, palette: palette)
            }
        case .tRNS:
            try Self.unique(assign: chunk.type, to: &transparency) 
            {
                try .init(parsing: chunk.data, pixel: pixel, palette: palette)
            }
            
        case .hIST:
            guard let palette:PNG.Palette = palette 
            else 
            {
                throw PNG.DecodingError.required(chunk: .PLTE, before: .hIST)
            }
            try Self.unique(assign: chunk.type, to: &self.histogram) 
            {
                try .init(parsing: chunk.data, palette: palette)
            }
        
        case .cHRM:
            try Self.unique(assign: chunk.type, to: &self.chromaticity) 
            {
                try .init(parsing: chunk.data)
            }
        case .gAMA:
            try Self.unique(assign: chunk.type, to: &self.gamma) 
            {
                try .init(parsing: chunk.data)
            }
        case .sRGB:
            try Self.unique(assign: chunk.type, to: &self.colorRendering) 
            {
                try .init(parsing: chunk.data)
            }
        case .iCCP:
            try Self.unique(assign: chunk.type, to: &self.colorProfile) 
            {
                try .init(parsing: chunk.data)
            }
        case .sBIT:
            try Self.unique(assign: chunk.type, to: &self.significantBits) 
            {
                try .init(parsing: chunk.data, pixel: pixel)
            }
        
        case .pHYs:
            try Self.unique(assign: chunk.type, to: &self.physicalDimensions) 
            {
                try .init(parsing: chunk.data)
            }
        case .tIME:
            try Self.unique(assign: chunk.type, to: &self.time) 
            {
                try .init(parsing: chunk.data)
            }
        
        case .sPLT:
            self.suggestedPalettes.append(try .init(parsing: chunk.data))
        case .iTXt:
            self.text.append(try .init(parsing: chunk.data))
        case .tEXt, .zTXt:
            self.text.append(try .init(parsing: chunk.data, unicode: false))
        
        default:
            self.application.append(chunk)
        }
    }
}

extension PNG 
{
    static 
    let adam7:[(base:(x:Int, y:Int), exponent:(x:Int, y:Int))] = 
    [
        (base: (0, 0), exponent: (3, 3)),
        (base: (4, 0), exponent: (3, 3)),
        (base: (0, 4), exponent: (2, 3)),
        (base: (2, 0), exponent: (2, 2)),
        (base: (0, 2), exponent: (1, 2)),
        (base: (1, 0), exponent: (1, 1)),
        (base: (0, 1), exponent: (0, 1)),
    ]
    
    struct Decoder 
    {
        private 
        var row:(index:Int, reference:[UInt8])?, 
            pass:Int?
        private(set)
        var `continue`:Void? 
        private 
        var inflator:LZ77.Inflator 
    }
}
extension PNG.Decoder 
{
    init(standard:PNG.Standard, interlaced:Bool)
    {
        self.row        = nil
        self.pass       = interlaced ? 0 : nil
        self.continue   = ()
        
        let format:LZ77.Format 
        switch standard 
        {
        case .common:   format = .zlib 
        case .ios:      format = .ios
        }
        
        self.inflator   = .init(format: format)
    }
    
    mutating 
    func push(_ data:[UInt8], size:(x:Int, y:Int), pixel:PNG.Format.Pixel, 
        delegate:(UnsafeBufferPointer<UInt8>, (x:Int, y:Int), (x:Int, y:Int)) throws -> ())
        throws -> Void?
    {
        guard let _:Void = self.continue 
        else 
        {
            throw PNG.DecodingError.extraneousImageDataCompressedData
        }
        
        self.continue = try self.inflator.push(data)
        
        let delay:Int   = (pixel.volume + 7) >> 3
        if let pass:Int = self.pass 
        {
            for z:Int in pass ..< 7
            {
                let (base, exponent):((x:Int, y:Int), (x:Int, y:Int)) = PNG.adam7[z]
                let stride:(x:Int, y:Int)   = 
                (
                    x: 1                                 << exponent.x, 
                    y: 1                                 << exponent.y
                )
                let subimage:(x:Int, y:Int) = 
                (
                    x: (size.x + stride.x - base.x - 1 ) >> exponent.x, 
                    y: (size.y + stride.y - base.y - 1 ) >> exponent.y
                )
                
                guard subimage.x > 0, subimage.y > 0 
                else 
                {
                    continue 
                }
                
                let pitch:Int = (subimage.x * pixel.volume + 7) >> 3
                var (start, last):(Int, [UInt8]) = self.row ?? 
                    (0, .init(repeating: 0, count: pitch + 1))
                self.row = nil 
                for y:Int in start ..< subimage.y 
                {
                    guard var scanline:[UInt8] = self.inflator.pull(last.count)
                    else 
                    {
                        self.row  = (y, last) 
                        self.pass = z
                        return self.continue
                    }
                    
                    #if DUMP_FILTERED_SCANLINES
                    print("< scanline(\(scanline[0]))[\(scanline.dropFirst().prefix(8).map(String.init(_:)).joined(separator: ", ")) ... ]")
                    #endif 
                    
                    Self.defilter(&scanline, last: last, delay: delay)
                    
                    let base:(x:Int, y:Int) = (base.x, base.y + y * stride.y)
                    try scanline.dropFirst().withUnsafeBufferPointer 
                    {
                        try delegate($0, base, stride)
                    }
                    
                    last = scanline 
                }
            }
        }
        else 
        {
            let pitch:Int = (size.x * pixel.volume + 7) >> 3
            
            var (start, last):(Int, [UInt8]) = self.row ?? 
                (0, .init(repeating: 0, count: pitch + 1))
            self.row = nil 
            for y:Int in start ..< size.y 
            {
                guard var scanline:[UInt8] = self.inflator.pull(last.count)
                else 
                {
                    self.row  = (y, last) 
                    return self.continue
                }
                
                #if DUMP_FILTERED_SCANLINES
                print("< scanline(\(scanline[0]))[\(scanline.dropFirst().prefix(8).map(String.init(_:)).joined(separator: ", ")) ... ]")
                #endif 
                
                Self.defilter(&scanline, last: last, delay: delay)
                try scanline.dropFirst().withUnsafeBufferPointer 
                {
                    try delegate($0, (0, y), (1, 1))
                }
                
                last = scanline 
            }
        }
        
        self.pass = 7
        guard self.inflator.pull().isEmpty 
        else 
        {
            throw PNG.DecodingError.extraneousImageData
        }
        return self.continue
    }
    
    static 
    func defilter(_ line:inout [UInt8], last:[UInt8], delay:Int)
    {
        let indices:Range<Int> = line.indices.dropFirst()
        switch line[line.startIndex]
        {
        case 0:
            break

        case 1: // sub
            for i:Int in indices.dropFirst(delay)
            {
                line[i] &+= line[i &- delay]
            }

        case 2: // up
            for i:Int in indices
            {
                line[i] &+= last[i]
            }

        case 3: // average
            for i:Int in indices.prefix(delay)
            {
                line[i] &+= last[i] >> 1
            }
            for i:Int in indices.dropFirst(delay)
            {
                let total:UInt16 = .init(line[i &- delay]) &+ .init(last[i])
                line[i] &+= .init(total >> 1)
            }

        case 4: // paeth
            for i:Int in indices.prefix(delay)
            {
                line[i] &+= PNG.paeth(0,                last[i], 0)
            }
            for i:Int in indices.dropFirst(delay)
            {
                line[i] &+= PNG.paeth(line[i &- delay], last[i], last[i &- delay])
            }

        default:
            break // invalid
        }
    }
}

extension PNG 
{
    /// struct PNG.Context 
    ///     A decoding context. 
    /// 
    ///     This type provides support for custom decoding schemes. You can 
    ///     work through an example of its usage in the 
    ///     [online decoding tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#online-decoding).
    /// ## (contextual-decoding)
    public 
    struct Context 
    {
        /// var PNG.Context.image : Data.Rectangular { get } 
        ///     The current image state.
        public private(set)
        var image:PNG.Data.Rectangular 
        
        private 
        var decoder:PNG.Decoder 
    }
}
extension PNG.Context 
{
    /// init PNG.Context.init?(standard:header:palette:background:transparency:metadata:uninitialized:)
    ///     Creates a fresh decoding context. 
    /// 
    ///     It is expected that client applications will initialize a decoding 
    ///     context upon encountering the first [`(Chunk).IDAT`] chunk in the image.
    /// - standard : Standard 
    ///     The PNG standard of the image being decoded. This should be [`(Standard).ios`]
    ///     if the image began with a [`(Chunk).CgBI`] chunk, and [`(Standard).common`]
    ///     otherwise.
    /// - header : Header 
    ///     The header of the image being decoded. This is expected to have been 
    ///     parsed from a previously-encountered [`(Chunk).IHDR`] chunk.
    /// - palette : Palette? 
    ///     The palette of the image being decoded, if present. If not `nil`, 
    ///     this is expected to have been parsed from a previously-encountered 
    ///     [`(Chunk).PLTE`] chunk.
    /// - background : Background? 
    ///     The background descriptor of the image being decoded, if present. 
    ///     If not `nil`, this is expected to have been parsed from a 
    ///     previously-encountered [`(Chunk).bKGD`] chunk.
    /// - transparency : Transparency? 
    ///     The transparency descriptor of the image being decoded, if present. 
    ///     If not `nil`, this is expected to have been parsed from a 
    ///     previously-encountered [`(Chunk).tRNS`] chunk.
    /// - metadata : Metadata 
    ///     A metadata instance. It is expected to contain metadata from all 
    ///     previously-encountered ancillary chunks, with the exception of 
    ///     [`(Chunk).bKGD`] and [`(Chunk).tRNS`].
    /// - uninitialized : Swift.Bool 
    ///     Specifies if the [`image`] [`(Data.Rectangular).storage`] should 
    ///     be initialized. If `false`, the storage buffer will be initialized 
    ///     to all zeros. This can be safely set to `true` if there is no need 
    ///     to access the image while it is in a partially-decoded state.
    /// 
    ///     The default value is `true`.
    public 
    init?(standard:PNG.Standard, header:PNG.Header, 
        palette:PNG.Palette?, background:PNG.Background?, transparency:PNG.Transparency?, 
        metadata:PNG.Metadata, 
        uninitialized:Bool = true) 
    {
        guard let image:PNG.Data.Rectangular = PNG.Data.Rectangular.init(
            standard:       standard, 
            header:         header, 
            palette:        palette, 
            background:     background, 
            transparency:   transparency, 
            metadata:       metadata, 
            uninitialized:  uninitialized)
        else 
        {
            return nil 
        }
        
        self.image      = image 
        self.decoder    = .init(standard: standard, interlaced: image.layout.interlaced)
    }
    /// mutating func PNG.Context.push(data:overdraw:)
    /// throws 
    ///     Decompresses the contents of an [`(Chunk).IDAT`] chunk, and updates 
    ///     the image state with the newly-decompressed image data. 
    /// - data : [Swift.UInt8]
    ///     The contents of the [`(Chunk).IDAT`] chunk to process.
    /// - overdraw : Swift.Bool 
    ///     If `true`, pixels that are not yet available will be filled-in 
    ///     with values from nearby available pixels. This option only has an 
    ///     effect for [`(Layout).interlaced`] images. 
    /// 
    ///     The default value is `false`.
    /// ## ()
    public mutating 
    func push(data:[UInt8], overdraw:Bool = false) throws 
    {
        try self.decoder.push(data, size: self.image.size, 
            pixel: self.image.layout.format.pixel, 
            delegate: overdraw ? 
        {
            let s:(x:Int, y:Int) = ($1.x == 0 ? 0 : 1, $1.y & 0b111 == 0 ? 0 : 1)
            self.image.assign(scanline: $0, at: $1, stride: $2.x)
            self.image.overdraw(            at: $1, brush: ($2.x >> s.x, $2.y >> s.y))
        } 
        : 
        {
            self.image.assign(scanline: $0, at: $1, stride: $2.x)
        }) 
    }
    /// mutating func PNG.Context.push(ancillary:)
    /// throws 
    ///     Parses an ancillary chunk appearing after the last [`(Chunk).IDAT`] 
    ///     chunk, and adds it to the [`image`] [`(Data.Rectangular).metadata`]. 
    /// 
    ///     This function validates the multiplicity of the given `chunk`, and 
    ///     its chunk ordering with respect to the [`(Chunk).IDAT`] chunks. The 
    ///     caller is expected to have consumed all preceeding [`(Chunk).IDAT`] 
    ///     chunks in the image being decoded.
    /// 
    ///     Despite its name, this function can also accept an [`(Chunk).IEND`] 
    ///     critical chunk, in which case this function will verify that the 
    ///     compressed image data stream has been properly-terminated.
    /// - chunk : (type:Chunk, data:[Swift.UInt8])
    ///     The chunk to process. Its `type` must be one of [`(Chunk).tIME`], 
    ///     [`(Chunk).iTXt`], [`(Chunk).tEXt`], [`(Chunk).zTXt`], or [`(Chunk).IEND`], 
    ///     or a private application data chunk type. 
    /// 
    ///     All other chunk types will `throw` appropriate errors.
    /// ## ()
    public mutating 
    func push(ancillary chunk:(type:PNG.Chunk, data:[UInt8])) throws 
    {
        switch chunk.type 
        {
        case .tIME:
            try PNG.Metadata.unique(assign: chunk.type, to: &self.image.metadata.time) 
            {
                try .init(parsing: chunk.data)
            }
        case .iTXt:
            self.image.metadata.text.append(try .init(parsing: chunk.data))
        case .tEXt, .zTXt:
            self.image.metadata.text.append(try .init(parsing: chunk.data, unicode: false))
        case .CgBI, .IHDR, .PLTE, .bKGD, .tRNS, .hIST, 
            .cHRM, .gAMA, .sRGB, .iCCP, .sBIT, .pHYs, .sPLT, .IDAT:
            throw PNG.DecodingError.unexpected(chunk: chunk.type, after: .IDAT) 
        case .IEND: 
            guard self.decoder.continue == nil 
            else 
            {
                throw PNG.DecodingError.incompleteImageDataCompressedDatastream
            } 
        default:
            self.image.metadata.application.append(chunk)
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
