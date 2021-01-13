/// protocol PNG.Error 
/// :   Swift.Error 
///     Functionality common to all library error types.
/// # [Propogating errors](error-propogation)
/// # [See also](error-handling)
/// ## (error-handling)
public 
protocol _PNGError:Error 
{
    /// static var PNG.Error.namespace : Swift.String { get }
    /// required 
    ///     A human-readable namespace for this error type.
    static 
    var namespace:String
    {
        get 
    }
    /// var PNG.Error.message : Swift.String { get }
    /// required 
    ///     A human-readable summary of this error.
    /// ## ()
    var message:String 
    {
        get 
    }
    /// var PNG.Error.details : Swift.String? { get }
    /// required 
    ///     An optional human-readable string providing additional details 
    ///     about this error.
    /// ## ()
    var details:String? 
    {
        get 
    }
}
extension PNG.Error 
{
    /// var PNG.Error.fatal : Swift.Never 
    ///     Halts execution by converting this error into a fatal error.
    /// ## (error-propogation)
    public 
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
    /// enum PNG.LexingError 
    /// :   Error 
    ///     A lexing error.
    /// # [See also](error-handling)
    /// ## (error-handling)
    public 
    enum LexingError
    {
        /// case PNG.LexingError.truncatedSignature 
        ///     The lexer encountered end-of-stream while reading signature 
        ///     bytes from a bytestream.
        case truncatedSignature
        /// case PNG.LexingError.invalidSignature(_:)
        ///     The signature bytes read by the lexer did not match the expected 
        ///     sequence. 
        /// 
        ///     The expected byte sequence is `[137, 80, 78, 71, 13, 10, 26, 10]`.
        /// - _ : [Swift.UInt8]
        ///     The invalid signature bytes. 
        case invalidSignature([UInt8])
        /// case PNG.LexingError.truncatedChunkHeader
        ///     The lexer encountered end-of-stream while reading a chunk header 
        ///     from a bytestream.
        case truncatedChunkHeader 
        /// case PNG.LexingError.truncatedChunkBody(expected:)
        ///     The lexer encountered end-of-stream while reading a chunk body 
        ///     from a bytestream.
        /// - expected : Swift.Int 
        ///     The number of bytes the lexer expected to read.
        case truncatedChunkBody(expected:Int)
        /// case PNG.LexingError.invalidChunkTypeCode(_:)
        ///     The lexer read a chunk with an invalid type identifier code. 
        /// - _ : Swift.UInt32 
        ///     The invalid type identifier code.
        case invalidChunkTypeCode(UInt32)
        /// case PNG.LexingError.invalidChunkChecksum(declared:computed:)
        ///     The chunk checksum computed by the lexer did not match the 
        ///     checksum declared in the chunk footer. 
        /// - declared : Swift.UInt32 
        ///     The checksum declared in the chunk footer.
        /// - computed : Swift.UInt32 
        ///     The checksum computed by the lexer.
        case invalidChunkChecksum(declared:UInt32, computed:UInt32)
    }
    
    /// enum PNG.FormattingError 
    /// :   Error 
    ///     A formatting error.
    /// # [See also](error-handling)
    /// ## (error-handling)
    public 
    enum FormattingError
    {
        /// case PNG.FormattingError.invalidDestination 
        ///     The formatter failed to write to a destination bytestream.
        case invalidDestination
    }
    
    /// enum PNG.ParsingError 
    /// :   Error 
    ///     A parsing error.
    /// # [Header errors](IHDR-parsing-errors)
    /// # [Palette errors](PLTE-parsing-errors)
    /// # [Transparency errors](tRNS-parsing-errors)
    /// # [Background errors](bKGD-parsing-errors)
    /// # [Histogram errors](hIST-parsing-errors)
    /// # [Gamma errors](gAMA-parsing-errors)
    /// # [Chromaticity errors](cHRM-parsing-errors)
    /// # [Color rendering errors](sRGB-parsing-errors)
    /// # [Significant bits errors](sBIT-parsing-errors)
    /// # [Color profile errors](iCCP-parsing-errors)
    /// # [Physical dimensions errors](pHYs-parsing-errors)
    /// # [Suggested palette errors](sPLT-parsing-errors)
    /// # [Time modified errors](tIME-parsing-errors)
    /// # [Text comment errors](text-chunk-parsing-errors)
    /// # [See also](error-handling)
    /// ## (error-handling)
    public 
    enum ParsingError
    {
        /// case PNG.ParsingError.invalidHeaderChunkLength(_:)
        ///     An [`(Chunk).IHDR`] chunk had the wrong length. 
        /// 
        ///     Header chunks should be exactly `13` bytes long.
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// ## (IHDR-parsing-errors)
        
