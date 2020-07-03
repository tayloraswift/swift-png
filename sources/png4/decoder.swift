extension PNG 
{
    enum DecodingError:Swift.Error 
    {
        case missingImageHeader
        case missingPalette
        case missingImageData
        
        case extraneousCompressedImageData
        case extraneousUncompressedImageData
        
        case duplicateChunk(PNG.Chunk)
        case invalidChunkOrder(PNG.Chunk, after:PNG.Chunk)
    }
}
extension PNG 
{
    public 
    struct Metadata 
    {
        public 
        var chromaticity:PNG.Chromaticity?,
            gamma:PNG.Gamma?,
            colorRendering:PNG.ColorRendering?,
            colorProfile:PNG.ColorProfile?,
            significantBits:PNG.SignificantBits?
        public 
        var histogram:PNG.Histogram?,
            physicalDimensions:PNG.PhysicalDimensions?,
            time:PNG.TimeModified?
        
        public 
        var suggestedPalettes:[PNG.SuggestedPalette]    = []
        public 
        var text:[PNG.Text]                             = []
        public 
        var application:[(PNG.Chunk, data:[UInt8])]     = []
        
        public 
        init(chromaticity:PNG.Chromaticity?             = nil,
            gamma:PNG.Gamma?                            = nil,
            colorRendering:PNG.ColorRendering?          = nil,
            colorProfile:PNG.ColorProfile?              = nil,
            significantBits:PNG.SignificantBits?        = nil, 
            
            histogram:PNG.Histogram?                    = nil,
            physicalDimensions:PNG.PhysicalDimensions?  = nil,
            time:PNG.TimeModified?                      = nil, 
            
            suggestedPalettes:[PNG.SuggestedPalette]    = [], 
            text:[PNG.Text]                             = [], 
            application:[(PNG.Chunk, data:[UInt8])]     = [])
        {
            self.chromaticity       = chromaticity
            self.gamma              = gamma
            self.colorRendering     = colorRendering
            self.colorProfile       = colorProfile
            self.significantBits    = significantBits
            self.histogram          = histogram
            self.physicalDimensions = physicalDimensions
            self.time               = time
            self.suggestedPalettes  = suggestedPalettes
            self.text               = text
            self.application        = application
        }
    }
    
    public 
    enum Standard 
    {
        case common
        case ios
    }
    
    public 
    struct Layout 
    {
        public 
        let format:PNG.Format 
        public 
        let standard:PNG.Standard, 
            interlaced:Bool
    }
}
extension PNG.Layout 
{
    public 
    init(standard:PNG.Standard, interlaced:Bool, pixel:PNG.Format.Pixel, 
        palette:PNG.Palette?, background:PNG.Background?, transparency:PNG.Transparency?) 
        throws 
    {
        guard let format:PNG.Format = .recognize(pixel: pixel, palette: palette, 
            background: background, transparency: transparency) 
        else 
        {
            // this is the only error condition that hasn’t already been checked 
            // against by the parsing APIs 
            throw PNG.DecodingError.missingPalette
        }
        
        self.init(format: format, standard: standard, interlaced: interlaced)
    }
}

extension PNG 
{
    public 
    enum Data 
    {
    }
    
    /// Returns the value of the paeth filter function with the given parameters.
    static
    func paeth(_ a:UInt8, _ b:UInt8, _ c:UInt8) -> UInt8
    {
        let v:SIMD3<Int16> = .init(truncatingIfNeeded: .init(a, b, c)),
            d:SIMD3<Int16> = v.x + v.y - v.z &- v
        let f:(x:Int16, y:Int16, z:Int16) = (abs(d.x), abs(d.y), abs(d.z))

        if f.x <= f.y && f.x <= f.z
        {
            return a
        }
        else if f.y <= f.z
        {
            return b
        }
        else
        {
            return c
        }
    }
}
extension PNG.Data 
{
    public 
    struct Rectangular 
    {
        public 
        let layout:PNG.Layout 
        public 
        let size:(x:Int, y:Int)
        public 
        var metadata:PNG.Metadata
        
