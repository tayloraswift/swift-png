public 
protocol _PNGColor 
{
    associatedtype Aggregate 
    
    static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format, 
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> Aggregate) 
        -> [Self]
    static 
    func pack(_ pixels:[Self], as format:PNG.Format, 
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Aggregate) -> Int) 
        -> [UInt8] 
        
    static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format) -> [Self]
    static 
    func pack(_ pixels:[Self], as format:PNG.Format) -> [UInt8] 
}
extension PNG 
{
    public 
    typealias Color = _PNGColor
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

extension PNG 
{
    @inlinable
    public static
    func premultiply<T>(color:T, alpha:T) -> T 
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
    
    @inlinable
    public static
    func straighten<T>(premultiplied:T, alpha:T) -> T 
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
    
    @frozen
    public
    struct RGBA<T>:Hashable where T:FixedWidthInteger & UnsignedInteger
    {
        /// The red component of this color.
        public
        var r:T
        /// The green component of this color.
        public
        var g:T
        /// The blue component of this color.
        public
        var b:T
        /// The alpha component of this color.
        public
        var a:T
    }
    
    @frozen
    public
    struct VA<T>:Hashable where T:FixedWidthInteger & UnsignedInteger
    {
        /// The value component of this color.
        public
        var v:T
        /// The alpha component of this color.
        public
        var a:T
    }
}
extension PNG.RGBA 
{
    /// Creates an opaque grayscale color with all color components set to the given
    /// value sample, and the alpha component set to `T.max`.
    /// 
    /// *Specialized* for `T` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - value: The value to initialize all color components to.
    @inlinable
    public
    init(_ value:T)
    {
        self.init(value, value, value, T.max)
    }

    /// Creates a grayscale color with all color components set to the given
    /// value sample, and the alpha component set to the given alpha sample.
    /// 
    /// *Specialized* for `T` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - value: The value to initialize all color components to.
    ///     - alpha: The value to initialize the alpha component to.
    @inlinable
    public
    init(_ value:T, _ alpha:T)
    {
        self.init(value, value, value, alpha)
    }

    /// Creates an opaque color with the given color samples, and the alpha
    /// component set to `T.max`.
    /// 
    /// *Specialized* for `T` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - red: The value to initialize the red component to.
    ///     - green: The value to initialize the green component to.
    ///     - blue: The value to initialize the blue component to.
    @inlinable
    public
    init(_ red:T, _ green:T, _ blue:T)
    {
        self.init(red, green, blue, T.max)
    }

    /// Creates an opaque color with the given color and alpha samples.
    /// 
    /// *Specialized* for `T` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - red: The value to initialize the red component to.
    ///     - green: The value to initialize the green component to.
    ///     - blue: The value to initialize the blue component to.
    ///     - alpha: The value to initialize the alpha component to.
    @inlinable
    public
    init(_ red:T, _ green:T, _ blue:T, _ alpha:T)
    {
        self.r = red
        self.g = green
        self.b = blue
        self.a = alpha
    }
    
    @inlinable
    public 
    init(_ va:PNG.VA<T>)
    {
        self.init(va.v, va.a)
    }

    /// The red, and alpha components of this color, stored as a grayscale-alpha
    /// color.
    /// 
    /// *Inlinable*.
    @inlinable
    public
    var va:PNG.VA<T>
    {
        .init(self.r, self.a)
    } 
    
    @inlinable
    public
    var premultiplied:Self
    {
        .init(  PNG.premultiply(color: self.r, alpha: self.a),
                PNG.premultiply(color: self.g, alpha: self.a),
                PNG.premultiply(color: self.b, alpha: self.a),
                self.a)
    }
    @inlinable
    public
    func premultiplied<U>(as _:U.Type) -> Self
        where U:FixedWidthInteger & UnsignedInteger
    {
        precondition(T.bitWidth > U.bitWidth, 
            "cannot premultiply alpha in higher-precision than original color")
        let shift:Int   = T.bitWidth - U.bitWidth
        let q:T         = T.max / T.max >> shift
        let a:U         = .init(self.a >> shift) 
        
        let r:T = T.init(PNG.premultiply(color: U.init(self.r >> shift), alpha: a)) * q, 
            g:T = T.init(PNG.premultiply(color: U.init(self.g >> shift), alpha: a)) * q, 
            b:T = T.init(PNG.premultiply(color: U.init(self.b >> shift), alpha: a)) * q
        return .init(r, g, b, T.init(a) * q)
    }
    
