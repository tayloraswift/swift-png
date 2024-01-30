extension General.Dictionary.District
{
    struct Index:Equatable
    {
        let offset:Int
    }
}
extension General.Dictionary.District.Index
{
    static
    func + (rhs:UnsafeMutableRawPointer, lhs:Self) -> General.Dictionary.District
    {
        .init(base: rhs + lhs.offset)
    }
}