        private(set)
        var storage:[UInt8]
    }
}
extension PNG.Data.Rectangular 
{
    internal // uninitialized buffer 
    init(size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata)  
    {
        precondition(size.x > 0 && size.y > 0, "image dimensions must be positive")
        self.layout     = layout
        self.size       = size
        self.metadata   = metadata
        
        let bytes:Int   = size.x * size.y * (layout.format.pixel.volume + 7) >> 3
        self.storage    = .init(unsafeUninitializedCapacity: bytes)
        {
            $1 = bytes
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
        case .rgb8:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 3 &* i &+ scanline.startIndex, 
                    d:Int = 3 &* (base.y &* self.size.x &+ x)
                self.storage[d     ] = scanline[a     ]
                self.storage[d &+ 1] = scanline[a &+ 1]
                self.storage[d &+ 2] = scanline[a &+ 2]
            }
        // 1 x 4, 2 x 2
        case .rgba8, .va16:
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
            throw PNG.DecodingError.duplicateChunk(type)
        }
        destination = try parser()
    }
    
    mutating 
    func push(ancillary chunk:(type:PNG.Chunk, data:[UInt8]), 
        pixel:PNG.Format.Pixel, palette:PNG.Palette?, 
        background:inout PNG.Background?, 
        transparency:inout PNG.Transparency?) throws 
    {
        // check before-palette chunk ordering 
        switch chunk.type 
        {
        case .cHRM, .gAMA, .sRGB, .iCCP, .sBIT:
            guard palette == nil 
            else 
            {
                throw PNG.DecodingError.invalidChunkOrder(chunk.type, after: .PLTE)
            }
        default:
            break 
        }
        
        switch chunk.type 
        {
        case .bKGD:
            try Self.unique(assign: chunk.type, to: &background) 
            {
                try .parse(chunk.data, pixel: pixel, palette: palette)
            }
        case .tRNS:
            try Self.unique(assign: chunk.type, to: &transparency) 
            {
                try .parse(chunk.data, pixel: pixel, palette: palette)
            }
            
        case .hIST:
            guard let palette:PNG.Palette = palette 
            else 
            {
                throw PNG.DecodingError.missingPalette
            }
            try Self.unique(assign: chunk.type, to: &self.histogram) 
            {
                try .parse(chunk.data, pixel: pixel, palette: palette)
            }
        
        case .cHRM:
            try Self.unique(assign: chunk.type, to: &self.chromaticity) 
            {
                try .parse(chunk.data)
            }
        case .gAMA:
            try Self.unique(assign: chunk.type, to: &self.gamma) 
            {
                try .parse(chunk.data)
            }
        case .sRGB:
            try Self.unique(assign: chunk.type, to: &self.colorRendering) 
            {
                try .parse(chunk.data)
            }
        case .iCCP:
            try Self.unique(assign: chunk.type, to: &self.colorProfile) 
            {
                try .parse(chunk.data)
            }
        case .sBIT:
            try Self.unique(assign: chunk.type, to: &self.significantBits) 
            {
                try .parse(chunk.data, pixel: pixel)
            }
        
        case .pHYs:
            try Self.unique(assign: chunk.type, to: &self.physicalDimensions) 
            {
                try .parse(chunk.data)
            }
        case .tIME:
            try Self.unique(assign: chunk.type, to: &self.time) 
            {
                try .parse(chunk.data)
            }
        
        case .sPLT:
            self.suggestedPalettes.append(try .parse(chunk.data))
        case .iTXt:
            self.text.append(try .parse(        chunk.data))
        case .tEXt, .zTXt:
            self.text.append(try .parse(latin1: chunk.data))
        
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
            pass:Int?,
            `continue`:Void? 
        private 
        var inflator:LZ77.Inflator 
    }
}
extension PNG.Decoder 
{
    init(interlaced:Bool)
    {
        self.row        = nil
        self.pass       = interlaced ? 0 : nil
        self.continue   = ()
        self.inflator   = .init()
    }
    
