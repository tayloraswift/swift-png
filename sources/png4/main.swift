extension PNG 
{
    enum DecodingError:Swift.Error 
    {
        case missingImageHeader
        case missingPalette
        case missingImageData
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
    struct Layout 
    {
        @usableFromInline
        enum Scheme 
        {
            @usableFromInline
            typealias RGB<T>  = (r:T, g:T, b:T)
            @usableFromInline
            typealias RGBA<T> = (r:T, g:T, b:T, a:T)
            
            case v1      (                       background:    UInt8?  , key:    UInt8?  )
            case v2      (                       background:    UInt8?  , key:    UInt8?  )
            case v4      (                       background:    UInt8?  , key:    UInt8?  )
            case v8      (                       background:    UInt8?  , key:    UInt8?  )
            case v16     (                       background:    UInt16? , key:    UInt16? )
            
            case rgb8    (palette:[RGB<UInt8>],  background:RGB<UInt8 >?, key:RGB<UInt8 >?)
            case rgb16   (palette:[RGB<UInt8>],  background:RGB<UInt16>?, key:RGB<UInt16>?)
            
            case indexed1(palette:[RGBA<UInt8>], background:     Int?                     )
            case indexed2(palette:[RGBA<UInt8>], background:     Int?                     )
            case indexed4(palette:[RGBA<UInt8>], background:     Int?                     )
            case indexed8(palette:[RGBA<UInt8>], background:     Int?                     )
            
            case va8     (                       background:    UInt8?                    )
            case va16    (                       background:    UInt16?                   )
            
            case rgba8   (palette:[RGB<UInt8>],  background:RGB<UInt8 >?                  )
            case rgba16  (palette:[RGB<UInt8>],  background:RGB<UInt16>?                  )
        }
        
        @usableFromInline
        let scheme:Scheme 
        public 
        let standard:Standard, 
            interlaced:Bool
    }
}
extension PNG.Layout 
{
    @inlinable
    public
    var format:PNG.Format 
    {
        switch self.scheme 
        {
        case .v1:       return .v1
        case .v2:       return .v2
        case .v4:       return .v4
        case .v8:       return .v8
        case .v16:      return .v16
        case .rgb8:     return .rgb8
        case .rgb16:    return .rgb16
        case .indexed1: return .indexed1
        case .indexed2: return .indexed2
        case .indexed4: return .indexed4
        case .indexed8: return .indexed8
        case .va8:      return .va8
        case .va16:     return .va16
        case .rgba8:    return .rgba8
        case .rgba16:   return .rgba16
        }
    }
    
    public 
    init(standard:PNG.Standard, interlaced:Bool, format:PNG.Format, 
        palette:PNG.Palette?, background:PNG.Background?, transparency:PNG.Transparency?) 
        throws 
    {
        let scheme:Scheme 
        switch format 
        {
        case .v1, .v2, .v4, .v8, .v16:
            guard palette == nil 
            else 
            {
                preconditionFailure("palette not allowed for grayscale format")
            }
            let b:UInt16?, 
                k:UInt16?
            switch background 
            {
            case nil: 
                b = nil 
            case .v(let v)?: 
                precondition(Int.init(v) < 1 << format.depth)
                b = v
            default: 
                preconditionFailure("incompatible format and background cases")
            }
            switch transparency 
            {
            case nil:
                k = nil 
            case .v(let v)?: 
                precondition(Int.init(v) < 1 << format.depth)
                k = v
            default: 
                preconditionFailure("incompatible format and transparency cases")
            }
            
            switch format 
            {
            case .v1:
                scheme = .v1(background: b.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v2:
                scheme = .v2(background: b.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v4:
                scheme = .v4(background: b.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v8:
                scheme = .v8(background: b.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v16:
                scheme = .v16(background: b,                    key: k)
            default:
                fatalError("unreachable")
            }
        
        case .rgb8, .rgb16:
            let palette:[Scheme.RGB<UInt8>] = palette?.entries ?? []
            let b:Scheme.RGB<UInt16>?, 
                k:Scheme.RGB<UInt16>?
            switch background 
            {
            case nil: 
                b = nil 
            case .rgb(let v)?: 
                b = v
            default: 
                preconditionFailure("incompatible format and background cases")
            }
            switch transparency 
            {
            case nil:
                k = nil 
            case .rgb(let v)?: 
                k = v
            default: 
                preconditionFailure("incompatible format and transparency cases")
            }
            
            switch format 
            {
            case .rgb8:
                scheme = .rgb8(palette: palette, 
                    background: b.map{ (.init($0.r), .init($0.g), .init($0.b)) }, 
                    key:        k.map{ (.init($0.r), .init($0.g), .init($0.b)) })
            case .rgb16:
                scheme = .rgb16(palette: palette, background: b, key: k)
            default:
                fatalError("unreachable")
            }
        
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let solid:PNG.Palette = palette 
            else 
            {
                throw PNG.DecodingError.missingPalette
            }
            precondition(solid.count <= 1 << format.depth)
            let b:Int? 
            switch background 
            {
            case nil:
                b = nil 
            case .palette(index: let i):
                precondition(i < solid.count)
                b = i
            default: 
                preconditionFailure("incompatible format and background cases")
            }
            let palette:[Scheme.RGBA<UInt8>]
            switch transparency 
            {
            case nil:
                palette =          solid.map        { (  $0.r,   $0.g,   $0.b, .max) }
            case .palette(alpha: let alpha):
                precondition(alpha.count <= solid.count)
                palette =      zip(solid, alpha).map{ ($0.0.r, $0.0.g, $0.0.b, $0.1) } + 
                    solid.dropFirst(alpha.count).map{ (  $0.r,   $0.g,   $0.b, .max) }
            default: 
                preconditionFailure("incompatible format and transparency cases")
            }
            
            switch format 
            {
            case .indexed1: 
                scheme = .indexed1(palette: palette, background: b)
            case .indexed2: 
                scheme = .indexed2(palette: palette, background: b)
            case .indexed4: 
                scheme = .indexed4(palette: palette, background: b)
            case .indexed8: 
                scheme = .indexed8(palette: palette, background: b)
            default:
                fatalError("unreachable")
            }
        
        case .va8, .va16:
            guard palette == nil 
            else 
            {
                preconditionFailure("palette not allowed for grayscale-alpha format")
            }
            guard transparency == nil 
            else 
            {
                preconditionFailure("chroma key not allowed for grayscale-alpha format")
            }
            let b:UInt16?
            switch background 
            {
            case nil:           b = nil 
            case .v(let v)?:    b = v
            default: 
                preconditionFailure("incompatible format and background cases")
            }
            
            switch format 
            {
            case .va8:
                scheme = .va8(background: b.map(UInt8.init(_:)))
            case .va16:
                scheme = .va16(background: b)
            default:
                fatalError("unreachable")
            }
        
        case .rgba8, .rgba16:
            guard transparency == nil 
            else 
            {
                preconditionFailure("chroma key not allowed for rgba format")
            }
            let palette:[Scheme.RGB<UInt8>] = palette?.entries ?? []
            let b:Scheme.RGB<UInt16>?
            switch background 
            {
            case nil:           b = nil 
            case .rgb(let v)?:  b = v
            default: 
                preconditionFailure("incompatible format and background cases")
            }
            
            switch format 
            {
            case .rgba8:
                scheme = .rgba8(palette: palette, 
                    background: b.map{ (.init($0.r), .init($0.g), .init($0.b)) })
            case .rgba16:
                scheme = .rgba16(palette: palette, background: b)
            default:
                fatalError("unreachable")
            }
        }
        
        self.init(scheme: scheme, standard: standard, interlaced: interlaced)
    }
}

extension PNG 
{
    public 
    enum Data 
    {
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
        
        private 
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
        
        let bytes:Int   = size.x * size.y * layout.format.channels * 
            (layout.format.depth + 7) >> 3
        self.storage    = .init(unsafeUninitializedCapacity: bytes)
        {
            $1 = bytes
        }
    }
    
    mutating 
    func assign<RAC>(scanline:RAC, at base:(x:Int, y:Int), stride:(x:Int, y:Int)) 
        where RAC:RandomAccessCollection, RAC.Index == Int, RAC.Element == UInt8
    {
        let indices:EnumeratedSequence<StrideTo<Int>> = 
            Swift.stride(from: base.x, to: self.size.x, by: stride.x).enumerated()
        switch self.layout.format 
        {
        // 0 x 1 
        case .v1, .indexed1:
            for (i, x):(Int, Int) in indices
            {
                let a:Int =   i >> 3 &+ scanline.startIndex, 
                    b:Int =  ~i & 0b111
                storage[base.y &* self.size.x &+ x] = scanline[a] &>> b & 0b0001
            }
        
        case .v2, .indexed2:
            for (i, x):(Int, Int) in indices
            {
                let a:Int =   i >> 2 &+ scanline.startIndex, 
                    b:Int = (~i & 0b011) << 1
                storage[base.y &* self.size.x &+ x] = scanline[a] &>> b & 0b0011
            }
        
        case .v4, .indexed4:
            for (i, x):(Int, Int) in indices
            {
                let a:Int =   i >> 1 &+ scanline.startIndex, 
                    b:Int = (~i & 0b001) << 2
                storage[base.y &* self.size.x &+ x] = scanline[a] &>> b & 0b1111
            }
        
        // 1 x 1
        case .v8, .indexed8:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = i &+ scanline.startIndex, 
                    d:Int = base.y &* self.size.x &+ x
                storage[d] = scanline[a]
            }
        // 1 x 2
        case .va8:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 2 &* i &+ scanline.startIndex, 
                    d:Int = 2 &* (base.y &* self.size.x &+ x)
                storage[d     ] = scanline[a     ]
                storage[d &+ 1] = scanline[a &+ 1]
            }
        // 1 x 3
        case .rgb8:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 3 &* i &+ scanline.startIndex, 
                    d:Int = 3 &* (base.y &* self.size.x &+ x)
                storage[d     ] = scanline[a     ]
                storage[d &+ 1] = scanline[a &+ 1]
                storage[d &+ 2] = scanline[a &+ 2]
            }
        // 1 x 4
        case .rgba8:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 4 &* i &+ scanline.startIndex, 
                    d:Int = 4 &* (base.y &* self.size.x &+ x)
                storage[d     ] = scanline[a     ]
                storage[d &+ 1] = scanline[a &+ 1]
                storage[d &+ 2] = scanline[a &+ 2]
                storage[d &+ 3] = scanline[a &+ 3]
            }
        
        // 2 x 1
        case .v16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 2 &* i &+ scanline.startIndex, 
                    d:Int = 2 &* base.y &* self.size.x &+ x
                storage[d     ] = scanline[a     ]
                storage[d &+ 1] = scanline[a &+ 1]
            }
        // 2 x 2
        case .va16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 4 &* i &+ scanline.startIndex, 
                    d:Int = 4 &* (base.y &* self.size.x &+ x)
                storage[d     ] = scanline[a     ]
                storage[d &+ 1] = scanline[a &+ 1]
                storage[d &+ 2] = scanline[a &+ 2]
                storage[d &+ 3] = scanline[a &+ 3]
            }
        // 2 x 3
        case .rgb16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 6 &* i &+ scanline.startIndex, 
                    d:Int = 6 &* (base.y &* self.size.x &+ x)
                storage[d     ] = scanline[a     ]
                storage[d &+ 1] = scanline[a &+ 1]
                storage[d &+ 2] = scanline[a &+ 2]
                storage[d &+ 3] = scanline[a &+ 3]
                storage[d &+ 4] = scanline[a &+ 4]
                storage[d &+ 5] = scanline[a &+ 5]
            }
        // 2 x 4
        case .rgba16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 8 &* i &+ scanline.startIndex, 
                    d:Int = 8 &* (base.y &* self.size.x &+ x)
                storage[d     ] = scanline[a     ]
                storage[d &+ 1] = scanline[a &+ 1]
                storage[d &+ 2] = scanline[a &+ 2]
                storage[d &+ 3] = scanline[a &+ 3]
                storage[d &+ 4] = scanline[a &+ 4]
                storage[d &+ 5] = scanline[a &+ 5]
                storage[d &+ 6] = scanline[a &+ 6]
                storage[d &+ 7] = scanline[a &+ 7]
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
        format:PNG.Format, palette:PNG.Palette?, 
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
                try .parse(chunk.data, format: format, palette: palette)
            }
        case .tRNS:
            try Self.unique(assign: chunk.type, to: &transparency) 
            {
                try .parse(chunk.data, format: format, palette: palette)
            }
            
        case .hIST:
            guard let palette:PNG.Palette = palette 
            else 
            {
                throw PNG.DecodingError.missingPalette
            }
            try Self.unique(assign: chunk.type, to: &self.histogram) 
            {
                try .parse(chunk.data, format: format, palette: palette)
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
                try .parse(chunk.data, format: format)
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
    struct Decoder 
    {
        private 
        var x:Int, 
            y:Int, 
            z:Int
        private 
        var reference:[UInt8] 
        private 
        var inflator:LZ77.Inflator 
        
        static 
        func interlaced() -> Self
        {
            .init(x: 0, y: -1, z: 0, reference: [], inflator: .init())
        }
        
        mutating 
        func push(_ data:[UInt8], size:(x:Int, y:Int), format:PNG.Format, 
            delegate:(ArraySlice<UInt8>, (x:Int, y:Int), (x:Int, y:Int)) throws -> ()) throws
        {
            try self.inflator.push(data)
            
            while self.z < 7 
            {
                let adam7:[(base:(x:Int, y:Int), exponent:(x:Int, y:Int))] = 
                [
                    (base: (0, 0), exponent: (3, 3)),
                    (base: (4, 0), exponent: (3, 3)),
                    (base: (0, 4), exponent: (2, 3)),
                    (base: (2, 0), exponent: (2, 2)),
                    (base: (0, 2), exponent: (1, 2)),
                    (base: (1, 0), exponent: (1, 1)),
                    (base: (0, 1), exponent: (0, 1)),
                    
                    (base: (0, 0), exponent: (0, 0)),
                ]
                
                let (base, exponent):((x:Int, y:Int), (x:Int, y:Int)) = adam7[z]
                let subimage:(x:Int, y:Int) = 
                (
                    (size.x + 7 - base.x) >> exponent.x, 
                    (size.y + 7 - base.y) >> exponent.y
                )
                let stride:(x:Int, y:Int) = (1 << exponent.x, 1 << exponent.y)
                let pitch:Int   = (subimage.x * format.volume + 7) >> 3
                
                if self.y < 0 
                {
                    self.reference = .init(repeating: 0, count: pitch + 1)
                    self.y = 0
                }
                
                while self.y < subimage.y 
                {
                    guard var scanline:[UInt8] = self.inflator.pull(self.reference.count)
                    else 
                    {
                        return 
                    }
                    
                    //self.defilter(&scanline)
                    
                    try delegate(scanline.dropFirst(), base, stride)
                    
                    self.reference  = scanline 
                    self.y         += 1
                }
                
                self.y  = -1
                self.z +=  1
            }
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
            format:         header.format, 
            palette:        palette, 
            background:     background, 
            transparency:   transparency)
        self.image = .init(size: header.size, layout: layout, metadata: metadata)
        
        self.decoder = .interlaced()
    }
    
    mutating 
    func push(imageData data:[UInt8]) throws 
    {
        try self.decoder.push(data, size: self.image.size, format: self.image.layout.format) 
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
    static 
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
                    palette = try .parse(chunk.data, format: header.format)
                
                case .IDAT:
                    return try .init(standard: standard, header: header, 
                        palette:        palette, 
                        background:     background, 
                        transparency:   transparency, 
                        metadata:       metadata)
                    
                case .IEND:
                    throw PNG.DecodingError.missingImageData
                
                default:
                    try metadata.push(ancillary: chunk, format: header.format, 
                        palette:        palette, 
                        background:     &background, 
                        transparency:   &transparency)
                }
                
                chunk = try stream.chunk()
            }
        }()
        
        while chunk.type == .IDAT  
        {
            try context.push(imageData: chunk.data)
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

guard let _:Void = 
    (try System.File.Source.open(path: "tests/integration/png/tbbn3p08.png")
{
    let _:PNG.Data.Rectangular = try .decompress(stream: &$0)
})
else 
{
    fatalError("failed to open file")
}
