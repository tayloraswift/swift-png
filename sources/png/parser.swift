//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/. 
    
extension PNG 
{
    public 
    struct Percentmille:AdditiveArithmetic, ExpressibleByIntegerLiteral
    {
        public 
        var points:Int 
        
        public static 
        let zero:Self = 0
        
        public 
        init<T>(_ points:T) where T:BinaryInteger
        {
            self.points = .init(points)
        }
        
        public 
        init(integerLiteral:Int)
        {
            self.init(integerLiteral)
        }
        
        public static 
        func + (lhs:Self, rhs:Self) -> Self 
        {
            .init(lhs.points + rhs.points)
        }
        public static 
        func += (lhs:inout Self, rhs:Self) 
        {
            lhs.points += rhs.points
        }
        public static 
        func - (lhs:Self, rhs:Self) -> Self 
        {
            .init(lhs.points - rhs.points)
        }
        public static 
        func -= (lhs:inout Self, rhs:Self) 
        {
            lhs.points -= rhs.points
        }
    }
    
    public 
    enum Format 
    {
        public 
        enum Pixel 
        {
            case v1
            case v2 
            case v4 
            case v8 
            case v16 
            
            case rgb8 
            case rgb16 
            
            case indexed1
            case indexed2
            case indexed4
            case indexed8 
            
            case va8 
            case va16 
            
            case rgba8 
            case rgba16 
        }
        
        case v1      (                                                fill:   UInt8?,                       key:   UInt8?                      )
        case v2      (                                                fill:   UInt8?,                       key:   UInt8?                      )
        case v4      (                                                fill:   UInt8?,                       key:   UInt8?                      )
        case v8      (                                                fill:   UInt8?,                       key:   UInt8?                      )
        case v16     (                                                fill:   UInt16?,                      key:   UInt16?                     )
        
        case bgr8    (palette:[(b:UInt8, g:UInt8, r:UInt8         )], fill:(b:UInt8,  g:UInt8,  r:UInt8 )?, key:(b:UInt8,  g:UInt8,  r:UInt8 )?)
        
        case rgb8    (palette:[(r:UInt8, g:UInt8, b:UInt8         )], fill:(r:UInt8,  g:UInt8,  b:UInt8 )?, key:(r:UInt8,  g:UInt8,  b:UInt8 )?)
        case rgb16   (palette:[(r:UInt8, g:UInt8, b:UInt8         )], fill:(r:UInt16, g:UInt16, b:UInt16)?, key:(r:UInt16, g:UInt16, b:UInt16)?)
        
        case indexed1(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:    Int?                                                            )
        case indexed2(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:    Int?                                                            )
        case indexed4(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:    Int?                                                            )
        case indexed8(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:    Int?                                                            )
        
        case va8     (                                                fill:   UInt8?                                                           )
        case va16    (                                                fill:   UInt16?                                                          )
        
        case bgra8   (palette:[(b:UInt8, g:UInt8, r:UInt8         )], fill:(b:UInt8,  g:UInt8,  r:UInt8 )?                                     )
        
        case rgba8   (palette:[(r:UInt8, g:UInt8, b:UInt8         )], fill:(r:UInt8,  g:UInt8,  b:UInt8 )?                                     )
        case rgba16  (palette:[(r:UInt8, g:UInt8, b:UInt8         )], fill:(r:UInt16, g:UInt16, b:UInt16)?                                     )
    }
}
extension PNG.Format.Pixel 
{
    @inlinable
    public
    var hasColor:Bool
    {
        switch self 
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
            return false 
        case .rgb8, .rgb16, .indexed1, .indexed2, .indexed4, .indexed8, .rgba8, .rgba16:
            return true 
        }
    }
    @inlinable
    public
    var hasAlpha:Bool
    {
        switch self 
        {
        case .v1, .v2, .v4, .v8, .v16, .rgb8, .rgb16, 
            .indexed1, .indexed2, .indexed4, .indexed8:
            return false 
        case .va8, .va16, .rgba8, .rgba16:
            return true 
        }
    }
    
    @inlinable
    var volume:Int
    {
        self.depth * self.channels
    }
    
    @inlinable
    public
    var channels:Int
    {
        switch self
        {
        case .v1, .v2, .v4, .v8, .v16,
            .indexed1, .indexed2, .indexed4, .indexed8:     return 1
        case .va8,   .va16:                                 return 2
        case .rgb8,  .rgb16:                                return 3
        case .rgba8, .rgba16:                               return 4
        }
    }
    
    @inlinable
    public
    var depth:Int 
    {
        switch self 
        {
        case    .v1,          .indexed1:                    return  1
        case    .v2,          .indexed2:                    return  2
        case    .v4,          .indexed4:                    return  4
        case    .v8,  .rgb8,  .indexed8, .va8,  .rgba8:     return  8
        case    .v16, .rgb16,            .va16, .rgba16:    return 16
        }
    }
    
    var code:(depth:UInt8, type:UInt8) 
    {
        switch self 
        {
        case .v1:        return ( 1, 0)
        case .v2:        return ( 2, 0)
        case .v4:        return ( 4, 0)
        case .v8:        return ( 8, 0)
        case .v16:       return (16, 0)
        
        case .rgb8:      return ( 8, 2)
        case .rgb16:     return (16, 2)
        
        case .indexed1:  return ( 1, 3)
        case .indexed2:  return ( 2, 3)
        case .indexed4:  return ( 4, 3)
        case .indexed8:  return ( 8, 3) 
        
        case .va8:       return ( 8, 4) 
        case .va16:      return (16, 4) 
        
        case .rgba8:     return ( 8, 6)
        case .rgba16:    return (16, 6) 
        }
    }
    
    static 
    func recognize(code:(depth:UInt8, type:UInt8)) -> Self?
    {
        switch code
        {
        case ( 1, 0):   return .v1
        case ( 2, 0):   return .v2
        case ( 4, 0):   return .v4
        case ( 8, 0):   return .v8
        case (16, 0):   return .v16
        
        case ( 8, 2):   return .rgb8
        case (16, 2):   return .rgb16
        
        case ( 1, 3):   return .indexed1
        case ( 2, 3):   return .indexed2
        case ( 4, 3):   return .indexed4
        case ( 8, 3):   return .indexed8
        
        case ( 8, 4):   return .va8
        case (16, 4):   return .va16
        
        case ( 8, 6):   return .rgba8
        case (16, 6):   return .rgba16
        
        default:        return nil
        }
    }
}
extension PNG.Format 
{
    // can’t use these in the enum cases because they are `internal` only
    typealias RGB<T>  = (r:T, g:T, b:T)
    typealias RGBA<T> = (r:T, g:T, b:T, a:T)
    
