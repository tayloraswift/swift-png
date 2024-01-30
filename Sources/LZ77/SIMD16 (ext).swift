// https://github.com/apple/swift/issues/60534
// https://forums.swift.org/t/builtin-intrinsics-intel-module-is-not-available-on-windows-pc-with-intel-cpu/61862
#if arch(x86_64) && !NO_INTRINSICS && canImport(_Builtin_intrinsics)

import _Builtin_intrinsics.intel

extension SIMD16 where Scalar == UInt8
{
    func find(_ key:UInt8) -> UInt16
    {
        let repeated:Self       = .init(repeating: key)
        let mask:SIMD2<Int64>   = _mm_cmpeq_epi8(
            unsafeBitCast(self,     to: SIMD2<Int64>.self),
            unsafeBitCast(repeated, to: SIMD2<Int64>.self))
        return .init(truncatingIfNeeded: _mm_movemask_epi8(mask))
    }
}

#else

extension SIMD16 where Scalar == UInt8
{
    func find(_ key:UInt8) -> UInt16
    {
        // (key: 5, vector: (1, 5, 1, 1, 5, 5, 1, 1, 1, 1, 1, 1, 5, 1, 1, 5))
        let places:SIMD16<UInt8>    =
            .init(128, 64, 32, 16, 8, 4, 2, 1, 128, 64, 32, 16, 8, 4, 2, 1),
            match:SIMD16<UInt8>     = places.replacing(with: 0, where: self .!= key)
        // match: ( 0, 64,  0,  0,  8,  4,  0,  0,  0,  0,  0,  0,  8,  0,  0,  1)
        let r8:SIMD8<UInt8> =    match.evenHalf |    match.oddHalf,
            r4:SIMD4<UInt8> =       r8.evenHalf |       r8.oddHalf,
            r2:SIMD2<UInt8> =       r4.evenHalf |       r4.oddHalf
        return .init(r2.x) << 8  | .init(r2.y)
    }
}

#endif
