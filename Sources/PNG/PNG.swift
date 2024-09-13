//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// A namespace for PNG-related functionality.
public
enum PNG
{
    static
    let signature:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
}
extension PNG
{
    /// A namespace for bytestream utilities.
    @available(*, deprecated)
    public
    enum Bytestream
    {
        @available(*, deprecated, renamed: "PNG.BytestreamSource")
        public
        typealias Source = PNG.BytestreamSource

        @available(*, deprecated, renamed: "PNG.BytestreamDestination")
        public
        typealias Destination = PNG.BytestreamDestination
    }
}
extension PNG
{
    /// Premultiplies a color component with an alpha value.
    ///
    /// - Parameters:
    ///     -   color:
    ///         The color component to premultiply.
    ///     -   alpha:
    ///         The alpha component to premultiply `color` with.
    ///
    /// -   Returns:
    ///     The premultiplied color component, rounded to the nearest integer.
    ///
    /// The `color` and `alpha` parameters are interpreted as rational numbers in the range
    /// [0, 1], where `T.min` maps to 0, and `T.max` maps to 1.
    ///
    /// This function uses no floating point operations, and satisfies the property that
    /// ``premultiply(_:alpha:)`` is equivalent to
    ///
    /// ``premultiply(_:alpha:)`` ∘ ``straighten(_:alpha:)`` ∘ ``premultiply(_:alpha:)``
    ///
    /// The computed properties ``RGBA.premultiplied`` and ``VA.premultiplied`` can be used to
    /// premultiply an entire instance of one of the built-in color targets.
    ///
    /// Premultiplication is a destructive operation. In the most extreme case, if `alpha` is
    /// `T.min`, this function will return `T.min` for any value of `color`.
    @inlinable public static
    func premultiply<T>(_ color:T, alpha:T) -> T
        where T:FixedWidthInteger & UnsignedInteger
    {
        // this generates pretty good assembly, though Swift/LLVM doesn’t
        // seem to know it can perform the full width arithmetic in one register
        // for T.bitWidth <= 32
        let product:(high:T, low:T.Magnitude) = color.multipliedFullWidth(by: alpha)
        let biased:(high:T, low:T.Magnitude),
            carried:Bool
        (biased.low, carried)   = product.low.addingReportingOverflow(.max >> 1)
        biased.high             = product.high &+ (carried ? 1 : 0)
        return T.max.dividingFullWidth(biased).quotient
    }
    /// Straightens a premultiplied color component given an alpha value.
    ///
    /// -   Parameters:
    ///     -   premultiplied:
    ///         The premultiplied color component to straighten.
    ///     -   alpha:
    ///         The alpha component that `premultiplied` was premultiplied by.
    ///
    /// -   Returns:
    ///     The straightened color component, rounded to the nearest integer.
    ///     If `alpha` is `T.min`, this function returns the original
    ///     `premultiplied` argument.
    ///
    /// The `color` and `alpha` parameters are interpreted as rational numbers
    /// in the range [0, 1], where `T.min` maps to 0,
    /// and `T.max` maps to 1.
    ///
    /// This function uses no floating point operations, and satisfies the
    /// property that ``premultiply(_:alpha:)``
    ///
    /// is equivalent to
    ///
    /// ``premultiply(_:alpha:)`` ∘ ``straighten(_:alpha:)`` ∘ ``premultiply(_:alpha:)``
    ///
    /// The computed properties ``RGBA.straightened`` and ``VA.straightened``
    /// can be used to straighten an entire instance of one of the built-in
    /// color targets.
    ///
    /// Premultiplication is a destructive operation. This function cannot
    /// recover the original color unless `alpha` is `T.max`, in which case
    /// this function performs a division by 1, and returns the original
    /// `premultiplied` argument.
    @inlinable public static
    func straighten<T>(_ premultiplied:T, alpha:T) -> T
        where T:FixedWidthInteger & UnsignedInteger
    {
        guard alpha > 0
        else
        {
            return premultiplied
        }

        let biased:(high:T, low:T.Magnitude)    =
            T.max.multipliedFullWidth(by: premultiplied)
        let product:(high:T, low:T.Magnitude),
            carried:Bool
        (product.low, carried)  = biased.low.addingReportingOverflow(alpha.magnitude >> 1)
        product.high            = biased.high &+ (carried ? 1 : 0)
        return alpha.dividingFullWidth(product).quotient
    }
}

