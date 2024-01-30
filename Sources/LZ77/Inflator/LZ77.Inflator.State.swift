extension LZ77.Inflator
{
    @frozen @usableFromInline
    enum State
    {
        case streamStart
        case blockStart
        case blockTables(final:Bool, runliterals:Int, distances:Int)
        case blockUncompressed(final:Bool, end:Int)
        case blockCompressed(final:Bool, semistatic:Semistatic)
        case streamChecksum
        case streamEnd
    }
}
