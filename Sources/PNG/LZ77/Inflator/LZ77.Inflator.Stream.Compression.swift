extension LZ77.Inflator.Stream
{
    enum Compression
    {
        case none(bytes:Int)
        case fixed
        case dynamic(runliterals:Int, distances:Int)
    }
}
