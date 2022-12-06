extension PNG.RGBA:Sendable where T:Sendable 
{
}
extension PNG
{
    /// struct PNG.RGBA<T> 
    /// :   Swift.Hashable
    /// :   PNG.Color
    /// @   frozen
    /// where T:Swift.FixedWidthInteger & Swift.UnsignedInteger
    ///     An RGBA color target. 
    /// 
    ///     This type is a built-in color target.
    /// # [See also](builtin-color-targets)
    /// ## (builtin-color-targets)
    /// ## (2:color-targets)
    @frozen
    public
    struct RGBA<T>:Hashable where T:FixedWidthInteger & UnsignedInteger
    {
        /// var PNG.RGBA.r  : T
        ///     The red component of this color.
        /// ## ()
        public
        var r:T
        /// var PNG.RGBA.g  : T
        ///     The green component of this color.
        /// ## ()
        public
        var g:T
        /// var PNG.RGBA.b  : T
        ///     The blue component of this color.
        /// ## ()
        public
        var b:T
        /// var PNG.RGBA.a  : T
        ///     The alpha component of this color.
        /// ## ()
        public
        var a:T
    }
}
extension PNG.RGBA 
{
    /// init PNG.RGBA.init(_:) 
    /// @   inlinable 
    ///     Creates an opaque, monochromatic RGBA color.
    /// 
    ///     The [`r`], [`g`], and [`b`] components will be set to `value`, 
    ///     and the [`a`] component will be set to [`T`max`]. 
    /// - value : T 
    ///     A gray value.
    /// ## ()
    @inlinable
    public
    init(_ value:T)
    {
        self.init(value, value, value, T.max)
    }
    /// init PNG.RGBA.init(_:_:) 
    /// @   inlinable 
    ///     Creates a monochromatic RGBA color.
    /// 
    ///     The [`r`], [`g`], and [`b`] components will be set to `value`, 
    ///     and the [`a`] component will be set to `alpha`. 
    /// - value : T 
    ///     A gray value.
    /// - alpha : T 
    ///     An alpha value.
    /// ## ()
    @inlinable
    public
    init(_ value:T, _ alpha:T)
    {
        self.init(value, value, value, alpha)
    }
    /// init PNG.RGBA.init(_:_:_:) 
    /// @   inlinable 
    ///     Creates an opaque RGBA color.
    /// 
    ///     The [`r`], [`g`], and [`b`] components will be set to `red`, `green`, 
    ///     and `blue`, respectively. The [`a`] component will be set to [`T`max`]. 
    /// - red : T 
    ///     A red value.
    /// - green : T 
    ///     A green value.
    /// - blue : T 
    ///     A blue value.
    /// ## ()
    @inlinable
    public
    init(_ red:T, _ green:T, _ blue:T)
    {
        self.init(red, green, blue, T.max)
    }
    /// init PNG.RGBA.init(_:_:_:_:) 
    /// @   inlinable 
    ///     Creates an RGBA color.
    /// 
    ///     The [`r`], [`g`], [`b`], and [`a`] components will be set to `red`, 
    ///     `green`, `blue`, and `alpha` respectively. 
    /// - red : T 
    ///     A red value.
    /// - green : T 
    ///     A green value.
    /// - blue : T 
    ///     A blue value.
    /// - alpha : T 
    ///     An alpha value.
    /// ## ()
    @inlinable
    public
    init(_ red:T, _ green:T, _ blue:T, _ alpha:T)
    {
        self.r = red
        self.g = green
        self.b = blue
        self.a = alpha
    }
    
