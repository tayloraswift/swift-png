import LZ77
import Testing

extension Main
{
    enum CompressionMicro
    {
    }
}
extension Main.CompressionMicro:TestBattery
{
    static
    func run(tests:TestGroup)
    {
        if  let tests:TestGroup = tests / "Empty"
        {
            Self.roundtrip(bytes: [], with: tests)
        }
        if  let tests:TestGroup = tests / "OneByte"
        {
            Self.roundtrip(bytes: [1], with: tests)
        }
        if  let tests:TestGroup = tests / "TwoBytes"
        {
            Self.roundtrip(bytes: [2, 3], with: tests)
        }
        if  let tests:TestGroup = tests / "ThreeBytes"
        {
            Self.roundtrip(bytes: [4, 5, 6], with: tests)
        }
        if  let tests:TestGroup = tests / "InParts"
        {
            var deflator:Gzip.Deflator = .init(level: 13, exponent: 15)
            deflator.push([1], last: false)
            deflator.push([2], last: true)

            var archive:[UInt8] = []
            while let part:[UInt8] = deflator.pull()
            {
                archive += part
            }

            tests.do
            {
                tests.expect(try Gzip.extract(from: archive[...]) ..? [1, 2])
            }
        }
    }

    private static
    func roundtrip(bytes:[UInt8], with tests:TestGroup)
    {
        let archive:[UInt8] = Gzip.archive(bytes: bytes[...], level: 10)
        tests.do
        {
            tests.expect(try Gzip.extract(from: archive[...]) ..? bytes)
        }
    }
}
