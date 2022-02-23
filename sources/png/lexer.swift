//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/. 

/// module PNG 
///     Decode, inspect, edit, and encode PNG images.
/// 
///     See example programs and library tutorials [here](https://github.com/kelvin13/swift-png/tree/master/examples).
/// #  [Top level namespaces](top-level-namespaces)

/// protocol PNG.Bytestream.Source 
///     A source bytestream.
/// 
///     To implement a custom data source type, conform it to this protocol by 
///     implementing [`(Source).read(count:)`]. It can 
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
    /// - ->        : [Swift.UInt8]?
    ///     The `count` bytes read, or `nil` if the read attempt failed. This 
    ///     method should return `nil` even if any number of bytes less than `count`
    ///     were successfully read.
    /// ## (file-io-source-interface)
    mutating
    func read(count:Int) -> [UInt8]?
}
/// protocol PNG.Bytestream.Destination 
///     A destination bytestream.
/// 
///     To implement a custom data destination type, conform it to this protocol by 
///     implementing [`(Destination).write(_:)`]. It can 
///     then be used with the library’s core compression interfaces.
/// #  [Stream interface](file-io-destination-interface)
/// #  [See also](file-io-protocols, system-file-destination)
/// ## (2:file-io-protocols)
/// ## (2:lexing-and-formatting)
public
protocol _PNGBytestreamDestination
{
    /// mutating func PNG.Bytestream.Destination.write(_:)
    /// required 
    ///     Attempts to write the given bytes to this stream.
    /// 
    ///     A successful call to this function should affect the bytestream state 
    ///     such that subsequent calls should pick up where the last call left off.
    /// 
    ///     The rest of the library interprets a `nil` return value from this function 
    ///     as indicating a write failure.
    /// - bytes     : [Swift.UInt8]
    ///     The bytes to write. 
    /// - ->        : Swift.Void?
    ///     A [`Swift.Void`] tuple, or `nil` if the write attempt failed. This 
    ///     method should return `nil` even if any number of bytes less than 
    ///     `bytes.count` were successfully written.
    /// ## (file-io-destination-interface)
    mutating
    func write(_ buffer:[UInt8]) -> Void?
}

/// enum PNG 
///     A namespace for PNG-related functionality. 
/// #  [Image data](images)
/// #  [Color formats](color-formats)
/// #  [Color targets](color-targets)
/// #  [Color target customization](custom-color-targets)
/// #  [Data IO and file structure](lexing-and-formatting)
/// #  [Parsed chunks](parsed-chunk-types)
/// #  [Contextual decoding](contextual-decoding)
/// #  [Currency types](currency-types)
/// #  [Error handling](error-handling)
/// #  [See also](top-level-namespaces)
/// ## (0:top-level-namespaces)
public 
enum PNG 
{
    static 
    let signature:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    
    /// enum PNG.Bytestream 
    ///     A namespace for bytestream utilities.
    /// #  [File IO](file-io-protocols)
    /// ## (0:file-io-protocols)
    /// ## (0:lexing-and-formatting)
    public 
    enum Bytestream 
    {
        public 
        typealias Source        = _PNGBytestreamSource
        public 
        typealias Destination   = _PNGBytestreamDestination
    }
    
    /// struct PNG.Chunk 
    /// :   Swift.Hashable 
    /// :   Swift.Equatable 
    /// :   Swift.CustomStringConvertible
    ///     A chunk type identifier.
    /// ## (lexing-and-formatting)
    public 
    struct Chunk:Hashable, Equatable, CustomStringConvertible
    {
        /// let PNG.Chunk.name  : Swift.UInt32
        ///     The chunk type code.
        public 
        let name:UInt32
        /// var PNG.Chunk.description : Swift.String { get }
        ///     A string displaying the ASCII representation of this chunk type identifier.
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
        
        /// init PNG.Chunk.init(name:)
        ///     Creates a chunk type identifier. 
        /// 
        ///     The chunk type code is a four byte integer, where bit 5 in each 
        ///     constituent byte is a flag bit. 
        /// 
        ///     The flag bit in the uppermost byte (bit 29) is the **ancillary bit**. 
        ///     
        ///     The flag bit in the third byte (bit 21) is the **private bit**. 
        /// 
        ///     The flag bit in the second byte (bit 13) is reserved and must be set.
        /// 
        ///     The flag bit in the lowest byte (bit 5) is the **safe-to-copy** bit.
        /// 
        ///     Passing an invalid type code will result in a precondition failure. 
        ///     For a failable version of this initializer, use [`init(validating:)`].
        ///     For more details on type code semantics, consult the 
        ///     [PNG specification](http://www.libpng.org/pub/png/spec/1.2/PNG-Structure.html).
        /// - name : Swift.UInt32 
        ///     The chunk type code. Bit 13 must be set. If the type code is not 
        ///     a public PNG chunk type code, then bit 29 must be clear.
        /// #  [See also](chunk-type-identifier-initializers)
        /// ## (chunk-type-identifier-initializers)
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
        
        /// init PNG.Chunk.init?(validating:)
        ///     Creates a chunk type identifier, returning `nil` if the type code 
        ///     is invalid. 
        /// 
        ///     This initializer is a non-trapping version of [`init(name:)`].
        /// - name : Swift.UInt32 
        ///     The chunk type code. Bit 13 must be set. If the type code is not 
        ///     a public PNG chunk type code, then bit 29 must be clear.
        /// #  [See also](chunk-type-identifier-initializers)
        /// ## (chunk-type-identifier-initializers)
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
        
