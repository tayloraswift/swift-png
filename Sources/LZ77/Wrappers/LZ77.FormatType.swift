extension LZ77
{
    @usableFromInline
    typealias FormatType = _LZ77FormatType
}
@usableFromInline
protocol _LZ77FormatType
{
    associatedtype Integral:LZ77.StreamIntegral
}
