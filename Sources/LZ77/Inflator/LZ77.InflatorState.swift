extension LZ77
{
    @frozen @usableFromInline
    enum InflatorState
    {
        case streamStart
        case blockStart
        case blockTables(final:Bool, runliterals:Int, distances:Int)
        case blockUncompressed(final:Bool, end:Int)
        case blockCompressed(final:Bool, semistatic:InflatorTables)
        case streamChecksum
        case streamEnd
    }
}
