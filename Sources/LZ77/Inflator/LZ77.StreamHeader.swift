extension LZ77
{
    struct StreamHeader
    {
        let exponent:Int

        private
        init(exponent:Int)
        {
            self.exponent = exponent
        }
    }
}
extension LZ77.StreamHeader
{
    static
    func read(_ input:inout LZ77.InflatorIn, from bit:inout Int) throws -> Self?
    {
        // read stream header
        guard bit + 16 <= input.count
        else
        {
            return nil
        }

        switch input[bit + 0, count: 4, as: UInt8.self]
        {
        case 0x08:      break
        case let code:  throw LZ77.StreamHeaderError.invalidCompressionMethod(code)
        }

        let e:Int = input[bit + 4, count: 4, as: Int.self]

        guard e < 8
        else
        {
            throw LZ77.StreamHeaderError.invalidWindowSize(exponent: e + 8)
        }

        let flags:Int = input[bit + 8, count: 8, as: Int.self]
        guard (e << 12 | 8 << 8 + flags) % 31 == 0
        else
        {
            throw LZ77.StreamHeaderError.invalidCheckBits
        }
        guard flags & 0x20 == 0
        else
        {
            throw LZ77.StreamHeaderError.unexpectedDictionary
        }

        bit += 16

        return .init(exponent: 8 + e)
    }
}
