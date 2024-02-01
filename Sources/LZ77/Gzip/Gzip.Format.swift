import CRC

extension Gzip
{
    @frozen public
    enum Format
    {
        case gzip
    }
}
extension Gzip.Format:LZ77.FormatType
{
    public
    typealias Integral = CRC32
}