    /// init PNG.RGBA.init(_:) 
    /// @   inlinable 
    ///     Creates an RGBA color from a grayscale-alpha color. 
    /// 
    ///     This function is equivalent to calling [`init(_:_:)`] with 
    ///     the [`(VA).v`] and [`(VA).a`] components of `va`.
    /// - va : VA<T> 
    ///     A grayscale-alpha color. 
    @inlinable
    public 
    init(_ va:PNG.VA<T>)
    {
        self.init(va.v, va.a)
    }
    /// var PNG.RGBA.va : VA<T> { get }
    /// @   inlinable 
    ///     The grayscale-alpha color obtained by discarding the green and blue 
    ///     components of this color.
    /// ## ()
    @inlinable
    public
    var va:PNG.VA<T>
    {
        .init(self.r, self.a)
    } 
    /// var PNG.RGBA.premultiplied : Self { get }
    /// @   inlinable 
    ///     The color obtained by premultiplying the red, green, and blue 
    ///     components of this color with its alpha channel.
    /// 
    ///     The premultiplied color is obtained by invoking [`premultiply(_:alpha:)`]
    ///     on [`r`], [`g`], and [`b`].
    @inlinable
    public
    var premultiplied:Self
    {
        .init(  PNG.premultiply(self.r, alpha: self.a),
                PNG.premultiply(self.g, alpha: self.a),
                PNG.premultiply(self.b, alpha: self.a),
                self.a)
    }
    /// func PNG.RGBA.premultiplied<U>(as:) 
    /// where U:Swift.FixedWidthInteger & Swift.UnsignedInteger
    /// @   inlinable 
    ///     The color obtained by premultiplying the red, green, and blue 
    ///     components of this color with its alpha channel, performing the 
    ///     premultiplication in the given integer type.
    /// 
    ///     Premultiplication in a different integer type is sometimes necessary 
    ///     to reproduce the output of other image processing frameworks.
    /// 
    ///     The premultiplied color is obtained by invoking [`premultiply(_:alpha:)`]
    ///     on [`r`], [`g`], and [`b`], after scaling them to the range of `U`. 
    ///     The returned components are then scaled back to the range of [`T`]. 
    ///     The rescaling operation also affects the [`a`] component.
    /// - _ : U.Type 
    ///     The integer type to perform the premultiplications in. `U.bitWidth`
    ///     must be less than [`T`bitWidth`].
    /// - -> : Self 
    ///     The premultiplied color.
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
        
        let r:T = T.init(PNG.premultiply(U.init(self.r >> shift), alpha: a)) * q, 
            g:T = T.init(PNG.premultiply(U.init(self.g >> shift), alpha: a)) * q, 
            b:T = T.init(PNG.premultiply(U.init(self.b >> shift), alpha: a)) * q
        return .init(r, g, b, T.init(a) * q)
    }
    /// var PNG.RGBA.straightened : Self { get }
    /// @   inlinable 
    ///     The color obtained by straightening the red, green, and blue 
    ///     components of this color according to its alpha channel.
    /// 
    ///     The straightened color is obtained by invoking [`straighten(_:alpha:)`]
    ///     on [`r`], [`g`], and [`b`].
    @inlinable
    public
    var straightened:Self
    {
        .init(  PNG.straighten(self.r, alpha: self.a),
                PNG.straighten(self.g, alpha: self.a),
                PNG.straighten(self.b, alpha: self.a),
                self.a)
    }
    /// func PNG.RGBA.straightened<U>(as:) 
    /// where U:Swift.FixedWidthInteger & Swift.UnsignedInteger
    /// @   inlinable 
    ///     The color obtained by straightening the red, green, and blue 
    ///     components of this color according to its alpha channel, performing the 
    ///     straightening in the given integer type.
    /// 
    ///     Straightening in a different integer type is sometimes necessary 
    ///     to reproduce the output of other image processing frameworks.
    /// 
    ///     The straightened color is obtained by invoking [`straighten(_:alpha:)`]
    ///     on [`r`], [`g`], and [`b`], after scaling them to the range of `U`. 
    ///     The returned components are then scaled back to the range of [`T`].
    ///     The rescaling operation also affects the [`a`] component.
    /// - _ : U.Type 
    ///     The integer type to perform the straightening in. `U.bitWidth`
    ///     must be less than [`T`bitWidth`].
    /// - -> : Self 
    ///     The straightened color.
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
        
        let r:T = T.init(PNG.straighten(U.init(self.r >> shift), alpha: a)) * q, 
            g:T = T.init(PNG.straighten(U.init(self.g >> shift), alpha: a)) * q, 
            b:T = T.init(PNG.straighten(U.init(self.b >> shift), alpha: a)) * q
        return .init(r, g, b, T.init(a) * q)
    }
}
extension PNG.RGBA:PNG.Color 
{
    /// typealias PNG.RGBA.Aggregate = (Swift.UInt8, Swift.UInt8, Swift.UInt8, Swift.UInt8)
    /// ?:  Color
    ///     Palette aggregates are (*red*, *green*, *blue*, *alpha*) quadruplets.
    public 
    typealias Aggregate = (UInt8, UInt8, UInt8, UInt8)
    