    @inlinable
    public
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
    
    public static 
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
                // palette not allowed for grayscale format
                return nil 
            }
            let f:UInt16?, 
                k:UInt16?
            switch background 
            {
            case .v(let v)?: 
                guard Int.init(v) < 1 << pixel.depth
                else 
                {
                    return nil 
                }
                f = v
            case nil: 
                f = nil 
            default: 
                return nil 
            }
            switch transparency 
            {
            
            case .v(let v)?: 
                guard Int.init(v) < 1 << pixel.depth
                else 
                {
                    return nil 
                }
                k = v
                
            case nil:
                k = nil 
            default: 
                return nil 
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
            switch background 
            {
            case .rgb(let c)?:      f = c
            case nil:               f =    nil 
            default:                return nil 
            }
            switch transparency 
            {
            case .rgb(key: let c)?: k = c
            case nil:               k =    nil 
            default:                return nil 
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
            guard let solid:PNG.Palette = palette, 
                solid.count <= 1 << pixel.depth 
            else 
            {
                return nil 
            }
            let f:Int? 
            switch background 
            {
            case .palette(index: let i):
                guard i < solid.count 
                else 
                {
                    return nil 
                }
                f = i
            case nil:
                f = nil 
            default: 
                return nil 
            }
            let palette:[RGBA<UInt8>]
            switch transparency 
            {
            case nil:
                palette =          solid.map        { (  $0.r,   $0.g,   $0.b, .max) }
            case .palette(alpha: let alpha):
                precondition(alpha.count <= solid.count)
                palette =      zip(solid, alpha).map{ ($0.0.r, $0.0.g, $0.0.b, $0.1) } + 
                    solid.dropFirst(alpha.count).map{ (  $0.r,   $0.g,   $0.b, .max) }
            default: 
                return nil 
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
            guard palette == nil, transparency == nil 
            else 
            {
                // palette/chroma-key not allowed for grayscale-alpha format
                return nil 
            }
            let f:UInt16?
            switch background 
            {
            case .v(let v)?:    f =    v
            case nil:           f =    nil 
            default:            return nil 
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
                // chroma key not allowed for rgba format
                return nil 
            }
            let palette:[RGB<UInt8>] = palette?.entries ?? []
            let f:RGB<UInt16>?
            switch background 
            {
            case .rgb(let c)?:  f = c
            case nil:           f =    nil 
            default:            return nil 
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
        
        return format 
    }
}

extension PNG 
{
    public 
    enum ParsingError:Swift.Error 
    {
        case invalidHeaderChunkLength(Int)
        case invalidHeaderPixelFormatCode(depth:UInt8, type:UInt8)
        case invalidHeaderPixelFormat(PNG.Format.Pixel, standard:PNG.Standard)
        case invalidHeaderCompressionCode(UInt8)
        case invalidHeaderFilterCode(UInt8)
        case invalidHeaderInterlacingCode(UInt8)
        case invalidHeaderSize((x:Int, y:Int))
        
        case unexpectedPalette(pixel:PNG.Format.Pixel)
        case invalidPaletteSampleCount(Int)
        case invalidPaletteEntryCount(Int, expected:ClosedRange<Int>)
        
        case unexpectedTransparency(pixel:PNG.Format.Pixel)
        case invalidTransparencyChunkLength(Int, expected:Int)
        case invalidChromaKeySample(UInt16, expected:ClosedRange<UInt16>)
        case invalidTransparencyPaletteEntryCount(Int, expected:ClosedRange<Int>)
        
        case unexpectedBackground
        case invalidBackgroundChunkLength(Int, expected:Int)
        case invalidBackgroundSample(UInt16, expected:ClosedRange<UInt16>)
        case invalidBackgroundPaletteEntryIndex(Int, expected:ClosedRange<Int>)
        
        case unexpectedHistogram
        case invalidHistogramChunkLength(Int)
        case invalidHistogramBinCount(Int, expected:Int)
        
        case invalidGammaChunkLength(Int)
        
        case invalidChromaticityChunkLength(Int)
        
        case invalidColorRenderingChunkLength(Int)
        case invalidColorRenderingCode(UInt8)
        
        case invalidSignificantBitsChunkLength(Int, expected:Int)
        case invalidSignificantBitsSamplePrecision(Int, expected:ClosedRange<Int>)
        
        case missingColorProfileName 
        case invalidColorProfileName 
        case missingColorProfileFlags
        case invalidColorProfileFlagsCode(method:UInt8)
        case truncatedColorProfileCompressedContent
        
        case invalidPhysicalDimensionsChunkLength(Int)
        case invalidPhysicalDimensionsDensityUnitCode(UInt8)
        
        case truncatedSuggestedPalette(Int, minimum:Int)
        case invalidSuggestedPaletteChunkLength(Int, offset:Int, stride:Int)
        case missingSuggestedPaletteName
        case invalidSuggestedPaletteName 
        case invalidSuggestedPaletteDepthCode(UInt8)
        
        case invalidTimeModifiedChunkLength(Int)
        case invalidTimeModifiedTime(year:Int, month:Int, day:Int, hour:Int, minute:Int, second:Int)
        
        case missingTextEnglishKeyword
        case invalidTextEnglishKeyword
        case missingTextFlags
        case invalidTextFlagsCode(compression:UInt8, method:UInt8)
        case missingTextLanguage
        case invalidTextLanguage
        case missingTextLocalizedKeyword
        case truncatedTextCompressedContent
    }
}
extension PNG 
{
    public 
    struct Header
    {
        public
        let size:(x:Int, y:Int), 
            pixel:PNG.Format.Pixel, 
            interlaced:Bool
        // need to override synthesized init
        private 
        init(unchecked size:(x:Int, y:Int), pixel:PNG.Format.Pixel, interlaced:Bool) 
        {
            self.size       = size 
            self.pixel      = pixel 
            self.interlaced = interlaced
        }
    }
}
extension PNG.Header 
{
    public 
    init(size:(x:Int, y:Int), pixel:PNG.Format.Pixel, interlaced:Bool) 
    {
        precondition(size.x > 0 && size.y > 0, "size must be positive")
        self.init(unchecked: size, pixel: pixel, interlaced: interlaced)
    }
    
    public 
    func serialized() -> [UInt8] 
    {
        .init(unsafeUninitializedCapacity: 13) 
        {
            $0.store(self.size.x, asBigEndian: UInt32.self, at: 0)
            $0.store(self.size.y, asBigEndian: UInt32.self, at: 4)
            ($0[8], $0[9])  = self.pixel.code 
            $0[10]          = 0
            $0[11]          = 0
            $0[12]          = self.interlaced ? 1 : 0
            $1              = 13
        }
    }
    
    public static 
    func parse(_ data:[UInt8], standard:PNG.Standard) throws -> Self 
    {
        guard data.count == 13
        else
        {
            throw PNG.ParsingError.invalidHeaderChunkLength(data.count)
        }
        
        guard let pixel:PNG.Format.Pixel = .recognize(code: (data[8], data[9]))
        else
        {
            throw PNG.ParsingError.invalidHeaderPixelFormatCode(depth: data[8], type: data[9])
        }
        
        // iphone-optimized PNG can only have pixel type rgb8 or rgb16
        switch (standard, pixel)
        {
        case    (.common, _):   break 
        case    (.ios, .rgb8), 
                (.ios, .rgba8): break
        default: 
            throw PNG.ParsingError.invalidHeaderPixelFormat(pixel, standard: standard)
        }

        // validate other fields
        guard data[10] == 0
        else
        {
            throw PNG.ParsingError.invalidHeaderCompressionCode(data[10])
        }
        guard data[11] == 0
        else
        {
            throw PNG.ParsingError.invalidHeaderFilterCode(data[11])
        }

        let interlaced:Bool
        switch data[12]
        {
        case 0:
            interlaced = false
        case 1:
            interlaced = true
        default:
            throw PNG.ParsingError.invalidHeaderInterlacingCode(data[12])
        }
        
        let size:(x:Int, y:Int) = 
        (
            data.load(bigEndian: UInt32.self, as: Int.self, at: 0),
            data.load(bigEndian: UInt32.self, as: Int.self, at: 4)
        )
        // validate size 
        guard size.x > 0, size.y > 0 
        else 
        {
            throw PNG.ParsingError.invalidHeaderSize(size)
        }

        return .init(size: size, pixel: pixel, interlaced: interlaced)
    }
}

extension PNG 
{
    public 
    struct Palette 
    {
        let entries:[(r:UInt8, g:UInt8, b:UInt8)]
    }
}
extension PNG.Palette 
{
    public 
    init(_ entries:[(r:UInt8, g:UInt8, b:UInt8)], pixel:PNG.Format.Pixel) 
    {
        precondition(1 ... Swift.min(256, 1 << pixel.depth) ~= entries.count, "invalid number of palette entries")
        precondition(pixel.hasColor, "invalid pixel format")
        self.entries = entries 
    }
    
    public 
    func serialized() -> [UInt8] 
    {
        .init(unsafeUninitializedCapacity: 3 * self.entries.count)
        {
            for (i, c):(Int, (r:UInt8, g:UInt8, b:UInt8)) in 
                zip(stride(from: $0.startIndex, to: $0.endIndex, by: 3), self.entries) 
            {
                $0[i    ] = c.r
                $0[i + 1] = c.g
                $0[i + 2] = c.b
            }
            $1 = $0.count
        }
    }
    
    public static 
    func parse(_ data:[UInt8], pixel:PNG.Format.Pixel) throws -> Self
    {
        guard pixel.hasColor
        else
        {
            throw PNG.ParsingError.unexpectedPalette(pixel: pixel)
        }
        
        let (count, remainder):(Int, Int) = data.count.quotientAndRemainder(dividingBy: 3)
        guard remainder == 0
        else
        {
            throw PNG.ParsingError.invalidPaletteSampleCount(data.count)
        }

        // check number of palette entries
        let maximum:Int = Swift.min(256, 1 << pixel.depth)
        guard 1 ... maximum ~= count 
        else
        {
            throw PNG.ParsingError.invalidPaletteEntryCount(count, expected: 1 ... maximum)
        }

        return .init(entries: (0 ..< count).map
        {
            (i:Int) -> (r:UInt8, g:UInt8, b:UInt8) in 
            (data[3 * i], data[3 * i + 1], data[3 * i + 2])
        })
    }
}
extension PNG.Palette:RandomAccessCollection 
{
    public 
    var startIndex:Int 
    {
        self.entries.startIndex
    }
    public 
    var endIndex:Int 
    {
        self.entries.endIndex
    }
    public 
    subscript(index:Int) -> (r:UInt8, g:UInt8, b:UInt8) 
    {
        self.entries[index]
    }
}

extension PNG 
{
    public 
    enum Transparency 
    {
        case palette(alpha:[UInt8])
        case rgb(key:(r:UInt16, g:UInt16, b:UInt16))
        case v(key:UInt16)
    }
}
extension PNG.Transparency 
{
    public 
    func serialized() -> [UInt8] 
    {
        switch self 
        {
        case .palette(alpha: let alpha):
            return .init(unsafeUninitializedCapacity: alpha.count)
            {
                $0.baseAddress?.assign(from: alpha, count: $0.count)
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
    
    public static 
    func parse(_ data:[UInt8], pixel:PNG.Format.Pixel, palette:PNG.Palette?) 
        throws -> Self
    {
        let max:UInt16 = .init(1 << pixel.depth - 1 as Int)
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16:
            guard data.count == 2 
            else 
            {
                throw PNG.ParsingError.invalidTransparencyChunkLength(data.count, 
                    expected: 2)
            }
            
            let v:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0)
            guard v <= max 
            else 
            {
                throw PNG.ParsingError.invalidChromaKeySample(v, expected: 0 ... max)
            }
            return .v(key: v)
        
        case .rgb8, .rgb16:
            guard data.count == 6 
            else 
            {
                throw PNG.ParsingError.invalidTransparencyChunkLength(data.count, 
                    expected: 6)
            }
            
            let r:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0),
                g:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 2),
                b:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 4)
            guard r <= max, g <= max, b <= max 
            else 
            {
                throw PNG.ParsingError.invalidChromaKeySample(Swift.max(r, g, b), 
                    expected: 0 ... max)
            }
            return .rgb(key: (r, g, b))
        
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let palette:PNG.Palette = palette 
            else 
            {
                throw PNG.ParsingError.unexpectedTransparency(pixel: pixel)
            }
            guard data.count <= palette.count  
            else 
            {
                throw PNG.ParsingError.invalidTransparencyPaletteEntryCount(data.count, 
                    expected: 1 ... palette.count)
            }
            return .palette(alpha: data)
        
        case .va8, .va16, .rgba8, .rgba16:
            throw PNG.ParsingError.unexpectedTransparency(pixel: pixel)
        }
    }
}

