import CRC

/// protocol PNG.Bytestream.Source
///     A source bytestream.
///
///     To implement a custom data source type, conform it to this protocol by
///     implementing ``Source/read(count:)``. It can
///     then be used with the library’s core decompression interfaces.
/// #  [Stream interface](file-io-source-interface)
/// #  [See also](file-io-protocols, system-file-source)
/// ## (1:file-io-protocols)
/// ## (1:lexing-and-formatting)
public
protocol _PNGBytestreamSource
{
    /// mutating func PNG.Bytestream.Source.read(count:)
    /// required
    ///     Attempts to read and return the given number of bytes from this stream.
    ///
    ///     A successful call to this function should affect the bytestream state
    ///     such that subsequent calls should pick up where the last call left off.
    ///
    ///     The rest of the library interprets a `nil` return value from this function
    ///     as indicating end-of-stream.
    /// - count     : Swift.Int
    ///     The number of bytes to read.
    /// -   Returns:
    ///     The `count` bytes read, or `nil` if the read attempt failed. This
    ///     method should return `nil` even if any number of bytes less than `count`
    ///     were successfully read.
    /// ## (file-io-source-interface)
    mutating
    func read(count:Int) -> [UInt8]?
}
extension _PNGBytestreamSource
{
    /// mutating func PNG.Bytestream.Source.signature()
    /// throws
    ///     Lexes the eight PNG signature bytes from this bytestream.
    ///
    ///     This function expects to read the byte sequence
    ///     `[137, 80, 78, 71, 13, 10, 26, 10]`. It reports end-of-stream by throwing
    ///     ``LexingError.truncatedSignature``. To recover on end-of-stream,
    ///     catch this error case.
    ///
    ///     This function is the inverse of ``Destination.signature()``.
    public mutating
    func signature() throws
    {
        guard let bytes:[UInt8] = self.read(count: PNG.signature.count)
        else
        {
            throw PNG.LexingError.truncatedSignature
        }
        guard bytes == PNG.signature
        else
        {
            throw PNG.LexingError.invalidSignature(bytes)
        }
    }

    /// mutating func PNG.Bytestream.Source.chunk()
    /// throws
    ///     Lexes a chunk from this bytestream.
    ///
    ///     This function reads a chunk, validating its stored checksum for
    ///     data integrity. It reports end-of-stream by throwing
    ///     ``LexingError.truncatedChunkHeader`` or
    ///     ``LexingError.truncatedChunkBody(expected:)``. To recover on end-of-stream,
    ///     catch these two error cases.
    ///
    ///     This function is the inverse of ``Destination.format(type:data:)``.
    /// -   Returns:
    ///     The type identifier, and contents of the lexed chunk. The chunk
    ///     contents do not include the checksum footer.
    public mutating
    func chunk() throws -> (type:PNG.Chunk, data:[UInt8])
    {
        guard let header:[UInt8] = self.read(count: 8)
        else
        {
            throw PNG.LexingError.truncatedChunkHeader
        }

        let length:Int  = header.prefix(4).load(bigEndian: UInt32.self, as:  Int.self),
            name:UInt32 = header.suffix(4).load(bigEndian: UInt32.self, as: UInt32.self)

        guard let type:PNG.Chunk = PNG.Chunk.init(validating: name)
        else
        {
            throw PNG.LexingError.invalidChunkTypeCode(name)
        }
        let bytes:Int = length + MemoryLayout<UInt32>.size
        guard var data:[UInt8] = self.read(count: bytes)
        else
        {
            throw PNG.LexingError.truncatedChunkBody(expected: bytes)
        }

        let declared:CRC32 = .init(
            checksum: data.suffix(4).load(bigEndian: UInt32.self, as: UInt32.self))
        data.removeLast(4)
        let computed:CRC32 = .init(hashing: header.suffix(4)).updated(with: data)

        guard declared == computed
        else
        {
            throw PNG.LexingError.invalidChunkChecksum(
                declared: declared.checksum,
                computed: computed.checksum)
        }

        return (type, data)
    }
}
