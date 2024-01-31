extension LZ77
{
    public
    typealias StreamFormat = _LZ77StreamFormat
}
public
protocol _LZ77StreamFormat
{
    associatedtype Integral:LZ77.StreamIntegral
    associatedtype Header:LZ77.StreamHeader

    func begin(inflating input:inout LZ77.InflatorIn, at bit:inout Int) throws -> Header?
    func check(inflating input:inout LZ77.InflatorIn, at bit:inout Int) -> UInt32??
}
