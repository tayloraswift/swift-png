extension F14.District
{
    struct Index:Equatable
    {
        let offset:Int
    }
}
extension F14.District.Index
{
    static
    func + (rhs:UnsafeMutableRawPointer, lhs:Self) -> F14.District
    {
        .init(base: rhs + lhs.offset)
    }
}
