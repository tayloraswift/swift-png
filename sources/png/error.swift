public 
protocol _PNGError:Error 
{
    static 
    var namespace:String
    {
        get 
    }
    var message:String 
    {
        get 
    }
    var details:String? 
    {
        get 
    }
}
extension PNG.Error 
{
    var fatal:Never 
    {
        fatalError("\(self)")
    }
}

extension PNG 
{
    public 
    typealias Error = _PNGError 
}
extension PNG 
{
    public 
    enum LexingError
    {
        case truncatedSignature
        case invalidSignature([UInt8])
        case truncatedChunkHeader 
        case truncatedChunkBody(expected:Int)
        case invalidChunkTypeCode(UInt32)
        case invalidChunkChecksum(declared:UInt32, computed:UInt32)
    }
    
    public 
    enum FormattingError
    {
        case invalidDestination
    }
    
    public 
    enum ParsingError
    {
        case invalidHeaderChunkLength(Int)
        case invalidHeaderPixelFormatCode((UInt8, UInt8))
        case invalidHeaderPixelFormat(PNG.Format.Pixel, standard:PNG.Standard)
        case invalidHeaderCompressionCode(UInt8)
        case invalidHeaderFilterCode(UInt8)
        case invalidHeaderInterlacingCode(UInt8)
        case invalidHeaderSize((x:Int, y:Int))
        
        case unexpectedPalette(pixel:PNG.Format.Pixel)
        case invalidPaletteChunkLength(Int)
        case invalidPaletteCount(Int, max:Int)
        
        case unexpectedTransparency(pixel:PNG.Format.Pixel)
        case invalidTransparencyChunkLength(Int, expected:Int)
        case invalidTransparencySample(UInt16, max:UInt16)
        case invalidTransparencyCount(Int, max:Int)
        
        case unexpectedBackground(pixel:PNG.Format.Pixel)
        case invalidBackgroundChunkLength(Int, expected:Int)
        case invalidBackgroundSample(UInt16, max:UInt16)
        case invalidBackgroundIndex(Int, max:Int)
        
        case unexpectedHistogram(pixel:PNG.Format.Pixel)
        case invalidHistogramChunkLength(Int, expected:Int)
        
        case invalidGammaChunkLength(Int)
        
        case invalidChromaticityChunkLength(Int)
        
        case invalidColorRenderingChunkLength(Int)
        case invalidColorRenderingCode(UInt8)
        
        case invalidSignificantBitsChunkLength(Int, expected:Int)
        case invalidSignificantBitsPrecision(Int, max:Int)
        
        case invalidColorProfileChunkLength(Int, min:Int) 
        case invalidColorProfileName(String?) 
        case invalidColorProfileCompressionMethodCode(UInt8)
        case incompleteColorProfileCompressedBytestream
        
        case invalidPhysicalDimensionsChunkLength(Int)
        case invalidPhysicalDimensionsDensityUnitCode(UInt8)
        
        case invalidSuggestedPaletteChunkLength(Int, min:Int)
        case invalidSuggestedPaletteName(String?)
        case invalidSuggestedPaletteDataLength(Int, stride:Int)
        case invalidSuggestedPaletteDepthCode(UInt8)
        case invalidSuggestedPaletteFrequency
        
        case invalidTimeModifiedChunkLength(Int)
        case invalidTimeModifiedTime(year:Int, month:Int, day:Int, hour:Int, minute:Int, second:Int)
        
        case invalidTextEnglishKeyword(String?)
        case invalidTextChunkLength(Int, min:Int)
        case invalidTextCompressionCode(UInt8)
        case invalidTextCompressionMethodCode(UInt8)
        case invalidTextLanguageTag(String?)
        case invalidTextLocalizedKeyword
        case incompleteTextCompressedBytestream
    }
    
    public 
    enum DecodingError
    {
        case missingImageHeader
        case missingPalette
        case missingImageData
        
        case incompleteImageDataCompressedBytestream
        case extraneousImageDataCompressedBytes
        case extraneousImageData
        
        case duplicateChunk(PNG.Chunk)
        case invalidChunkOrder(PNG.Chunk, after:PNG.Chunk)
    }
}
extension LZ77 
{
    public 
    enum DecompressionError
    {
        // stream errors
        case invalidStreamCompressionMethodCode(UInt8)
        case invalidStreamWindowSize(exponent:Int)
        case invalidStreamHeaderCheckBits
        case unexpectedStreamDictionary
        case invalidStreamChecksum(declared:UInt32, computed:UInt32)
        // block errors 
        case invalidBlockTypeCode(UInt8)
        case invalidBlockElementCountParity(UInt16, UInt16)
        case invalidHuffmanRunLiteralSymbolCount(Int)
        case invalidHuffmanCodelengthHuffmanTable
        case invalidHuffmanCodelengthSequence
        case invalidHuffmanTable
        
