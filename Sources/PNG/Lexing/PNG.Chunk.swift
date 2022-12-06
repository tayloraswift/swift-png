extension PNG
{
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
