import CRC

extension Gzip
{
    @frozen public
    enum DeflateFormat
    {
        case gzip
    }
}
extension Gzip.Format:LZ77.FormatType
{
    public
    typealias Integral = CRC32
}