        case invalidStringReference
    }
}

extension PNG.LexingError:PNG.Error 
{
    public static 
    var namespace:String 
    {
        "lexing error"
    }
    
    public 
    var message:String 
    {
        switch self 
        {
        case .invalidSignature: 
            return "invalid png signature bytes"
        case .truncatedSignature: 
            return "failed to read png signature bytes from source bytestream"
        case .truncatedChunkHeader:
            return "failed to read chunk header from source bytestream"
        case .truncatedChunkBody:
            return "failed to read chunk body from source bytestream"
        case .invalidChunkTypeCode:
            return "invalid chunk type code"
        case .invalidChunkChecksum:
            return "invalid chunk checksum"
        }
    }
    
    public 
    var details:String?
    {
        switch self 
        {
        case .invalidSignature(let declared): 
            return "signature \(declared) does not match expected png signature \(PNG.signature)"
        case .truncatedSignature, .truncatedChunkHeader, .truncatedChunkBody:
            return nil
        case .invalidChunkTypeCode(let name):
            let string:String = withUnsafeBytes(of: name.bigEndian) 
            {
                .init(decoding: $0, as: Unicode.ASCII.self)
            }
            return "type specifier '\(string)' is not a valid chunk type"
        case .invalidChunkChecksum(declared: let declared, computed: let computed):
            return "computed crc-32 checksum (\(computed)) does not match declared checksum (\(declared))"
        }
    }
}
extension PNG.FormattingError:PNG.Error 
{
    public static 
    var namespace:String 
    {
        "formatting error"
    }
    
    public 
    var message:String 
    {
        switch self 
        {
        case .invalidDestination: 
            return "failed to write to destination bytestream"
        }
    }
    
    public 
    var details:String?
    {
        switch self 
        {
        case .invalidDestination:
            return nil
        }
    }
}
extension PNG.ParsingError:PNG.Error 
{
    public static 
    var namespace:String 
    {
        "parsing error"
    }
    