        /// case PNG.ParsingError.invalidHeaderPixelFormatCode(_:)
        ///     An [`(Chunk).IHDR`] chunk had an invalid pixel format code. 
        /// - _ : (Swift.UInt8, Swift.UInt8) 
        ///     The invalid pixel format code.
        /// ## (IHDR-parsing-errors)
        
        /// case PNG.ParsingError.invalidHeaderPixelFormat(_:standard:)
        ///     An [`(Chunk).IHDR`] chunk specified a pixel format that is disallowed 
        ///     according to the PNG standard used by the image. 
        /// 
        ///     This error gets thrown when an iphone-optimized image 
        ///     ([`(Standard).ios`]) has a pixel format that is not 
        ///     [`(Format.Pixel).rgb8`] or [`(Format.Pixel).rgba8`].
        /// - _ : Format.Pixel 
        ///     The invalid pixel format.
        /// - standard : Standard 
        ///     The PNG standard. This error is only relevant for iphone-optimized 
        ///     images, so library-generated instances of this error case always have 
        ///     this field set to [`(Standard).ios`].
        /// ## (IHDR-parsing-errors)
        
        /// case PNG.ParsingError.invalidHeaderCompressionMethodCode(_:)
        ///     An [`(Chunk).IHDR`] chunk had an invalid compression method code.
        /// 
        ///     The compression method code should always be `0`. 
        /// - _ : Swift.UInt8
        ///     The invalid compression method code.
        /// ## (IHDR-parsing-errors)
        
        /// case PNG.ParsingError.invalidHeaderFilterCode(_:)
        ///     An [`(Chunk).IHDR`] chunk had an invalid filter code.
        /// 
        ///     The filter code should always be `0`. 
        /// - _ : Swift.UInt8
        ///     The invalid filter code.
        /// ## (IHDR-parsing-errors)
        
        /// case PNG.ParsingError.invalidHeaderInterlacingCode(_:)
        ///     An [`(Chunk).IHDR`] chunk had an invalid interlacing code.
        /// 
        ///     The interlacing code should be either `0` or `1`. 
        /// - _ : Swift.UInt8
        ///     The invalid interlacing code.
        /// ## (IHDR-parsing-errors)
        
        /// case PNG.ParsingError.invalidHeaderSize(_:)
        ///     An [`(Chunk).IHDR`] chunk specified an invalid image size.
        /// 
        ///     Both size dimensions must be strictly positive.
        /// - _ : (x:Swift.Int, y:Swift.Int)
        ///     The invalid size.
        /// ## (IHDR-parsing-errors)
        case invalidHeaderChunkLength(Int)
        case invalidHeaderPixelFormatCode((UInt8, UInt8))
        case invalidHeaderPixelFormat(PNG.Format.Pixel, standard:PNG.Standard)
        case invalidHeaderCompressionMethodCode(UInt8)
        case invalidHeaderFilterCode(UInt8)
        case invalidHeaderInterlacingCode(UInt8)
        case invalidHeaderSize((x:Int, y:Int))
        
        /// case PNG.ParsingError.unexpectedPalette(pixel:)
        ///     The parser encountered a [`(Chunk).PLTE`] chunk in an image 
        ///     with a pixel format that forbids it. 
        /// - pixel : Format.Pixel 
        ///     The image pixel format.
        /// ## (PLTE-parsing-errors)
        
        /// case PNG.ParsingError.invalidPaletteChunkLength(_:)
        ///     A [`(Chunk).PLTE`] chunk had a length that is not divisible by `3`. 
        /// - _ : Swift.Int
        ///     The chunk length.
        /// ## (PLTE-parsing-errors)
        
        /// case PNG.ParsingError.invalidPaletteCount(_:max:)
        ///     A [`(Chunk).PLTE`] chunk contained more entries than allowed. 
        /// - _ : Swift.Int
        ///     The number of palette entries.
        /// - max : Swift.Int
        ///     The maximum allowed number of palette entries, according to the 
        ///     image bit depth.
        /// ## (PLTE-parsing-errors)
        case unexpectedPalette(pixel:PNG.Format.Pixel)
        case invalidPaletteChunkLength(Int)
        case invalidPaletteCount(Int, max:Int)
        
