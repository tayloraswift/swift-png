extension LZ77
{
    enum BlockType
    {
        case dynamic    (final:Bool, literals:Int, distances:Int)
        case fixed      (final:Bool)
        case bytes      (final:Bool, count:Int)
    }
}