extension PNG
{
    /// Returns the value of the paeth filter function with the given parameters.
    static
    func paeth(_ a:UInt8, _ b:UInt8, _ c:UInt8) -> UInt8
    {
        // abs here is poorly-predicted so it benefits from this
        // branchless implementation
        func abs(_ x:Int16) -> Int16
        {
            let mask:Int16 = x >> 15
            return (x ^ mask) + (mask & 1)
        }

        #if DEBUG
            // in debug mode this manual UInt8 -> Int16 code makes `paeth` approximately 7x
            // faster than using either `Int16(x)` or `Int16(bitPattern: UInt16(x))`. before
            // this, paeth often took up around 10% of the time taken during decoding large images.
            // the regular Int16/UInt16 initialisers aren't specialised in debug mode and end up
            // spending most of their time reading generic metadata and checking stack canaries.
            // hand unrolling the calls to this function has minimal effect on debug mode
            // performance.
            func customUInt8ToInt16(_ x: UInt8) -> Int16
            {
                let tuple:(UInt8, UInt8) = (x, 0)
                return unsafeBitCast(tuple, to: Int16.self)
            }

            let v:(Int16, Int16, Int16) =
            (
                customUInt8ToInt16(a),
                customUInt8ToInt16(b),
                customUInt8ToInt16(c)
            )
        #else
            // the debug mode implementation uses unsafe pointer code which the compiler takes
            // to mean that we want a stack check inserted, even in release mode, so this simple
            // implementation is better for release mode. note that the stack check insertion
            // theory is from looking at Godbolt, so the situation may be different on ARM.
            let v:(Int16, Int16, Int16) = (.init(a), .init(b), .init(c))
        #endif

        let d:(Int16, Int16)        = (v.1 - v.2, v.0 - v.2)
        let f:(Int16, Int16, Int16) = (abs(d.0), abs(d.1), abs(d.0 + d.1))

        let p:(UInt8, UInt8, UInt8) =
        (
            .init(truncatingIfNeeded: (f.1 - f.0) >> 15), // 0x00 if f.0 <= f.1 else 0xff
            .init(truncatingIfNeeded: (f.2 - f.0) >> 15),
            .init(truncatingIfNeeded: (f.2 - f.1) >> 15)
        )

        return ~(p.0 | p.1) &  a        |
                (p.0 | p.1) & (b & ~p.2 | c & p.2)
    }
}
extension PNG
{
    private static
    func convolve<A, T, C>(_ samples:UnsafeBufferPointer<A>,
        _ kernel:(T, A) -> C, _ transform:(A) -> T)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger
    {
        samples.map
        {
            let v:A = .init(bigEndian: $0)
            return kernel(transform(v), v)
        }
    }
    private static
    func convolve<A, T, C>(_ samples:UnsafeBufferPointer<A>,
        _ kernel:((T, T)) -> C, _ transform:(A) -> T)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger
    {
        stride(from: samples.startIndex, to: samples.endIndex, by: 2).map
        {
            let v:A = .init(bigEndian: samples[$0     ])
            let a:A = .init(bigEndian: samples[$0 &+ 1])
            return kernel((transform(v), transform(a)))
        }
    }
    private static
    func convolve<A, T, C>(_ samples:UnsafeBufferPointer<A>,
        _ kernel:((T, T, T), (A, A, A)) -> C, _ transform:(A) -> T)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger
    {
        stride(from: samples.startIndex, to: samples.endIndex, by: 3).map
        {
            let r:A = .init(bigEndian: samples[$0     ])
            let g:A = .init(bigEndian: samples[$0 &+ 1])
            let b:A = .init(bigEndian: samples[$0 &+ 2])
            return kernel((transform(r), transform(g), transform(b)), (r, g, b))
        }
    }
    private static
    func convolve<A, T, C>(_ samples:UnsafeBufferPointer<A>,
        _ kernel:((T, T, T, T)) -> C, _ transform:(A) -> T)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger
    {
        stride(from: samples.startIndex, to: samples.endIndex, by: 4).map
        {
            let r:A = .init(bigEndian: samples[$0     ])
            let g:A = .init(bigEndian: samples[$0 &+ 1])
            let b:A = .init(bigEndian: samples[$0 &+ 2])
            let a:A = .init(bigEndian: samples[$0 &+ 3])
            return kernel((transform(r), transform(g), transform(b), transform(a)))
        }
    }

    private static
    func convolve<A, T, C>(_ samples:UnsafeBufferPointer<UInt8>,
        _ kernel:(T) -> C, _ dereference:(Int) -> A, _ transform:(A) -> T)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger
    {
        samples.map
        {
            return kernel(transform(dereference(.init($0))))
        }
    }
    private static
    func convolve<A, T, C>(_ samples:UnsafeBufferPointer<UInt8>,
        _ kernel:((T, T)) -> C, _ dereference:(Int) -> (A, A), _ transform:(A) -> T)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger
    {
        samples.map
        {
            let (v, a):(A, A) = dereference(.init($0))
            return kernel((transform(v), transform(a)))
        }
    }
    // not used by any of the built-in targets, but here for completeness
    private static
    func convolve<A, T, C>(_ samples:UnsafeBufferPointer<UInt8>,
        _ kernel:((T, T, T)) -> C, _ dereference:(Int) -> (A, A, A), _ transform:(A) -> T)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger
    {
        samples.map
        {
            let (r, g, b):(A, A, A) = dereference(.init($0))
            return kernel((transform(r), transform(g), transform(b)))
        }
    }
    private static
    func convolve<A, T, C>(_ samples:UnsafeBufferPointer<UInt8>,
        _ kernel:((T, T, T, T)) -> C, _ dereference:(Int) -> (A, A, A, A), _ transform:(A) -> T)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger
    {
        samples.map
        {
            let (r, g, b, a):(A, A, A, A) = dereference(.init($0))
            return kernel((transform(r), transform(g), transform(b), transform(a)))
        }
    }