        /// case PNG.ParsingError.unexpectedTransparency(pixel:)
        ///     The parser encountered a [`(Chunk).tRNS`] chunk in an image 
        ///     with a pixel format that forbids it. 
        /// - pixel : Format.Pixel 
        ///     The image pixel format.
        /// ## (tRNS-parsing-errors)
        
        /// case PNG.ParsingError.invalidTransparencyChunkLength(_:expected:)
        ///     A [`(Chunk).tRNS`] chunk had the wrong length. 
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// - expected : Swift.Int 
        ///     The expected chunk length.
        /// ## (tRNS-parsing-errors)
        
        /// case PNG.ParsingError.invalidTransparencySample(_:max:)
        ///     A [`(Chunk).tRNS`] chunk contained an invalid chroma key sample. 
        /// - _ : Swift.UInt16
        ///     The value of the invalid chroma key sample.
        /// - max : Swift.UInt16
        ///     The maximum allowed value for a chroma key sample, according to the 
        ///     image color depth.
        /// ## (tRNS-parsing-errors)
        
        /// case PNG.ParsingError.invalidTransparencyCount(_:max:)
        ///     A [`(Chunk).tRNS`] chunk contained too many alpha samples. 
        /// - _ : Swift.Int
        ///     The number of alpha samples present.
        /// - max : Swift.Int
        ///     The maximum allowed number of alpha samples, which is equal to 
        ///     the number of entries in the image palette.
        /// ## (tRNS-parsing-errors)
        case unexpectedTransparency(pixel:PNG.Format.Pixel)
        case invalidTransparencyChunkLength(Int, expected:Int)
        case invalidTransparencySample(UInt16, max:UInt16)
        case invalidTransparencyCount(Int, max:Int)
        
        /// case PNG.ParsingError.invalidBackgroundChunkLength(_:expected:)
        ///     A [`(Chunk).bKGD`] chunk had the wrong length. 
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// - expected : Swift.Int 
        ///     The expected chunk length.
        /// ## (bKGD-parsing-errors)
        
        /// case PNG.ParsingError.invalidBackgroundSample(_:max:)
        ///     A [`(Chunk).bKGD`] chunk contained an invalid background sample. 
        /// - _ : Swift.UInt16
        ///     The value of the invalid background sample.
        /// - max : Swift.UInt16
        ///     The maximum allowed value for a background sample, according to the 
        ///     image color depth.
        /// ## (bKGD-parsing-errors)
        
        /// case PNG.ParsingError.invalidBackgroundIndex(_:max:)
        ///     A [`(Chunk).bKGD`] chunk specified an out-of-range palette index. 
        /// - _ : Swift.Int
        ///     The invalid index.
        /// - max : Swift.Int
        ///     The maximum allowed index value, which is equal to one less than 
        ///     the number of entries in the image palette.
        /// ## (bKGD-parsing-errors)
        case invalidBackgroundChunkLength(Int, expected:Int)
        case invalidBackgroundSample(UInt16, max:UInt16)
        case invalidBackgroundIndex(Int, max:Int)
        
        /// case PNG.ParsingError.invalidHistogramChunkLength(_:expected:)
        ///     A [`(Chunk).hIST`] chunk had the wrong length. 
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// - expected : Swift.Int 
        ///     The expected chunk length.
        /// ## (hIST-parsing-errors)
        case invalidHistogramChunkLength(Int, expected:Int)
        
        /// case PNG.ParsingError.invalidGammaChunkLength(_:)
        ///     A [`(Chunk).gAMA`] chunk had the wrong length. 
        /// 
        ///     Gamma chunks should be exactly `4` bytes long.
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// ## (gAMA-parsing-errors)
        case invalidGammaChunkLength(Int)
        
        /// case PNG.ParsingError.invalidChromaticityChunkLength(_:)
        ///     A [`(Chunk).cHRM`] chunk had the wrong length. 
        /// 
        ///     Chromaticity chunks should be exactly `32` bytes long.
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// ## (cHRM-parsing-errors)
        case invalidChromaticityChunkLength(Int)
        
