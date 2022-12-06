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