extension PNG 
{
    public 
    enum Background 
    {
        case palette(index:Int)
        case rgb((r:UInt16, g:UInt16, b:UInt16))
        case v(UInt16)
    }
}
extension PNG.Background 
{
    // will trap if index doesn’t fit in a uint8
    public 
    func serialized() -> [UInt8] 
    {
        switch self 
        {
        case .palette(index: let i):
            return .init(unsafeUninitializedCapacity: 1)
            {
                $0[0] = .init(i)
                $1 = $0.count
            }
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
    
    public static 
    func parse(_ data:[UInt8], pixel:PNG.Format.Pixel, palette:PNG.Palette?) 
        throws -> Self
    {
        let max:UInt16 = .init(1 << pixel.depth - 1 as Int)
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
            guard data.count == 2 
            else 
            {
                throw PNG.ParsingError.invalidBackgroundChunkLength(data.count, 
                    expected: 2)
            }
            
            let v:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0)
            guard v <= max 
            else 
            {
                throw PNG.ParsingError.invalidBackgroundSample(v, expected: 0 ... max)
            }
            return .v(v)
        
        case .rgb8, .rgb16, .rgba8, .rgba16:
            guard data.count == 6 
            else 
            {
                throw PNG.ParsingError.invalidBackgroundChunkLength(data.count, 
                    expected: 6)
            }
            
            let r:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0),
                g:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 2),
                b:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 4)
            for v:UInt16 in [r, g, b] where v > max
            {
                throw PNG.ParsingError.invalidBackgroundSample(v, expected: 0 ... max)
            }
            
            return .rgb((r, g, b))
        
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let palette:PNG.Palette = palette 
            else 
            {
                throw PNG.ParsingError.unexpectedBackground
            }
            guard data.count == 1
            else 
            {
                throw PNG.ParsingError.invalidBackgroundChunkLength(data.count, 
                    expected: 1)
            }
            let index:Int = .init(data[0])
            guard index < palette.count
            else 
            {
                throw PNG.ParsingError.invalidBackgroundPaletteEntryIndex(index, 
                    expected: 0 ... palette.count - 1)
            }
            return .palette(index: index)
        }
    }
}