        /// case PNG.ParsingError.invalidColorRenderingChunkLength(_:)
        ///     An [`(Chunk).sRGB`] chunk had the wrong length. 
        /// 
        ///     Color rendering chunks should be exactly `1` byte long.
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// ## (sRGB-parsing-errors)
        
        /// case PNG.ParsingError.invalidColorRenderingCode(_:)
        ///     An [`(Chunk).sRGB`] chunk had an invalid color rendering code.
        /// 
        ///     The color rendering code should be one of `0`, `1`, `2`, or `3`. 
        /// - _ : Swift.UInt8
        ///     The invalid color rendering code.
        /// ## (sRGB-parsing-errors)
        case invalidColorRenderingChunkLength(Int)
        case invalidColorRenderingCode(UInt8)
        
        /// case PNG.ParsingError.invalidSignificantBitsChunkLength(_:expected:)
        ///     An [`(Chunk).sBIT`] chunk had the wrong length. 
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// - expected : Swift.Int 
        ///     The expected chunk length.
        /// ## (sBIT-parsing-errors)
        
        /// case PNG.ParsingError.invalidSignificantBitsPrecision(_:max:)
        ///     An [`(Chunk).sBIT`] chunk specified an invalid precision value. 
        /// - _ : Swift.Int 
        ///     The invalid precision value.
        /// - max : Swift.Int 
        ///     The maximum allowed precision value, which is equal to the image 
        ///     color depth.
        /// ## (sBIT-parsing-errors)
        case invalidSignificantBitsChunkLength(Int, expected:Int)
        case invalidSignificantBitsPrecision(Int, max:Int)
        
        /// case PNG.ParsingError.invalidColorProfileChunkLength(_:min:)
        ///     An [`(Chunk).iCCP`] chunk had an invalid length. 
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// - min : Swift.Int 
        ///     The minimum expected chunk length.
        /// ## (iCCP-parsing-errors)
        
        /// case PNG.ParsingError.invalidColorProfileName(_:)
        ///     An [`(Chunk).iCCP`] chunk had an invalid profile name. 
        /// - _ : Swift.String?
        ///     The invalid profile name, or `nil` if the parser could not find 
        ///     the null-terminator of the profile name string.
        /// ## (iCCP-parsing-errors)
        
        /// case PNG.ParsingError.invalidColorProfileCompressionMethodCode(_:)
        ///     An [`(Chunk).iCCP`] chunk had an invalid compression method code.
        /// 
        ///     The compression method code should always be `0`. 
        /// - _ : Swift.UInt8
        ///     The invalid compression method code.
        /// ## (iCCP-parsing-errors)
        
        /// case PNG.ParsingError.incompleteColorProfileCompressedDatastream
        ///     The compressed data stream in an [`(Chunk).iCCP`] chunk was not 
        ///     properly terminated.
        /// ## (iCCP-parsing-errors)
        case invalidColorProfileChunkLength(Int, min:Int) 
        case invalidColorProfileName(String?) 
        case invalidColorProfileCompressionMethodCode(UInt8)
        case incompleteColorProfileCompressedDatastream
        
        /// case PNG.ParsingError.invalidPhysicalDimensionsChunkLength(_:)
        ///     A [`(Chunk).pHYs`] chunk had the wrong length. 
        /// 
        ///     Physical dimensions chunks should be exactly `9` bytes long.
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// ## (pHYs-parsing-errors)
        
        /// case PNG.ParsingError.invalidPhysicalDimensionsDensityUnitCode(_:)
        ///     A [`(Chunk).pHYs`] chunk had an invalid density unit code.
        /// 
        ///     The density code should be either `0` or `1`. 
        /// - _ : Swift.UInt8
        ///     The invalid density unit code.
        /// ## (pHYs-parsing-errors)
        case invalidPhysicalDimensionsChunkLength(Int)
        case invalidPhysicalDimensionsDensityUnitCode(UInt8)
        
        /// case PNG.ParsingError.invalidSuggestedPaletteChunkLength(_:min:)
        ///     An [`(Chunk).sPLT`] chunk had an invalid length. 
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// - min : Swift.Int 
        ///     The minimum expected chunk length.
        /// ## (sPLT-parsing-errors)
        
        /// case PNG.ParsingError.invalidSuggestedPaletteName(_:)
        ///     An [`(Chunk).sPLT`] chunk had an invalid palette name. 
        /// - _ : Swift.String?
        ///     The invalid palette name, or `nil` if the parser could not find 
        ///     the null-terminator of the palette name string.
        /// ## (sPLT-parsing-errors)
        
