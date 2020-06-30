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
    }
}
extension PNG.Data.Rectangular 
{
    init(standard:PNG.Standard, header:PNG.Header, 
        palette:PNG.Palette?, background:PNG.Background?, transparency:PNG.Transparency?, 
        metadata:PNG.Metadata) throws 
    {
        self.size       = header.size
        self.layout     = try .init(standard: standard, 
            interlaced:     header.interlaced, 
            format:         header.format, 
            palette:        palette, 
            background:     background, 
            transparency:   transparency)
        self.metadata   = metadata
    }
    
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
        
        func unique<T>(assign:inout T?, parser:() throws -> T) throws 
        {
            guard assign == nil 
            else 
            {
                throw PNG.DecodingError.duplicateChunk(chunk.type)
            }
            assign = try parser()
        }
        
        var image:Self = try 
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
                
                
                case .bKGD:
                    try unique(assign: &background) 
                    {
                        try .parse(chunk.data, format: header.format, palette: palette)
                    }
                case .tRNS:
                    try unique(assign: &transparency) 
                    {
                        try .parse(chunk.data, format: header.format, palette: palette)
                    }
                case .hIST:
                    try unique(assign: &metadata.histogram) 
                    {
                        try .parse(chunk.data, format: header.format, palette: palette)
                    }
                
                case .cHRM:
                    try unique(assign: &metadata.chromaticity) 
                    {
                        try .parse(chunk.data)
                    }
                case .gAMA:
                    try unique(assign: &metadata.gamma) 
                    {
                        try .parse(chunk.data)
                    }
                case .sRGB:
                    try unique(assign: &metadata.colorRendering) 
                    {
                        try .parse(chunk.data)
                    }
                case .iCCP:
                    try unique(assign: &metadata.colorProfile) 
                    {
                        try .parse(chunk.data)
                    }
                case .sBIT:
                    try unique(assign: &metadata.significantBits) 
                    {
                        try .parse(chunk.data, format: header.format)
                    }
                
                case .pHYs:
                    try unique(assign: &metadata.physicalDimensions) 
                    {
                        try .parse(chunk.data)
                    }
                case .tIME:
                    try unique(assign: &metadata.time) 
                    {
                        try .parse(chunk.data)
                    }
                
                case .sPLT:
                    metadata.suggestedPalettes.append(try .parse(chunk.data))
                case .iTXt:
                    metadata.text.append(try .parse(chunk.data))
                case .tEXt, .zTXt:
                    metadata.text.append(try .parse(latin1: chunk.data))
                
                default:
                    metadata.application.append(chunk)
                }
                
                // check before-palette chunk ordering 
                switch chunk.type 
                {
                case .cHRM, .gAMA, .iCCP, .sBIT, .sRGB:
                    guard palette == nil 
                    else 
                    {
                        throw PNG.DecodingError.invalidChunkOrder(chunk.type, after: .PLTE)
                    }
                default:
                    break 
                }
                
                chunk = try stream.chunk()
            }
        }()
        
        while chunk.type == .IDAT  
        {
            chunk = try stream.chunk()
        }
        
        while chunk.type != .IEND 
        {
            switch chunk.type 
            {
            case .tIME:
                try unique(assign: &image.metadata.time) 
                {
                    try .parse(chunk.data)
                }
            case .iTXt:
                image.metadata.text.append(try .parse(        chunk.data))
            case .tEXt, .zTXt:
                image.metadata.text.append(try .parse(latin1: chunk.data))
            default:
                throw PNG.DecodingError.invalidChunkOrder(chunk.type, after: .IDAT)
            }
            
            chunk = try stream.chunk()
        }
        
        return image
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
