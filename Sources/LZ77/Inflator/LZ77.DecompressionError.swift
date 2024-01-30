extension LZ77
{
    /// A decompression error.
    ///
    /// ## Topics
    ///
    /// ### Stream errors
    /// -   ``invalidStreamCompressionMethodCode(_:)``
    /// -   ``invalidStreamWindowSize(exponent:)``
    /// -   ``invalidStreamHeaderCheckBits``
    /// -   ``unexpectedStreamDictionary``
    /// -   ``invalidStreamChecksum(declared:computed:)``
    ///
    /// ### Block errors
    /// -   ``invalidBlockTypeCode(_:)``
    /// -   ``invalidBlockElementCountParity(_:_:)``
    /// -   ``invalidHuffmanRunLiteralSymbolCount(_:)``
    /// -   ``invalidHuffmanCodelengthHuffmanTable``
    /// -   ``invalidHuffmanCodelengthSequence``
    /// -   ``invalidHuffmanTable``
    /// -   ``invalidStringReference``
    public
    enum DecompressionError:Error, Equatable, Sendable
    {
        /// A compressed data stream had an invalid compression method code.
        ///
        /// The compression method code should always be `8`.
        case invalidStreamCompressionMethodCode(UInt8)

        /// A compressed data stream specified an invalid window size.
        ///
        /// The window size exponent should be in the range `8 ... 15`.
        case invalidStreamWindowSize(exponent:Int)

        /// A compressed data stream had invalid header check bits.
        ///
        /// The header check bits should not be confused with the modular redundancy checksum,
        /// which corresponds to the ``invalidStreamChecksum(declared:computed:)`` error case.
        case invalidStreamHeaderCheckBits

        /// A compressed data stream contains a stream dictionary, which is not allowed in a
        /// compressed PNG data stream.
        case unexpectedStreamDictionary

        /// The modular redundancy checksum computed on the uncompressed data did not match the
        /// checksum declared in the compressed data stream footer.
        ///
        /// This error should not be confused with ``invalidStreamHeaderCheckBits``, nor should
        /// it be confused with ``PNG.LexingError.invalidChunkChecksum(declared:computed:)``,
        /// which refers to the cyclic redundancy checksum in every PNG chunk.
        case invalidStreamChecksum(declared:UInt32, computed:UInt32)

        /// A compressed block had an invalid block type code.
        ///
        /// The block type code should be one of `0`, `1`, or `2`.
        case invalidBlockTypeCode(UInt8)

        /// A compressed block of stored type had inconsistent element count fields.
        ///
        /// A valid element count field is the bitwise negation of the other element count
        /// field.
        case invalidBlockElementCountParity(UInt16, UInt16)

        /// A compressed block of dynamic type declared an invalid number of run-literal
        /// symbols.
        ///
        /// The number of run-literal symbols must be in the range `257 ... 286`.
        case invalidHuffmanRunLiteralSymbolCount(Int)

        /// A compressed block of dynamic type declared an invalid codelength huffman table.
        case invalidHuffmanCodelengthHuffmanTable

        /// A compressed block of dynamic type declared an invalid sequence of symbol
        /// codelengths.
        case invalidHuffmanCodelengthSequence

        /// A compressed block of dynamic type declared an invalid distance or run-literal
        /// huffman table.
        case invalidHuffmanTable

        /// A compressed block contains an invalid run-length string reference.
        case invalidStringReference
    }
}