        /// static let PNG.Chunk.CgBI : Self 
        ///     The `CgBI` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x43674249`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let CgBI:Self = .init(unchecked: 0x43_67_42_49)
        /// static let PNG.Chunk.IHDR : Self 
        ///     The `IHDR` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x49484452`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let IHDR:Self = .init(unchecked: 0x49_48_44_52)
        /// static let PNG.Chunk.PLTE : Self 
        ///     The `PLTE` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x504c5445`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let PLTE:Self = .init(unchecked: 0x50_4c_54_45)
        /// static let PNG.Chunk.IDAT : Self 
        ///     The `IDAT` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x49444154`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let IDAT:Self = .init(unchecked: 0x49_44_41_54)
        /// static let PNG.Chunk.IEND : Self 
        ///     The `IEND` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x49454e44`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let IEND:Self = .init(unchecked: 0x49_45_4e_44)

        /// static let PNG.Chunk.cHRM : Self 
        ///     The `cHRM` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x6348524d`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let cHRM:Self = .init(unchecked: 0x63_48_52_4d)
        /// static let PNG.Chunk.gAMA : Self 
        ///     The `gAMA` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x67414d41`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let gAMA:Self = .init(unchecked: 0x67_41_4d_41)
        /// static let PNG.Chunk.iCCP : Self 
        ///     The `iCCP` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x69434350`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let iCCP:Self = .init(unchecked: 0x69_43_43_50)
        /// static let PNG.Chunk.sBIT : Self 
        ///     The `sBIT` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x73424954`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let sBIT:Self = .init(unchecked: 0x73_42_49_54)
        /// static let PNG.Chunk.sRGB : Self 
        ///     The `sRGB` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x73524742`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let sRGB:Self = .init(unchecked: 0x73_52_47_42)
        /// static let PNG.Chunk.bKGD : Self 
        ///     The `bKGD` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x624b4744`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let bKGD:Self = .init(unchecked: 0x62_4b_47_44)
        /// static let PNG.Chunk.hIST : Self 
        ///     The `hIST` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x68495354`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let hIST:Self = .init(unchecked: 0x68_49_53_54)
        /// static let PNG.Chunk.tRNS : Self 
        ///     The `tRNS` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x74524e53`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let tRNS:Self = .init(unchecked: 0x74_52_4e_53)

        /// static let PNG.Chunk.pHYs : Self 
        ///     The `pHYs` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x70485973`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let pHYs:Self = .init(unchecked: 0x70_48_59_73)

        /// static let PNG.Chunk.sPLT : Self 
        ///     The `sPLT` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x73504c54`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let sPLT:Self = .init(unchecked: 0x73_50_4c_54)
        /// static let PNG.Chunk.tIME : Self 
        ///     The `tIME` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x74494d45`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let tIME:Self = .init(unchecked: 0x74_49_4d_45)

        /// static let PNG.Chunk.iTXt : Self 
        ///     The `iTXt` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x69545874`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let iTXt:Self = .init(unchecked: 0x69_54_58_74)
        /// static let PNG.Chunk.tEXt : Self 
        ///     The `tEXt` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x74455874`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
        public static
        let tEXt:Self = .init(unchecked: 0x74_45_58_74)
        /// static let PNG.Chunk.zTXt : Self 
        ///     The `zTXt` chunk type. 
        /// 
        ///     The numerical type code for this type identifier is `0x7a545874`.
        /// # [See also](chunk-type-identifiers)
        /// ## (chunk-type-identifiers)
        /// ## ()
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
    /// mutating func PNG.Bytestream.Source.signature()
    /// throws 
    ///     Lexes the eight PNG signature bytes from this bytestream. 
    /// 
    ///     This function expects to read the byte sequence 
    ///     `[137, 80, 78, 71, 13, 10, 26, 10]`. It reports end-of-stream by throwing 
    ///     [`LexingError.truncatedSignature`]. To recover on end-of-stream, 
    ///     catch this error case.
    /// 
    ///     This function is the inverse of [`Destination.signature()`].
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
    ///     [`LexingError.truncatedChunkHeader`] or 
    ///     [`LexingError.truncatedChunkBody(expected:)`]. To recover on end-of-stream, 
    ///     catch these two error cases.
    /// 
    ///     This function is the inverse of [`Destination.format(type:data:)`].
    /// - -> : (type:PNG.Chunk, data:[Swift.UInt8])
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
    /// mutating func PNG.Bytestream.Destination.signature()
    /// throws 
    ///     Emits the eight PNG signature bytes into this bytestream. 
    /// 
    ///     This function emits the constant byte sequence 
    ///     `[137, 80, 78, 71, 13, 10, 26, 10]`. It will throw a 
    ///     [`FormattingError`] if it fails to write to the bytestream.
    /// 
    ///     This function is the inverse of [`Source.signature()`].
    public mutating 
    func signature() throws 
    {
        guard let _:Void = self.write(PNG.signature)
        else
        {
            throw PNG.FormattingError.invalidDestination
        }
    }
    /// mutating func PNG.Bytestream.Destination.format(type:data:)
    /// throws 
    ///     Emits a chunk into this bytestream. 
    /// 
    ///     This function will compute the checksum for the given chunk contents and 
    ///     format it with the appropriate chunk headers and footers. It will throw a 
    ///     [`FormattingError`] if it fails to write to the bytestream.
    /// 
    ///     This function is the inverse of [`Source.chunk()`].
    /// - type : PNG.Chunk 
    ///     The type identifier of the chunk to emit.
    /// - data : [Swift.UInt8]
    ///     The contents of the chunk to emit. It should not include a checksum 
    ///     footer, as this function computes and appends it automatically. 
    /// 
    ///     The default value is `[]`.
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
