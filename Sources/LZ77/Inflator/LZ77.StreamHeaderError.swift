extension LZ77 {
    /// Errors that can occur when decompressing a DEFLATE stream embedded in the ‘zlib’ wrapper
    /// format.
    public enum StreamHeaderError: Error, Equatable {
        /// A compressed data stream had an invalid compression method code.
        ///
        /// The compression method code should always be `8`.
        case invalidCompressionMethod(UInt8)

        /// A compressed data stream specified an invalid window size.
        ///
        /// The window size exponent should be in the range `8 ... 15`.
        case invalidWindowSize(exponent: Int)

        /// A compressed data stream had invalid header check bits.
        ///
        /// The header check bits should not be confused with the modular redundancy checksum,
        /// which corresponds to the
        /// ``DecompressionError.invalidStreamChecksum(declared:computed:)`` error.
        case invalidCheckBits

        /// A compressed data stream contains a stream dictionary, which is not allowed in a
        /// compressed PNG data stream.
        case unexpectedDictionary
    }
}
