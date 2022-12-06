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