    @inlinable
    public
    var straightened:Self
    {
        .init(  PNG.straighten(premultiplied: self.r, alpha: self.a),
                PNG.straighten(premultiplied: self.g, alpha: self.a),
                PNG.straighten(premultiplied: self.b, alpha: self.a),
                self.a)
    }
    @inlinable
    public
    func straightened<U>(as _:U.Type) -> Self
        where U:FixedWidthInteger & UnsignedInteger
    {
        precondition(T.bitWidth > U.bitWidth, 
            "cannot straighten alpha in higher-precision than original color")

        let shift:Int   = T.bitWidth - U.bitWidth
        let q:T         = T.max / T.max >> shift
        let a:U         = .init(self.a >> shift) 
        
        let r:T = T.init(PNG.straighten(premultiplied: U.init(self.r >> shift), alpha: a)) * q, 
            g:T = T.init(PNG.straighten(premultiplied: U.init(self.g >> shift), alpha: a)) * q, 
            b:T = T.init(PNG.straighten(premultiplied: U.init(self.b >> shift), alpha: a)) * q
        return .init(r, g, b, T.init(a) * q)
    }
}
extension PNG.VA 
{
    @inlinable
    public
    init(_ value:T)
    {
        self.init(value, T.max)
    }
    
    @inlinable
    public
    init(_ value:T, _ alpha:T)
    {
        self.v = value
        self.a = alpha
    }
    
    @inlinable
    public
    var premultiplied:Self
    {
        .init(PNG.premultiply(color: self.v, alpha: self.a), self.a)
    }
    @inlinable
    public
    func premultiplied<U>(as _:U.Type) -> Self
        where U:FixedWidthInteger & UnsignedInteger
    {
        precondition(T.bitWidth > U.bitWidth, 
            "cannot premultiply in higher-precision than original color")
        let shift:Int   = T.bitWidth - U.bitWidth
        let q:T         = T.max / T.max >> shift
        let a:U         = .init(self.a >> shift) 
        
        let v:T = T.init(PNG.premultiply(color: U.init(self.v >> shift), alpha: a)) * q
        return .init(v, T.init(a) * q)
    }
    
