import func Glibc.asin
import func Glibc.acos
import func Glibc.atan2

protocol _SwiftFloatingPoint:FloatingPoint
{
    static func sin(_:Self) -> Self
    static func cos(_:Self) -> Self
    static func asin(_:Self) -> Self
    static func acos(_:Self) -> Self
    static func atan2(_:Self, _:Self) -> Self
}
extension Float:_SwiftFloatingPoint
{
    @inline(__always)
    static
    func sin(_ x:Float) -> Float
    {
        return _sin(x)
    }

    @inline(__always)
    static
    func cos(_ x:Float) -> Float
    {
        return _cos(x)
    }

    @inline(__always)
    static
    func asin(_ x:Float) -> Float
    {
        return Glibc.asin(x)
    }

    @inline(__always)
    static
    func acos(_ x:Float) -> Float
    {
        return Glibc.acos(x)
    }

    @inline(__always)
    static
    func atan2(_ y:Float, _ x:Float) -> Float
    {
        return Glibc.atan2(y, x)
    }
}
extension Double:_SwiftFloatingPoint
{
    @inline(__always)
    static
    func sin(_ x:Double) -> Double
    {
        return _sin(x)
    }

    @inline(__always)
    static
    func cos(_ x:Double) -> Double
    {
        return _cos(x)
    }

    @inline(__always)
    static
    func asin(_ x:Double) -> Double
    {
        return Glibc.asin(x)
    }

    @inline(__always)
    static
    func acos(_ x:Double) -> Double
    {
        return Glibc.acos(x)
    }

    @inline(__always)
    static
    func atan2(_ y:Double, _ x:Double) -> Double
    {
        return Glibc.atan2(y, x)
    }
}

enum Math<N>
{
    typealias V2 = (x:N, y:N)
    typealias V3 = (x:N, y:N, z:N)
    typealias V4 = (x:N, y:N, z:N, w:N)
    
    typealias Mat3 = (V3, V3, V3)
    typealias Mat4 = (V4, V4, V4, V4)
    
    typealias Rectangle = (a:V2, b:V2)

    @inline(__always)
    static
    func copy(_ v:V2, to ptr:UnsafeMutablePointer<N>)
    {
        ptr[0] = v.x
        ptr[1] = v.y
    }
    @inline(__always)
    static
    func copy(_ v:V3, to ptr:UnsafeMutablePointer<N>)
    {
        ptr[0] = v.x
        ptr[1] = v.y
        ptr[2] = v.z
    }
    @inline(__always)
    static
    func copy(_ v:V4, to ptr:UnsafeMutablePointer<N>)
    {
        ptr[0] = v.x
        ptr[1] = v.y
        ptr[2] = v.z
        ptr[3] = v.w
    }
    @inline(__always)
    static
    func copy(_ v:Mat4, to ptr:UnsafeMutablePointer<N>)
    {
        copy(v.0, to: ptr)
        copy(v.0, to: ptr + 4)
        copy(v.0, to: ptr + 8)
        copy(v.0, to: ptr + 12)
    }

    @inline(__always)
    static
    func load(from ptr:UnsafeMutablePointer<N>) -> V2
    {
        return (ptr[0], ptr[1])
    }
    @inline(__always)
    static
    func load(from ptr:UnsafeMutablePointer<N>) -> V3
    {
        return (ptr[0], ptr[1], ptr[2])
    }
    @inline(__always)
    static
    func load(from ptr:UnsafeMutablePointer<N>) -> V4
    {
        return (ptr[0], ptr[1], ptr[2], ptr[3])
    }
}

extension Math where N:Numeric
{    
    @inline(__always)
    static
    func sum(_ v:V2) -> N
    {
        return v.x + v.y
    }
    @inline(__always)
    static
    func sum(_ v:V3) -> N
    {
        return v.x + v.y + v.z
    }

    @inline(__always)
    static
    func add(_ v1:V2, _ v2:V2) -> V2
    {
        return (v1.x + v2.x, v1.y + v2.y)
    }
    @inline(__always)
    static
    func add(_ v1:V3, _ v2:V3) -> V3
    {
        return (v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)
    }

    @inline(__always)
    static
    func sub(_ v1:V2, _ v2:V2) -> V2
    {
        return (v1.x - v2.x, v1.y - v2.y)
    }
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
    @inline(__always)
    static
    func vol(_ v:V3) -> N
    {
        return v.x * v.y * v.z
    }

    @inline(__always)
    static
    func mult(_ v1:V2, _ v2:V2) -> V2
    {
        return (v1.x * v2.x, v1.y * v2.y)
    }
    @inline(__always)
    static
    func mult(_ v1:V3, _ v2:V3) -> V3
    {
        return (v1.x * v2.x, v1.y * v2.y, v1.z * v2.z)
    }

