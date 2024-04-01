@frozen public
enum Gzip
{
    /// Extracts gzip-compressed data.
    public static
    func extract(from bytes:ArraySlice<UInt8>) throws -> [UInt8]
    {
        var inflator:Gzip.Inflator = .init()
        try inflator.push(bytes)
        return inflator.pull()
    }

    /// Archives data using gzip.
    ///
    /// -   Parameters:
    ///     -   bytes:
    ///         The data to compress.
    ///
    ///     -   level:
    ///         The compression level to use, in the range `0 ... 13`. Higher levels provide
    ///         more aggressive compression at the cost of more CPU time.
    ///
    ///         Levels 0 through 3 use a **greedy** matching algorithm, levels 4 through 7 use a
    ///         more sophisticated **lazy** matching algorithm, and levels 8 through 13 use a
    ///         **full** matching algorithm.
    ///
    ///         The default is 7.
    ///
    ///     -   hint:
    ///         Provides a size hint for the compressor, which influences the size of the
    ///         compressed blocks in the gzip archive. The size hint is in units of `UInt16`.
    ///         The default is 128K, which means 256K bytes.
    public static
    func archive(bytes:ArraySlice<UInt8>,
        level:Int = 7,
        hint:Int = 128 << 10) -> [UInt8]
    {
        var deflator:Gzip.Deflator = .init(level: level, hint: hint)
            deflator.push(bytes, last: true)
        var gzip:[UInt8] = []
        while let part:[UInt8] = deflator.pull()
        {
            gzip += part
        }
        return gzip
    }
}
