public 
protocol _PNGColor 
{
    static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format) -> [Self]
}
extension PNG 
{
    public 
    typealias Color = _PNGColor
    
    enum Functional 
    {
    }
}

extension PNG
{
    private static 
    func convolve<C, A, T, R>(_ samples:C, _ kernel:(T, A) -> R, _ transform:(A) -> T)
        -> [R]
        where C:RandomAccessCollection, C.Element == A, A:FixedWidthInteger
    {
        samples.map
        {
            let v:A = .init(bigEndian: $0)
            return kernel(transform(v), v)
        }
    }
    private static 
    func convolve<C, A, T, R>(_ samples:C, _ kernel:((T, T)) -> R, _ transform:(A) -> T)
        -> [R]
        where C:RandomAccessCollection, C.Index == Int, C.Element == A, A:FixedWidthInteger
    {
        stride(from: samples.startIndex, to: samples.endIndex, by: 2).map
        {
            let v:A = .init(bigEndian: samples[$0     ])
            let a:A = .init(bigEndian: samples[$0 &+ 1])
            return kernel((transform(v), transform(a)))
        }
    }
    private static 
    func convolve<C, A, T, R>(_ samples:C, _ kernel:((T, T, T), (A, A, A)) -> R, _ transform:(A) -> T)
        -> [R]
        where C:RandomAccessCollection, C.Index == Int, C.Element == A, A:FixedWidthInteger
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
    func convolve<C, A, T, R>(_ samples:C, _ kernel:((T, T, T, T)) -> R, _ transform:(A) -> T)
        -> [R]
        where C:RandomAccessCollection, C.Index == Int, C.Element == A, A:FixedWidthInteger
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
    func convolve<C, A, T, R>(_ samples:C, _ kernel:((T, T, T, T)) -> R, 
        _ dereference:(Int) -> (A, A, A, A), _ transform:(A) -> T)
        -> [R]
        where C:RandomAccessCollection, C.Element == UInt8, A:FixedWidthInteger
    {
        samples.map
        {
            let (r, g, b, a):(A, A, A, A) = dereference(.init($0))
            return kernel((transform(r), transform(g), transform(b), transform(a)))
        }
    }
    
    private static 
    func quantum<T>(source:Int, destination _:T.Type) -> T 
        where T:FixedWidthInteger & UnsignedInteger 
    {
        T.max / T.max >> (T.bitWidth - source)
    }
    