        /// case PNG.ParsingError.invalidSuggestedPaletteDataLength(_:stride:)
        ///     The length of the palette data in an [`(Chunk).sPLT`] chunk was 
        ///     not divisible by its expected stride. 
        /// - _ : Swift.Int 
        ///     The length of the palette data.
        /// - stride : Swift.Int 
        ///     The expected stride of the palette entries.
        /// ## (sPLT-parsing-errors)
        
        /// case PNG.ParsingError.invalidSuggestedPaletteDepthCode(_:)
        ///     An [`(Chunk).sPLT`] chunk had an invalid depth code. 
        ///
        ///     The depth code should be either `8` or `16`. 
        /// - _ : Swift.UInt8 
        ///     The invalid depth code.
        /// ## (sPLT-parsing-errors)
        
        /// case PNG.ParsingError.invalidSuggestedPaletteFrequency
        ///     The entries in an [`(Chunk).sPLT`] chunk were not ordered by 
        ///     descending frequency.
        /// ## (sPLT-parsing-errors)
        case invalidSuggestedPaletteChunkLength(Int, min:Int)
        case invalidSuggestedPaletteName(String?)
        case invalidSuggestedPaletteDataLength(Int, stride:Int)
        case invalidSuggestedPaletteDepthCode(UInt8)
        case invalidSuggestedPaletteFrequency
        
        /// case PNG.ParsingError.invalidTimeModifiedChunkLength(_:)
        ///     A [`(Chunk).tIME`] chunk had the wrong length. 
        /// 
        ///     Time modified chunks should be exactly `7` bytes long.
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// ## (tIME-parsing-errors)
        
        /// case PNG.ParsingError.invalidTimeModifiedTime(year:month:day:hour:minute:second:)
        ///     A [`(Chunk).tIME`] chunk specified an invalid timestamp. 
        /// - year : Swift.Int 
        ///     The specified year.
        /// - month : Swift.Int 
        ///     The specified month.
        /// - day : Swift.Int 
        ///     The specified day.
        /// - hour : Swift.Int 
        ///     The specified hour.
        /// - minute : Swift.Int 
        ///     The specified minute.
        /// - second : Swift.Int 
        ///     The specified second.
        /// ## (tIME-parsing-errors)
        case invalidTimeModifiedChunkLength(Int)
        case invalidTimeModifiedTime(year:Int, month:Int, day:Int, hour:Int, minute:Int, second:Int)
        
        /// case PNG.ParsingError.invalidTextEnglishKeyword(_:)
        ///     A [`(Chunk).tEXt`], [`(Chunk).zTXt`], or [`(Chunk).iTXt`] chunk 
        ///     had an invalid english keyword. 
        /// - _ : Swift.String?
        ///     The invalid english keyword, or `nil` if the parser could not find 
        ///     the null-terminator of the keyword string.
        /// ## (text-chunk-parsing-errors)
        
        /// case PNG.ParsingError.invalidTextChunkLength(_:min:)
        ///     A [`(Chunk).tEXt`], [`(Chunk).zTXt`], or [`(Chunk).iTXt`] chunk 
        ///     had an invalid length. 
        /// - _ : Swift.Int 
        ///     The chunk length.
        /// - min : Swift.Int 
        ///     The minimum expected chunk length.
        /// ## (text-chunk-parsing-errors)
        
        /// case PNG.ParsingError.invalidTextCompressionCode(_:)
        ///     An [`(Chunk).iTXt`] chunk had an invalid compression code.
        /// 
        ///     The compression code should be either `0` or `1`. 
        /// - _ : Swift.UInt8
        ///     The invalid compression code.
        /// ## (text-chunk-parsing-errors)
        
        /// case PNG.ParsingError.invalidTextCompressionMethodCode(_:)
        ///     A [`(Chunk).zTXt`] or [`(Chunk).iTXt`] chunk had an invalid 
        ///     compression method code.
        /// 
        ///     The compression method code should always be `0`. 
        /// - _ : Swift.UInt8
        ///     The invalid compression method code.
        /// ## (text-chunk-parsing-errors)
        
