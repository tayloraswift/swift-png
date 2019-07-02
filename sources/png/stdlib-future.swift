// blocked by this: https://github.com/apple/swift/pull/22289
extension Sequence 
{
    @inlinable
    func count(where predicate:(Element) throws -> Bool) rethrows -> Int 
    {
        var count:Int = 0
        for e:Element in self where try predicate(e)   
        {
            count += 1
        }
        return count
    }
}
