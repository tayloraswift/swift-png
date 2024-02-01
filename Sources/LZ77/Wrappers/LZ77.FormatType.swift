extension LZ77
{
    public
    typealias FormatType = _LZ77FormatType
}
public
protocol _LZ77FormatType
{
    associatedtype Integral:LZ77.StreamIntegral

    // func begin(inflating input:inout LZ77.InflatorIn, at bit:inout Int) throws -> Header?
    // func check(inflating input:inout LZ77.InflatorIn, at bit:inout Int) -> UInt32??
}