        /// case PNG.ParsingError.invalidTextLanguageTag(_:)
        ///     An [`(Chunk).iTXt`] chunk had an invalid language tag. 
        /// - _ : Swift.String?
        ///     The invalid language tag component, or `nil` if the parser could 
        ///     not find the null-terminator of the language tag string. 
        ///     The language tag component is not the entire language tag string.
        /// ## (text-chunk-parsing-errors)
        
        /// case PNG.ParsingError.invalidTextLocalizedKeyword
        ///     The parser could not find the null-terminator of the localized 
        ///     keyword string in an [`(Chunk).iTXt`] chunk.
        /// ## (text-chunk-parsing-errors)
        
        /// case PNG.ParsingError.incompleteTextCompressedDatastream
        ///     The compressed data stream in a [`(Chunk).zTXt`] or [`(Chunk).iTXt`] 
        ///     chunk was not properly terminated.
        /// ## (text-chunk-parsing-errors)
        case invalidTextEnglishKeyword(String?)
        case invalidTextChunkLength(Int, min:Int)
        case invalidTextCompressionCode(UInt8)
        case invalidTextCompressionMethodCode(UInt8)
        case invalidTextLanguageTag(String?)
        case invalidTextLocalizedKeyword
        case incompleteTextCompressedDatastream
    }
    
    /// enum PNG.DecodingError 
    /// :   Error 
    ///     A decoding error. 
    /// # [See also](error-handling)
    /// ## (error-handling)
    public 
    enum DecodingError
    {
        /// case PNG.DecodingError.required(chunk:before:) 
        ///     The decoder encountered a chunk of a type that requires a 
        ///     previously encountered chunk of a particular type.
        /// - chunk : Chunk 
        ///     The type of the preceeding chunk required by the encountered chunk.
        /// - before : Chunk 
        ///     The type of the encountered chunk. 
        /// ## ()
        
        /// case PNG.DecodingError.duplicate(chunk:) 
        ///     The decoder encountered multiple instances of a chunk type that 
        ///     can only appear once in a PNG file.
        /// - chunk : Chunk 
        ///     The type of the duplicated chunk. 
        /// ## ()
        
        /// case PNG.DecodingError.unexpected(chunk:after:) 
        ///     The decoder encountered a chunk of a type that is not allowed 
        ///     to appear after a previously encountered chunk of a particular type.
        /// 
        ///     If both fields are set to [`(Chunk).IDAT`], this indicates 
        ///     a non-contiguous [`(Chunk).IDAT`] sequence.
        /// - chunk : Chunk 
        ///     The type of the encountered chunk. 
        /// - after : Chunk 
        ///     The type of the preceeding chunk that precludes the encountered chunk.
        /// ## ()
        case required(chunk:PNG.Chunk, before:PNG.Chunk)
        case duplicate(chunk:PNG.Chunk)
        case unexpected(chunk:PNG.Chunk, after:PNG.Chunk)
        
        /// case PNG.DecodingError.incompleteImageDataCompressedDatastream
        ///     The decoder finished processing the last [`(Chunk).IDAT`] chunk 
        ///     before the compressed image data stream was properly terminated.
        case incompleteImageDataCompressedDatastream
        /// case PNG.DecodingError.extraneousImageDataCompressedData
        ///     The decoder encountered additional [`(Chunk).IDAT`] chunks 
        ///     after the end of the compressed image data stream. 
        /// 
        ///     This error should not be confused with an [`unexpected(chunk:after:)`] 
        ///     error with both fields set to [`(Chunk).IDAT`], which indicates a 
        ///     non-contiguous [`(Chunk).IDAT`] sequence.
        case extraneousImageDataCompressedData
        /// case PNG.DecodingError.extraneousImageData
        ///     The compressed image data stream produces more uncompressed image 
        ///     data than expected. 
        case extraneousImageData
    }
}
extension LZ77 
{
    /// enum LZ77.DecompressionError 
    /// :   PNG.Error 
    ///     A decompression error. 
    /// # [Stream errors](decompression-stream-errors)
    /// # [INFLATE errors](inflate-errors)
    /// # [See also](error-handling)
    /// ## (error-handling)
    public 
    enum DecompressionError
    {
        // stream errors 
        
        /// case LZ77.DecompressionError.invalidStreamCompressionMethodCode(_:)
        ///     A compressed data stream had an invalid compression method code.
        /// 
        ///     The compression method code should always be `8`. 
        /// - _ : Swift.UInt8
        ///     The invalid compression method code.
        /// ## (decompression-stream-errors)
        