extension PNG 
{
    public 
    struct Histogram 
    {
        public private(set)
        var frequencies:[UInt16]
    }
}
extension PNG.Histogram 
{
    public 
    func serialized() -> [UInt8] 
    {
        .init(unsafeUninitializedCapacity: 2 * self.frequencies.count) 
        {
            for (i, frequency):(Int, UInt16) in self.frequencies.enumerated()
            {
                $0.store(frequency, asBigEndian: UInt16.self, at: i << 1)
            }
            $1 = 2 * self.frequencies.count
        }
    }
    public static 
    func parse(_ data:[UInt8], pixel:PNG.Format.Pixel, palette:PNG.Palette) 
        throws -> Self
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16, .rgb8, .rgb16, .rgba8, .rgba16:
            throw PNG.ParsingError.unexpectedHistogram
        
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard data.count & 1 == 0 
            else 
            {
                // must have parity 2
                throw PNG.ParsingError.invalidHistogramChunkLength(data.count)
            }
            guard data.count >> 1 == palette.count
            else 
            {
                throw PNG.ParsingError.invalidHistogramBinCount(data.count >> 1, 
                    expected: palette.count)
            }
            return .init(frequencies: (0 ..< data.count >> 1).map 
            {
                data.load(bigEndian: UInt16.self, as: UInt16.self, at: $0 << 1)
            })
        }
    }
}