    @inline(__always)
    static
    func scale(_ v:V2, by c:N) -> V2
    {
        return (v.x * c, v.y * c)
    }
    @inline(__always)
    static
    func scale(_ v:V3, by c:N) -> V3
    {
        return (v.x * c, v.y * c, v.z * c)
    }

    @inline(__always)
    static
    func dot(_ v1:V2, _ v2:V2) -> N
    {
        return v1.x * v2.x + v1.y * v2.y
    }
    @inline(__always)
    static
    func dot(_ v1:V3, _ v2:V3) -> N
    {
        return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
    }
    @inline(__always)
    static
    func dot(_ v1:V4, _ v2:V4) -> N
    {
        return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z + v1.w * v2.w
    }

    @inline(__always)
    static
    func eusq(_ v:V2) -> N
    {
        return v.x * v.x + v.y * v.y
    }
    @inline(__always)
    static
    func eusq(_ v:V3) -> N
    {
        return v.x * v.x + v.y * v.y + v.z * v.z
    }

    @inline(__always)
    static
    func cross(_ v1:V2, _ v2:V2) -> N
    {
        return v1.x*v2.y - v2.x*v1.y
    }
    @inline(__always)
    static
    func cross(_ v1:V3, _ v2:V3) -> V3
    {
        return (v1.y*v2.z - v2.y*v1.z, v1.z*v2.x - v2.z*v1.x, v1.x*v2.y - v2.x*v1.y)
    }
    
    // matrix math
    @inline(__always)
    static
    func mat3(from M:Mat4) -> Mat3
    {
        return 
            (
                (M.0.0, M.0.1, M.0.2), 
                (M.1.0, M.1.1, M.1.2), 
                (M.2.0, M.2.1, M.2.2)
            )
    }
    
    @inline(__always)
    static
    func transpose(_ M:Mat3) -> Mat3
    {
        return 
            (
                (M.0.0, M.1.0, M.2.0), 
                (M.0.1, M.1.1, M.2.1), 
                (M.0.2, M.1.2, M.2.2)
            )
    }
    @inline(__always)
    static
    func transpose(_ M:Mat4) -> Mat4
    {
        return 
            (
                (M.0.0, M.1.0, M.2.0, M.3.0), 
                (M.0.1, M.1.1, M.2.1, M.3.1), 
                (M.0.2, M.1.2, M.2.2, M.3.2), 
                (M.0.3, M.1.3, M.2.3, M.3.3)
            )
    }

    @inline(__always)
    static
    func mult(_ A:Mat3, _ v:V3) -> V3
    {
        let AT:(V3, V3, V3) = transpose(A)
        return (dot(AT.0, v), dot(AT.1, v), dot(AT.2, v))
    }
    @inline(__always)
    static
    func mult(_ A:Mat3, _ B:Mat3) -> Mat3
    {
        let AT:(V3, V3, V3) = transpose(A)
        return 
            (
                (dot(AT.0, B.0), dot(AT.1, B.0), dot(AT.2, B.0)),
                (dot(AT.0, B.1), dot(AT.1, B.1), dot(AT.2, B.1)),
                (dot(AT.0, B.2), dot(AT.1, B.2), dot(AT.2, B.2))
            )
    }
    
    @inline(__always)
    static
    func mult(_ A:Mat4, _ v:V4) -> V4
    {
        let AT:Mat4 = transpose(A)
        return (dot(AT.0, v), dot(AT.1, v), dot(AT.2, v), dot(AT.3, v))
    }
    @inline(__always)
    static
    func mult(_ A:Mat4, _ B:Mat4) -> Mat4
    {
        let AT:Mat4 = transpose(A)
        return 
            (
                (dot(AT.0, B.0), dot(AT.1, B.0), dot(AT.2, B.0), dot(AT.3, B.0)), 
                (dot(AT.0, B.1), dot(AT.1, B.1), dot(AT.2, B.1), dot(AT.3, B.1)), 
                (dot(AT.0, B.2), dot(AT.1, B.2), dot(AT.2, B.2), dot(AT.3, B.2)), 
                (dot(AT.0, B.3), dot(AT.1, B.3), dot(AT.2, B.3), dot(AT.3, B.3))
            )
    }
    
    @inline(__always)
    static
    func homogenize(_ v:V2) -> V3
    {
        return (v.x, v.y, 1)
    }
    @inline(__always)
    static
    func homogenize(_ v:V3) -> V4
    {
        return (v.x, v.y, v.z, 1)
    }
}

