import LZ77
import Testing

@Suite
enum Compression
{
    @Test(arguments: [4, 7, 9], [5, 15, 100, 200, 2000, 5000])
    static func LZ77(_ level:Int, _ count:Int) throws
    {
        let input:[UInt8] = (0 ..< count).map{ _ in .random(in: .min ... .max) }

        var deflator:LZ77.Deflator = .init(level: level, exponent: 8, hint: 16)
            deflator.push(input[...], last: true)

        var compressed:[UInt8] = []
        while let part:[UInt8] = deflator.pull()
        {
            compressed += part
        }

        var inflator:LZ77.Inflator = .init()
        try inflator.push(compressed[...])

        let output:[UInt8] = inflator.pull()

        #expect(input == output)
    }

    @Test(arguments: [5, 15, 100, 200, 2000, 5000])
    static func Gzip(_ count:Int) throws
    {
        let input:[UInt8] = (0 ..< count).map{ _ in .random(in: .min ... .max) }

        var deflator:Gzip.Deflator = .init(level: 7, exponent: 15, hint: 64 << 10)
            deflator.push(input[...], last: true)

        var compressed:[UInt8] = []
        while let part:[UInt8] = deflator.pull()
        {
            compressed += part
        }

        var inflator:Gzip.Inflator = .init()
        try inflator.push(compressed[...])

        let output:[UInt8] = inflator.pull()

        #expect(input == output)
    }
}
