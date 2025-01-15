import PNG
import Testing

@Suite
enum Roundtripping
{
    @Test(arguments: Self.basic)
    static func DecodeBasic(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "Common")
    }

    @Test(arguments: Self.interlaced)
    static func DecodeInterlaced(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "Common")
    }

    @Test(arguments: Self.oddSizes)
    static func DecodeOddSizes(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "Common")
    }

    @Test(arguments: Self.backgrounds)
    static func DecodeBackgrounds(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "Common")
    }

    @Test(arguments: Self.transparency)
    static func DecodeTransparency(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "Common")
    }

    @Test(arguments: Self.gamma)
    static func DecodeGamma(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "Common")
    }

    @Test(arguments: Self.filters)
    static func DecodeFilters(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "Common")
    }

    @Test(arguments: Self.palettes)
    static func DecodePalettes(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "Common")
    }

    @Test(arguments: Self.ancillary)
    static func DecodeAncillary(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "Common")
    }

    @Test(arguments: Self.chunkOrdering)
    static func DecodeChunkOrdering(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "Common")
    }

    @Test(arguments: Self.lz77)
    static func DecodeLZ77(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "Common")
    }

    @Test(arguments: Self.iOS)
    static func DecodeiPhoneOptimized(_ name:String) throws
    {
        try Self.decode(name, subdirectory: "iOS")
    }


    @Test(arguments: Self.basic, [4, 7, 10])
    static func EncodeBasic(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "Common", level: level)
    }

    @Test(arguments: Self.interlaced, [4, 7, 10])
    static func EncodeInterlaced(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "Common", level: level)
    }

    @Test(arguments: Self.oddSizes, [4, 7, 10])
    static func EncodeOddSizes(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "Common", level: level)
    }

    @Test(arguments: Self.backgrounds, [4, 7, 10])
    static func EncodeBackgrounds(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "Common", level: level)
    }

    @Test(arguments: Self.transparency, [4, 7, 10])
    static func EncodeTransparency(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "Common", level: level)
    }

    @Test(arguments: Self.gamma, [4, 7, 10])
    static func EncodeGamma(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "Common", level: level)
    }

    @Test(arguments: Self.filters, [4, 7, 10])
    static func EncodeFilters(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "Common", level: level)
    }

    @Test(arguments: Self.palettes, [4, 7, 10])
    static func EncodePalettes(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "Common", level: level)
    }

    @Test(arguments: Self.ancillary, [4, 7, 10])
    static func EncodeAncillary(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "Common", level: level)
    }

    @Test(arguments: Self.chunkOrdering, [4, 7, 10])
    static func EncodeChunkOrdering(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "Common", level: level)
    }

    @Test(arguments: Self.lz77, [4, 7, 10])
    static func EncodeLZ77(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "Common", level: level)
    }

    @Test(arguments: Self.iOS, [13])
    static func EncodeiPhoneOptimized(_ name:String, _ level:Int) throws
    {
        try Self.encode(name, subdirectory: "iOS", level: level)
    }
}
extension Roundtripping
{
    private
    static func decode(_ name:String, subdirectory:String) throws
    {
        try Self.decode(path:
            (
                "Sources/PNGIntegrationTests/Inputs/\(subdirectory)/\(name).png",
                "Sources/PNGIntegrationTests/RGBA/\(name).png.rgba"
            ),
            premultiplied: subdirectory == "iOS")
    }

