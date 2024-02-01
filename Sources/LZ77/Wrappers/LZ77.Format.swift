extension LZ77
{
    @available(*, deprecated, renamed: "Format")
    public
    typealias DeflateFormat = Format

    @frozen public
    enum Format
    {
        case zlib
        case ios
    }
}
extension LZ77.Format:LZ77.FormatType
{
    @usableFromInline
    typealias Integral = LZ77.MRC32
}
extension LZ77.Format
{
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