    private static
    func quantum<T>(source:Int, destination:Int) -> T
        where T:FixedWidthInteger & UnsignedInteger
    {
        // needless to say, `destination` can be no greater than `T.bitWidth`
        T.max >> (T.bitWidth - destination) / T.max >> (T.bitWidth - source)
    }

    /// Converts an image data buffer to a pixel array, using the given
    /// pixel kernel and dereferencing function.
    ///
    /// This function casts each byte in `buffer` to an ``Int`` index,
    /// and passes each index to the given `dereference` function, receiving
    /// scalar atoms of type `A` in return. It then scales the atoms to the
    /// range of `T`, and constructs instances of `C` by mapping the given
    /// `kernel` function over each `T` scalar.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter buffer:
    ///     An image data buffer.
    /// -   Parameter dereference:
    ///     A dereferencing function.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An array of pixels constructed by the given `kernel` function.
    ///     This array has the same number of elements as `buffer`.
    public static
    func convolve<A, T, C>(_ buffer:[UInt8], dereference:(Int) -> A,
        kernel:(T) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        buffer.withUnsafeBufferPointer
        {
            if      T.bitWidth == A.bitWidth
            {
                return Self.convolve($0, kernel, dereference, T.init(_:))
            }
            else if T.bitWidth >  A.bitWidth
            {
                let quantum:T = Self.quantum(source: A.bitWidth, destination: T.bitWidth)
                return Self.convolve($0, kernel, dereference)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = A.bitWidth - T.bitWidth
                return Self.convolve($0, kernel, dereference)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts an image data buffer to a pixel array, using the given
    /// pixel kernel and dereferencing function.
    ///
    /// This function casts each byte in `buffer` to an ``Int`` index,
    /// and passes each index to the given `dereference` function, receiving
    /// pairs of atoms of type `A` in return. It then scales the atoms to the
    /// range of `T`, and constructs instances of `C` by mapping the given
    /// `kernel` function over each `(T, T)` pair.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter buffer:
    ///     An image data buffer.
    /// -   Parameter dereference:
    ///     A dereferencing function.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An array of pixels constructed by the given `kernel` function.
    ///     This array has the same number of elements as `buffer`.
    public static
    func convolve<A, T, C>(_ buffer:[UInt8], dereference:(Int) -> (A, A),
        kernel:((T, T)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        buffer.withUnsafeBufferPointer
        {
            if      T.bitWidth == A.bitWidth
            {
                return Self.convolve($0, kernel, dereference, T.init(_:))
            }
            else if T.bitWidth >  A.bitWidth
            {
                let quantum:T = Self.quantum(source: A.bitWidth, destination: T.bitWidth)
                return Self.convolve($0, kernel, dereference)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = A.bitWidth - T.bitWidth
                return Self.convolve($0, kernel, dereference)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts an image data buffer to a pixel array, using the given
    /// pixel kernel and dereferencing function.
    ///
    /// This function casts each byte in `buffer` to an ``Int`` index,
    /// and passes each index to the given `dereference` function, receiving
    /// triplets of atoms of type `A` in return. It then scales the atoms to the
    /// range of `T`, and constructs instances of `C` by mapping the given
    /// `kernel` function over each `(T, T, T)` triplet.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter buffer:
    ///     An image data buffer.
    /// -   Parameter dereference:
    ///     A dereferencing function.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An array of pixels constructed by the given `kernel` function.
    ///     This array has the same number of elements as `buffer`.
    public static
    func convolve<A, T, C>(_ buffer:[UInt8], dereference:(Int) -> (A, A, A),
        kernel:((T, T, T)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        buffer.withUnsafeBufferPointer
        {
            if      T.bitWidth == A.bitWidth
            {
                return Self.convolve($0, kernel, dereference, T.init(_:))
            }
            else if T.bitWidth >  A.bitWidth
            {
                let quantum:T = Self.quantum(source: A.bitWidth, destination: T.bitWidth)
                return Self.convolve($0, kernel, dereference)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = A.bitWidth - T.bitWidth
                return Self.convolve($0, kernel, dereference)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts an image data buffer to a pixel array, using the given
    /// pixel kernel and dereferencing function.
    ///
    /// This function casts each byte in `buffer` to an ``Int`` index,
    /// and passes each index to the given `dereference` function, receiving
    /// quadruplets of atoms of type `A` in return. It then scales the atoms to the
    /// range of `T`, and constructs instances of `C` by mapping the given
    /// `kernel` function over each `(T, T, T, T)` quadruplet.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter buffer:
    ///     An image data buffer.
    /// -   Parameter dereference:
    ///     A dereferencing function.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An array of pixels constructed by the given `kernel` function.
    ///     This array has the same number of elements as `buffer`.
    public static
    func convolve<A, T, C>(_ buffer:[UInt8], dereference:(Int) -> (A, A, A, A),
        kernel:((T, T, T, T)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        buffer.withUnsafeBufferPointer
        {
            if      T.bitWidth == A.bitWidth
            {
                return Self.convolve($0, kernel, dereference, T.init(_:))
            }
            else if T.bitWidth >  A.bitWidth
            {
                let quantum:T = Self.quantum(source: A.bitWidth, destination: T.bitWidth)
                return Self.convolve($0, kernel, dereference)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = A.bitWidth - T.bitWidth
                return Self.convolve($0, kernel, dereference)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    // cannot genericize the kernel parameters, since it produces an unacceptable slowdown
    // so we have to manually specialize for all four cases (using the exact same function body)

    /// Converts an image data buffer to a pixel array, using the given
    /// pixel kernel.
    ///
    /// This function interprets `buffer` as an array of big-endian atoms of
    /// type `A`. It then scales the atoms to the range of `T`, according to
    /// the given color `depth`, and constructs instances of `C` by mapping
    /// the given `kernel` function over each `T` scalar, and the original
    /// scalar atom it was generated from.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter buffer:
    ///     An image data buffer. Its length must be divisible by the stride of `A`.
    /// -   Parameter _:
    ///     An atom type.
    /// -   Parameter depth:
    ///     A color depth used to interpret the intensity of each atom.
    ///     This depth must be no greater than `A.bitWidth`.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An array of pixels constructed by the given `kernel` function.
    ///     This array has a length of `buffer.count` divided by the stride of `A`.
    public static
    func convolve<A, T, C>(_ buffer:[UInt8], of _:A.Type, depth:Int,
        kernel:(T, A) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        buffer.withUnsafeBytes
        {
            let samples:UnsafeBufferPointer<A> = $0.bindMemory(to: A.self)
            if      T.bitWidth == depth
            {
                return Self.convolve(samples, kernel, T.init(_:))
            }
            else if T.bitWidth >  depth
            {
                let quantum:T = Self.quantum(source: depth, destination: T.bitWidth)
                return Self.convolve(samples, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = depth - T.bitWidth
                return Self.convolve(samples, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts an image data buffer to a pixel array, using the given
    /// pixel kernel.
    ///
    /// This function interprets `buffer` as an array of big-endian atoms of
    /// type `A`. It then scales the atoms to the range of `T`, according to
    /// the given color `depth`, and constructs instances of `C` by mapping
    /// the given `kernel` function over consecutive `(T, T)` pairs.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter buffer:
    ///     An image data buffer. Its length must be divisible by twice the
    ///     stride of `A`.
    /// -   Parameter _:
    ///     An atom type.
    /// -   Parameter depth:
    ///     A color depth used to interpret the intensity of each atom.
    ///     This depth must be no greater than `A.bitWidth`.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An array of pixels constructed by the given `kernel` function.
    ///     This array has a length of `buffer.count` divided by the twice the
    ///     stride of `A`.
    public static
    func convolve<A, T, C>(_ buffer:[UInt8], of _:A.Type, depth:Int,
        kernel:((T, T)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        buffer.withUnsafeBytes
        {
            let samples:UnsafeBufferPointer<A> = $0.bindMemory(to: A.self)
            if      T.bitWidth == depth
            {
                return Self.convolve(samples, kernel, T.init(_:))
            }
            else if T.bitWidth >  depth
            {
                let quantum:T = Self.quantum(source: depth, destination: T.bitWidth)
                return Self.convolve(samples, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = depth - T.bitWidth
                return Self.convolve(samples, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts an image data buffer to a pixel array, using the given
    /// pixel kernel.
    ///
    /// This function interprets `buffer` as an array of big-endian atoms of
    /// type `A`. It then scales the atoms to the range of `T`, according to
    /// the given color `depth`, and constructs instances of `C` by mapping
    /// the given `kernel` function over consecutive `(T, T, T)` triplets,
    /// and the original atoms they were generated from.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter buffer:
    ///     An image data buffer. Its length must be divisible by three times the
    ///     stride of `A`.
    /// -   Parameter _:
    ///     An atom type.
    /// -   Parameter depth:
    ///     A color depth used to interpret the intensity of each atom.
    ///     This depth must be no greater than `A.bitWidth`.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An array of pixels constructed by the given `kernel` function.
    ///     This array has a length of `buffer.count` divided by the three times
    ///     the stride of `A`.
    public static
    func convolve<A, T, C>(_ buffer:[UInt8], of _:A.Type, depth:Int,
        kernel:((T, T, T), (A, A, A)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        buffer.withUnsafeBytes
        {
            let samples:UnsafeBufferPointer<A> = $0.bindMemory(to: A.self)
            if      T.bitWidth == depth
            {
                return Self.convolve(samples, kernel, T.init(_:))
            }
            else if T.bitWidth >  depth
            {
                let quantum:T = Self.quantum(source: depth, destination: T.bitWidth)
                return Self.convolve(samples, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = depth - T.bitWidth
                return Self.convolve(samples, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts an image data buffer to a pixel array, using the given
    /// pixel kernel.
    ///
    /// This function interprets `buffer` as an array of big-endian atoms of
    /// type `A`. It then scales the atoms to the range of `T`, according to
    /// the given color `depth`, and constructs instances of `C` by mapping
    /// the given `kernel` function over consecutive `(T, T, T, T)` quadruplets.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter buffer:
    ///     An image data buffer. Its length must be divisible by four times the
    ///     stride of `A`.
    /// -   Parameter _:
    ///     An atom type.
    /// -   Parameter depth:
    ///     A color depth used to interpret the intensity of each atom.
    ///     This depth must be no greater than `A.bitWidth`.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An array of pixels constructed by the given `kernel` function.
    ///     This array has a length of `buffer.count` divided by the four times
    ///     the stride of `A`.
    public static
    func convolve<A, T, C>(_ buffer:[UInt8], of _:A.Type, depth:Int,
        kernel:((T, T, T, T)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        buffer.withUnsafeBytes
        {
            let samples:UnsafeBufferPointer<A> = $0.bindMemory(to: A.self)
            if      T.bitWidth == depth
            {
                return Self.convolve(samples, kernel, T.init(_:))
            }
            else if T.bitWidth >  depth
            {
                let quantum:T = Self.quantum(source: depth, destination: T.bitWidth)
                return Self.convolve(samples, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = depth - T.bitWidth
                return Self.convolve(samples, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
}
// deconvolution methods
extension PNG
{
    private static
    func deconvolve<A, T, C>(pixels:[C], _ samples:UnsafeMutableBufferPointer<A>,
        _ kernel:(C) -> T, _ transform:(T) -> A)
        where A:FixedWidthInteger & UnsignedInteger
    {
        for (i, pixel) in zip(samples.indices, pixels)
        {
            samples[i]                      = transform(kernel(pixel)).bigEndian
        }
    }
    private static
    func deconvolve<A, T, C>(pixels:[C], _ samples:UnsafeMutableBufferPointer<A>,
        _ kernel:(C) -> (T, T), _ transform:(T) -> A)
        where A:FixedWidthInteger & UnsignedInteger
    {
        for (i, pixel) in zip(stride(from: samples.startIndex, to: samples.endIndex, by: 2), pixels)
        {
            let (v, a):(T, T)               = kernel(pixel)
            samples[i     ]                 = transform(v).bigEndian
            samples[i &+ 1]                 = transform(a).bigEndian
        }
    }
    private static
    func deconvolve<A, T, C>(pixels:[C], _ samples:UnsafeMutableBufferPointer<A>,
        _ kernel:(C) -> (T, T, T), _ transform:(T) -> A)
        where A:FixedWidthInteger & UnsignedInteger
    {
        for (i, pixel) in zip(stride(from: samples.startIndex, to: samples.endIndex, by: 3), pixels)
        {
            let (r, g, b):(T, T, T)         = kernel(pixel)
            samples[i     ]                 = transform(r).bigEndian
            samples[i &+ 1]                 = transform(g).bigEndian
            samples[i &+ 2]                 = transform(b).bigEndian
        }
    }
    private static
    func deconvolve<A, T, C>(pixels:[C], _ samples:UnsafeMutableBufferPointer<A>,
        _ kernel:(C) -> (T, T, T, T), _ transform:(T) -> A)
        where A:FixedWidthInteger & UnsignedInteger
    {
        for (i, pixel) in zip(stride(from: samples.startIndex, to: samples.endIndex, by: 4), pixels)
        {
            let (r, g, b, a):(T, T, T, T)   = kernel(pixel)
            samples[i     ]                 = transform(r).bigEndian
            samples[i &+ 1]                 = transform(g).bigEndian
            samples[i &+ 2]                 = transform(b).bigEndian
            samples[i &+ 3]                 = transform(a).bigEndian
        }
    }
    private static
    func deconvolve<A, T, C>(pixels:[C], _ samples:UnsafeMutableBufferPointer<UInt8>,
        _ reference:(A) -> Int, _ kernel:(C) -> T, _ transform:(T) -> A)
        where A:FixedWidthInteger & UnsignedInteger
    {
        for (i, pixel) in zip(samples.indices, pixels)
        {
            let v:T                         = kernel(pixel)
            samples[i]                      = .init(reference(transform(v)))
        }
    }
    private static
    func deconvolve<A, T, C>(pixels:[C], _ samples:UnsafeMutableBufferPointer<UInt8>,
        _ reference:((A, A)) -> Int, _ kernel:(C) -> (T, T), _ transform:(T) -> A)
        where A:FixedWidthInteger & UnsignedInteger
    {
        for (i, pixel) in zip(samples.indices, pixels)
        {
            let (v, a):(T, T)               = kernel(pixel)
            samples[i]                      = .init(reference(
                (transform(v), transform(a))))
        }
    }
    private static
    func deconvolve<A, T, C>(pixels:[C], _ samples:UnsafeMutableBufferPointer<UInt8>,
        _ reference:((A, A, A)) -> Int, _ kernel:(C) -> (T, T, T), _ transform:(T) -> A)
        where A:FixedWidthInteger & UnsignedInteger
    {
        for (i, pixel) in zip(samples.indices, pixels)
        {
            let (r, g, b):(T, T, T)         = kernel(pixel)
            samples[i]                      = .init(reference(
                (transform(r), transform(g), transform(b))))
        }
    }
    private static
    func deconvolve<A, T, C>(pixels:[C], _ samples:UnsafeMutableBufferPointer<UInt8>,
        _ reference:((A, A, A, A)) -> Int, _ kernel:(C) -> (T, T, T, T), _ transform:(T) -> A)
        where A:FixedWidthInteger & UnsignedInteger
    {
        for (i, pixel) in zip(samples.indices, pixels)
        {
            let (r, g, b, a):(T, T, T, T)   = kernel(pixel)
            samples[i]                      = .init(reference(
                (transform(r), transform(g), transform(b), transform(a))))
        }
    }
    /// Converts a pixel array to an image data buffer, using the given
    /// pixel kernel and referencing function.
    ///
    /// This function maps the given `kernel` function over each element in
    /// `pixels`, receiving scalar intensities of type `T` in return. It then
    /// converts them into atoms of type `A`, scaling each intensity value
    /// to the range of `A`. Each scalar atom is then converted to an ``Int``
    /// index using the given `reference` function, and stored as a byte in
    /// the returned image data buffer.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter pixels:
    ///     A pixel array.
    /// -   Parameter reference:
    ///     A referencing function. Its return value must be in the range `0 ... 255`.
    ///     Depending on bit depth of the image it is being used for, there may
    ///     be further restrictions on the range of the returned indices.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An image data buffer.
    ///     This array has the same number of elements as `pixels`.
    public static
    func deconvolve<A, T, C>(_ pixels:[C], reference:(A) -> Int,
        kernel:(C) -> T)
        -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        .init(unsafeUninitializedCapacity: pixels.count)
        {
            (samples:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            count = pixels.count
            if      T.bitWidth == A.bitWidth
            {
                Self.deconvolve(pixels: pixels, samples, reference, kernel, A.init(_:))
            }
            else if T.bitWidth <  A.bitWidth
            {
                // there are essentially no situations where this path will actually get
                // executed since  palette entries are always 8-bits deep. however,
                // the implementation is here in case someone wants to use a
                // customized kernel that takes a wider integer type for some reason
                let quantum:A = Self.quantum(source: T.bitWidth, destination: A.bitWidth)
                Self.deconvolve(pixels: pixels, samples, reference, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = T.bitWidth - A.bitWidth
                Self.deconvolve(pixels: pixels, samples, reference, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts a pixel array to an image data buffer, using the given
    /// pixel kernel and referencing function.
    ///
    /// This function maps the given `kernel` function over each element in
    /// `pixels`, receiving `(T, T)` intensity pairs in return. It then
    /// converts them into atoms of type `A`, scaling each intensity value
    /// to the range of `A`. Each `(A, A)` pair is then converted to an ``Int``
    /// index using the given `reference` function, and stored as a byte in
    /// the returned image data buffer.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter pixels:
    ///     A pixel array.
    /// -   Parameter reference:
    ///     A referencing function. Its return value must be in the range `0 ... 255`.
    ///     Depending on bit depth of the image it is being used for, there may
    ///     be further restrictions on the range of the returned indices.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An image data buffer.
    ///     This array has the same number of elements as `pixels`.
    public static
    func deconvolve<A, T, C>(_ pixels:[C], reference:((A, A)) -> Int,
        kernel:(C) -> (T, T))
        -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        .init(unsafeUninitializedCapacity: pixels.count)
        {
            (samples:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            count = pixels.count
            if      T.bitWidth == A.bitWidth
            {
                Self.deconvolve(pixels: pixels, samples, reference, kernel, A.init(_:))
            }
            else if T.bitWidth <  A.bitWidth
            {
                // there are essentially no situations where this path will actually get
                // executed since  palette entries are always 8-bits deep. however,
                // the implementation is here in case someone wants to use a
                // customized kernel that takes a wider integer type for some reason
                let quantum:A = Self.quantum(source: T.bitWidth, destination: A.bitWidth)
                Self.deconvolve(pixels: pixels, samples, reference, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = T.bitWidth - A.bitWidth
                Self.deconvolve(pixels: pixels, samples, reference, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts a pixel array to an image data buffer, using the given
    /// pixel kernel and referencing function.
    ///
    /// This function maps the given `kernel` function over each element in
    /// `pixels`, receiving `(T, T, T)` intensity triplets in return. It then
    /// converts them into atoms of type `A`, scaling each intensity value
    /// to the range of `A`. Each `(A, A, A)` triplet is then converted to
    /// an ``Int`` index using the given `reference` function, and
    /// stored as a byte in the returned image data buffer.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter pixels:
    ///     A pixel array.
    /// -   Parameter reference:
    ///     A referencing function. Its return value must be in the range `0 ... 255`.
    ///     Depending on bit depth of the image it is being used for, there may
    ///     be further restrictions on the range of the returned indices.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An image data buffer.
    ///     This array has the same number of elements as `pixels`.
    public static
    func deconvolve<A, T, C>(_ pixels:[C], reference:((A, A, A)) -> Int,
        kernel:(C) -> (T, T, T))
        -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        .init(unsafeUninitializedCapacity: pixels.count)
        {
            (samples:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            count = pixels.count
            if      T.bitWidth == A.bitWidth
            {
                Self.deconvolve(pixels: pixels, samples, reference, kernel, A.init(_:))
            }
            else if T.bitWidth <  A.bitWidth
            {
                // there are essentially no situations where this path will actually get
                // executed since  palette entries are always 8-bits deep. however,
                // the implementation is here in case someone wants to use a
                // customized kernel that takes a wider integer type for some reason
                let quantum:A = Self.quantum(source: T.bitWidth, destination: A.bitWidth)
                Self.deconvolve(pixels: pixels, samples, reference, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = T.bitWidth - A.bitWidth
                Self.deconvolve(pixels: pixels, samples, reference, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts a pixel array to an image data buffer, using the given
    /// pixel kernel and referencing function.
    ///
    /// This function maps the given `kernel` function over each element in
    /// `pixels`, receiving `(T, T, T, T)` intensity quadruplets in return.
    /// It then converts them into atoms of type `A`, scaling each intensity value
    /// to the range of `A`. Each `(A, A, A, A)` quadruplet is then converted to
    /// an ``Int`` index using the given `reference` function, and
    /// stored as a byte in the returned image data buffer.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter pixels:
    ///     A pixel array.
    /// -   Parameter reference:
    ///     A referencing function. Its return value must be in the range `0 ... 255`.
    ///     Depending on bit depth of the image it is being used for, there may
    ///     be further restrictions on the range of the returned indices.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An image data buffer.
    ///     This array has the same number of elements as `pixels`.
    public static
    func deconvolve<A, T, C>(_ pixels:[C], reference:((A, A, A, A)) -> Int,
        kernel:(C) -> (T, T, T, T))
        -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        .init(unsafeUninitializedCapacity: pixels.count)
        {
            (samples:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            count = pixels.count
            if      T.bitWidth == A.bitWidth
            {
                Self.deconvolve(pixels: pixels, samples, reference, kernel, A.init(_:))
            }
            else if T.bitWidth <  A.bitWidth
            {
                // there are essentially no situations where this path will actually get
                // executed since  palette entries are always 8-bits deep. however,
                // the implementation is here in case someone wants to use a
                // customized kernel that takes a wider integer type for some reason
                let quantum:A = Self.quantum(source: T.bitWidth, destination: A.bitWidth)
                Self.deconvolve(pixels: pixels, samples, reference, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = T.bitWidth - A.bitWidth
                Self.deconvolve(pixels: pixels, samples, reference, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts a pixel array to an image data buffer, using the given
    /// pixel kernel.
    ///
    /// This function maps the given `kernel` function over each element in
    /// `pixels`, receiving scalar intensities of type `T` in return. It then
    /// converts them into atoms of type `A`, scaling each intensity value
    /// to the range specified by the given color `depth`. Each scalar atom
    /// is then stored as a big-endian integer in the returned image data buffer.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter pixels:
    ///     A pixel array.
    /// -   Parameter _:
    ///     An atom type.
    /// -   Parameter depth:
    ///     A color depth specifying the range of the atom values. This depth
    ///     can be no greater than `A.bitWidth`.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An image data buffer.
    ///     This array has a length of `pixels.count`, multiplied by the stride
    ///     of `A`.
    public static
    func deconvolve<A, T, C>(_ pixels:[C], as _:A.Type, depth:Int,
        kernel:(C) -> T)
        -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        let bytes:Int = pixels.count * MemoryLayout<A>.stride
        return .init(unsafeUninitializedCapacity: bytes)
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            count = bytes
            let raw:UnsafeMutableRawBufferPointer       = .init(buffer)
            let samples:UnsafeMutableBufferPointer<A>   = raw.bindMemory(to: A.self)
            if      T.bitWidth == depth
            {
                Self.deconvolve(pixels: pixels, samples, kernel, A.init(_:))
            }
            else if T.bitWidth <  depth
            {
                let quantum:A = Self.quantum(source: T.bitWidth, destination: depth)
                Self.deconvolve(pixels: pixels, samples, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = T.bitWidth - depth
                Self.deconvolve(pixels: pixels, samples, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts a pixel array to an image data buffer, using the given
    /// pixel kernel.
    ///
    /// This function maps the given `kernel` function over each element in
    /// `pixels`, receiving `(T, T)` intensity pairs in return. It then
    /// converts them into atoms of type `A`, scaling each intensity value
    /// to the range specified by the given color `depth`. The elements of
    /// the generated `(A, A)` pairs are then stored sequentially
    /// as big-endian integers in the returned image data buffer.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter pixels:
    ///     A pixel array.
    /// -   Parameter _:
    ///     An atom type.
    /// -   Parameter depth:
    ///     A color depth specifying the range of the atom values. This depth
    ///     can be no greater than `A.bitWidth`.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An image data buffer.
    ///     This array has a length of `pixels.count`, multiplied by twice the
    ///     stride of `A`.
    public static
    func deconvolve<A, T, C>(_ pixels:[C], as _:A.Type, depth:Int,
        kernel:(C) -> (T, T))
        -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        let bytes:Int = pixels.count * MemoryLayout<A>.stride * 2
        return .init(unsafeUninitializedCapacity: bytes)
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            count = bytes
            let raw:UnsafeMutableRawBufferPointer       = .init(buffer)
            let samples:UnsafeMutableBufferPointer<A>   = raw.bindMemory(to: A.self)
            if      T.bitWidth == depth
            {
                Self.deconvolve(pixels: pixels, samples, kernel, A.init(_:))
            }
            else if T.bitWidth <  depth
            {
                let quantum:A = Self.quantum(source: T.bitWidth, destination: depth)
                Self.deconvolve(pixels: pixels, samples, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = T.bitWidth - depth
                Self.deconvolve(pixels: pixels, samples, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts a pixel array to an image data buffer, using the given
    /// pixel kernel.
    ///
    /// This function maps the given `kernel` function over each element in
    /// `pixels`, receiving `(T, T, T)` intensity triplets in return. It then
    /// converts them into atoms of type `A`, scaling each intensity value
    /// to the range specified by the given color `depth`. The elements of
    /// the generated `(A, A, A)` triplets are then stored sequentially
    /// as big-endian integers in the returned image data buffer.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter pixels:
    ///     A pixel array.
    /// -   Parameter _:
    ///     An atom type.
    /// -   Parameter depth:
    ///     A color depth specifying the range of the atom values. This depth
    ///     can be no greater than `A.bitWidth`.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An image data buffer.
    ///     This array has a length of `pixels.count`, multiplied by three times
    ///     the stride of `A`.
    public static
    func deconvolve<A, T, C>(_ pixels:[C], as _:A.Type, depth:Int,
        kernel:(C) -> (T, T, T))
        -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        let bytes:Int = pixels.count * MemoryLayout<A>.stride * 3
        return .init(unsafeUninitializedCapacity: bytes)
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            count = bytes
            let raw:UnsafeMutableRawBufferPointer       = .init(buffer)
            let samples:UnsafeMutableBufferPointer<A>   = raw.bindMemory(to: A.self)
            if      T.bitWidth == depth
            {
                Self.deconvolve(pixels: pixels, samples, kernel, A.init(_:))
            }
            else if T.bitWidth <  depth
            {
                let quantum:A = Self.quantum(source: T.bitWidth, destination: depth)
                Self.deconvolve(pixels: pixels, samples, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = T.bitWidth - depth
                Self.deconvolve(pixels: pixels, samples, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
    /// Converts a pixel array to an image data buffer, using the given
    /// pixel kernel.
    ///
    /// This function maps the given `kernel` function over each element in
    /// `pixels`, receiving `(T, T, T, T)` intensity quadruplets in return. It then
    /// converts them into atoms of type `A`, scaling each intensity value
    /// to the range specified by the given color `depth`. The elements of
    /// the generated `(A, A, A, A)` quadruplets are then stored sequentially
    /// as big-endian integers in the returned image data buffer.
    ///
    /// A worked example of how to use this function to implement a custom
    /// color target can be found in the
    /// [custom color targets tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#custom-color-targets).
    /// -   Parameter pixels:
    ///     A pixel array.
    /// -   Parameter _:
    ///     An atom type.
    /// -   Parameter depth:
    ///     A color depth specifying the range of the atom values. This depth
    ///     can be no greater than `A.bitWidth`.
    /// -   Parameter kernel:
    ///     A pixel kernel.
    /// -   Returns:
    ///     An image data buffer.
    ///     This array has a length of `pixels.count`, multiplied by four times
    ///     the stride of `A`.
    public static
    func deconvolve<A, T, C>(_ pixels:[C], as _:A.Type, depth:Int,
        kernel:(C) -> (T, T, T, T))
        -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        let bytes:Int = pixels.count * MemoryLayout<A>.stride * 4
        return .init(unsafeUninitializedCapacity: bytes)
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            count = bytes
            let raw:UnsafeMutableRawBufferPointer       = .init(buffer)
            let samples:UnsafeMutableBufferPointer<A>   = raw.bindMemory(to: A.self)
            if      T.bitWidth == depth
            {
                Self.deconvolve(pixels: pixels, samples, kernel, A.init(_:))
            }
            else if T.bitWidth <  depth
            {
                let quantum:A = Self.quantum(source: T.bitWidth, destination: depth)
                Self.deconvolve(pixels: pixels, samples, kernel)
                {
                    quantum &* .init($0)
                }
            }
            else
            {
                let shift:Int = T.bitWidth - depth
                Self.deconvolve(pixels: pixels, samples, kernel)
                {
                    .init($0 &>> shift)
                }
            }
        }
    }
}
