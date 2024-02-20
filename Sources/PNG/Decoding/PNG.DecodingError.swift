extension PNG
{
    /// A decoding error.
    public
    enum DecodingError
    {
        /// The decoder encountered a chunk of a type that requires a
        /// previously encountered chunk of a particular type.
        /// -   Parameter chunk:
        ///     The type of the preceeding chunk required by the encountered chunk.
        /// -   Parameter before:
        ///     The type of the encountered chunk.

        ///     The decoder encountered multiple instances of a chunk type that
        ///     can only appear once in a PNG file.
        /// -   Parameter chunk:
        ///     The type of the duplicated chunk.

        ///     The decoder encountered a chunk of a type that is not allowed
        ///     to appear after a previously encountered chunk of a particular type.
        ///
        ///     If both fields are set to ``Chunk/IDAT``, this indicates
        ///     a non-contiguous ``Chunk/IDAT`` sequence.
        /// -   Parameter chunk:
        ///     The type of the encountered chunk.
        /// -   Parameter after:
        ///     The type of the preceeding chunk that precludes the encountered chunk.
        case required(chunk:PNG.Chunk, before:PNG.Chunk)
        case duplicate(chunk:PNG.Chunk)
        case unexpected(chunk:PNG.Chunk, after:PNG.Chunk)

        /// The decoder finished processing the last ``Chunk/IDAT`` chunk
        /// before the compressed image data stream was properly terminated.
        case incompleteImageDataCompressedDatastream
        /// The decoder encountered additional ``Chunk/IDAT`` chunks
        /// after the end of the compressed image data stream.
        ///
        /// This error should not be confused with an ``unexpected(chunk:after:)``
        /// error with both fields set to ``Chunk/IDAT``, which indicates a
        /// non-contiguous ``Chunk/IDAT`` sequence.
        case extraneousImageDataCompressedData
        /// The compressed image data stream produces more uncompressed image
        /// data than expected.
        case extraneousImageData
    }
}
extension PNG.DecodingError:PNG.Error
{
    /// The string `"decoding error"`.
    public static
    var namespace:String
    {
        "decoding error"
    }
    /// A human-readable summary of this error.
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
    /// An optional human-readable string providing additional details
    /// about this error.
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