    @inlinable
    public
    var straightened:Self
    {
        .init(PNG.straighten(premultiplied: self.v, alpha: self.a), self.a)
    }
    @inlinable
    public
    func straightened<U>(as _:U.Type) -> Self
        where U:FixedWidthInteger & UnsignedInteger
    {
        precondition(T.bitWidth > U.bitWidth, 
            "cannot premultiply in higher-precision than original color")
        let shift:Int   = T.bitWidth - U.bitWidth
        let q:T         = T.max / T.max >> shift
        let a:U         = .init(self.a >> shift) 
        
        let v:T = T.init(PNG.straighten(premultiplied: U.init(self.v >> shift), alpha: a)) * q
        return .init(v, T.init(a) * q)
    }
}

extension PNG.RGBA:PNG.Color 
{
    public 
    typealias Aggregate = (UInt8, UInt8, UInt8, UInt8)
    
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    public static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format, 
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> Aggregate) 
        -> [Self] 
    {
        let depth:Int = format.pixel.depth 
        switch format 
        {
        case    .indexed1(palette: let palette, fill: _), 
                .indexed2(palette: let palette, fill: _), 
                .indexed4(palette: let palette, fill: _), 
                .indexed8(palette: let palette, fill: _):
            return PNG.convolve(interleaved, dereference: deindexer(palette)) 
            {
                (c) in .init(c.0, c.1, c.2, c.3)
            }
                
        case    .v1(fill: _, key: nil),
                .v2(fill: _, key: nil),
                .v4(fill: _, key: nil),
                .v8(fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth) 
            {
                (c:T, _) in .init(c)
            }
        case    .v16(fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth) 
            {
                (c:T, _) in .init(c)
            }
        case    .v1(fill: _, key: let key?),
                .v2(fill: _, key: let key?),
                .v4(fill: _, key: let key?),
                .v8(fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:T, k:UInt8 )     in .init(c, k == key ? .min : .max)
            }
        case    .v16(fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth) 
            {
                (c:T, k:UInt16)     in .init(c, k == key ? .min : .max)
            }

        case    .va8(fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T))          in .init(c.0, c.1)
            }
        case    .va16(fill: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T))          in .init(c.0, c.1)
            }
        
        case    .bgr8(palette: _, fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), _)    in .init(c.2, c.1, c.0)
            }
        case    .bgr8(palette: _, fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), k:(UInt8,  UInt8,  UInt8 )) in 
                .init(c.2, c.1, c.0, k == key ? .min : .max)
            }
    
        case    .rgb8(palette: _, fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), _)    in .init(c.0, c.1, c.2)
            }
        case    .rgb16(palette: _, fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T), _)    in .init(c.0, c.1, c.2)
            }
        case    .rgb8(palette: _, fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), k:(UInt8,  UInt8,  UInt8 )) in 
                .init(c.0, c.1, c.2, k == key ? .min : .max)
            }
        case    .rgb16(palette: _, fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T), k:(UInt16, UInt16, UInt16)) in 
                .init(c.0, c.1, c.2, k == key ? .min : .max)
            }
        
        case    .bgra8(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T, T)) in .init(c.2, c.1, c.0, c.3)
            }
        
        case    .rgba8(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T, T)) in .init(c.0, c.1, c.2, c.3)
            }
        case    .rgba16(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T, T)) in .init(c.0, c.1, c.2, c.3)
            }
        }
    }
    
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    public static 
    func pack(_ pixels:[Self], as format:PNG.Format, 
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Aggregate) -> Int) 
        -> [UInt8] 
    {
        let depth:Int = format.pixel.depth 
        switch format 
        {
        case    .indexed1(palette: let palette, fill: _), 
                .indexed2(palette: let palette, fill: _), 
                .indexed4(palette: let palette, fill: _), 
                .indexed8(palette: let palette, fill: _):
            return PNG.deconvolve(pixels, reference: indexer(palette)) 
            {
                (c) in (c.r, c.g, c.b, c.a)
            }
                
        case    .v1(fill: _, key: _),
                .v2(fill: _, key: _),
                .v4(fill: _, key: _),
                .v8(fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self,  depth: depth, kernel: \.r) 
        case    .v16(fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth, kernel: \.r) 

        case    .va8(fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c) in (c.r, c.a)
            }
        case    .va16(fill: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (c) in (c.r, c.a)
            }
        
        case    .bgr8(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c) in (c.b, c.g, c.r)
            }
    
        case    .rgb8(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c) in (c.r, c.g, c.b)
            }
        case    .rgb16(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (c) in (c.r, c.g, c.b)
            }
        
        case    .bgra8(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c) in (c.b, c.g, c.r, c.a)
            }
        
        case    .rgba8(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c) in (c.r, c.g, c.b, c.a)
            }
        case    .rgba16(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (c) in (c.r, c.g, c.b, c.a)
            }
        }
    }
}
extension PNG.VA:PNG.Color 
{
    public 
    typealias Aggregate = (UInt8, UInt8)
    
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    public static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format, 
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> Aggregate) 
        -> [Self] 
    {
        let depth:Int = format.pixel.depth 
        switch format 
        {
        case    .indexed1(palette: let palette, fill: _), 
                .indexed2(palette: let palette, fill: _), 
                .indexed4(palette: let palette, fill: _), 
                .indexed8(palette: let palette, fill: _):
            return PNG.convolve(interleaved, dereference: deindexer(palette)) 
            {
                (c) in .init(c.0, c.1)
            }
                
        case    .v1(fill: _, key: nil),
                .v2(fill: _, key: nil),
                .v4(fill: _, key: nil),
                .v8(fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth) 
            {
                (c:T, _) in .init(c)
            }
        case    .v16(fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth) 
            {
                (c:T, _) in .init(c)
            }
        case    .v1(fill: _, key: let key?),
                .v2(fill: _, key: let key?),
                .v4(fill: _, key: let key?),
                .v8(fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:T, k:UInt8 )     in .init(c, k == key ? .min : .max)
            }
        case    .v16(fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth) 
            {
                (c:T, k:UInt16)     in .init(c, k == key ? .min : .max)
            }

        case    .va8(fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T))          in .init(c.0, c.1)
            }
        case    .va16(fill: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T))          in .init(c.0, c.1)
            }
        
        case    .bgr8(palette: _, fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), _)    in .init(c.2)
            }
        case    .bgr8(palette: _, fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), k:(UInt8,  UInt8,  UInt8 )) in 
                .init(c.2, k == key ? .min : .max)
            }
    
        case    .rgb8(palette: _, fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), _)    in .init(c.0)
            }
        case    .rgb16(palette: _, fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T), _)    in .init(c.0)
            }
        case    .rgb8(palette: _, fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), k:(UInt8,  UInt8,  UInt8 )) in 
                .init(c.0, k == key ? .min : .max)
            }
        case    .rgb16(palette: _, fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T), k:(UInt16, UInt16, UInt16)) in 
                .init(c.0, k == key ? .min : .max)
            }
        
        case    .bgra8(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T, T)) in .init(c.2, c.3)
            }
        
        case    .rgba8(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T, T)) in .init(c.0, c.3)
            }
        case    .rgba16(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T, T)) in .init(c.0, c.3)
            }
        }
    }
    
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    public static 
    func pack(_ pixels:[Self], as format:PNG.Format, 
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Aggregate) -> Int) 
        -> [UInt8] 
    {
        let depth:Int = format.pixel.depth 
        switch format 
        {
        case    .indexed1(palette: let palette, fill: _), 
                .indexed2(palette: let palette, fill: _), 
                .indexed4(palette: let palette, fill: _), 
                .indexed8(palette: let palette, fill: _):
            return PNG.deconvolve(pixels, reference: indexer(palette)) 
            {
                (c) in (c.v, c.a)
            }
                
        case    .v1(fill: _, key: _),
                .v2(fill: _, key: _),
                .v4(fill: _, key: _),
                .v8(fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth) 
            {
                (c) in c.v
            }
        case    .v16(fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth) 
            {
                (c) in c.v
            }

        case    .va8(fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c) in (c.v, c.a)
            }
        case    .va16(fill: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (c) in (c.v, c.a)
            }
        
        case    .bgr8(palette: _, fill: _, key: _), 
                .rgb8(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c) in (c.v, c.v, c.v)
            }
        case    .rgb16(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (c) in (c.v, c.v, c.v)
            }
        
        case    .bgra8(palette: _, fill: _), 
                .rgba8(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c) in (c.v, c.v, c.v, c.a)
            }
        case    .rgba16(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (c) in (c.v, c.v, c.v, c.a)
            }
        }
    }
}
extension PNG.Data.Rectangular  
{
    // factoring out the specialized entry point reduces module overhead, because 
    // the emitted entry point can make use of the specialized function bodies
    @usableFromInline
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    static 
    func unpack<T>(_ interleaved:[UInt8], of format:PNG.Format, as _:T.Type, 
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> UInt8) 
        -> [T] 
        where T:FixedWidthInteger & UnsignedInteger
    {
        let depth:Int = format.pixel.depth 
        switch format 
        {
        case    .indexed1(palette: let palette, fill: _), 
                .indexed2(palette: let palette, fill: _), 
                .indexed4(palette: let palette, fill: _), 
                .indexed8(palette: let palette, fill: _):
            return PNG.convolve(interleaved, dereference: deindexer(palette)) 
            {
                (c) in c
            }
            
        case    .v1(fill: _, key: _),
                .v2(fill: _, key: _),
                .v4(fill: _, key: _),
                .v8(fill: _, key: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth) 
            {
                (c:T, _) in c
            }
        case    .v16(fill: _, key: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth) 
            {
                (c:T, _) in c
            }

        case    .va8(fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T))       in c.0
            }
        case    .va16(fill: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T))       in c.0
            }
        
        case    .bgr8(palette: _, fill: _, key: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), _) in c.2
            }
    
        case    .rgb8(palette: _, fill: _, key: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), _) in c.0
            }
        case    .rgb16(palette: _, fill: _, key: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T), _) in c.0
            }
        
        case    .bgra8(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T, T)) in c.2
            }
        
        case    .rgba8(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T, T)) in c.0
            }
        case    .rgba16(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T, T)) in c.0
            }
        }
    }
    
    @usableFromInline
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    static 
    func pack<T>(_ pixels:[T], as format:PNG.Format, 
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (UInt8) -> Int) 
        -> [UInt8] 
        where T:FixedWidthInteger & UnsignedInteger
    {
        let depth:Int = format.pixel.depth 
        switch format 
        {
        case    .indexed1(palette: let palette, fill: _), 
                .indexed2(palette: let palette, fill: _), 
                .indexed4(palette: let palette, fill: _), 
                .indexed8(palette: let palette, fill: _):
            return PNG.deconvolve(pixels, reference: indexer(palette)) 
            {
                (v) in v
            }
                
        case    .v1(fill: _, key: _),
                .v2(fill: _, key: _),
                .v4(fill: _, key: _),
                .v8(fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth) 
            {
                (v) in v
            }
        case    .v16(fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth) 
            {
                (v) in v
            }

        case    .va8(fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (v) in (v, .max)
            }
        case    .va16(fill: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (v) in (v, .max)
            }
        
        case    .bgr8(palette: _, fill: _, key: _), 
                .rgb8(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (v) in (v, v, v)
            }
        case    .rgb16(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (v) in (v, v, v)
            }
        
        case    .bgra8(palette: _, fill: _), 
                .rgba8(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (v) in (v, v, v, .max)
            }
        case    .rgba16(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (v) in (v, v, v, .max)
            }
        }
    }
}

