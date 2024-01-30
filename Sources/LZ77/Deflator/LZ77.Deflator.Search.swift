extension LZ77.Deflator
{
    @frozen @usableFromInline
    enum Search
    {
        case greedy(attempts:Int, goal:Int)
        case lazy(attempts:Int, goal:Int)
        case full(attempts:Int, goal:Int, iterations:Int)
    }
}