        /// case LZ77.DecompressionError.invalidStreamWindowSize(exponent:)
        ///     A compressed data stream specified an invalid window size.
        /// 
        ///     The window size exponent should be in the range `8 ... 15`. 
        /// - exponent : Swift.Int
        ///     The invalid window size exponent.
        /// ## (decompression-stream-errors)
        
        /// case LZ77.DecompressionError.invalidStreamHeaderCheckBits 
        ///     A compressed data stream had invalid header check bits.
        /// 
        ///     The header check bits should not be confused with the modular 
        ///     redundancy checksum, which corresponds to the 
        ///     [`invalidStreamChecksum(declared:computed:)`] error case.
        /// ## (decompression-stream-errors)
        
        /// case LZ77.DecompressionError.unexpectedStreamDictionary 
        ///     A compressed data stream contains a stream dictionary, which 
        ///     is not allowed in a PNG compressed data stream.
        /// ## (decompression-stream-errors)
        
        /// case LZ77.DecompressionError.invalidStreamChecksum(declared:computed:) 
        ///     The modular redundancy checksum computed on 
        ///     the uncompressed data did not match the checksum declared in the 
        ///     compressed data stream footer. 
        /// 
        ///     This error should not be confused with [`invalidStreamHeaderCheckBits`]. 
        ///     Nor should it be confused with [`PNG.LexingError.invalidChunkChecksum(declared:computed:)`], 
        ///     which refers to the cyclic redundancy checksum in every PNG chunk.
        /// - declared : Swift.UInt32 
        ///     The checksum declared in the compressed data stream footer.
        /// - computed : Swift.UInt32 
        ///     The checksum computed on the uncompressed data.
        /// ## (decompression-stream-errors)
        case invalidStreamCompressionMethodCode(UInt8)
        case invalidStreamWindowSize(exponent:Int)
        case invalidStreamHeaderCheckBits
        case unexpectedStreamDictionary
        case invalidStreamChecksum(declared:UInt32, computed:UInt32)
        // block errors 
        
        /// case LZ77.DecompressionError.invalidBlockTypeCode(_:) 
        ///     A compressed block had an invalid block type code.
        /// 
        ///     The block type code should be one of `0`, `1`, or `2`. 
        /// - _ : Swift.UInt8
        ///     The invalid block type code.
        /// ## (inflate-errors)
        
        /// case LZ77.DecompressionError.invalidBlockElementCountParity(_:_:) 
        ///     A compressed block of stored type had inconsistent element count fields.
        /// 
        ///     A valid element count field is the bitwise negation of the other 
        ///     element count field.
        /// - _ : Swift.UInt16
        ///     The value of the first element count field.
        /// - _ : Swift.UInt16
        ///     The value of the second element count field.
        /// ## (inflate-errors)
        
        /// case LZ77.DecompressionError.invalidHuffmanRunLiteralSymbolCount(_:) 
        ///     A compressed block of dynamic type declared an invalid number of 
        ///     run-literal symbols.
        /// 
        ///     The number of run-literal symbols must be in the range `257 ... 286`.
        /// - _ : Swift.Int
        ///     The number of run-literal symbols declared in the compressed block.
        /// ## (inflate-errors)
        
        /// case LZ77.DecompressionError.invalidHuffmanCodelengthHuffmanTable() 
        ///     A compressed block of dynamic type declared an invalid 
        ///     codelength huffman table.
        /// ## (inflate-errors)
        
        /// case LZ77.DecompressionError.invalidHuffmanCodelengthSequence
        ///     A compressed block of dynamic type declared an invalid sequence of 
        ///     symbol codelengths.
        /// ## (inflate-errors)
        
        /// case LZ77.DecompressionError.invalidHuffmanTable
        ///     A compressed block of dynamic type declared an invalid 
        ///     distance or run-literal huffman table.
        /// ## (inflate-errors)
        case invalidBlockTypeCode(UInt8)
        case invalidBlockElementCountParity(UInt16, UInt16)
        case invalidHuffmanRunLiteralSymbolCount(Int)
        case invalidHuffmanCodelengthHuffmanTable
        case invalidHuffmanCodelengthSequence
        case invalidHuffmanTable
        /// case LZ77.DecompressionError.invalidStringReference
        ///     A compressed block contains an invalid run-length string reference.
        /// ## (inflate-errors)
        case invalidStringReference
    }
}