// custom-indexer APIs 
extension PNG.Data.Rectangular 
{
    @inlinable 
    public 
    func unpack<Color>(as _:Color.Type, 
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> Color.Aggregate) 
        -> [Color] 
        where Color:PNG.Color
    {
        Color.unpack(self.storage, of: self.layout.format, deindexer: deindexer)
    }
    @inlinable 
    public 
    func unpack<T>(as _:T.Type, 
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> UInt8) 
        -> [T] 
        where T:FixedWidthInteger & UnsignedInteger
    {
        Self.unpack(self.storage, of: self.layout.format, as: T.self, deindexer: deindexer)
    }
    
    @inlinable 
    public 
    init<Color>(packing pixels:[Color], 
        size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata = .init(), 
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Color.Aggregate) -> Int) 
        where Color:PNG.Color
    {
        precondition(pixels.count == size.x * size.y, 
            "pixel array `count` must be equal to `size.x * size.y`")
        self.init(size: size, layout: layout, metadata: metadata, 
            storage: Color.pack(pixels, as: layout.format, indexer: indexer))
    }
    @inlinable 
    public 
    init<T>(packing pixels:[T], 
        size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata = .init(), 
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (UInt8) -> Int) 
        where T:FixedWidthInteger & UnsignedInteger
    {
        precondition(pixels.count == size.x * size.y, 
            "pixel array `count` must be equal to `size.x * size.y`")
        self.init(size: size, layout: layout, metadata: metadata, 
            storage: Self.pack(pixels, as: layout.format, indexer: indexer))
    }
}