    /// static func PNG.RGBA.unpack(_:of:deindexer:) 
    /// @   specialized where T == Swift.UInt8
    /// @   specialized where T == Swift.UInt16
    /// @   specialized where T == Swift.UInt32
    /// @   specialized where T == Swift.UInt64
    /// @   specialized where T == Swift.UInt
    /// ?:  Color 
    ///     Unpacks an image data storage buffer to an array of RGBA pixels. 
    /// 
    ///     For a grayscale color `format`, this function expands 
    ///     pixels of the form (*v*) to RGBA quadruplets (*v*, *v*, *v*, [`T`max`]).
    /// 
    ///     For a grayscale-alpha color `format`, this function expands 
    ///     pixels of the form (*v*, *a*) to RGBA quadruplets (*v*, *v*, *v*, *a*).
    /// 
    ///     For an RGB color `format`, this function expands 
    ///     pixels of the form (*r*, *g*, *b*) to RGBA quadruplets (*r*, *g*, *b*, [`T`max`]).
    /// 
    ///     For a BGR color `format`, this function expands 
    ///     pixels of the form (*b*, *g*, *r*) to RGBA quadruplets (*r*, *g*, *b*, [`T`max`]).
    /// 
    ///     For a BGRA color `format`, this function shuffles 
    ///     pixels of the form (*b*, *g*, *r*, *a*) into RGBA quadruplets (*r*, *g*, *b*, *a*).
    /// 
    ///     This function will apply chroma keys if present. The unpacked components 
    ///     are scaled to fill the range of [`T`], according to the color depth 
    ///     computed from the color `format`.
    /// - interleaved : [Swift.UInt8] 
    ///     An image data buffer. It is expected to be obtained from the 
    ///     [`(Data.Rectangular).storage`] property of a [`(Data).Rectangular`]
    ///     image.
    /// - format : Format 
    ///     The color format associated with the given data buffer.
    ///     It is expected to be obtained from the the 
    ///     [`(Data.Rectangular).layout``(Layout).format`] property of a 
    ///     [`(Data).Rectangular`] image.
    /// - deindexer : ([(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8, a:Swift.UInt8)]) -> (Swift.Int) -> Aggregate 
    ///     A function which uses the palette entries in the color `format` to 
    ///     generate a dereferencing function. This function is only invoked 
    ///     if the color `format` is an indexed format. Its palette aggregates 
    ///     will be interpreted as (*red*, *green*, *blue*, *alpha*) quadruplets.
    /// 
    ///     See the [indexed color tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#using-indexed-images) 
    ///     for more about the semantics of this function.
    /// - -> : [Self]
    ///     An array of RGBA pixels. The pixels 
    ///     appear in the same order as they do in the image data buffer.
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
    /// static func PNG.RGBA.pack(_:as:indexer:)
    /// @   specialized where T == Swift.UInt8
    /// @   specialized where T == Swift.UInt16
    /// @   specialized where T == Swift.UInt32
    /// @   specialized where T == Swift.UInt64
    /// @   specialized where T == Swift.UInt
    /// ?:  Color 
    ///     Packs an array of RGBA pixels to an image data storage buffer.
    /// 
    ///     For a grayscale color `format`, this function selects the [`r`] 
    ///     component of each RGBA pixel.
    /// 
    ///     For a grayscale-alpha color `format`, this function selects the [`r`] 
    ///     and [`a`] components of each RGBA pixel.
    ///
    ///     For an RGB or BGR color `format`, this function selects the [`r`], [`g`], and 
    ///     [`b`] components of each RGBA pixel.
    ///
    ///     The components in each RGBA pixel are assumed to fill the entire 
    ///     range of [`T`]. 
    /// - pixels : [Self] 
    ///     An array of RGBA pixels.
    /// - format : Format 
    ///     The color format to pack the given pixels as in the returned data buffer. 
    ///
    ///     When the library uses an implementation of this function to construct 
    ///     a [`(Data).Rectangular`] image, this color format will be stored in 
    ///     its [`(Data.Rectangular).layout``(Layout).format`] property.
    /// - indexer : ([(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8, a:Swift.UInt8)]) -> (Aggregate) -> Swift.Int 
    ///     A function which uses the palette entries in the color `format` to 
    ///     generate a referencing function. This function will only be invoked 
    ///     if the color `format` is an indexed format. Its palette aggregates 
    ///     will be interpreted as (*red*, *green*, *blue*, *alpha*) quadruplets.
    /// 
    ///     See the [indexed color tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#using-indexed-images) 
    ///     for more about the semantics of this function.
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. The packed samples in this buffer appear 
    ///     in the same order as the pixels in the `pixels` array. (But not 
    ///     necessarily in the same order within each individual pixel.)
    ///
    ///     When the library uses an implementation of this function to construct 
    ///     a [`(Data).Rectangular`] image, this data buffer will be stored in 
    ///     its [`(Data.Rectangular).storage`] property.
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
