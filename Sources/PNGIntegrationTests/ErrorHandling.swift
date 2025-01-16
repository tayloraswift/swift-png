import PNG
import Testing

@Suite
enum ErrorHandling
{
    @Test(arguments: [
            "xs1n0g01",
            "xs2n0g01",
            "xs4n0g01",
            "xs7n0g01",
            "xcrn0g04",
            "xlfn0g04"
        ])
    static func InvalidSignatures(_ name:String) throws
    {
        #expect(throws: PNG.LexingError.self)
        {
            try Self.decode(name)
        }
    }

    @Test
    static func InvalidIHDRChecksum() throws
    {
        do
        {
            try decode("xhdn0g08")
        }
        catch PNG.LexingError.invalidChunkChecksum(declared: 1129534797, computed: 1443964200)
        {
        }
    }

    @Test
    static func InvalidIDATChecksum() throws
    {
        do
        {
            try decode("xcsn0g01")
        }
        catch PNG.LexingError.invalidChunkChecksum(declared: 1129534797, computed: 3492746441)
        {
        }
    }

    @Test(arguments: [
            ("xc1n0g08", ( 8, 1)),
            ("xc9n2c08", ( 8, 9)),
            ("xd0n2c08", ( 0, 2)),
            ("xd3n2c08", ( 3, 2)),
            ("xd9n2c08", (99, 2)),
        ])
    static func InvalidColorFormat(_ name:String, _ code:(UInt8, UInt8)) throws
    {
        do
        {
            try Self.decode(name)
        }
        catch PNG.ParsingError.invalidHeaderPixelFormatCode((code.0, code.1))
        {
        }
    }

    @Test(arguments: ["xdtn0g01"])
    static func MissingIDAT(_ name:String) throws
    {
        do
        {
            try decode(name)
        }
        catch PNG.DecodingError.required(chunk: .IDAT, before: .IEND)
        {
        }
    }

    private
    static func decode(_ name:String) throws
    {
        let path:String = "Sources/PNGIntegrationTests/Inputs/Invalid/\(name).png"
        if  let _:PNG.Image = try .decompress(path: path)
        {
            Issue.record("file '\(path)' is invalid, but decoded without errors")
        }
        else
        {
            Issue.record("failed to read file '\(path)'")
        }
    }
}