    private
    static func decode(path:(in:String, rgba:String), premultiplied:Bool) throws
    {
        guard
        let rectangular:PNG.Image = try .decompress(path: path.in)
        else
        {
            Issue.record("failed to open file '\(path.in)'")
            return
        }

        let image:[PNG.RGBA<UInt16>] = rectangular.unpack(as: PNG.RGBA<UInt16>.self)

        // if !Global.options.contains(.compact)
        // {
        //     print(Self.terminal(image: image, size: rectangular.size))
        //     print(rectangular.metadata)
        //     print()
        // }

        guard
        let result:[PNG.RGBA<UInt16>]? = (System.File.Source.open(path: path.rgba)
        {
            let pixels:Int = rectangular.size.x * rectangular.size.y,
                bytes:Int  = pixels * MemoryLayout<PNG.RGBA<UInt16>>.stride

            guard
            let data:[UInt8] = $0.read(count: bytes)
            else
            {
                return nil
            }

            return (0 ..< pixels).map
            {
                let r:UInt16 = data.load(littleEndian: UInt16.self, at: $0 << 3),
                    g:UInt16 = data.load(littleEndian: UInt16.self, at: $0 << 3 | 2),
                    b:UInt16 = data.load(littleEndian: UInt16.self, at: $0 << 3 | 4),
                    a:UInt16 = data.load(littleEndian: UInt16.self, at: $0 << 3 | 6)

                let pixel:PNG.RGBA<UInt16> = .init(r, g, b, a)
                // have to manually premultiply since the CgBI formula does the
                // multiplication in 8-bit precision
                if  premultiplied
                {
                    return pixel.premultiplied(as: UInt8.self)
                }
                else
                {
                    return pixel
                }
            }
        })
        else
        {
            Issue.record("failed to open file '\(path.rgba)'")
            return
        }

        guard let reference:[PNG.RGBA<UInt16>] = result
        else
        {
            Issue.record("failed to read file '\(path.rgba)'")
            return
        }

        for (i, pair):(Int, (PNG.RGBA<UInt16>, PNG.RGBA<UInt16>)) in
            zip(image, reference).enumerated()
        {
            #expect(pair.0 == pair.1, "mismatch in pixel \(i)")
        }
    }
}
extension Roundtripping
{
    private
    static func encode(_ name:String, subdirectory:String, level:Int) throws
    {
        try Self.encode(path:
            (
                "Sources/PNGIntegrationTests/Inputs/\(subdirectory)/\(name).png",
                "Sources/PNGIntegrationTests/RGBA/\(name).png.rgba",
                "Sources/PNGIntegrationTests/Outputs/\(subdirectory)/\(name).png"
            ),
            level: level,
            premultiplied: subdirectory == "iOS")
    }

    private
    static func encode(path:(in:String, rgba:String, out:String),
        level:Int,
        premultiplied:Bool) throws
    {
        guard
        let rectangular:PNG.Image = try .decompress(path: path.in)
        else
        {
            Issue.record("failed to open file '\(path.in)'")
            return
        }

        try rectangular.compress(path: path.out, level: level)
        try Self.decode(path: (in: path.out, rgba: path.rgba), premultiplied: premultiplied)
    }
}
extension Roundtripping
{
    private
    static let basic:[String] = [
        "PngSuite",

        "basn0g01",
        "basn0g02",
        "basn0g04",
        "basn0g08",
        "basn0g16",
        "basn2c08",
        "basn2c16",
        "basn3p01",
        "basn3p02",
        "basn3p04",
        "basn3p08",
        "basn4a08",
        "basn4a16",
        "basn6a08",
        "basn6a16"
    ]

    private
    static let interlaced:[String] = [
        "basi0g01",
        "basi0g02",
        "basi0g04",
        "basi0g08",
        "basi0g16",
        "basi2c08",
        "basi2c16",
        "basi3p01",
        "basi3p02",
        "basi3p04",
        "basi3p08",
        "basi4a08",
        "basi4a16",
        "basi6a08",
        "basi6a16"
    ]

    private
    static let oddSizes:[String] = [
        "s01i3p01",
        "s01n3p01",
        "s02i3p01",
        "s02n3p01",
        "s03i3p01",
        "s03n3p01",
        "s04i3p01",
        "s04n3p01",
        "s05i3p02",
        "s05n3p02",
        "s06i3p02",
        "s06n3p02",
        "s07i3p02",
        "s07n3p02",
        "s08i3p02",
        "s08n3p02",
        "s09i3p02",
        "s09n3p02",
        "s32i3p04",
        "s32n3p04",
        "s33i3p04",
        "s33n3p04",
        "s34i3p04",
        "s34n3p04",
        "s35i3p04",
        "s35n3p04",
        "s36i3p04",
        "s36n3p04",
        "s37i3p04",
        "s37n3p04",
        "s38i3p04",
        "s38n3p04",
        "s39i3p04",
        "s39n3p04",
        "s40i3p04",
        "s40n3p04"
    ]