extension PNG 
{
    public 
    struct Gamma 
    {
        public 
        let pcm:Percentmille 
    }
}
extension PNG.Gamma 
{
    public 
    func serialized() -> [UInt8] 
    {
        .init(unsafeUninitializedCapacity: MemoryLayout<UInt32>.size) 
        {
            $0.store(self.pcm.points, asBigEndian: UInt32.self, at: 0)
            $1 = $0.count
        }
    }
    
    public static 
    func parse(_ data:[UInt8]) throws -> Self
    {
        guard data.count == 4
        else 
        {
            throw PNG.ParsingError.invalidGammaChunkLength(data.count)
        }
        
        return .init(pcm: .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 0)))
    }
}

extension PNG 
{
    public 
    struct Chromaticity  
    {
        public 
        let w:(x:Percentmille, y:Percentmille), 
            r:(x:Percentmille, y:Percentmille), 
            g:(x:Percentmille, y:Percentmille), 
            b:(x:Percentmille, y:Percentmille)
    }
}
extension PNG.Chromaticity 
{
    public 
    func serialized() -> [UInt8] 
    {
        .init(unsafeUninitializedCapacity: 32) 
        {
            $0.store(self.w.x.points, asBigEndian: UInt32.self, at:  0)
            $0.store(self.w.y.points, asBigEndian: UInt32.self, at:  4)
            
            $0.store(self.r.x.points, asBigEndian: UInt32.self, at:  8)
            $0.store(self.r.y.points, asBigEndian: UInt32.self, at: 12)
            
            $0.store(self.g.x.points, asBigEndian: UInt32.self, at: 16)
            $0.store(self.g.y.points, asBigEndian: UInt32.self, at: 20)
            
            $0.store(self.b.x.points, asBigEndian: UInt32.self, at: 24)
            $0.store(self.b.y.points, asBigEndian: UInt32.self, at: 28)
            $1 = $0.count
        }
    }
    
    public static 
    func parse(_ data:[UInt8]) throws -> Self
    {
        guard data.count == 32
        else 
        {
            throw PNG.ParsingError.invalidChromaticityChunkLength(data.count)
        }
        
        return .init(
            w: 
            (
                .init(data.load(bigEndian: UInt32.self, as: Int.self, at:  0)),
                .init(data.load(bigEndian: UInt32.self, as: Int.self, at:  4))
            ),
            r: 
            (
                .init(data.load(bigEndian: UInt32.self, as: Int.self, at:  8)),
                .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 12))
            ),
            g: 
            (
                .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 16)),
                .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 20))
            ),
            b: 
            (
                .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 24)),
                .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 28))
            ))
    }
}

extension PNG 
{
    public 
    enum ColorRendering
    {
        case perceptual 
        case relative 
        case saturation 
        case absolute 
    }
}
extension PNG.ColorRendering 
{
    public 
    func serialized() -> [UInt8] 
    {
        switch self 
        {
        case .perceptual:   return [0]
        case .relative:     return [1]
        case .saturation:   return [2]
        case .absolute:     return [3]
        }
    }
    
    public static 
    func parse(_ data:[UInt8]) throws -> Self
    {
        guard data.count == 1
        else 
        {
            throw PNG.ParsingError.invalidColorRenderingChunkLength(data.count)
        }
        
        switch data[0] 
        {
        case 0:     return .perceptual 
        case 1:     return .relative 
        case 2:     return .saturation 
        case 3:     return .absolute 
        default:    throw PNG.ParsingError.invalidColorRenderingCode(data[0])
        }
    }
}

extension PNG 
{
    public 
    enum SignificantBits 
    {
        case v(Int)
        case va((v:Int, a:Int))
        case rgb((r:Int, g:Int, b:Int))
        case rgba((r:Int, g:Int, b:Int, a:Int))
    }
}
extension PNG.SignificantBits 
{
    public 
    func serialized() -> [UInt8] 
    {
        switch self 
        {
        case .v(   let c):  return [c].map(UInt8.init(_:))
        case .va(  let c):  return [c.v, c.a].map(UInt8.init(_:))
        case .rgb( let c):  return [c.r, c.g, c.b].map(UInt8.init(_:))
        case .rgba(let c):  return [c.r, c.g, c.b, c.a].map(UInt8.init(_:))
        }
    }
    
    public static 
    func parse(_ data:[UInt8], pixel:PNG.Format.Pixel) throws -> Self
    {
        let arity:Int = (pixel.hasColor ? 3 : 1) + (pixel.hasAlpha ? 1 : 0)
        guard data.count == arity 
        else 
        {
            throw PNG.ParsingError.invalidSignificantBitsChunkLength(data.count, 
                expected: arity)
        }
        
        let range:ClosedRange<Int> 
        switch pixel  
        {
        case .indexed1, .indexed2, .indexed4, .indexed8:    range = 1 ... 8
        default:                                            range = 1 ... pixel.depth 
        }
        
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16:
            let v:Int = .init(data[0])
            guard range ~= v 
            else 
            {
                throw PNG.ParsingError.invalidSignificantBitsSamplePrecision(v, 
                    expected: range)
            }
            return .v(v)
        
        case .rgb8, .rgb16, .indexed1, .indexed2, .indexed4, .indexed8:
            let r:Int = .init(data[0]), 
                g:Int = .init(data[1]), 
                b:Int = .init(data[2])
            for v:Int in [r, g, b] where !(range ~= v)
            {
                throw PNG.ParsingError.invalidSignificantBitsSamplePrecision(v, 
                    expected: range)
            }
            return .rgb((r, g, b))
        
        case .va8, .va16:
            let v:Int = .init(data[0]), 
                a:Int = .init(data[1])
            for v:Int in [v, a] where !(range ~= v)
            {
                throw PNG.ParsingError.invalidSignificantBitsSamplePrecision(v, 
                    expected: range)
            }
            return .va((v, a))
        
        case .rgba8, .rgba16:
            let r:Int = .init(data[0]), 
                g:Int = .init(data[1]), 
                b:Int = .init(data[2]),
                a:Int = .init(data[3])
            for v:Int in [r, g, b, a] where !(range ~= v)
            {
                throw PNG.ParsingError.invalidSignificantBitsSamplePrecision(v, 
                    expected: range)
            }
            return .rgba((r, g, b, a))
        }
    }
}

