@usableFromInline
enum Math<N>
{
    @usableFromInline typealias V2 = (x:N, y:N)
    @usableFromInline typealias V3 = (x:N, y:N, z:N)
    @usableFromInline typealias V4 = (x:N, y:N, z:N, w:N)
}

extension Math where N:Numeric
{
    @inline(__always)
    static
    func sub(_ v1:V3, _ v2:V3) -> V3
    {
        return (v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
    }

    @inline(__always)
    static
    func vol(_ v:V2) -> N
    {
        return v.x * v.y
    }
}

extension Math where N:SignedNumeric, N.Magnitude == N
{
    @inline(__always)
    static
    func abs(_ v:V3) -> V3
    {
        return (Swift.abs(v.x), Swift.abs(v.y), Swift.abs(v.z))
    }
}
extension Math where N:Comparable, N:SignedNumeric
{
    @inline(__always)
    static
    func abs(_ v:V3) -> V3
    {
        return (Swift.abs(v.x), Swift.abs(v.y), Swift.abs(v.z))
    }
}

extension Math where N:BinaryInteger
{
    @usableFromInline @inline(__always)
    static
    func cast<I>(_ v:V3, as _:I.Type) -> Math<I>.V3 where I:BinaryInteger
    {
        return (I(v.x), I(v.y), I(v.z))
    }
    @usableFromInline @inline(__always)
    static
    func cast<I>(_ v:V4, as _:I.Type) -> Math<I>.V4 where I:BinaryInteger
    {
        return (I(v.x), I(v.y), I(v.z), I(v.w))
    }
}