    private 
    var scope:Any.Type 
    {
        switch self 
        {
        case    .invalidHeaderChunkLength,
                .invalidHeaderPixelFormatCode,
                .invalidHeaderPixelFormat,
                .invalidHeaderCompressionCode,
                .invalidHeaderFilterCode,
                .invalidHeaderInterlacingCode,
                .invalidHeaderSize:
            return PNG.Header.self
        case    .unexpectedPalette,
                .invalidPaletteChunkLength,
                .invalidPaletteCount:
            return PNG.Palette.self
        case    .unexpectedTransparency,
                .invalidTransparencyChunkLength,
                .invalidTransparencySample,
                .invalidTransparencyCount:
            return PNG.Transparency.self 
        case    .unexpectedBackground,
                .invalidBackgroundChunkLength,
                .invalidBackgroundSample,
                .invalidBackgroundIndex:
            return PNG.Background.self 
        case    .unexpectedHistogram,
                .invalidHistogramChunkLength:
            return PNG.Histogram.self 
        case    .invalidGammaChunkLength:
            return PNG.Gamma.self 
        case    .invalidChromaticityChunkLength:
            return PNG.Chromaticity.self 
        case    .invalidColorRenderingChunkLength,
                .invalidColorRenderingCode:
            return PNG.ColorRendering.self 
        case    .invalidSignificantBitsChunkLength,
                .invalidSignificantBitsPrecision:
            return PNG.SignificantBits.self 
        case    .invalidColorProfileChunkLength,
                .invalidColorProfileName,
                .invalidColorProfileCompressionMethodCode,
                .incompleteColorProfileCompressedBytestream:
            return PNG.ColorProfile.self 
        case    .invalidPhysicalDimensionsChunkLength,
                .invalidPhysicalDimensionsDensityUnitCode:
            return PNG.PhysicalDimensions.self 
        case    .invalidSuggestedPaletteChunkLength,
                .invalidSuggestedPaletteDataLength,
                .invalidSuggestedPaletteName,
                .invalidSuggestedPaletteFrequency,
                .invalidSuggestedPaletteDepthCode:
            return PNG.SuggestedPalette.self 
        case    .invalidTimeModifiedChunkLength,
                .invalidTimeModifiedTime:
            return PNG.TimeModified.self 
        case    .invalidTextChunkLength,
                .invalidTextEnglishKeyword,
                .invalidTextCompressionCode,
                .invalidTextCompressionMethodCode,
                .invalidTextLanguageTag,
                .invalidTextLocalizedKeyword,
                .incompleteTextCompressedBytestream:
            return PNG.Text.self
        }
    }
    public 
    var message:String 
    {
        let text:String
        switch self 
        {
        case    .invalidHeaderChunkLength,
                .invalidPaletteChunkLength,
                .invalidTransparencyChunkLength,
                .invalidBackgroundChunkLength,
                .invalidHistogramChunkLength,
                .invalidGammaChunkLength,
                .invalidChromaticityChunkLength,
                .invalidColorRenderingChunkLength,
                .invalidColorProfileChunkLength,
                .invalidSignificantBitsChunkLength,
                .invalidPhysicalDimensionsChunkLength,
                .invalidSuggestedPaletteChunkLength,
                .invalidSuggestedPaletteDataLength,
                .invalidTimeModifiedChunkLength, 
                .invalidTextChunkLength:
            text = "invalid chunk length"
        
        case    .invalidHeaderPixelFormatCode,
                .invalidHeaderCompressionCode,
                .invalidHeaderFilterCode,
                .invalidHeaderInterlacingCode,
                .invalidColorRenderingCode,
                .invalidPhysicalDimensionsDensityUnitCode, 
                .invalidColorProfileCompressionMethodCode,
                .invalidSuggestedPaletteDepthCode,
                .invalidTextCompressionMethodCode,
                .invalidTextCompressionCode:
            text = "invalid flag code"
        
        case    .invalidHeaderPixelFormat:
            text = "invalid pixel format"
        case    .invalidHeaderSize:
            text = "invalid image size"
        
        case    .unexpectedPalette,
                .unexpectedTransparency,
                .unexpectedBackground,
                .unexpectedHistogram:
            text = "unexpected chunk"
        
        case    .invalidPaletteCount,
                .invalidTransparencyCount:
            text = "invalid count"
        
        case    .invalidTransparencySample,
                .invalidBackgroundSample:
            text = "invalid sample"
        case    .invalidBackgroundIndex:
            text = "invalid index"
        
        case    .invalidSignificantBitsPrecision:
            text = "invalid precision"
        
        case    .invalidColorProfileName,
                .invalidSuggestedPaletteName:
            text = "invalid name"
        
        case    .invalidSuggestedPaletteFrequency:
            text = "invalid frequency"
        
        case    .incompleteColorProfileCompressedBytestream,
                .incompleteTextCompressedBytestream:
            text = "compressed bytestream is incomplete"
        case    .invalidTimeModifiedTime:
            text = "invalid time"
        case    .invalidTextEnglishKeyword, 
                .invalidTextLocalizedKeyword:
            text = "invalid keyword"
        case    .invalidTextLanguageTag: 
            text = "invalid language tag"
        }
        
        return "(\(self.scope)) \(text)"
    }
    