extension PNG 
{
    public 
    struct ColorProfile
    {
        public 
        let name:String 
        public 
        let profile:[UInt8]
    }
}
extension PNG.ColorProfile 
{
    public 
    func serialized() -> [UInt8] 
    {
        var data:[UInt8] = []
        data.reserveCapacity(2 + self.name.count)
        
        data.append(contentsOf: self.name.unicodeScalars.map{ .init($0.value) })
        data.append(0)
        data.append(0) // compression method
        
        var deflator:LZ77.Deflator = .init(level: 13, exponent: 15, hint: 4096)
        deflator.push(self.profile, last: true)
        while true 
        {
            let segment:[UInt8] = deflator.pull()
            guard !segment.isEmpty 
            else 
            {
                break 
            }
            
            data.append(contentsOf: segment)
        }
        
        return data
    }
    
    public static 
    func parse(_ data:[UInt8]) throws -> Self
    {
        //  ┌ ╶ ╶ ╶ ╶ ╶ ╶┬───┬───┬ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶┐
        //  │    name    │ 0 │ M │        profile         │
        //  └ ╶ ╶ ╶ ╶ ╶ ╶┴───┴───┴ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶┘
        //               k  k+1 k+2
        guard let k:Int = data.firstIndex(of: 0)
        else 
        {
            throw PNG.ParsingError.missingColorProfileName
        }
        // assert existence of method byte
        guard k + 1 < data.endIndex 
        else 
        {
            throw PNG.ParsingError.missingColorProfileFlags
        }
        
        guard let name:String = PNG.Text.validate(name: data.prefix(k))
        else 
        {
            throw PNG.ParsingError.invalidColorProfileName
        }
        
        guard data[k + 1] == 0
        else 
        {
            throw PNG.ParsingError.invalidColorProfileFlagsCode(method: data[k + 1])
        }
        
        var inflator:LZ77.Inflator = .init()
        guard try inflator.push(.init(data.dropFirst(k + 2))) == nil 
        else 
        {
            throw PNG.ParsingError.truncatedColorProfileCompressedContent
        }
        
        return .init(name: name, profile: inflator.pull())
    }
}


extension PNG 
{
    public 
    struct PhysicalDimensions
    {
        public 
        enum Unit 
        {
            case meter
        }
        
        public 
        let density:(x:Int, y:Int, unit:Unit?)
    }
}
extension PNG.PhysicalDimensions 
{
    public 
    func serialized() -> [UInt8] 
    {
        .init(unsafeUninitializedCapacity: 9) 
        {
            $0.store(self.density.x, asBigEndian: UInt32.self, at:  0)
            $0.store(self.density.y, asBigEndian: UInt32.self, at:  4)
            
            switch self.density.unit 
            {
            case nil:       $0[8] = 0
            case .meter?:   $0[8] = 1
            }
            $1 = $0.count
        }
    }
    
    public static 
    func parse(_ data:[UInt8]) throws -> Self
    {
        guard data.count == 9
        else 
        {
            throw PNG.ParsingError.invalidPhysicalDimensionsChunkLength(data.count)
        }
        
        let x:Int = data.load(bigEndian: UInt32.self, as: Int.self, at: 0),
            y:Int = data.load(bigEndian: UInt32.self, as: Int.self, at: 4)
        
        let unit:Unit?
        switch data[8]
        {
        case 0:     unit = nil 
        case 1:     unit = .meter 
        default:    throw PNG.ParsingError.invalidPhysicalDimensionsDensityUnitCode(data[8])
        }
        
        return .init(density: (x, y, unit))
    }
}

extension PNG 
{
    public 
    struct SuggestedPalette 
    {
        public 
        enum Entries 
        {
            case rgba8( [(color:(r:UInt8,  g:UInt8,  b:UInt8,  a:UInt8),  frequency:UInt16)])
            case rgba16([(color:(r:UInt16, g:UInt16, b:UInt16, a:UInt16), frequency:UInt16)])
        }
        
        public 
        let name:String 
        public 
        var entries:Entries 
    }
}
extension PNG.SuggestedPalette 
{
    public 
    func serialized() -> [UInt8] 
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
    
