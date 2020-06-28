#if PNG_4 

extension PNG 
{
    public 
    enum Standard 
    {
        case common
        case ios
    }
    
    public 
    enum Format 
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
        
        @inlinable
        public
        var hasColor:Bool
        {
            switch self 
            {
            case .rgb8, .rgb16, .indexed1, .indexed2, .indexed4, .indexed8, .rgba8, .rgba16:
                return true 
            case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
                return false 
            }
        }
        @inlinable
        public
        var depth:Int 
        {
            switch self 
            {
            case .v1,          .indexed1:                   return  1
            case .v2,          .indexed2:                   return  2
            case .v4,          .indexed4:                   return  4
            case .v8,  .rgb8,  .indexed8, .va8,  .rgba8:    return  8
            case .v16, .rgb16,            .va16, .rgba16:   return 16
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
}
extension PNG 
{
    public 
    struct Layout 
    {
        enum Scheme 
        {
            case v1
            case v2
            case v4
            case v8
            case v16
            
            case rgb8(palette:PNG.Palette?)
            case rgb16(palette:PNG.Palette?)
            
            case indexed1(palette:PNG.Palette)
            case indexed2(palette:PNG.Palette)
            case indexed4(palette:PNG.Palette)
            case indexed8(palette:PNG.Palette)
            
            case va8
            case va16
            case rgba8(palette:PNG.Palette?)
            case rgba16(palette:PNG.Palette?)
        }
        
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
    
    @inlinable
    public
    var palette:PNG.Palette?
    {
        switch self.scheme
        {
        case    .indexed1(  let palette),
                .indexed2(  let palette),
                .indexed4(  let palette),
                .indexed8(  let palette):
            return palette

        case    .rgb8(      let option),
                .rgb16(     let option),
                .rgba8(     let option),
                .rgba16(    let option):
            return option
        default:
            return nil
        }
    }
}

extension PNG 
{
    public 
    enum ParsingError:Swift.Error 
    {
        case truncatedMarkerSegmentBody(Marker, Int, expected:ClosedRange<Int>)
        case extraneousMarkerSegmentData(Marker, Int, expected:Int)
        
        case invalidHeaderColorCode(depth:UInt8, type:UInt8)
        case invalidHeaderCompressionCode(UInt8)
        case invalidHeaderFilterCode(UInt8)
        case invalidHeaderInterlacingCode(UInt8)
        case invalidHeaderSize((x:Int, y:Int))
        
        static 
        func mismatched(marker:Marker, count:Int, minimum:Int) -> Self 
        {
            .truncatedMarkerSegmentBody(marker, count, expected: minimum ... .max)
        }
        static 
        func mismatched(marker:Marker, count:Int, expected:Int) -> Self 
        {
            if count < expected 
            {
                return .truncatedMarkerSegmentBody(marker, count, expected: expected ... expected)
            }
            else 
            {
                return .extraneousMarkerSegmentData(marker, count, expected: expected)
            }
        }
    }
}
extension PNG 
{
    public 
    enum Header
    {
        public
        let size:(x:Int, y:Int), 
            format:PNG.Format, 
            interlaced:Bool
    }
}
extension PNG.Header 
{
    public static 
    func parse(_ data:[UInt8]) throws -> Self 
    {
        guard data.count == 13
        else
        {
            throw PNG.ParsingError.mismatched(chunk: .core(.header), 
                count: data.count, expected: 13)
        }
        
        guard let format:PNG.Format = .recognize(code: (data[8], data[9]))
        else
        {
            throw PNG.ParsingError.invalidHeaderColorCode(depth: data[8], type: data[9])
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

        return .init(size: size, format: format, interlaced: interlaced)
    }
}

extension PNG 
{
    public 
    struct Palette 
    {
        private 
        let storage:[RGBA<UInt8>]
    }
}
extension PNG.Palette 
{
    public static 
    func parse(_ data:[UInt8], format:PNG.Format) throws -> Self
    {
        guard format.hasColor
        else
        {
            throw PNG.ParsingError.unexpectedPalette(format)
        }

        guard data.count.isMultiple(of: 3)
        else
        {
            throw PNG.ParsingError.invalidPaletteSampleCount(data.count)
        }

        // check number of palette entries
        let maxEntries:Int = 1 << format.depth
        guard data.count  <= 3 * maxEntries 
        else
        {
            throw DecodingError.invalidPaletteEntryCount(data.count / 3, expected: maxEntries)
        }

        return stride(from: data.startIndex, to: data.endIndex, by: 3).map
        {
            let r:UInt8 = data[$0    ],
                g:UInt8 = data[$0 + 1],
                b:UInt8 = data[$0 + 2]
            return .init(r, g, b)
        }
    }
}

#endif