    public 
    var details:String? 
    {
        func plural(bytes count:Int) -> String 
        {
            count == 1 ? "1 byte" : "\(count) bytes"
        }
        
        switch self 
        {
        case    .invalidHeaderChunkLength           (let bytes):
            return "chunk is \(plural(bytes: bytes)), expected 13 bytes"
        case    .invalidPaletteChunkLength          (let bytes):
            return "chunk length (\(bytes)) must be divisible by 3"
        case    .invalidTransparencyChunkLength     (let bytes, expected: let expected),
                .invalidBackgroundChunkLength       (let bytes, expected: let expected),
                .invalidHistogramChunkLength        (let bytes, expected: let expected),
                .invalidSignificantBitsChunkLength  (let bytes, expected: let expected):
            return "chunk is \(plural(bytes: bytes)), expected \(plural(bytes: expected))"
        case    .invalidGammaChunkLength            (let bytes):
            return "chunk is \(plural(bytes: bytes)), expected 4 bytes"
        case    .invalidChromaticityChunkLength     (let bytes):
            return "chunk is \(plural(bytes: bytes)), expected 32 bytes"
        case    .invalidColorRenderingChunkLength   (let bytes):
            return "chunk is \(plural(bytes: bytes)), expected 1 byte"
        case    .invalidPhysicalDimensionsChunkLength(let bytes):
            return "chunk is \(plural(bytes: bytes)), expected 9 bytes"
        case    .invalidTimeModifiedChunkLength     (let bytes):
            return "chunk is \(plural(bytes: bytes)), expected 7 bytes"
        
        case    .invalidColorProfileChunkLength     (let bytes, min: let min),
                .invalidSuggestedPaletteChunkLength (let bytes, min: let min),
                .invalidTextChunkLength             (let bytes, min: let min):
            return "chunk is \(plural(bytes: bytes)), expected at least \(plural(bytes: min))"
        
        case .invalidSuggestedPaletteDataLength(let bytes, stride: let stride):
            return "palette data length (\(plural(bytes: bytes))) must be divisible by \(stride)"
        
        case    .invalidHeaderPixelFormatCode(let code):
            return "\(code) is not a valid pixel format code"
        case    .invalidHeaderPixelFormat(let pixel, standard: let standard):
            return "`\(pixel)` is not a valid pixel format under the png standard `\(standard)`"
        case    .invalidHeaderCompressionCode(let code), 
                .invalidTextCompressionCode(let code):
            return "(\(code)) is not a valid compression code"
        case    .invalidHeaderFilterCode(let code):
            return "(\(code)) is not a valid filter code"
        case    .invalidHeaderInterlacingCode(let code):
            return "(\(code)) is not a valid interlacing code"
        case    .invalidColorRenderingCode(let code):
            return "(\(code)) is not a valid color rendering code"
        case    .invalidPhysicalDimensionsDensityUnitCode(let code):
            return "(\(code)) is not a valid density unit code"
        case    .invalidSuggestedPaletteDepthCode(let code):
            return "(\(code)) is not a valid suggested palette depth code"
        case    .invalidColorProfileCompressionMethodCode(let code),
                .invalidTextCompressionMethodCode(let code):
            return "(\(code)) is not a valid compression method code"
        
        case    .invalidHeaderSize(let size):
            return "image dimensions \(size) must be greater than 0"
        
        case    .unexpectedPalette(pixel: let pixel):
            return "palette not allowed for pixel format `\(pixel)`"
        case    .invalidPaletteCount(let count, max: let max):
            return "number of palette entries (\(count)) must be in the range 1 ... \(max)"
        
        case    .unexpectedTransparency(pixel: let pixel):
            switch pixel 
            {
            case .indexed1, .indexed2, .indexed4, .indexed8: 
                return "transparency for pixel format `\(pixel)` requires a previously-defined image palette"
            default:
                return "transparency not allowed for pixel format `\(pixel)`"
            }
        case    .invalidTransparencySample(let sample, max: let max):
            return "chroma key sample (\(sample)) must be in the range 0 ... \(max)"
        case    .invalidTransparencyCount(let count, max: let max):
            return "number of alpha samples (\(count)) exceeds number of palette entries (\(max))"
        
        case    .unexpectedBackground(pixel: let pixel): 
            return "background for pixel format `\(pixel)` requires a previously-defined image palette"
        case    .invalidBackgroundSample(let sample, max: let max):
            return "background sample (\(sample)) must be in the range 0 ... \(max)"
        case    .invalidBackgroundIndex(let index, max: let max):
            return "background index (\(index)) is out of range for palette of length \(max + 1)"
        
        case    .unexpectedHistogram(pixel: let pixel):
            return "histogram not allowed for pixel format `\(pixel)`"
        
        case    .invalidSignificantBitsPrecision(let precision, max: let max):
            return "precision (\(precision)) must be in the range 1 ... \(max)"
        

        
        case    .incompleteColorProfileCompressedBytestream, 
                .incompleteTextCompressedBytestream:
            return nil

        case    .invalidSuggestedPaletteFrequency:
            return "frequency values must appear in descending order"

        case    .invalidTimeModifiedTime(
            year:   let year, 
            month:  let month, 
            day:    let day, 
            hour:   let hour, 
            minute: let minute, 
            second: let second):
            return "\((year: year, month: month, day: day, hour: hour, minute: minute, second: second)) is not a valid time stamp"

        case    .invalidColorProfileName(nil):
            return "color profile name must be a null-terminated string"
        case    .invalidSuggestedPaletteName(nil):
            return "suggested palette name must be a null-terminated string"
        case    .invalidTextEnglishKeyword(nil):
            return "english keyword must be a null-terminated string"
        case    .invalidTextLanguageTag(nil):
            return "language specifier must be a null-terminated string"
        case    .invalidTextLocalizedKeyword:
            return "localized keyword must be a null-terminated string"
                
                
        case    .invalidColorProfileName(let name?):
            return "color profile name '\(name)' is not a valid name"
        case    .invalidSuggestedPaletteName(let name?):
            return "suggested palette name '\(name)' is not a valid name"
        case    .invalidTextEnglishKeyword(let name?):
            return "english keyword '\(name)' is not a valid keyword"
        case    .invalidTextLanguageTag(let tag?):
            return "language tag '\(tag)' is not a valid language tag"
        }
    }
}
extension PNG.DecodingError:PNG.Error 
{
    public static 
    var namespace:String 
    {
        "decoding error"
    }
    