    private
    static let backgrounds:[String] = [
        "bgai4a08",
        "bgai4a16",
        "bgan6a08",
        "bgan6a16",
        "bgbn4a08",
        "bggn4a16",
        "bgwn6a08",
        "bgyn6a16"
    ]

    private
    static let transparency:[String] = [
        "tbbn0g04",
        "tbbn2c16",
        "tbbn3p08",
        "tbgn2c16",
        "tbgn3p08",
        "tbrn2c08",
        "tbwn0g16",
        "tbwn3p08",
        "tbyn3p08",
        "tm3n3p02",
        "tp0n0g08",
        "tp0n2c08",
        "tp0n3p08",
        "tp1n3p08"
    ]

    private
    static let gamma:[String] = [
        "g03n0g16",
        "g03n2c08",
        "g03n3p04",
        "g04n0g16",
        "g04n2c08",
        "g04n3p04",
        "g05n0g16",
        "g05n2c08",
        "g05n3p04",
        "g07n0g16",
        "g07n2c08",
        "g07n3p04",
        "g10n0g16",
        "g10n2c08",
        "g10n3p04",
        "g25n0g16",
        "g25n2c08",
        "g25n3p04"
    ]

    private
    static let filters:[String] = [
        "f00n0g08",
        "f00n2c08",
        "f01n0g08",
        "f01n2c08",
        "f02n0g08",
        "f02n2c08",
        "f03n0g08",
        "f03n2c08",
        "f04n0g08",
        "f04n2c08",
        "f99n0g04"
    ]

    private
    static let palettes:[String] = [
        "pp0n2c16",
        "pp0n6a08",
        "ps1n0g08",
        "ps1n2c16",
        "ps2n0g08",
        "ps2n2c16"
    ]

    private
    static let ancillary:[String] = [
        "ccwn2c08",
        "ccwn3p08",
        "cdfn2c08",
        "cdhn2c08",
        "cdsn2c08",
        "cdun2c08",
        "ch1n3p04",
        "ch2n3p08",
        "cm0n0g04",
        "cm7n0g04",
        "cm9n0g04",
        "cs3n2c16",
        "cs3n3p08",
        "cs5n2c08",
        "cs5n3p08",
        "cs8n2c08",
        "cs8n3p08",
        "ct0n0g04",
        "ct1n0g04",
        "cten0g04",
        "ctfn0g04",
        "ctgn0g04",
        "cthn0g04",
        "ctjn0g04",
        "ctzn0g04"
    ]

    private
    static let chunkOrdering:[String] = [
        "oi1n0g16",
        "oi1n2c16",
        "oi2n0g16",
        "oi2n2c16",
        "oi4n0g16",
        "oi4n2c16",
        "oi9n0g16",
        "oi9n2c16"
    ]

    private
    static let lz77:[String] = [
        "z00n2c08",
        "z03n2c08",
        "z06n2c08",
        "z09n2c08"
    ]

    private
    static let iOS:[String] = [
        "PngSuite",
        "basi2c08",
        "basi6a08",
        "basn2c08",
        "basn6a08",
        "bgan6a08",
        "bgwn6a08",
        "ccwn2c08",
        "cdfn2c08",
        "cdhn2c08",
        "cdsn2c08",
        "cdun2c08",
        "cs5n2c08",
        "cs8n2c08",
        "f00n2c08",
        "f01n2c08",
        "f02n2c08",
        "f03n2c08",
        "f04n2c08",
        "g03n2c08",
        "g04n2c08",
        "g05n2c08",
        "g07n2c08",
        "g10n2c08",
        "g25n2c08",
        "pp0n6a08",
        "tbrn2c08",
        "tp0n2c08",
        "z00n2c08",
        "z03n2c08",
        "z06n2c08",
        "z09n2c08",
    ]
}
