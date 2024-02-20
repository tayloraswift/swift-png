extension PNG
{
    /// A parsing error.
    public
    enum ParsingError
    {
        /// An ``Chunk/IHDR`` chunk had the wrong length.
        ///
        /// Header chunks should be exactly `13` bytes long.
        /// -   Parameter _:
        ///     The chunk length.
        case invalidHeaderChunkLength(Int)

        /// An ``Chunk/IHDR`` chunk had an invalid pixel format code.
        /// -   Parameter _:
        ///     The invalid pixel format code.
        case invalidHeaderPixelFormatCode((UInt8, UInt8))

        /// An ``Chunk/IHDR`` chunk specified a pixel format that is disallowed
        /// according to the PNG standard used by the image.
        ///
        /// This error gets thrown when an iphone-optimized image
        /// (``Standard/ios``) has a pixel format that is not
        /// ``Format.Pixel/rgb8`` or ``Format.Pixel/rgba8``.
        /// -   Parameter _:
        ///     The invalid pixel format.
        /// -   Parameter standard:
        ///     The PNG standard. This error is only relevant for iphone-optimized
        ///     images, so library-generated instances of this error case always have
        ///     this field set to ``Standard/ios``.
        case invalidHeaderPixelFormat(PNG.Format.Pixel, standard:PNG.Standard)

        /// An ``Chunk/IHDR`` chunk had an invalid compression method code.
        ///
        /// The compression method code should always be `0`.
        /// -   Parameter _:
        ///     The invalid compression method code.
        case invalidHeaderCompressionMethodCode(UInt8)

        /// An ``Chunk/IHDR`` chunk had an invalid filter code.
        ///
        /// The filter code should always be `0`.
        /// -   Parameter _:
        ///     The invalid filter code.
        case invalidHeaderFilterCode(UInt8)

        /// An ``Chunk/IHDR`` chunk had an invalid interlacing code.
        ///
        /// The interlacing code should be either `0` or `1`.
        /// -   Parameter _:
        ///     The invalid interlacing code.
        case invalidHeaderInterlacingCode(UInt8)

        /// An ``Chunk/IHDR`` chunk specified an invalid image size.
        ///
        /// Both size dimensions must be strictly positive.
        /// -   Parameter _:
        ///     The invalid size.
        case invalidHeaderSize((x:Int, y:Int))


        /// The parser encountered a ``Chunk/PLTE`` chunk in an image
        /// with a pixel format that forbids it.
        /// -   Parameter pixel:
        ///     The image pixel format.
        case unexpectedPalette(pixel:PNG.Format.Pixel)

        /// A ``Chunk/PLTE`` chunk had a length that is not divisible by `3`.
        /// -   Parameter _:
        ///     The chunk length.
        case invalidPaletteChunkLength(Int)

        /// A ``Chunk/PLTE`` chunk contained more entries than allowed.
        /// -   Parameter _:
        ///     The number of palette entries.
        /// -   Parameter max:
        ///     The maximum allowed number of palette entries, according to the
        ///     image bit depth.
        case invalidPaletteCount(Int, max:Int)

        /// The parser encountered a ``Chunk/tRNS`` chunk in an image
        /// with a pixel format that forbids it.
        /// -   Parameter pixel:
        ///     The image pixel format.
        case unexpectedTransparency(pixel:PNG.Format.Pixel)

        /// A ``Chunk/tRNS`` chunk had the wrong length.
        /// -   Parameter _:
        ///     The chunk length.
        /// -   Parameter expected:
        ///     The expected chunk length.
        case invalidTransparencyChunkLength(Int, expected:Int)

        /// A ``Chunk/tRNS`` chunk contained an invalid chroma key sample.
        /// -   Parameter _:
        ///     The value of the invalid chroma key sample.
        /// -   Parameter max:
        ///     The maximum allowed value for a chroma key sample, according to the
        ///     image color depth.
        case invalidTransparencySample(UInt16, max:UInt16)

        /// A ``Chunk/tRNS`` chunk contained too many alpha samples.
        /// -   Parameter _:
        ///     The number of alpha samples present.
        /// -   Parameter max:
        ///     The maximum allowed number of alpha samples, which is equal to
        ///     the number of entries in the image palette.
        case invalidTransparencyCount(Int, max:Int)


        /// A ``Chunk/bKGD`` chunk had the wrong length.
        /// -   Parameter _:
        ///     The chunk length.
        /// -   Parameter expected:
        ///     The expected chunk length.
        case invalidBackgroundChunkLength(Int, expected:Int)

        /// A ``Chunk/bKGD`` chunk contained an invalid background sample.
        /// -   Parameter _:
        ///     The value of the invalid background sample.
        /// -   Parameter max:
        ///     The maximum allowed value for a background sample, according to the
        ///     image color depth.
        case invalidBackgroundSample(UInt16, max:UInt16)

        /// A ``Chunk/bKGD`` chunk specified an out-of-range palette index.
        /// -   Parameter _:
        ///     The invalid index.
        /// -   Parameter max:
        ///     The maximum allowed index value, which is equal to one less than
        ///     the number of entries in the image palette.
        case invalidBackgroundIndex(Int, max:Int)

        /// A ``Chunk/hIST`` chunk had the wrong length.
        /// -   Parameter _:
        ///     The chunk length.
        /// -   Parameter expected:
        ///     The expected chunk length.
        case invalidHistogramChunkLength(Int, expected:Int)

        /// A ``Chunk/gAMA`` chunk had the wrong length.
        ///
        /// Gamma chunks should be exactly `4` bytes long.
        /// -   Parameter _:
        ///     The chunk length.
        case invalidGammaChunkLength(Int)

        /// A ``Chunk/cHRM`` chunk had the wrong length.
        ///
        /// Chromaticity chunks should be exactly `32` bytes long.
        /// -   Parameter _:
        ///     The chunk length.
        case invalidChromaticityChunkLength(Int)

        /// An ``Chunk/sRGB`` chunk had the wrong length.
        ///
        /// Color rendering chunks should be exactly `1` byte long.
        /// -   Parameter _:
        ///     The chunk length.
        case invalidColorRenderingChunkLength(Int)

        /// An ``Chunk/sRGB`` chunk had an invalid color rendering code.
        ///
        /// The color rendering code should be one of `0`, `1`, `2`, or `3`.
        /// -   Parameter _:
        ///     The invalid color rendering code.
        case invalidColorRenderingCode(UInt8)

        /// An ``Chunk/sBIT`` chunk had the wrong length.
        /// -   Parameter _:
        ///     The chunk length.
        /// -   Parameter expected:
        ///     The expected chunk length.
        case invalidSignificantBitsChunkLength(Int, expected:Int)

        /// An ``Chunk/sBIT`` chunk specified an invalid precision value.
        /// -   Parameter _:
        ///     The invalid precision value.
        /// -   Parameter max:
        ///     The maximum allowed precision value, which is equal to the image
        ///     color depth.
        case invalidSignificantBitsPrecision(Int, max:Int)

        /// An ``Chunk/iCCP`` chunk had an invalid length.
        /// -   Parameter _:
        ///     The chunk length.
        /// -   Parameter min:
        ///     The minimum expected chunk length.
        case invalidColorProfileChunkLength(Int, min:Int)

        /// An ``Chunk/iCCP`` chunk had an invalid profile name.
        /// -   Parameter _:
        ///     The invalid profile name, or `nil` if the parser could not find
        ///     the null-terminator of the profile name string.
        case invalidColorProfileName(String?)

        /// An ``Chunk/iCCP`` chunk had an invalid compression method code.
        ///
        /// The compression method code should always be `0`.
        /// -   Parameter _:
        ///     The invalid compression method code.
        case invalidColorProfileCompressionMethodCode(UInt8)

        /// The compressed data stream in an ``Chunk/iCCP`` chunk was not
        /// properly terminated.
        case incompleteColorProfileCompressedDatastream

        /// A ``Chunk/pHYs`` chunk had the wrong length.
        ///
        /// Physical dimensions chunks should be exactly `9` bytes long.
        /// -   Parameter _:
        ///     The chunk length.
        case invalidPhysicalDimensionsChunkLength(Int)

        /// A ``Chunk/pHYs`` chunk had an invalid density unit code.
        ///
        /// The density code should be either `0` or `1`.
        /// -   Parameter _:
        ///     The invalid density unit code.
        case invalidPhysicalDimensionsDensityUnitCode(UInt8)

        /// An ``Chunk/sPLT`` chunk had an invalid length.
        /// -   Parameter _:
        ///     The chunk length.
        /// -   Parameter min:
        ///     The minimum expected chunk length.
        case invalidSuggestedPaletteChunkLength(Int, min:Int)

        /// An ``Chunk/sPLT`` chunk had an invalid palette name.
        /// -   Parameter _:
        ///     The invalid palette name, or `nil` if the parser could not find
        ///     the null-terminator of the palette name string.
        case invalidSuggestedPaletteName(String?)

        /// The length of the palette data in an ``Chunk/sPLT`` chunk was
        /// not divisible by its expected stride.
        /// -   Parameter _:
        ///     The length of the palette data.
        /// -   Parameter stride:
        ///     The expected stride of the palette entries.
        case invalidSuggestedPaletteDataLength(Int, stride:Int)

        /// An ``Chunk/sPLT`` chunk had an invalid depth code.
        ///
        /// The depth code should be either `8` or `16`.
        /// -   Parameter _:
        ///     The invalid depth code.
        case invalidSuggestedPaletteDepthCode(UInt8)

        /// The entries in an ``Chunk/sPLT`` chunk were not ordered by
        /// descending frequency.
        case invalidSuggestedPaletteFrequency

        /// A ``Chunk/tIME`` chunk had the wrong length.
        ///
        /// Time modified chunks should be exactly `7` bytes long.
        /// -   Parameter _:
        ///     The chunk length.
        case invalidTimeModifiedChunkLength(Int)

        /// A ``Chunk/tIME`` chunk specified an invalid timestamp.
        /// -   Parameter year:
        ///     The specified year.
        /// -   Parameter month:
        ///     The specified month.
        /// -   Parameter day:
        ///     The specified day.
        /// -   Parameter hour:
        ///     The specified hour.
        /// -   Parameter minute:
        ///     The specified minute.
        /// -   Parameter second:
        ///     The specified second.
        case invalidTimeModifiedTime(year:Int, month:Int, day:Int, hour:Int, minute:Int, second:Int)

        /// A ``Chunk/tEXt``, ``Chunk/zTXt``, or ``Chunk/iTXt`` chunk
        /// had an invalid english keyword.
        /// -   Parameter _:
        ///     The invalid english keyword, or `nil` if the parser could not find
        ///     the null-terminator of the keyword string.
        case invalidTextEnglishKeyword(String?)

        /// A ``Chunk/tEXt``, ``Chunk/zTXt``, or ``Chunk/iTXt`` chunk
        /// had an invalid length.
        /// -   Parameter _:
        ///     The chunk length.
        /// -   Parameter min:
        ///     The minimum expected chunk length.
        case invalidTextChunkLength(Int, min:Int)

        /// An ``Chunk/iTXt`` chunk had an invalid compression code.
        ///
        /// The compression code should be either `0` or `1`.
        /// -   Parameter _:
        ///     The invalid compression code.
        case invalidTextCompressionCode(UInt8)

        /// A ``Chunk/zTXt`` or ``Chunk/iTXt`` chunk had an invalid
        /// compression method code.
        ///
        /// The compression method code should always be `0`.
        /// -   Parameter _:
        ///     The invalid compression method code.
        case invalidTextCompressionMethodCode(UInt8)

        /// An ``Chunk/iTXt`` chunk had an invalid language tag.
        /// -   Parameter _:
        ///     The invalid language tag component, or `nil` if the parser could
        ///     not find the null-terminator of the language tag string.
        ///     The language tag component is not the entire language tag string.
        case invalidTextLanguageTag(String?)

        /// The parser could not find the null-terminator of the localized
        /// keyword string in an ``Chunk/iTXt`` chunk.
        case invalidTextLocalizedKeyword

        /// The compressed data stream in a ``Chunk/zTXt`` or ``Chunk/iTXt``
        /// chunk was not properly terminated.
        case incompleteTextCompressedDatastream
    }
}
extension PNG.ParsingError:PNG.Error
{
    /// The string `"parsing error"`.
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
                .invalidHeaderCompressionMethodCode,
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
        case    .invalidBackgroundChunkLength,
                .invalidBackgroundSample,
                .invalidBackgroundIndex:
            return PNG.Background.self
        case    .invalidHistogramChunkLength:
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
                .incompleteColorProfileCompressedDatastream:
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
                .incompleteTextCompressedDatastream:
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
                .invalidHeaderCompressionMethodCode,
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
                .unexpectedTransparency:
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

        case    .incompleteColorProfileCompressedDatastream,
                .incompleteTextCompressedDatastream:
            text = "content field does not contain a full compressed data stream"
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
        case    .invalidTextCompressionCode(let code):
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
        case    .invalidHeaderCompressionMethodCode(let code),
                .invalidColorProfileCompressionMethodCode(let code),
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

        case    .invalidBackgroundSample(let sample, max: let max):
            return "background sample (\(sample)) must be in the range 0 ... \(max)"
        case    .invalidBackgroundIndex(let index, max: let max):
            return "background index (\(index)) is out of range for palette of length \(max + 1)"

        case    .invalidSignificantBitsPrecision(let precision, max: let max):
            return "precision (\(precision)) must be in the range 1 ... \(max)"



        case    .incompleteColorProfileCompressedDatastream,
                .incompleteTextCompressedDatastream:
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