extension Math where N:Numeric, N:Comparable 
{
    @inline(__always)
    static
    func test(_ v:V2, lessThan r:N) -> Bool
    {
        return eusq(v) < r * r
    }
    @inline(__always)
    static
    func test(_ v:V3, lessThan r:N) -> Bool
    {
        return eusq(v) < r * r
    }
    @inline(__always)
    static
    func test(_ v:V2, lessEqual r:N) -> Bool
    {
        return eusq(v) <= r * r
    }
    @inline(__always)
    static
    func test(_ v:V3, lessEqual r:N) -> Bool
    {
        return eusq(v) <= r * r
    }
}

extension Math where N:SignedNumeric
{
    @inline(__always)
    static
    func neg(_ v:V2) -> V2
    {
        return (-v.x, -v.y)
    }
    @inline(__always)
    static
    func neg(_ v:V3) -> V3
    {
        return (-v.x, -v.y, -v.z)
    }
}
extension Math where N:FloatingPoint
{
    @inline(__always)
    static
    func abs(_ v:V2) -> V2
    {
        return (Swift.abs(v.x), Swift.abs(v.y))
    }
    @inline(__always)
    static
    func abs(_ v:V3) -> V3
    {
        return (Swift.abs(v.x), Swift.abs(v.y), Swift.abs(v.z))
    }
    
    @inline(__always)
    static
    func clamp(_ v:N, to range:ClosedRange<N> = 0 ... 1) -> N
    {
        return max(range.lowerBound, min(v, range.upperBound))
    }
    @inline(__always)
    static
    func clamp(_ v:V2) -> V2
    {
        return (clamp(v.x), clamp(v.y))
    }
    @inline(__always)
    static
    func clamp(_ v:V3) -> V3
    {
        return (clamp(v.x), clamp(v.y), clamp(v.z))
    }
}
extension Math where N:SignedNumeric, N.Magnitude == N
{
    @inline(__always)
    static
    func abs(_ v:V2) -> V2
    {
        return (Swift.abs(v.x), Swift.abs(v.y))
    }
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
    func abs(_ v:V2) -> V2
    {
        return (Swift.abs(v.x), Swift.abs(v.y))
    }
    @inline(__always)
    static
    func abs(_ v:V3) -> V3
    {
        return (Swift.abs(v.x), Swift.abs(v.y), Swift.abs(v.z))
    }
}

extension Math where N:BinaryFloatingPoint
{
    @inline(__always)
    static
    func cast<I>(_ v:V2, as _:I.Type) -> Math<I>.V2 where I:BinaryInteger
    {
        return (I(v.x), I(v.y))
    }
    @inline(__always)
    static
    func cast<I>(_ v:V3, as _:I.Type) -> Math<I>.V3 where I:BinaryInteger
    {
        return (I(v.x), I(v.y), I(v.z))
    }
}
extension Math where N:BinaryInteger
{
    @inline(__always)
    static
    func cast<I>(_ v:V2, as _:I.Type) -> Math<I>.V2 where I:BinaryInteger
    {
        return (I(v.x), I(v.y))
    }
    @inline(__always)
    static
    func cast<I>(_ v:V3, as _:I.Type) -> Math<I>.V3 where I:BinaryInteger
    {
        return (I(v.x), I(v.y), I(v.z))
    }
    @inline(__always)
    static
    func cast<F>(_ v:V2, as _:F.Type) -> Math<F>.V2 where F:FloatingPoint
    {
        return (F(v.x), F(v.y))
    }
    @inline(__always)
    static
    func cast<F>(_ v:V3, as _:F.Type) -> Math<F>.V3 where F:FloatingPoint
    {
        return (F(v.x), F(v.y), F(v.z))
    }

    @inline(__always)
    static
    func idiv(_ dividend:V2, by divisor:V2) -> Math<(N, N)>.V2
    {
        return (dividend.x.quotientAndRemainder(dividingBy: divisor.x),
                dividend.y.quotientAndRemainder(dividingBy: divisor.y))
    }
    @inline(__always)
    static
    func idiv(_ dividend:V3, by divisor:V3) -> Math<(N, N)>.V3
    {
        return (dividend.x.quotientAndRemainder(dividingBy: divisor.x),
                dividend.y.quotientAndRemainder(dividingBy: divisor.y),
                dividend.z.quotientAndRemainder(dividingBy: divisor.z))
    }
}

extension Math where N:FloatingPoint
{
    @inline(__always)
    static
    func reciprocal(_ v:V2) -> V2
    {
        return (1 / v.x, 1 / v.y)
    }
    @inline(__always)
    static
    func reciprocal(_ v:V3) -> V3
    {
        return (1 / v.x, 1 / v.y, 1 / v.z)
    }
    