    static 
    func convolve<A, T, R>(_ buffer:[UInt8], kernel:((T, T, T, T)) -> R, 
        dereference:(Int) -> (A, A, A, A))
        -> [R]
        where A:FixedWidthInteger, T:FixedWidthInteger & UnsignedInteger
    {
        buffer.withUnsafeBufferPointer
        {
            if      T.bitWidth == A.bitWidth 
            {
                return Self.convolve($0, kernel, dereference, T.init(_:))
            }
            else if T.bitWidth >  A.bitWidth 
            {
                let quantum:T = Self.quantum(source: A.bitWidth, destination: T.self)
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
    static 
    func convolve<A, T, R>(_ buffer:[UInt8], of _:A.Type, depth:Int, kernel:(T, A) -> R)
        -> [R]
        where A:FixedWidthInteger, T:FixedWidthInteger & UnsignedInteger
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
                let quantum:T = Self.quantum(source: depth, destination: T.self)
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
    static 
    func convolve<A, T, R>(_ buffer:[UInt8], of _:A.Type, depth:Int, kernel:((T, T)) -> R)
        -> [R]
        where A:FixedWidthInteger, T:FixedWidthInteger & UnsignedInteger
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
                let quantum:T = Self.quantum(source: depth, destination: T.self)
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
    static 
    func convolve<A, T, R>(_ buffer:[UInt8], of _:A.Type, depth:Int, kernel:((T, T, T), (A, A, A)) -> R)
        -> [R]
        where A:FixedWidthInteger, T:FixedWidthInteger & UnsignedInteger
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
                let quantum:T = Self.quantum(source: depth, destination: T.self)
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
    static 
    func convolve<A, T, R>(_ buffer:[UInt8], of _:A.Type, depth:Int, kernel:((T, T, T, T)) -> R)
        -> [R]
        where A:FixedWidthInteger, T:FixedWidthInteger & UnsignedInteger
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
                let quantum:T = Self.quantum(source: depth, destination: T.self)
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

    /* /// Returns a copy of this color with the alpha component set to the given sample.
    /// - Parameters:
    ///     - a: An alpha sample.
    /// - Returns: This color with the alpha component set to the given sample.
    func withAlpha(_ a:Component) -> RGBA<Component>
    {
        return .init(self.r, self.g, self.b, a)
    }

    /// Returns a boolean value indicating whether the color components of this
    /// color are equal to the color components of the given color, ignoring
    /// the alpha components.
    /// - Parameters:
    ///     - other: Another color.
    /// - Returns: `true` if the red, green, and blue components of this color
    ///     and `other` are equal, `false` otherwise.
    func equals(opaque other:RGBA<Component>) -> Bool
    {
        return self.r == other.r && self.g == other.g && self.b == other.b
    } */
    
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
            "cannot premultiply in higher-precision than original color")
        let shift:Int   = T.bitWidth - U.bitWidth
        let q:T         = T.max / T.max >> shift
        let a:U         = .init(self.a >> shift) 
        
        let r:T = T.init(PNG.premultiply(color: U.init(self.r >> shift), alpha: a)) * q, 
            g:T = T.init(PNG.premultiply(color: U.init(self.g >> shift), alpha: a)) * q, 
            b:T = T.init(PNG.premultiply(color: U.init(self.b >> shift), alpha: a)) * q
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
}

extension PNG.RGBA:PNG.Color 
{
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    public static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format) 
        -> [Self] 
    {
        let depth:Int = format.pixel.depth 
        switch format 
        {
        case    .indexed1(palette: let palette, fill: _), 
                .indexed2(palette: let palette, fill: _), 
                .indexed4(palette: let palette, fill: _), 
                .indexed8(palette: let palette, fill: _):
            return PNG.convolve(interleaved) 
            {
                (c) in .init(c.0, c.1, c.2, c.3)
            }
            dereference:
            {
                (i) in palette[i]
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
}
extension PNG.VA:PNG.Color 
{
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    public static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format) 
        -> [Self] 
    {
        let depth:Int = format.pixel.depth 
        switch format 
        {
        case    .indexed1(palette: let palette, fill: _), 
                .indexed2(palette: let palette, fill: _), 
                .indexed4(palette: let palette, fill: _), 
                .indexed8(palette: let palette, fill: _):
            return PNG.convolve(interleaved) 
            {
                (c) in .init(c.0, c.3)
            }
            dereference:
            {
                (i) in palette[i]
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
}

extension PNG.Data.Rectangular 
{
    @inlinable @inline(never)
    public 
    func unpack<Color>(as _:Color.Type) -> [Color] where Color:PNG.Color
    {
        Color.unpack(self.storage, of: self.layout.format)
    }
    
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    public  
    func unpack<T>(as _:T.Type) -> [T] where T:FixedWidthInteger & UnsignedInteger
    {
        let depth:Int = self.layout.format.pixel.depth 
        switch self.layout.format 
        {
        case    .indexed1(palette: let palette, fill: _), 
                .indexed2(palette: let palette, fill: _), 
                .indexed4(palette: let palette, fill: _), 
                .indexed8(palette: let palette, fill: _):
            return PNG.convolve(self.storage) 
            {
                (c) in c.0
            }
            dereference:
            {
                (i) in palette[i]
            }
                
        case    .v1(fill: _, key: _),
                .v2(fill: _, key: _),
                .v4(fill: _, key: _),
                .v8(fill: _, key: _):
            return PNG.convolve(self.storage, of: UInt8.self, depth: depth) 
            {
                (c:T, _) in c
            }
        case    .v16(fill: _, key: _):
            return PNG.convolve(self.storage, of: UInt16.self, depth: depth) 
            {
                (c:T, _) in c
            }

        case    .va8(fill: _):
            return PNG.convolve(self.storage, of: UInt8.self, depth: depth)
            {
                (c:(T, T))       in c.0
            }
        case    .va16(fill: _):
            return PNG.convolve(self.storage, of: UInt16.self, depth: depth)
            {
                (c:(T, T))       in c.0
            }
        
        case    .bgr8(palette: _, fill: _, key: _):
            return PNG.convolve(self.storage, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), _) in c.2
            }
    
        case    .rgb8(palette: _, fill: _, key: _):
            return PNG.convolve(self.storage, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T), _) in c.0
            }
        case    .rgb16(palette: _, fill: _, key: _):
            return PNG.convolve(self.storage, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T), _) in c.0
            }
        
        case    .bgra8(palette: _, fill: _):
            return PNG.convolve(self.storage, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T, T)) in c.2
            }
        
        case    .rgba8(palette: _, fill: _):
            return PNG.convolve(self.storage, of: UInt8.self, depth: depth)
            {
                (c:(T, T, T, T)) in c.0
            }
        case    .rgba16(palette: _, fill: _):
            return PNG.convolve(self.storage, of: UInt16.self, depth: depth)
            {
                (c:(T, T, T, T)) in c.0
            }
        }
    }
}
