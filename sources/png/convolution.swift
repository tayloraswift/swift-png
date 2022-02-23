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
    
    /// static func PNG.convolve<A, T, C>(_:dereference:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts an image data buffer to a pixel array, using the given 
    ///     pixel kernel and dereferencing function.
    /// 
    ///     This function casts each byte in `buffer` to an [`Swift.Int`] index, 
    ///     and passes each index to the given `dereference` function, receiving 
    ///     scalar atoms of type `A` in return. It then scales the atoms to the 
    ///     range of `T`, and constructs instances of `C` by mapping the given 
    ///     `kernel` function over each `T` scalar.
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - buffer : [Swift.UInt8]
    ///     An image data buffer. 
    /// - dereference : (Swift.Int) -> A 
    ///     A dereferencing function. 
    /// - kernel : (T) -> C 
    ///     A pixel kernel. 
    /// - -> : [C]
    ///     An array of pixels constructed by the given `kernel` function. 
    ///     This array has the same number of elements as `buffer`. 
    /// # [See also](convolution)
    /// ## (convolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.convolve<A, T, C>(_:dereference:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts an image data buffer to a pixel array, using the given 
    ///     pixel kernel and dereferencing function.
    /// 
    ///     This function casts each byte in `buffer` to an [`Swift.Int`] index, 
    ///     and passes each index to the given `dereference` function, receiving 
    ///     pairs of atoms of type `A` in return. It then scales the atoms to the 
    ///     range of `T`, and constructs instances of `C` by mapping the given 
    ///     `kernel` function over each `(T, T)` pair.
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - buffer : [Swift.UInt8]
    ///     An image data buffer. 
    /// - dereference : (Swift.Int) -> (A, A) 
    ///     A dereferencing function. 
    /// - kernel : ((T, T)) -> C 
    ///     A pixel kernel. 
    /// - -> : [C]
    ///     An array of pixels constructed by the given `kernel` function. 
    ///     This array has the same number of elements as `buffer`. 
    /// # [See also](convolution)
    /// ## (convolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.convolve<A, T, C>(_:dereference:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts an image data buffer to a pixel array, using the given 
    ///     pixel kernel and dereferencing function.
    /// 
    ///     This function casts each byte in `buffer` to an [`Swift.Int`] index, 
    ///     and passes each index to the given `dereference` function, receiving 
    ///     triplets of atoms of type `A` in return. It then scales the atoms to the 
    ///     range of `T`, and constructs instances of `C` by mapping the given 
    ///     `kernel` function over each `(T, T, T)` triplet.
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - buffer : [Swift.UInt8]
    ///     An image data buffer. 
    /// - dereference : (Swift.Int) -> (A, A, A) 
    ///     A dereferencing function. 
    /// - kernel : ((T, T, T)) -> C 
    ///     A pixel kernel. 
    /// - -> : [C]
    ///     An array of pixels constructed by the given `kernel` function. 
    ///     This array has the same number of elements as `buffer`. 
    /// # [See also](convolution)
    /// ## (convolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.convolve<A, T, C>(_:dereference:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts an image data buffer to a pixel array, using the given 
    ///     pixel kernel and dereferencing function.
    /// 
    ///     This function casts each byte in `buffer` to an [`Swift.Int`] index, 
    ///     and passes each index to the given `dereference` function, receiving 
    ///     quadruplets of atoms of type `A` in return. It then scales the atoms to the 
    ///     range of `T`, and constructs instances of `C` by mapping the given 
    ///     `kernel` function over each `(T, T, T, T)` quadruplet.
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - buffer : [Swift.UInt8]
    ///     An image data buffer. 
    /// - dereference : (Swift.Int) -> (A, A, A, A) 
    ///     A dereferencing function. 
    /// - kernel : ((T, T, T, T)) -> C 
    ///     A pixel kernel. 
    /// - -> : [C]
    ///     An array of pixels constructed by the given `kernel` function. 
    ///     This array has the same number of elements as `buffer`. 
    /// # [See also](convolution)
    /// ## (convolution)
    /// ## (custom-color-targets)
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
    
    /// static func PNG.convolve<A, T, C>(_:of:depth:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts an image data buffer to a pixel array, using the given 
    ///     pixel kernel.
    /// 
    ///     This function interprets `buffer` as an array of big-endian atoms of 
    ///     type `A`. It then scales the atoms to the range of `T`, according to 
    ///     the given color `depth`, and constructs instances of `C` by mapping 
    ///     the given `kernel` function over each `T` scalar, and the original 
    ///     scalar atom it was generated from.
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - buffer : [Swift.UInt8]
    ///     An image data buffer. Its length must be divisible by the stride of `A`.
    /// - _ : A.Type 
    ///     An atom type.
    /// - depth : Swift.Int 
    ///     A color depth used to interpret the intensity of each atom.
    ///     This depth must be no greater than `A.bitWidth`.
    /// - kernel : (T, A) -> C 
    ///     A pixel kernel. 
    /// - -> : [C]
    ///     An array of pixels constructed by the given `kernel` function. 
    ///     This array has a length of `buffer.count` divided by the stride of `A`.
    /// # [See also](convolution)
    /// ## (convolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.convolve<A, T, C>(_:of:depth:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts an image data buffer to a pixel array, using the given 
    ///     pixel kernel.
    /// 
    ///     This function interprets `buffer` as an array of big-endian atoms of 
    ///     type `A`. It then scales the atoms to the range of `T`, according to 
    ///     the given color `depth`, and constructs instances of `C` by mapping 
    ///     the given `kernel` function over consecutive `(T, T)` pairs.
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - buffer : [Swift.UInt8]
    ///     An image data buffer. Its length must be divisible by twice the 
    ///     stride of `A`.
    /// - _ : A.Type 
    ///     An atom type.
    /// - depth : Swift.Int 
    ///     A color depth used to interpret the intensity of each atom.
    ///     This depth must be no greater than `A.bitWidth`.
    /// - kernel : ((T, T)) -> C 
    ///     A pixel kernel. 
    /// - -> : [C]
    ///     An array of pixels constructed by the given `kernel` function. 
    ///     This array has a length of `buffer.count` divided by the twice the 
    ///     stride of `A`.
    /// # [See also](convolution)
    /// ## (convolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.convolve<A, T, C>(_:of:depth:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts an image data buffer to a pixel array, using the given 
    ///     pixel kernel.
    /// 
    ///     This function interprets `buffer` as an array of big-endian atoms of 
    ///     type `A`. It then scales the atoms to the range of `T`, according to 
    ///     the given color `depth`, and constructs instances of `C` by mapping 
    ///     the given `kernel` function over consecutive `(T, T, T)` triplets, 
    ///     and the original atoms they were generated from.
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - buffer : [Swift.UInt8]
    ///     An image data buffer. Its length must be divisible by three times the 
    ///     stride of `A`.
    /// - _ : A.Type 
    ///     An atom type.
    /// - depth : Swift.Int 
    ///     A color depth used to interpret the intensity of each atom.
    ///     This depth must be no greater than `A.bitWidth`.
    /// - kernel : ((T, T, T), (A, A, A)) -> C 
    ///     A pixel kernel. 
    /// - -> : [C]
    ///     An array of pixels constructed by the given `kernel` function. 
    ///     This array has a length of `buffer.count` divided by the three times 
    ///     the stride of `A`.
    /// # [See also](convolution)
    /// ## (convolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.convolve<A, T, C>(_:of:depth:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts an image data buffer to a pixel array, using the given 
    ///     pixel kernel.
    /// 
    ///     This function interprets `buffer` as an array of big-endian atoms of 
    ///     type `A`. It then scales the atoms to the range of `T`, according to 
    ///     the given color `depth`, and constructs instances of `C` by mapping 
    ///     the given `kernel` function over consecutive `(T, T, T, T)` quadruplets.
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - buffer : [Swift.UInt8]
    ///     An image data buffer. Its length must be divisible by four times the 
    ///     stride of `A`.
    /// - _ : A.Type 
    ///     An atom type.
    /// - depth : Swift.Int 
    ///     A color depth used to interpret the intensity of each atom.
    ///     This depth must be no greater than `A.bitWidth`.
    /// - kernel : ((T, T, T, T)) -> C 
    ///     A pixel kernel. 
    /// - -> : [C]
    ///     An array of pixels constructed by the given `kernel` function. 
    ///     This array has a length of `buffer.count` divided by the four times 
    ///     the stride of `A`.
    /// # [See also](convolution)
    /// ## (convolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.deconvolve<A, T, C>(_:reference:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts a pixel array to an image data buffer, using the given 
    ///     pixel kernel and referencing function.
    /// 
    ///     This function maps the given `kernel` function over each element in 
    ///     `pixels`, receiving scalar intensities of type `T` in return. It then 
    ///     converts them into atoms of type `A`, scaling each intensity value 
    ///     to the range of `A`. Each scalar atom is then converted to an [`Swift.Int`]
    ///     index using the given `reference` function, and stored as a byte in 
    ///     the returned image data buffer. 
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - pixels : [C]
    ///     A pixel array. 
    /// - reference : (A) -> Swift.Int 
    ///     A referencing function. Its return value must be in the range `0 ... 255`. 
    ///     Depending on bit depth of the image it is being used for, there may 
    ///     be further restrictions on the range of the returned indices.
    /// - kernel : (C) -> T 
    ///     A pixel kernel. 
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. 
    ///     This array has the same number of elements as `pixels`. 
    /// # [See also](deconvolution)
    /// ## (deconvolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.deconvolve<A, T, C>(_:reference:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts a pixel array to an image data buffer, using the given 
    ///     pixel kernel and referencing function.
    /// 
    ///     This function maps the given `kernel` function over each element in 
    ///     `pixels`, receiving `(T, T)` intensity pairs in return. It then 
    ///     converts them into atoms of type `A`, scaling each intensity value 
    ///     to the range of `A`. Each `(A, A)` pair is then converted to an [`Swift.Int`]
    ///     index using the given `reference` function, and stored as a byte in 
    ///     the returned image data buffer. 
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - pixels : [C]
    ///     A pixel array. 
    /// - reference : ((A, A)) -> Swift.Int 
    ///     A referencing function. Its return value must be in the range `0 ... 255`. 
    ///     Depending on bit depth of the image it is being used for, there may 
    ///     be further restrictions on the range of the returned indices.
    /// - kernel : (C) -> (T, T)
    ///     A pixel kernel. 
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. 
    ///     This array has the same number of elements as `pixels`. 
    /// # [See also](deconvolution)
    /// ## (deconvolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.deconvolve<A, T, C>(_:reference:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts a pixel array to an image data buffer, using the given 
    ///     pixel kernel and referencing function.
    /// 
    ///     This function maps the given `kernel` function over each element in 
    ///     `pixels`, receiving `(T, T, T)` intensity triplets in return. It then 
    ///     converts them into atoms of type `A`, scaling each intensity value 
    ///     to the range of `A`. Each `(A, A, A)` triplet is then converted to 
    ///     an [`Swift.Int`] index using the given `reference` function, and 
    ///     stored as a byte in the returned image data buffer. 
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - pixels : [C]
    ///     A pixel array. 
    /// - reference : ((A, A, A)) -> Swift.Int 
    ///     A referencing function. Its return value must be in the range `0 ... 255`. 
    ///     Depending on bit depth of the image it is being used for, there may 
    ///     be further restrictions on the range of the returned indices.
    /// - kernel : (C) -> (T, T, T)
    ///     A pixel kernel. 
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. 
    ///     This array has the same number of elements as `pixels`. 
    /// # [See also](deconvolution)
    /// ## (deconvolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.deconvolve<A, T, C>(_:reference:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts a pixel array to an image data buffer, using the given 
    ///     pixel kernel and referencing function.
    /// 
    ///     This function maps the given `kernel` function over each element in 
    ///     `pixels`, receiving `(T, T, T, T)` intensity quadruplets in return. 
    ///     It then converts them into atoms of type `A`, scaling each intensity value 
    ///     to the range of `A`. Each `(A, A, A, A)` quadruplet is then converted to 
    ///     an [`Swift.Int`] index using the given `reference` function, and 
    ///     stored as a byte in the returned image data buffer. 
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - pixels : [C]
    ///     A pixel array. 
    /// - reference : ((A, A, A, A)) -> Swift.Int 
    ///     A referencing function. Its return value must be in the range `0 ... 255`. 
    ///     Depending on bit depth of the image it is being used for, there may 
    ///     be further restrictions on the range of the returned indices.
    /// - kernel : (C) -> (T, T, T, T)
    ///     A pixel kernel. 
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. 
    ///     This array has the same number of elements as `pixels`. 
    /// # [See also](deconvolution)
    /// ## (deconvolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.deconvolve<A, T, C>(_:as:depth:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts a pixel array to an image data buffer, using the given 
    ///     pixel kernel.
    /// 
    ///     This function maps the given `kernel` function over each element in 
    ///     `pixels`, receiving scalar intensities of type `T` in return. It then 
    ///     converts them into atoms of type `A`, scaling each intensity value 
    ///     to the range specified by the given color `depth`. Each scalar atom 
    ///     is then stored as a big-endian integer in the returned image data buffer. 
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - pixels : [C]
    ///     A pixel array. 
    /// - _ : A.Type 
    ///     An atom type.
    /// - depth : Swift.Int 
    ///     A color depth specifying the range of the atom values. This depth 
    ///     can be no greater than `A.bitWidth`.
    /// - kernel : (C) -> T 
    ///     A pixel kernel. 
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. 
    ///     This array has a length of `pixels.count`, multiplied by the stride 
    ///     of `A`. 
    /// # [See also](deconvolution)
    /// ## (deconvolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.deconvolve<A, T, C>(_:as:depth:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts a pixel array to an image data buffer, using the given 
    ///     pixel kernel.
    /// 
    ///     This function maps the given `kernel` function over each element in 
    ///     `pixels`, receiving `(T, T)` intensity pairs in return. It then 
    ///     converts them into atoms of type `A`, scaling each intensity value 
    ///     to the range specified by the given color `depth`. The elements of 
    ///     the generated `(A, A)` pairs are then stored sequentially 
    ///     as big-endian integers in the returned image data buffer. 
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - pixels : [C]
    ///     A pixel array. 
    /// - _ : A.Type 
    ///     An atom type.
    /// - depth : Swift.Int 
    ///     A color depth specifying the range of the atom values. This depth 
    ///     can be no greater than `A.bitWidth`.
    /// - kernel : (C) -> (T, T) 
    ///     A pixel kernel. 
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. 
    ///     This array has a length of `pixels.count`, multiplied by twice the 
    ///     stride of `A`. 
    /// # [See also](deconvolution)
    /// ## (deconvolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.deconvolve<A, T, C>(_:as:depth:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts a pixel array to an image data buffer, using the given 
    ///     pixel kernel.
    /// 
    ///     This function maps the given `kernel` function over each element in 
    ///     `pixels`, receiving `(T, T, T)` intensity triplets in return. It then 
    ///     converts them into atoms of type `A`, scaling each intensity value 
    ///     to the range specified by the given color `depth`. The elements of 
    ///     the generated `(A, A, A)` triplets are then stored sequentially 
    ///     as big-endian integers in the returned image data buffer. 
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - pixels : [C]
    ///     A pixel array. 
    /// - _ : A.Type 
    ///     An atom type.
    /// - depth : Swift.Int 
    ///     A color depth specifying the range of the atom values. This depth 
    ///     can be no greater than `A.bitWidth`.
    /// - kernel : (C) -> (T, T, T) 
    ///     A pixel kernel. 
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. 
    ///     This array has a length of `pixels.count`, multiplied by three times 
    ///     the stride of `A`. 
    /// # [See also](deconvolution)
    /// ## (deconvolution)
    /// ## (custom-color-targets)
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
    /// static func PNG.deconvolve<A, T, C>(_:as:depth:kernel:)
    /// where A:Swift.FixedWidthInteger & Swift.UnsignedInteger, T:Swift.FixedWidthInteger & Swift.UnsignedInteger 
    ///     Converts a pixel array to an image data buffer, using the given 
    ///     pixel kernel.
    /// 
    ///     This function maps the given `kernel` function over each element in 
    ///     `pixels`, receiving `(T, T, T, T)` intensity quadruplets in return. It then 
    ///     converts them into atoms of type `A`, scaling each intensity value 
    ///     to the range specified by the given color `depth`. The elements of 
    ///     the generated `(A, A, A, A)` quadruplets are then stored sequentially 
    ///     as big-endian integers in the returned image data buffer. 
    /// 
    ///     A worked example of how to use this function to implement a custom 
    ///     color target can be found in the 
    ///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
    /// - pixels : [C]
    ///     A pixel array. 
    /// - _ : A.Type 
    ///     An atom type.
    /// - depth : Swift.Int 
    ///     A color depth specifying the range of the atom values. This depth 
    ///     can be no greater than `A.bitWidth`.
    /// - kernel : (C) -> (T, T, T, T) 
    ///     A pixel kernel. 
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. 
    ///     This array has a length of `pixels.count`, multiplied by four times 
    ///     the stride of `A`. 
    /// # [See also](deconvolution)
    /// ## (deconvolution)
    /// ## (custom-color-targets)
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
