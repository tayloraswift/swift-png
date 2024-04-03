extension LZ77
{
    enum BlockShape
    {
        case dynamic    (final:Bool, literals:Int, distances:Int)
        case fixed      (final:Bool)
        case bytes      (final:Bool, count:Int)
    }
}
