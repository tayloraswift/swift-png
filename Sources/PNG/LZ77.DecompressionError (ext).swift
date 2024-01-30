import LZ77

extension LZ77.DecompressionError:PNG.Error
{
    /// The string `"decompression error"`.
    public static
    var namespace:String
    {
        "decompression error"
    }
    /// A human-readable summary of this error.
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
    /// An optional human-readable string providing additional details about this error.
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
