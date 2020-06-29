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
    
    public 
    struct Chunk:Hashable, Equatable, CustomStringConvertible
    {
        /// The four-byte name of this PNG chunk type.
        private 
        let ancillary:UInt8, 
            authority:UInt8, 
            reserved:UInt8, 
            copy:UInt8 
        
        public 
        var name:(UInt8, UInt8, UInt8, UInt8) 
        {
            (self.ancillary, self.authority, self.reserved, self.copy)
        }

        /// A string displaying the ASCII representation of this PNG chunk type’s name.
        public
        var description:String
        {
            .init(decoding: [self.ancillary, self.authority, self.reserved, self.copy],
                        as: Unicode.ASCII.self)
        }

        private
        init(_ ancillary:UInt8, _ authority:UInt8, _ reserved:UInt8, _ copy:UInt8)
        {
            self.ancillary  = ancillary 
            self.authority  = authority 
            self.reserved   = reserved 
            self.copy       = copy
        }

        public
        init(name:(UInt8, UInt8, UInt8, UInt8))
        {
            guard let chunk:Self = .validate(name: name) 
            else 
            {
                let string:String = .init(decoding: [name.0, name.1, name.2, name.3],
                    as: Unicode.ASCII.self)
                preconditionFailure("'\(string)' is not a valid png chunk type")
            }
            self = chunk 
        }
        
        public static 
        func validate(name:(UInt8, UInt8, UInt8, UInt8)) -> Self? 
        {
            let chunk:Self = .init(name.0, name.1, name.2, name.3)
            switch chunk 
            {
            // legal public chunks
            case    .CgBI, .IHDR, .PLTE, .IDAT, .IEND,
                    .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS,
                    .pHYs, .sPLT, .tIME, .iTXt, .tEXt, .zTXt:
                break

            default:
                guard   chunk.ancillary & 0x20 != 0, 
                        chunk.reserved  & 0x20 == 0
                else
                {
                    return nil
                }
            }
            return chunk 
        }
        
        public static
        let CgBI:Self = .init( 67, 103,  66,  73)
        /// The PNG header chunk type.
        public static
        let IHDR:Self = .init( 73,  72,  68,  82)
        /// The PNG palette chunk type.
        public static
        let PLTE:Self = .init( 80,  76,  84,  69)
        /// The PNG image data chunk type.
        public static
        let IDAT:Self = .init( 73,  68,  65,  84)
        /// The PNG image end chunk type.
        public static
        let IEND:Self = .init( 73,  69,  78,  68)

        /// The PNG chromaticity chunk type.
        public static
        let cHRM:Self = .init( 99,  72,  82,  77)
        /// The PNG gamma chunk type.
        public static
        let gAMA:Self = .init(103,  65,  77,  65)
        /// The PNG embedded ICC chunk type.
        public static
        let iCCP:Self = .init(105,  67,  67,  80)
        /// The PNG significant bits chunk type.
        public static
        let sBIT:Self = .init(115,  66,  73,  84)
        /// The PNG *s*RGB chunk type.
        public static
        let sRGB:Self = .init(115,  82,  71,  66)
        /// The PNG background chunk type.
        public static
        let bKGD:Self = .init( 98,  75,  71,  68)
        /// The PNG histogram chunk type.
        public static
        let hIST:Self = .init(104,  73,  83,  84)
        /// The PNG transparency chunk type.
        public static
        let tRNS:Self = .init(116,  82,  78,  83)

        /// The PNG physical dimensions chunk type.
        public static
        let pHYs:Self = .init(112,  72,  89, 115)

        /// The PNG suggested palette chunk type.
        public static
        let sPLT:Self = .init(115,  80,  76,  84)
        /// The PNG time chunk type.
        public static
        let tIME:Self = .init(116,  73,  77,  69)

        /// The PNG UTF-8 text chunk type.
        public static
        let iTXt:Self = .init(105,  84,  88, 116)
        /// The PNG Latin-1 text chunk type.
        public static
        let tEXt:Self = .init(116,  69,  88, 116)
        /// The PNG compressed Latin-1 text chunk type.
        public static
        let zTXt:Self = .init(122,  84,  88, 116)
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
            var c:UInt32 = ~crc 
            for byte:UInt8 in input 
            {
                c = Self.table[.init((.init(truncatingIfNeeded: c) ^ byte))] ^ c >> 8
            }
            return ~c
        }
        
        static 
        func compute<S>(_ input:S) -> UInt32 
            where S:Sequence, S.Element == UInt8 
        {
            Self.update(0, with: input)
        }
    }
}

extension PNG 
{
    public 
    enum LexingError:Swift.Error 
    {
        case missingSignature
        
        case truncatedChunkHeader 
        case invalidChunkTypeCode((UInt8, UInt8, UInt8, UInt8))
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
    func chunk() throws -> (type:PNG.Chunk, data:[UInt8])
    {
        guard let header:[UInt8] = self.read(count: 8)
        else
        {
            throw PNG.LexingError.truncatedChunkHeader
        }

        let length:Int = header.prefix(4).load(bigEndian: UInt32.self, as: Int.self), 
            name:(UInt8, UInt8, UInt8, UInt8) = 
        (
            header[4], 
            header[5], 
            header[6], 
            header[7]
        )
        
        guard let type:PNG.Chunk = .validate(name: name)
        else 
        {
            throw PNG.LexingError.invalidChunkTypeCode(name)
        }

        guard var data:[UInt8] = self.read(count: length + MemoryLayout<UInt32>.size)
        else
        {
            throw PNG.LexingError.truncatedChunkData
        }

        let declared:UInt32 = data.suffix(4).load(bigEndian: UInt32.self, as: UInt32.self)
        data.removeLast(4)
        let computed:UInt32 = PNG.CRC32.update(PNG.CRC32.compute(header.suffix(4)), with: data)
        
        guard declared == computed
        else
        {
            throw PNG.LexingError.invalidChunkChecksum(declared: declared, computed: computed)
        }
        
        return (type, data)
    }
}
