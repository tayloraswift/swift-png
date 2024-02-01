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
extension LZ77.DeflatorSearch
{
    init(level:Int)
    {
        switch level
        {
        case .min ... 0:    self = .greedy(attempts:   1, goal:   6)
        case  1:            self = .greedy(attempts:   2, goal:   8)
        case  2:            self = .greedy(attempts:   4, goal:  10)
        case  3:            self = .greedy(attempts:  40, goal:  24)

        case  4:            self = .lazy(attempts:    20, goal:  32)
        case  5:            self = .lazy(attempts:    40, goal:  54)
        case  6:            self = .lazy(attempts:    64, goal:  80)
        case  7:            self = .lazy(attempts:   100, goal: 160)

        case  8:            self = .full(attempts:    14, goal:  20, iterations: 1)
        case  9:            self = .full(attempts:    20, goal:  32, iterations: 2)
        case 10:            self = .full(attempts:    30, goal:  50, iterations: 3)
        case 11:            self = .full(attempts:    60, goal:  80, iterations: 4)
        case 12:            self = .full(attempts:   100, goal: 133, iterations: 5)
        default:            self = .full(attempts:  .max, goal: 258, iterations: 6)
        }
    }
}
