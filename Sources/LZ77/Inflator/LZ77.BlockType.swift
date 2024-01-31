extension LZ77
{
    enum BlockType
    {
        case dynamic(runliterals:Int, distances:Int)
        case fixed
        case bytes(Int)
    }
}