    @inline(__always)
    static
    func div(_ v1:V2, _ v2:V2) -> V2
    {
        return (v1.x / v2.x, v1.y / v2.y)
    }
    @inline(__always)
    static
    func div(_ v1:V3, _ v2:V3) -> V3
    {
        return (v1.x / v2.x, v1.y / v2.y, v1.z / v2.z)
    }

    @inline(__always)
    static
    func madd(_ v1:V2, _ v2:V2, _ v3:V2) -> V2
    {
        return (v1.x.addingProduct(v2.x, v3.x), v1.y.addingProduct(v2.y, v3.y))
    }
    @inline(__always)
    static
    func madd(_ v1:V3, _ v2:V3, _ v3:V3) -> V3
    {
        return (v1.x.addingProduct(v2.x, v3.x), v1.y.addingProduct(v2.y, v3.y), v1.z.addingProduct(v2.z, v3.z))
    }

    @inline(__always)
    static
    func scadd(_ v1:V2, _ v2:V2, _ c:N) -> V2
    {
        return (v1.x.addingProduct(v2.x, c), v1.y.addingProduct(v2.y, c))
    }
    @inline(__always)
    static
    func scadd(_ v1:V3, _ v2:V3, _ c:N) -> V3
    {
        return (v1.x.addingProduct(v2.x, c), v1.y.addingProduct(v2.y, c), v1.z.addingProduct(v2.z, c))
    }

    @inline(__always)
    static
    func lerp(_ v1:N, _ v2:N, _ t:N) -> N
    {
        return v1.addingProduct(-t, v1).addingProduct(t, v2)
    }
    @inline(__always)
    static
    func lerp(_ v1:V2, _ v2:V2, _ t:N) -> V2
    {
        return (v1.x.addingProduct(-t, v1.x).addingProduct(t, v2.x),
                v1.y.addingProduct(-t, v1.y).addingProduct(t, v2.y))
    }
    @inline(__always)
    static
    func lerp(_ v1:V3, _ v2:V3, _ t:N) -> V3
    {
        return (v1.x.addingProduct(-t, v1.x).addingProduct(t, v2.x),
                v1.y.addingProduct(-t, v1.y).addingProduct(t, v2.y),
                v1.z.addingProduct(-t, v1.z).addingProduct(t, v2.z))
    }

    @inline(__always)
    static
    func length(_ v:V2) -> N
    {
        return eusq(v).squareRoot()
    }
    @inline(__always)
    static
    func length(_ v:V3) -> N
    {
        return eusq(v).squareRoot()
    }

    @inline(__always)
    static
    func normalize(_ v:V2) -> V2
    {
        return scale(v, by: 1 / length(v))
    }
    @inline(__always)
    static
    func normalize(_ v:V3) -> V3
    {
        return scale(v, by: 1 / length(v))
    }
}
extension Math where N:BinaryFloatingPoint
{
    @inline(__always)
    static
    func cast<F>(_ v:V2, as _:F.Type) -> Math<F>.V2 where F:BinaryFloatingPoint
    {
        return (F(v.x), F(v.y))
    }
    @inline(__always)
    static
    func cast<F>(_ v:V3, as _:F.Type) -> Math<F>.V3 where F:BinaryFloatingPoint
    {
        return (F(v.x), F(v.y), F(v.z))
    }
}
extension Math where N:FixedWidthInteger 
{
    // rounds up to the next power of two, with 0 rounding up to 1. 
    // numbers that are already powers of two return themselves
    @inline(__always)
    static 
    func nextPowerOfTwo(_ n:N) -> N 
    {
        return 1 &<< (N.bitWidth - (n - 1).leadingZeroBitCount)
    }
}

extension Math where N:_SwiftFloatingPoint
{
    typealias S2 = (θ:N, φ:N) // θ = latitude, φ = longitude

    @inline(__always)
    static
    func cartesian(_ s:S2) -> V3
    {
        return (N.sin(s.θ) * N.cos(s.φ), N.sin(s.θ) * N.sin(s.φ), N.cos(s.θ))
    }

    @inline(__always)
    static
    func spherical(_ c:V3) -> S2
    {
        return (N.acos(c.z / length(c)), N.atan2(c.y, c.x))
    }

    @inline(__always)
    static
    func spherical(normalized c:V3) -> S2
    {
        return (N.acos(c.z), N.atan2(c.y, c.x))
    }
}

extension Array
{
    @inline(__always)
    mutating
    func append(vector:Math<Element>.V2)
    {
        self.append(vector.x)
        self.append(vector.y)
    }

    @inline(__always)
    mutating
    func append(vector:Math<Element>.V3)
    {
        self.append(vector.x)
        self.append(vector.y)
        self.append(vector.z)
    }
}