// default-indexer implementations 
extension PNG.Color where Aggregate == (UInt8, UInt8)
{
    @inlinable 
    public static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format) -> [Self]
    {
        self.unpack(interleaved, of: format) 
        {
            (palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) in 
            {
                (i:Int) in (palette[i].r, palette[i].a)
            }
        }
    }
    @inlinable 
    public static 
    func pack(_ pixels:[Self], as format:PNG.Format) -> [UInt8] 
    {
        // behavior: create hash table for palette lookup. if a color is not in 
        // the palette, return entry 0
        Self.pack(pixels, as: format)
        {
            (palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) in 
            // currently blocked by the issue discussed at 
            // https://github.com/apple/swift/pull/28833
            // as a workaround, we box the UInt8s into an RGBA<UInt8> struct 
            let lookup:[PNG.RGBA<UInt8>: Int] = .init(uniqueKeysWithValues: 
                zip(palette.map{ .init($0.r, $0.g, $0.b, $0.a) }, palette.indices))
            return 
                { 
                    (c:(v:UInt8, a:UInt8)) in 
                    lookup[.init(c.v, c.v, c.v, c.a), default: 0] 
                }
        }
    }
}
extension PNG.Color where Aggregate == (UInt8, UInt8, UInt8, UInt8)
{
    @inlinable 
    public static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format) -> [Self]
    {
        self.unpack(interleaved, of: format) 
        {
            (palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) in 
            {
                (i:Int) in palette[i]
            }
        }
    }
    @inlinable 
    public static 
    func pack(_ pixels:[Self], as format:PNG.Format) -> [UInt8] 
    {
        // behavior: create hash table for palette lookup. if a color is not in 
        // the palette, return entry 0
        Self.pack(pixels, as: format)
        {
            (palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) in 
            // currently blocked by the issue discussed at 
            // https://github.com/apple/swift/pull/28833
            // as a workaround, we box the UInt8s into an RGBA<UInt8> struct 
            let lookup:[PNG.RGBA<UInt8>: Int] = .init(uniqueKeysWithValues: 
                zip(palette.map{ .init($0.r, $0.g, $0.b, $0.a) }, palette.indices))
            return 
                { 
                    (c:(r:UInt8, g:UInt8, b:UInt8, a:UInt8)) in 
                    lookup[.init(c.r, c.g, c.b, c.a), default: 0] 
                }
        }
    }
}
extension PNG.Data.Rectangular 
{
    @inlinable 
    public 
    func unpack<Color>(as _:Color.Type) -> [Color] where Color:PNG.Color
    {
        Color.unpack(self.storage, of: self.layout.format)
    }
    @inlinable 
    public 
    init<Color>(packing pixels:[Color], 
        size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata = .init()) 
        where Color:PNG.Color
    {
        precondition(pixels.count == size.x * size.y, 
            "pixel array `count` must be equal to `size.x * size.y`")
        self.init(size: size, layout: layout, metadata: metadata, 
            storage: Color.pack(pixels, as: layout.format))
    }
    
    @inlinable 
    public 
    func unpack<T>(as _:T.Type) -> [T] where T:FixedWidthInteger & UnsignedInteger
    {
        self.unpack(as: T.self) 
        {
            (palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) in 
            {
                (i:Int) in palette[i].r
            }
        }
    }
    @inlinable 
    public 
    init<T>(packing pixels:[T], 
        size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata = .init()) 
        where T:FixedWidthInteger & UnsignedInteger
    {
        self.init(packing: pixels, size: size, layout: layout, metadata: metadata)
        {
            (palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) in 
            // currently blocked by the issue discussed at 
            // https://github.com/apple/swift/pull/28833
            // as a workaround, we box the UInt8s into an RGBA<UInt8> struct 
            let lookup:[PNG.RGBA<UInt8>: Int] = .init(uniqueKeysWithValues: 
                zip(palette.map{ .init($0.r, $0.g, $0.b, $0.a) }, palette.indices))
            return 
                { 
                    (v:UInt8) in 
                    lookup[.init(v, v, v, .max), default: 0] 
                }
        }
    } 
}
