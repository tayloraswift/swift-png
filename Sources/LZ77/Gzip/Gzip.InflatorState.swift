extension Gzip
{
    @frozen @usableFromInline
    enum InflatorState
    {
        case initial
        case strings(skip:Int, count:Int)
        case block(LZ77.BlockState)
        case checksum
        case epilogue
        case terminal
    }
}
