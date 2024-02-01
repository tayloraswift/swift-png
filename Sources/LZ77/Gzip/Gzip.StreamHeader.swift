extension Gzip
{
    @frozen public
    struct StreamHeader
    {
        let flag:(Bool, Bool, Bool, Bool, Bool)
        let xlen:Int

        init(flag:(Bool, Bool, Bool, Bool, Bool), xlen:Int)
        {
            self.flag = flag
            self.xlen = xlen
        }
    }
}
extension Gzip.StreamHeader
{
    static
    func read(_ input:inout LZ77.InflatorIn, from bit:inout Int) throws -> Self?
    {
        guard bit + 80 <= input.count
        else
        {
            return nil
        }

        guard
        case 0x1f = input[bit,     count: 8, as: UInt8.self],
        case 0x8b = input[bit + 8, count: 8, as: UInt8.self]
        else
        {
            throw Gzip.StreamHeaderError.invalidSigil
        }

        switch input[bit + 16, count: 8, as: UInt8.self]
        {
        case 0x08:      break
        case let code:  throw Gzip.StreamHeaderError.invalidCompressionMethod(code)
        }

        let flags:UInt8 = input[bit + 24, count: 8, as: UInt8.self]
        if  flags & 0b1110_0000 != 0
        {
            throw Gzip.StreamHeaderError.invalidFlagBits(flags)
        }

        let flag:(Bool, Bool, Bool, Bool, Bool) =
        (
            flags & 0x01 != 0,
            flags & 0x02 != 0,
            flags & 0x04 != 0,
            flags & 0x08 != 0,
            flags & 0x10 != 0
        )

        //  TODO: read MTIME instead of skipping over it

        if  flag.2
        {
            guard bit + 96 <= input.count
            else
            {
                //  We will need to reparse the header once more data is available.
                return nil
            }

            let xlen:Int = input[bit + 80, count: 16, as: Int.self]

            bit += 96

            return .init(flag: flag, xlen: xlen)
        }
        else
        {
            bit += 80
            return .init(flag: flag, xlen: 0)
        }
    }
}
