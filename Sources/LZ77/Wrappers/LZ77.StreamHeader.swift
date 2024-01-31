extension LZ77
{
    public
    typealias StreamHeader = _LZ77StreamHeader
}
public
protocol _LZ77StreamHeader
{
    var window:Int { get }
}
