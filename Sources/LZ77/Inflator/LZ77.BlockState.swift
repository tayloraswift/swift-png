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
