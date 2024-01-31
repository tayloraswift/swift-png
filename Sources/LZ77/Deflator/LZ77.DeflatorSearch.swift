extension LZ77
{
    @frozen @usableFromInline
    enum DeflatorSearch
    {
        case greedy(attempts:Int, goal:Int)
        case lazy(attempts:Int, goal:Int)
        case full(attempts:Int, goal:Int, iterations:Int)
    }
}
