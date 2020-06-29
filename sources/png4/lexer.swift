/// An abstract data source. To provide a custom data source to the library, conform
/// your type to this protocol by implementing the `read(count:)` method.
public
protocol _PNGBytestreamSource
{
    /// Read the specified number of bytes from this data source.
    /// - Parameters:
    ///     - count: The number of bytes to read.
    /// - Returns: An array of size `count`, if `count` bytes could be read, and
    ///     `nil` otherwise.
    mutating
    func read(count:Int) -> [UInt8]?
}
/// An abstract data destination. To specify a custom data destination for the library,
/// conform your type to this protocol by implementing the `write(_:)` method.
public
protocol _PNGBytestreamDestination
{
    /// Write the given data buffer to this data destination.
    /// - Parameters:
    ///     - buffer: The data to write.
    /// - Returns: `()` on success, and `nil` otherwise.
    mutating
    func write(_ buffer:[UInt8]) -> Void?
}

public 
enum PNG 
{
    static 
    let signature:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    
    public 
    enum Bytestream 
    {
        public 
        typealias Source        = _PNGBytestreamSource
        public 
        typealias Destination   = _PNGBytestreamDestination
    }
}

// http://www.libpng.org/pub/png/spec/1.2/PNG-CRCAppendix.html
extension PNG 
{
    enum CRC32 
    {
        private static 
        let table:[UInt32] = .init(unsafeUninitializedCapacity: 256)
        {
            for n:Int in 0 ..< 256 
            {
                var c:UInt32 = .init(n)
                for k:Int in 0 ..< 8 
                {
                    c = ((c & 1) * 0xed_b8_83_20) ^ c >> 1
                }
                $0[n] = c
            }
            $1 = 256
        }
        
        static 
        func update<S>(_ crc:UInt32, with input:S) -> UInt32 
            where S:Sequence, S.Element == UInt8 
        {
            var c:UInt32 = crc 
            for byte:UInt8 in input 
            {
                c = Self.table[.init((.init(truncatingIfNeeded: c) ^ byte))] ^ c >> 8
            }
            return c
        }
        
        static 
        func compute<S>(_ input:S) -> UInt32 
            where S:Sequence, S.Element == UInt8 
        {
            ~Self.update(0xff_ff_ff_ff, with: input)
        }
    }
}

extension PNG 
{
    enum LexingError:Swift.Error 
    {
        case missingSignature
        
        case truncatedChunkHeader 
        case truncatedChunkData
        case invalidChunkChecksum(declared:UInt32, computed:UInt32)
    }
}

extension PNG.Bytestream.Source 
{
    public mutating 
    func signature() throws 
    {
        guard   let bytes:[UInt8] = self.read(count: PNG.signature.count),
                    bytes == PNG.signature
        else
        {
            throw PNG.LexingError.missingSignature
        }
    }
    
    public mutating
    func next() throws -> (name:(UInt8, UInt8, UInt8, UInt8), data:[UInt8])
    {
        guard let header:[UInt8] = self.read(count: 8)
        else
        {
            throw PNG.LexingError.truncatedChunkHeader
        }

        let length:Int = header.prefix(4).load(bigEndian: UInt32.self, as: Int.self),
            name:(UInt8, UInt8, UInt8, UInt8) = (header[4], header[5], header[6], header[7])

        guard var data:[UInt8] = self.read(count: length + MemoryLayout<UInt32>.size)
        else
        {
            throw PNG.LexingError.truncatedChunkData
        }

        let checksum:UInt32 = data.suffix(4).load(bigEndian: UInt32.self, as: UInt32.self)

        data.removeLast(4)
        
        let computed:UInt32 = PNG.CRC32.update(PNG.CRC32.compute(header.suffix(4)), with: data)
        
        guard checksum == computed
        else
        {
            throw PNG.LexingError.invalidChunkChecksum(declared: checksum, computed: computed)
        }
        
        return (name, data)
    }
}