    public static 
    func parse(_ data:[UInt8]) throws -> Self
    {
        guard let offset:Int = data.firstIndex(of: 0)
        else 
        {
            throw PNG.ParsingError.missingSuggestedPaletteName
        }
        // validate keyword 
        guard let name:String = PNG.Text.validate(name: data.prefix(offset))
        else 
        {
            throw PNG.ParsingError.invalidSuggestedPaletteName
        }
        
        guard offset + 1 < data.count 
        else 
        {
            throw PNG.ParsingError.truncatedSuggestedPalette(data.count, 
                minimum: offset + 2)
        }
        
        switch data[offset + 1] 
        {
        case 8:
            let (count, remainder):(Int, Int) = 
                (data.count - offset - 2).quotientAndRemainder(dividingBy: 6)
            guard remainder == 0 
            else 
            {
                throw PNG.ParsingError.invalidSuggestedPaletteChunkLength(data.count,  
                    offset: offset + 2, stride: 6)
            }
            
            return .init(name: name, entries: .rgba8((0 ..< count).map 
            {
                (i:Int) -> (color:(r:UInt8, g:UInt8, b:UInt8, a:UInt8), frequency:UInt16) in
                (
                    (
                        data[offset + 2 + 6 * i    ],
                        data[offset + 2 + 6 * i + 1],
                        data[offset + 2 + 6 * i + 2],
                        data[offset + 2 + 6 * i + 3]
                    ), 
                    data.load(bigEndian: UInt16.self, as: UInt16.self, 
                        at:  offset + 2 + 6 * i + 4)
                )
            }))
        
        case 16:
            let (count, remainder):(Int, Int) = 
                (data.count - offset - 2).quotientAndRemainder(dividingBy: 10)
            guard remainder == 0 
            else 
            {
                throw PNG.ParsingError.invalidSuggestedPaletteChunkLength(data.count,  
                    offset: offset + 2, stride: 10)
            }
            
            return .init(name: name, entries: .rgba16((0 ..< count).map 
            {
                (i:Int) -> (color:(r:UInt16, g:UInt16, b:UInt16, a:UInt16), frequency:UInt16) in
                (
                    (
                        data.load(bigEndian: UInt16.self, as: UInt16.self, 
                            at: offset + 2 + 10 * i    ),
                        data.load(bigEndian: UInt16.self, as: UInt16.self, 
                            at: offset + 2 + 10 * i + 2),
                        data.load(bigEndian: UInt16.self, as: UInt16.self, 
                            at: offset + 2 + 10 * i + 4),
                        data.load(bigEndian: UInt16.self, as: UInt16.self, 
                            at: offset + 2 + 10 * i + 6)
                    ), 
                    data.load(bigEndian: UInt16.self, as: UInt16.self, 
                        at:     offset + 2 + 10 * i + 8)
                )
            }))
        
        default:
            throw PNG.ParsingError.invalidSuggestedPaletteDepthCode(data[offset + 1])
        }
    }
}

extension PNG 
{
    public 
    struct TimeModified 
    {
        public 
        let year:Int, 
            month:Int, 
            day:Int, 
            hour:Int, 
            minute:Int, 
            second:Int
    }
}
extension PNG.TimeModified 
{
    public 
    func serialized() -> [UInt8] 
    {
        .init(unsafeUninitializedCapacity: 7) 
        {
            $0.store(self.year, asBigEndian: UInt16.self, at: 0)
            $0[2] = .init(self.month)
            $0[3] = .init(self.day)
            $0[4] = .init(self.hour)
            $0[5] = .init(self.minute)
            $0[6] = .init(self.second)
            $1 = $0.count
        }
    }
    
    public static 
    func parse(_ data:[UInt8]) throws -> Self
    {
        guard data.count == 7 
        else 
        {
            throw PNG.ParsingError.invalidTimeModifiedChunkLength(data.count)
        }
        
        let year:Int    = data.load(bigEndian: UInt16.self, as: Int.self, at: 0), 
            month:Int   = .init(data[2]), 
            day:Int     = .init(data[3]), 
            hour:Int    = .init(data[4]), 
            minute:Int  = .init(data[5]), 
            second:Int  = .init(data[6]) 
        
        guard   1 ... 12 ~= month, 
                1 ... 31 ~= day, 
                0 ... 23 ~= hour, 
                0 ... 59 ~= minute, 
                0 ... 60 ~= second 
        else 
        {
            throw PNG.ParsingError.invalidTimeModifiedTime(year: year, month: month, 
                day: day, hour: hour, minute: minute, second: second)
        }
        
        return .init(year: year, month: month, day: day, 
            hour: hour, minute: minute, second: second)
    }
}

extension PNG 
{
    public 
    struct Text 
    {
        public 
        let compressed:Bool 
        public 
        let keyword:(english:String, localized:String), 
            language:[String]
        public 
        let content:String
    }
}
extension PNG.Text 
{
    public 
    func serialized() -> [UInt8] 
    {
        let size:Int = 5 +
            self.keyword.english.count                      + 
            self.keyword.localized.count                    + 
            self.language.reduce(0){ $0 + $1.count + 1 }    + 
            self.content.utf8.count 
            
        var data:[UInt8] = []
        data.reserveCapacity(size)
        data.append(contentsOf: self.keyword.english.unicodeScalars.map{ .init($0.value) })
        data.append(0)
        data.append(self.compressed ? 1 : 0)
        data.append(0) // compression method
        data.append(contentsOf: self.language.map
        { 
            $0.unicodeScalars.map{ .init($0.value) }
        }.joined(separator: [0x2d]))
        data.append(0)
        if self.keyword.localized != self.keyword.english 
        {
            data.append(contentsOf: self.keyword.localized.utf8)
        }
        data.append(0)
        
        if self.compressed 
        {
            var deflator:LZ77.Deflator = .init(level: 13, exponent: 15, hint: 4096)
            deflator.push(.init(self.content.utf8), last: true)
            while true 
            {
                let segment:[UInt8] = deflator.pull()
                guard !segment.isEmpty 
                else 
                {
                    break 
                }
                
                data.append(contentsOf: segment)
            }
        }
        else 
        {
            data.append(contentsOf: self.content.utf8)
        }
        
        return data
    }
    