extension PNG.LexingError:PNG.Error 
{
    /// static var PNG.LexingError.namespace : Swift.String { get }
    /// ?:  Error 
    ///     The string `"lexing error"`.
    public static 
    var namespace:String 
    {
        "lexing error"
    }
    /// var PNG.LexingError.message : Swift.String { get }
    /// ?:  Error 
    ///     A human-readable summary of this error.
    /// ## ()
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
    /// var PNG.LexingError.details : Swift.String? { get }
    /// ?:  Error 
    ///     An optional human-readable string providing additional details 
    ///     about this error.
    /// ## ()
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
    /// static var PNG.FormattingError.namespace : Swift.String { get }
    /// ?:  Error 
    ///     The string `"formatting error"`.
    public static 
    var namespace:String 
    {
        "formatting error"
    }
    /// var PNG.FormattingError.message : Swift.String { get }
    /// ?:  Error 
    ///     A human-readable summary of this error.
    /// ## ()
    public 
    var message:String 
    {
        switch self 
        {
        case .invalidDestination: 
            return "failed to write to destination bytestream"
        }
    }
    /// var PNG.FormattingError.details : Swift.String? { get }
    /// ?:  Error 
    ///     An optional human-readable string providing additional details 
    ///     about this error.
    /// ## ()
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
    /// static var PNG.ParsingError.namespace : Swift.String { get }
    /// ?:  Error 
    ///     The string `"parsing error"`.
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
    /// var PNG.ParsingError.message : Swift.String { get }
    /// ?:  Error 
    ///     A human-readable summary of this error.
    /// ## ()
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
    /// var PNG.ParsingError.details : Swift.String? { get }
    /// ?:  Error 
    ///     An optional human-readable string providing additional details 
    ///     about this error.
    /// ## ()
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
extension PNG.DecodingError:PNG.Error 
{
    /// static var PNG.DecodingError.namespace : Swift.String { get }
    /// ?:  Error 
    ///     The string `"decoding error"`.
    public static 
    var namespace:String 
    {
        "decoding error"
    }
    /// var PNG.DecodingError.message : Swift.String { get }
    /// ?:  Error 
    ///     A human-readable summary of this error.
    /// ## ()
    public 
    var message:String 
    {
        switch self 
        {
        case .incompleteImageDataCompressedDatastream:
            return "image data chunks do not contain a full compressed data stream"
        case .extraneousImageDataCompressedData:
            return "image contains trailing image data chunks that are not part of the compressed data stream"
        case .extraneousImageData:
            return "compressed image data stream produces more uncompressed image data than expected"
        case .duplicate:
            return "duplicate chunk"
        case .required, .unexpected:
            return "invalid chunk ordering"
        }
    }
    /// var PNG.DecodingError.details : Swift.String? { get }
    /// ?:  Error 
    ///     An optional human-readable string providing additional details 
    ///     about this error.
    /// ## ()
    public 
    var details:String? 
    {
        switch self 
        {
        case    .incompleteImageDataCompressedDatastream,
                .extraneousImageDataCompressedData,
                .extraneousImageData:
            return nil
        case    .required(chunk: let previous, before: let chunk):
            return "chunk of type '\(chunk)' requires a previously encountered chunk of type '\(previous)'"
        case    .duplicate(chunk: let chunk):
            return "chunk of type '\(chunk)' can only appear once"
        case    .unexpected(chunk: .IDAT, after: .IDAT):
            return "chunks of type 'IDAT' must be contiguous"
        case    .unexpected(chunk: let chunk, after: let previous):
            return "chunk of type '\(chunk)' cannot appear after chunk of type '\(previous)'"
        }
    }
}
extension LZ77.DecompressionError:PNG.Error 
{
    /// static var LZ77.DecompressionError.namespace : Swift.String { get }
    /// ?:  PNG.Error 
    ///     The string `"decompression error"`.
    public static 
    var namespace:String 
    {
        "decompression error"
    }
    /// var LZ77.DecompressionError.message : Swift.String { get }
    /// ?:  PNG.Error 
    ///     A human-readable summary of this error.
    /// ## ()
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
    /// var LZ77.DecompressionError.details : Swift.String? { get }
    /// ?:  PNG.Error 
    ///     An optional human-readable string providing additional details 
    ///     about this error.
    /// ## ()
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
