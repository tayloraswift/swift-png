extension LZ77
{
    @available(*, deprecated, renamed: "DeflateFormat")
    public
    typealias Format = DeflateFormat

    @frozen public
    enum DeflateFormat
    {
        case zlib
        case ios
    }
}
extension LZ77.DeflateFormat:LZ77.StreamFormat
{
    public
    typealias Integral = LZ77.MRC32

    public
    func begin(inflating input:inout LZ77.InflatorIn,
        at bit:inout Int) throws -> LZ77.DeflateHeader?
    {
        if  case .ios = self
        {
            return .init(exponent: 15)
        }

        // read stream header
        guard bit + 16 <= input.count
        else
        {
            return nil
        }

        switch input[bit + 0, count: 4, as: UInt8.self]
        {
        case 8:
            break
        case let code:
            throw LZ77.DeflateHeaderError.invalidCompressionMethod(code)
        }

        let e:Int = input[bit + 4, count: 4, as: Int.self]

        guard e < 8
        else
        {
            throw LZ77.DeflateHeaderError.invalidWindowSize(exponent: e + 8)
        }

        let flags:Int = input[bit + 8, count: 8, as: Int.self]
        guard (e << 12 | 8 << 8 + flags) % 31 == 0
        else
        {
            throw LZ77.DeflateHeaderError.invalidCheckBits
        }
        guard flags & 0x20 == 0
        else
        {
            throw LZ77.DeflateHeaderError.unexpectedDictionary
        }

        bit += 16

        return .init(exponent: 8 + e)
    }

    public
    func check(inflating input:inout LZ77.InflatorIn, at bit:inout Int) -> UInt32??
    {
        if  case .ios = self
        {
            return .some(nil)
        }

        // skip to next byte boundary, read 4 bytes
        let boundary:Int = (bit + 7) & ~7
        if  boundary + 32 <= input.count
        {
            bit = boundary + 32
        }
        else
        {
            return .none
        }

        // mrc-32 is big-endian
        let bytes:(UInt32, UInt32, UInt32, UInt32) =
        (
            input[boundary,      count: 8, as: UInt32.self],
            input[boundary +  8, count: 8, as: UInt32.self],
            input[boundary + 16, count: 8, as: UInt32.self],
            input[boundary + 24, count: 8, as: UInt32.self]
        )
        let checksum:UInt32   = bytes.0 << 24 |
                                bytes.1 << 16 |
                                bytes.2 <<  8 |
                                bytes.3

        return .some(checksum)
    }
}