    mutating 
    func push(_ data:[UInt8], size:(x:Int, y:Int), pixel:PNG.Format.Pixel, 
        delegate:(UnsafeBufferPointer<UInt8>, (x:Int, y:Int), Int) throws -> ()) 
        throws -> Void?
    {
        guard let _:Void = self.continue 
        else 
        {
            throw PNG.DecodingError.extraneousCompressedImageData
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
                    
                    self.defilter(&scanline, last: last, delay: delay)
                    try scanline.dropFirst().withUnsafeBufferPointer 
                    {
                        try delegate($0, (base.x, base.y + y * stride.y), stride.x)
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
                
                self.defilter(&scanline, last: last, delay: delay)
                try scanline.dropFirst().withUnsafeBufferPointer 
                {
                    try delegate($0, (0, y), 1)
                }
                
                last = scanline 
            }
        }
        
        self.pass = 7
        guard self.inflator.pull().isEmpty 
        else 
        {
            throw PNG.DecodingError.extraneousUncompressedImageData
        }
        return self.continue
    }
    
    private
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
    public 
    struct Context 
    {
        public private(set)
        var image:PNG.Data.Rectangular 
        
        private 
        var decoder:PNG.Decoder 
    }
}
extension PNG.Context 
{
    public 
    init(standard:PNG.Standard, header:PNG.Header, 
        palette:PNG.Palette?, background:PNG.Background?, transparency:PNG.Transparency?, 
        metadata:PNG.Metadata) throws 
    {
        let layout:PNG.Layout = try .init(standard: standard, 
            interlaced:     header.interlaced, 
            pixel:          header.pixel, 
            palette:        palette, 
            background:     background, 
            transparency:   transparency)
        self.image      = .init(size: header.size, layout: layout, metadata: metadata)
        self.decoder    = .init(interlaced: header.interlaced)
    }
    
    mutating 
    func push(data:[UInt8]) throws 
    {
        try self.decoder.push(data, size: self.image.size, pixel: self.image.layout.format.pixel) 
        {
            self.image.assign(scanline: $0, at: $1, stride: $2)
        }
    }
    
    mutating 
    func push(ancillary chunk:(type:PNG.Chunk, data:[UInt8])) throws 
    {
        switch chunk.type 
        {
        case .tIME:
            try PNG.Metadata.unique(assign: chunk.type, to: &self.image.metadata.time) 
            {
                try .parse(chunk.data)
            }
        case .iTXt:
            self.image.metadata.text.append(try .parse(        chunk.data))
        case .tEXt, .zTXt:
            self.image.metadata.text.append(try .parse(latin1: chunk.data))
        case .IHDR, .PLTE, .bKGD, .tRNS, .hIST, 
            .cHRM, .gAMA, .sRGB, .iCCP, .sBIT, .pHYs, .sPLT:
            throw PNG.DecodingError.invalidChunkOrder(chunk.type, after: .IDAT)
        case .IEND: 
            break 
        default:
            self.image.metadata.application.append(chunk)
        }
    }
}


extension PNG.Data.Rectangular 
{    
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
            switch chunk 
            {
            case (.IHDR, let data):
                return (standard, try .parse(data))
            default:
                throw PNG.DecodingError.missingImageHeader
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
                    throw PNG.DecodingError.duplicateChunk(.IHDR)
                
                case .PLTE:
                    guard palette == nil 
                    else 
                    {
                        throw PNG.DecodingError.duplicateChunk(.PLTE)
                    }
                    guard background == nil
                    else 
                    {
                        throw PNG.DecodingError.invalidChunkOrder(.PLTE, after: .bKGD)
                    }
                    guard transparency == nil
                    else 
                    {
                        throw PNG.DecodingError.invalidChunkOrder(.PLTE, after: .tRNS)
                    }
                    guard metadata.histogram == nil 
                    else 
                    {
                        throw PNG.DecodingError.invalidChunkOrder(.PLTE, after: .hIST)
                    }
                    palette = try .parse(chunk.data, pixel: header.pixel)
                
                case .IDAT:
                    return try .init(standard: standard, header: header, 
                        palette:        palette, 
                        background:     background, 
                        transparency:   transparency, 
                        metadata:       metadata)
                    
                case .IEND:
                    throw PNG.DecodingError.missingImageData
                
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
        
        while chunk.type != .IEND 
        {
            try context.push(ancillary: chunk)
            chunk = try stream.chunk()
        }
        
        return context.image
    }
}
