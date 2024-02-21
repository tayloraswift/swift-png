extension PNG
{
    /// A chunk type identifier.
    public
    struct Chunk:Hashable, Equatable, CustomStringConvertible
    {
        /// The chunk type code.
        public
        let name:UInt32
        /// A string displaying the ASCII representation of this chunk type identifier.
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

        /// Creates a chunk type identifier.
        ///
        /// The chunk type code is a four byte integer, where bit 5 in each
        /// constituent byte is a flag bit.
        ///
        /// The flag bit in the uppermost byte (bit 29) is the **ancillary bit**.
        ///
        /// The flag bit in the third byte (bit 21) is the **private bit**.
        ///
        /// The flag bit in the second byte (bit 13) is reserved and must be set.
        ///
        /// The flag bit in the lowest byte (bit 5) is the **safe-to-copy** bit.
        ///
        /// Passing an invalid type code will result in a precondition failure.
        /// For a failable version of this initializer, use ``init(validating:)``.
        /// For more details on type code semantics, consult the
        /// [PNG specification](http://www.libpng.org/pub/png/spec/1.2/PNG-Structure.html).
        /// -   Parameter name:
        ///     The chunk type code. Bit 13 must be set. If the type code is not
        ///     a public PNG chunk type code, then bit 29 must be clear.
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

        /// Creates a chunk type identifier, returning `nil` if the type code
        /// is invalid.
        ///
        /// This initializer is a non-trapping version of ``init(name:)``.
        /// -   Parameter name:
        ///     The chunk type code. Bit 13 must be set. If the type code is not
        ///     a public PNG chunk type code, then bit 29 must be clear.
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

        /// The `CgBI` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x43674249`.
        public static
        let CgBI:Self = .init(unchecked: 0x43_67_42_49)
        /// The `IHDR` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x49484452`.
        public static
        let IHDR:Self = .init(unchecked: 0x49_48_44_52)
        /// The `PLTE` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x504c5445`.
        public static
        let PLTE:Self = .init(unchecked: 0x50_4c_54_45)
        /// The `IDAT` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x49444154`.
        public static
        let IDAT:Self = .init(unchecked: 0x49_44_41_54)
        /// The `IEND` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x49454e44`.
        public static
        let IEND:Self = .init(unchecked: 0x49_45_4e_44)

        /// The `cHRM` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x6348524d`.
        public static
        let cHRM:Self = .init(unchecked: 0x63_48_52_4d)
        /// The `gAMA` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x67414d41`.
        public static
        let gAMA:Self = .init(unchecked: 0x67_41_4d_41)
        /// The `iCCP` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x69434350`.
        public static
        let iCCP:Self = .init(unchecked: 0x69_43_43_50)
        /// The `sBIT` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x73424954`.
        public static
        let sBIT:Self = .init(unchecked: 0x73_42_49_54)
        /// The `sRGB` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x73524742`.
        public static
        let sRGB:Self = .init(unchecked: 0x73_52_47_42)
        /// The `bKGD` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x624b4744`.
        public static
        let bKGD:Self = .init(unchecked: 0x62_4b_47_44)
        /// The `hIST` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x68495354`.
        public static
        let hIST:Self = .init(unchecked: 0x68_49_53_54)
        /// The `tRNS` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x74524e53`.
        public static
        let tRNS:Self = .init(unchecked: 0x74_52_4e_53)

        /// The `pHYs` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x70485973`.
        public static
        let pHYs:Self = .init(unchecked: 0x70_48_59_73)

        /// The `sPLT` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x73504c54`.
        public static
        let sPLT:Self = .init(unchecked: 0x73_50_4c_54)
        /// The `tIME` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x74494d45`.
        public static
        let tIME:Self = .init(unchecked: 0x74_49_4d_45)

        /// The `iTXt` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x69545874`.
        public static
        let iTXt:Self = .init(unchecked: 0x69_54_58_74)
        /// The `tEXt` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x74455874`.
        public static
        let tEXt:Self = .init(unchecked: 0x74_45_58_74)
        /// The `zTXt` chunk type.
        ///
        /// The numerical type code for this type identifier is `0x7a545874`.
        public static
        let zTXt:Self = .init(unchecked: 0x7a_54_58_74)
    }
}
