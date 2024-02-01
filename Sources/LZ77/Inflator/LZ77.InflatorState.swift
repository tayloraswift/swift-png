extension LZ77
{
    @frozen @usableFromInline
    enum BlockState
    {
        case metadata
        case tables         (final:Bool, literals:Int, distances:Int)
        case compressed     (final:Bool, tables:InflatorTables)
        case uncompressed   (final:Bool, end:Int)
    }
}
extension LZ77
{
    @frozen @usableFromInline
    enum InflatorState
    {
        case initial
        case block(LZ77.BlockState)
        case checksum
        case terminal
    }
}
extension Gzip
{
    @frozen @usableFromInline
    enum InflatorState
    {
        case initial
        case strings(start:Int, count:Int)
        case block(LZ77.BlockState)
        case checksum
        case terminal
    }
}
