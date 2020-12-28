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
        let name:UInt32
        /// A string displaying the ASCII representation of this PNG chunk type’s name.
        public
        var description:String
        {
            withUnsafeBytes(of: self.name.bigEndian) 
            {
                .init(decoding: $0, as: Unicode.ASCII.self)
            }
        }
        
        private 
        init(unchecked name:UInt32) 
        {
            self.name = name
        }
        
        public
        init(name:UInt32)
        {
            guard let chunk:Self = Self.init(validating: name) 
            else 
            {
                let string:String = withUnsafeBytes(of: name.bigEndian) 
                {
                    .init(decoding: $0, as: Unicode.ASCII.self)
                }
                preconditionFailure("'\(string)' is not a valid png chunk type")
            }
            self = chunk 
        }
        
        public 
        init?(validating name:UInt32) 
        {
            let chunk:Self = .init(unchecked: name) 
            switch chunk 
            {
            // legal public chunks
            case    .CgBI, .IHDR, .PLTE, .IDAT, .IEND,
                    .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS,
                    .pHYs, .sPLT, .tIME, .iTXt, .tEXt, .zTXt:
                break

            default:
                guard chunk.name & 0x20_00_20_00 == 0x20_00_00_00
                else
                {
                    return nil
                }
            }
            self.name = name
        }
        
        public static
        let CgBI:Self = .init(unchecked: 0x43_67_42_49)
        /// The PNG header chunk type.
        public static
        let IHDR:Self = .init(unchecked: 0x49_48_44_52)
        /// The PNG palette chunk type.
        public static
        let PLTE:Self = .init(unchecked: 0x50_4c_54_45)
        /// The PNG image data chunk type.
        public static
        let IDAT:Self = .init(unchecked: 0x49_44_41_54)
        /// The PNG image end chunk type.
        public static
        let IEND:Self = .init(unchecked: 0x49_45_4e_44)

        /// The PNG chromaticity chunk type.
        public static
        let cHRM:Self = .init(unchecked: 0x63_48_52_4d)
        /// The PNG gamma chunk type.
        public static
        let gAMA:Self = .init(unchecked: 0x67_41_4d_41)
        /// The PNG embedded ICC chunk type.
        public static
        let iCCP:Self = .init(unchecked: 0x69_43_43_50)
        /// The PNG significant bits chunk type.
        public static
        let sBIT:Self = .init(unchecked: 0x73_42_49_54)
        /// The PNG *s*RGB chunk type.
        public static
        let sRGB:Self = .init(unchecked: 0x73_52_47_42)
        /// The PNG background chunk type.
        public static
        let bKGD:Self = .init(unchecked: 0x62_4b_47_44)
        /// The PNG histogram chunk type.
        public static
        let hIST:Self = .init(unchecked: 0x68_49_53_54)
        /// The PNG transparency chunk type.
        public static
        let tRNS:Self = .init(unchecked: 0x74_52_4e_53)

        /// The PNG physical dimensions chunk type.
        public static
        let pHYs:Self = .init(unchecked: 0x70_48_59_73)

        /// The PNG suggested palette chunk type.
        public static
        let sPLT:Self = .init(unchecked: 0x73_50_4c_54)
        /// The PNG time chunk type.
        public static
        let tIME:Self = .init(unchecked: 0x74_49_4d_45)

        /// The PNG UTF-8 text chunk type.
        public static
        let iTXt:Self = .init(unchecked: 0x69_54_58_74)
        /// The PNG Latin-1 text chunk type.
        public static
        let tEXt:Self = .init(unchecked: 0x74_45_58_74)
        /// The PNG compressed Latin-1 text chunk type.
        public static
        let zTXt:Self = .init(unchecked: 0x7a_54_58_74)
    }
}

// http://www.libpng.org/pub/png/spec/1.2/PNG-CRCAppendix.html
extension PNG 
{
    enum CRC32 
    {
        private static 
        let table:[UInt32] = (0 ..< 256).map 
        {
            (i:UInt32) in 
            (0 ..< 8).reduce(i){ (c, _) in (c & 1 * 0xed_b8_83_20) ^ c >> 1 }
        }
        
        static 
        func update<S>(_ crc:UInt32, with input:S) -> UInt32 
            where S:Sequence, S.Element == UInt8 
        {
            ~input.reduce(~crc) 
            {
                (c:UInt32, byte:UInt8) in 
                Self.table[.init((.init(truncatingIfNeeded: c) ^ byte))] ^ c >> 8
            }
        }
        
        static 
        func compute<S>(_ input:S) -> UInt32 
            where S:Sequence, S.Element == UInt8 
        {
            Self.update(0, with: input)
        }
    }
}

extension PNG.Bytestream.Source 
{
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

extension PNG.Bytestream.Destination 
{
    public mutating 
    func signature() throws 
    {
        guard let _:Void = self.write(PNG.signature)
        else
        {
            throw PNG.FormattingError.invalidDestination
        }
    }
    
    public mutating 
    func format(type:PNG.Chunk, data:[UInt8] = []) throws 
    {
        let header:[UInt8] = .init(unsafeUninitializedCapacity: 8) 
        {
            $0.store(data.count, asBigEndian: UInt32.self, at: 0)
            $0.store(type.name,  asBigEndian: UInt32.self, at: 4)
            $1 = 8
        }
        let footer:[UInt8] = .init(unsafeUninitializedCapacity: 4) 
        {
            let crc:UInt32 = PNG.CRC32.update(PNG.CRC32.compute(header.suffix(4)), with: data)
            $0.store(crc, asBigEndian: UInt32.self)
            $1 = 4
        }
        
        guard   let _:Void = self.write(header), 
                let _:Void = self.write(data), 
                let _:Void = self.write(footer)
        else
        {
            throw PNG.FormattingError.invalidDestination
        }
    }
}