    public 
    var message:String 
    {
        switch self 
        {
        case .missingImageHeader:
            return "missing image header"
        case .missingPalette:
            return "missing image palette"
        case .missingImageData:
            return "missing image data"
        case .incompleteImageDataCompressedBytestream:
            return "compressed image data bytestream is incomplete"
        case .extraneousImageDataCompressedBytes:
            return "unexpected data after end of compressed image data bytestream"
        case .extraneousImageData:
            return "uncompressed image data bytestream contains more data than expected"
        case .duplicateChunk:
            return "duplicate chunk"
        case .invalidChunkOrder:
            return "invalid chunk ordering"
        }
    }
    
    public 
    var details:String? 
    {
        switch self 
        {
        case    .missingImageHeader,
                .missingPalette,
                .missingImageData,
                .incompleteImageDataCompressedBytestream,
                .extraneousImageDataCompressedBytes,
                .extraneousImageData:
            return nil
        case .duplicateChunk(let chunk):
            return "chunk of type '\(chunk)' can only appear once"
        case .invalidChunkOrder(.IDAT, after: .IDAT):
            return "chunks of type 'IDAT' must be contiguous"
        case .invalidChunkOrder(let chunk, after: let previous):
            return "chunk of type '\(chunk)' cannot appear after chunk of type '\(previous)'"
        }
    }
}
extension LZ77.DecompressionError:PNG.Error 
{
    public static 
    var namespace:String 
    {
        "inflate error"
    }
    
    public 
    var message:String 
    {
        switch self 
        {
        case .invalidStreamCompressionMethodCode:
            return "invalid rfc-1950 stream compression method code"
        case .invalidStreamWindowSize:
            return "invalid rfc-1950 stream window size"
        case .invalidStreamHeaderCheckBits:
            return "invalid rfc-1950 stream header check bits"
        case .unexpectedStreamDictionary:
            return "unexpected rfc-1950 stream dictionary"
        case .invalidStreamChecksum:
            return "invalid rfc-1950 checksum"
        case .invalidBlockTypeCode:
            return "invalid rfc-1951 block type code"
        case .invalidBlockElementCountParity:
            return "invalid rfc-1951 block element count parity"
        case .invalidHuffmanRunLiteralSymbolCount:
            return "invalid rfc-1951 run-literal huffman symbol count"
        case .invalidHuffmanCodelengthHuffmanTable:
            return "invalid rfc-1951 codelength huffman table"
        case .invalidHuffmanCodelengthSequence:
            return "invalid rfc-1951 codelength sequence"
        case .invalidHuffmanTable:
            return "invalid rfc-1951 run-literal/distance huffman table"
        case .invalidStringReference:
            return "invalid rfc-1951 string reference"
        }
    }
    
    public 
    var details:String? 
    {
        switch self 
        {
        case    .invalidStreamCompressionMethodCode(let code):
            return "(\(code)) is not a valid compression method code"
        case    .invalidStreamWindowSize(exponent: let exponent):
            return "base-2 log of stream window size (\(exponent)) must be in the range 8 ... 15"
        case    .invalidStreamHeaderCheckBits,
                .unexpectedStreamDictionary,
                .invalidHuffmanCodelengthHuffmanTable,
                .invalidHuffmanCodelengthSequence,
                .invalidHuffmanTable,
                .invalidStringReference:
            return nil
        case    .invalidStreamChecksum(declared: let declared, computed: let computed):
            return "computed mrc-32 checksum (\(computed)) does not match declared checksum (\(declared))"
        case    .invalidBlockTypeCode(let code):
            return "(\(code)) is not a valid block type code"
        case    .invalidBlockElementCountParity(let l, let m):
            return "inverted block element count (\(String.init(~l, radix: 2))) does not match declared parity bits (\(String.init(m, radix: 2)))"
        case    .invalidHuffmanRunLiteralSymbolCount(let count):
            return "run-literal symbol count (\(count)) must be in the range 257 ... 286"
        }
    }
}
