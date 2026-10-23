import LZ77
import Testing

@Suite enum CompressionMicro {
    @Test(arguments: [[], [1], [2, 3], [4, 5, 6]])
    static func Roundtrip(_ bytes: [UInt8]) throws {
        let archive: [UInt8] = Gzip.archive(bytes: bytes[...], level: 10)
        #expect(try Gzip.extract(from: archive[...]) == bytes)
    }

    @Test static func InParts() throws {
        var deflator: Gzip.Deflator = .init(level: 13, exponent: 15)
        deflator.push([1], last: false)
        deflator.push([2], last: true)

        var archive: [UInt8] = []
        while let part: [UInt8] = deflator.pull() {
            archive += part
        }

        #expect(try Gzip.extract(from: archive[...]) == [1, 2])
    }

    @Test static func ZlibDeflator() {
        var deflator: LZ77.Deflator = .init(format: .zlib, level: 7, hint: 128 << 10)
        deflator.push([1, 2, 3][...], last: true)
        var count: Int = 0
        while let part: [UInt8] = deflator.pull() {
            count += part.count
        }
        #expect(count == 19)
    }
}