    static 
    func validate<C>(name latin1:C) -> String?
        where C:Collection, C.Index == Int, C.Element == UInt8 
    {
        guard 1 ..< 80 ~= latin1.count, 
            (latin1.allSatisfy{ 0x20 ... 0x7d ~= $0 || 0xa1 ... 0xff ~= 0 })
        else 
        {
            return nil
        }
        
        let name:String = .init(latin1.map{ Character.init(Unicode.Scalar.init($0)) })
        guard   !latin1.reversed().starts(with: [0x20]), // no trailing spaces 
                !latin1.starts(           with: [0x20])  // no leading spaces 
        else 
        {
            return nil
        }
        for i:Int in latin1.indices where latin1[i] == 0x20 
        {
            // don’t need to check index bounds because we already verified 
            // it has no trailing spaces
            guard latin1[i + 1] != 0x20 
            else 
            {
                return nil
            }
        }
        return name
    }
    
    private static 
    func validate<C>(keyword latin1:C) throws -> String
        where C:Collection, C.Index == Int, C.Element == UInt8 
    {
        guard let keyword:String = Self.validate(name: latin1)
        else 
        {
            throw PNG.ParsingError.invalidTextEnglishKeyword
        }
        return keyword
    }
    private static 
    func validate<C>(language ascii:C) throws -> [String]
        where C:Collection, C.Index == Int, C.Element == UInt8 
    {
        // split on '-' 
        try ascii.split(separator: 0x2d, omittingEmptySubsequences: false).map 
        {
            guard 1 ... 8 ~= $0.count, 
                ($0.allSatisfy{ 0x61 ... 0x7a ~= $0 || 0x41 ... 0x5a ~= $0 })
            else 
            {
                throw PNG.ParsingError.invalidTextLanguage
            }
            
            // 0x20 converts to canonical lowercase 
            return .init($0.map{ Character.init(Unicode.Scalar.init($0 | 0x20)) })
        }
    }
    
    public static 
    func parse(_ data:[UInt8]) throws -> Self
    {
        //  ┌ ╶ ╶ ╶ ╶ ╶ ╶┬───┬───┬───┬ ╶ ╶ ╶ ╶ ╶ ╶┬───┬ ╶ ╶ ╶ ╶ ╶ ╶┬───┬ ╶ ╶ ╶ ╶ ╶ ╶┐
        //  │   keyword  │ 0 │ C │ M │  language  │ 0 │   keyword  │ 0 │    text    │
        //  └ ╶ ╶ ╶ ╶ ╶ ╶┴───┴───┴───┴ ╶ ╶ ╶ ╶ ╶ ╶┴───┴ ╶ ╶ ╶ ╶ ╶ ╶┴───┴ ╶ ╶ ╶ ╶ ╶ ╶┘
        //               k  k+1 k+2 k+3           l  l+1           m  m+1
        guard let k:Int = data.firstIndex(of: 0)
        else 
        {
            throw PNG.ParsingError.missingTextEnglishKeyword
        }
        // assert existence of compression flag and method bytes 
        guard k + 2 < data.endIndex 
        else 
        {
            throw PNG.ParsingError.missingTextFlags
        }
        guard let l:Int = data.dropFirst(k + 3).firstIndex(of: 0)
        else 
        {
            throw PNG.ParsingError.missingTextLanguage
        }
        guard let m:Int = data.dropFirst(l + 1).firstIndex(of: 0) 
        else 
        {
            throw PNG.ParsingError.missingTextLocalizedKeyword
        }
        
        let localized:String = .init(decoding: data[l + 1 ..< m], as: Unicode.UTF8.self)
        let keyword:(english:String, localized:String) 
        keyword.english     = try Self.validate(keyword: data.prefix(k))
        keyword.localized   = keyword.english == localized ? "" : localized
        
        let uncompressed:ArraySlice<UInt8>
        let compressed:Bool 
        if      data[k + 1] == 0 
        {
            uncompressed = data.dropFirst(m + 1)
            compressed   = false
        }
        else if data[k + 1] == 1, data[k + 2] == 0
        {
            var inflator:LZ77.Inflator = .init()
            guard try inflator.push(.init(data.dropFirst(m + 1))) == nil 
            else 
            {
                throw PNG.ParsingError.truncatedTextCompressedContent
            }
            uncompressed = inflator.pull()[...]
            compressed   = true
        }
        else 
        {
            throw PNG.ParsingError.invalidTextFlagsCode(
                compression: data[k + 1], method: data[k + 2])
        }
        
        // language can be empty, in which case it is unknown 
        let language:[String] = k + 3 == l ? 
            [] : try Self.validate(language: data[k + 3 ..< l])
        return .init(compressed: compressed, keyword: keyword, language: language, 
            content: .init(decoding: uncompressed, as: Unicode.UTF8.self))
    }
    public static 
    func parse(latin1 data:[UInt8]) throws -> Self
    {
        guard let k:Int = data.firstIndex(of: 0)
        else 
        {
            throw PNG.ParsingError.missingTextEnglishKeyword
        }
        
        let keyword:String = try Self.validate(keyword: data.prefix(k))
        // if the next byte is also null, the chunk uses compression
        let uncompressed:ArraySlice<UInt8>
        let compressed:Bool 
        if k + 1 < data.endIndex, data[k + 1] == 0
        {
            var inflator:LZ77.Inflator = .init()
            guard try inflator.push(.init(data.dropFirst(k + 2))) == nil 
            else 
            {
                throw PNG.ParsingError.truncatedTextCompressedContent
            }
            uncompressed = inflator.pull()[...]
            compressed   = true
        }
        else 
        {
            uncompressed = data.dropFirst(k + 1)
            compressed   = false
        }
        return .init(compressed: compressed, 
            keyword:    (english: keyword, localized: ""), 
            language:   ["en"], 
            content:    .init(uncompressed.map 
            {
                Character.init(Unicode.Scalar.init($0))
            }))
    }
}
