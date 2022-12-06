extension PNG.VA:Sendable where T:Sendable 
{
}
extension PNG
{
    /// struct PNG.VA<T> 
    /// :   Swift.Hashable
    /// :   PNG.Color
    /// @   frozen
    /// where T:Swift.FixedWidthInteger & Swift.UnsignedInteger
    ///     A grayscale-alpha color target. 
    /// 
    ///     This type is a built-in color target.
    /// # [See also](builtin-color-targets)
    /// ## (builtin-color-targets)
    /// ## (2:color-targets)
    @frozen
    public
    struct VA<T>:Hashable where T:FixedWidthInteger & UnsignedInteger
    {
        /// var PNG.VA.v  : T
        ///     The gray component of this color.
        /// ## ()
        public
        var v:T
        /// var PNG.VA.a  : T
        ///     The alpha component of this color.
        /// ## ()
        public
        var a:T
    }
}
extension PNG.VA 
{
    /// init PNG.VA.init(_:) 
    /// @   inlinable 
    ///     Creates an opaque grayscale-alpha color.
    /// 
    ///     The [`v`] component will be set to `value`, 
    ///     and the [`a`] component will be set to [`T`max`]. 
    /// - value : T 
    ///     A gray value.
    /// ## ()
    @inlinable
    public
    init(_ value:T)
    {
        self.init(value, T.max)
    }
    /// init PNG.VA.init(_:_:) 
    /// @   inlinable 
    ///     Creates a grayscale-alpha color.
    /// 
    ///     The [`v`] component will be set to `value`, 
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
        self.v = value
        self.a = alpha
    }
    /// var PNG.VA.premultiplied : Self { get }
    /// @   inlinable 
    ///     The color obtained by premultiplying the gray
    ///     component of this color with its alpha channel.
    /// 
    ///     The premultiplied color is obtained by invoking [`premultiply(_:alpha:)`]
    ///     on [`v`].
    @inlinable
    public
    var premultiplied:Self
    {
        .init(PNG.premultiply(self.v, alpha: self.a), self.a)
    }
    /// func PNG.VA.premultiplied<U>(as:) 
    /// where U:Swift.FixedWidthInteger & Swift.UnsignedInteger
    /// @   inlinable 
    ///     The color obtained by premultiplying the gray
    ///     component of this color with its alpha channel, performing the 
    ///     premultiplication in the given integer type.
    /// 
    ///     Premultiplication in a different integer type is sometimes necessary 
    ///     to reproduce the output of other image processing frameworks.
    /// 
    ///     The premultiplied color is obtained by invoking [`premultiply(_:alpha:)`]
    ///     on [`v`], after scaling it to the range of `U`. 
    ///     The returned component is then scaled back to the range of [`T`].
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
            "cannot premultiply in higher-precision than original color")
        let shift:Int   = T.bitWidth - U.bitWidth
        let q:T         = T.max / T.max >> shift
        let a:U         = .init(self.a >> shift) 
        
        let v:T = T.init(PNG.premultiply(U.init(self.v >> shift), alpha: a)) * q
        return .init(v, T.init(a) * q)
    }
    /// var PNG.VA.straightened : Self { get }
    /// @   inlinable 
    ///     The color obtained by straightening the gray
    ///     component of this color according to its alpha channel.
    /// 
    ///     The straightened color is obtained by invoking [`straighten(_:alpha:)`]
    ///     on [`v`].
    @inlinable
    public
    var straightened:Self
    {
        .init(PNG.straighten(self.v, alpha: self.a), self.a)
    }
    /// func PNG.VA.straightened<U>(as:) 
    /// where U:Swift.FixedWidthInteger & Swift.UnsignedInteger
    /// @   inlinable 
    ///     The color obtained by straightening the gray
    ///     component of this color according to its alpha channel, performing the 
    ///     straightening in the given integer type.
    /// 
    ///     Straightening in a different integer type is sometimes necessary 
    ///     to reproduce the output of other image processing frameworks.
    /// 
    ///     The straightened color is obtained by invoking [`straighten(_:alpha:)`]
    ///     on [`v`], after scaling it to the range of `U`. 
    ///     The returned component is then scaled back to the range of [`T`].
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
            "cannot premultiply in higher-precision than original color")
        let shift:Int   = T.bitWidth - U.bitWidth
        let q:T         = T.max / T.max >> shift
        let a:U         = .init(self.a >> shift) 
        
        let v:T = T.init(PNG.straighten(U.init(self.v >> shift), alpha: a)) * q
        return .init(v, T.init(a) * q)
    }
}
extension PNG.VA:PNG.Color 
{
    /// typealias PNG.VA.Aggregate = (Swift.UInt8, Swift.UInt8)
    /// ?:  Color
    ///     Palette aggregates are (*gray*, *alpha*) pairs.
    public 
    typealias Aggregate = (UInt8, UInt8)
    
    /// static func PNG.VA.unpack(_:of:deindexer:) 
    /// @   specialized where T == Swift.UInt8
    /// @   specialized where T == Swift.UInt16
    /// @   specialized where T == Swift.UInt32
    /// @   specialized where T == Swift.UInt64
    /// @   specialized where T == Swift.UInt
    /// ?:  Color 
    ///     Unpacks an image data storage buffer to an array of grayscale-alpha pixels. 
    /// 
    ///     For a grayscale color `format`, this function expands 
    ///     pixels of the form (*v*) to grayscale-alpha pairs (*v*, [`T`max`]).
    /// 
    ///     For an RGB color `format`, this function slices 
    ///     pixels of the form (*r*, *g*, *b*) into grayscale-alpha pairs (*r*, [`T`max`]).
    /// 
    ///     For an RGBA color `format`, this function slices 
    ///     pixels of the form (*r*, *g*, *b*, *a*) into grayscale-alpha pairs (*r*, *a*).
    /// 
    ///     For a BGR color `format`, this function slices 
    ///     pixels of the form (*b*, *g*, *r*) to grayscale-alpha pairs (*r*, [`T`max`]).
    /// 
    ///     For a BGRA color `format`, this function slices 
    ///     pixels of the form (*b*, *g*, *r*, *a*) into grayscale-alpha pairs (*r*, *a*).
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
    ///     will be interpreted as (*gray*, *alpha*) pairs.
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
    /// static func PNG.VA.pack(_:as:indexer:)
    /// @   specialized where T == Swift.UInt8
    /// @   specialized where T == Swift.UInt16
    /// @   specialized where T == Swift.UInt32
    /// @   specialized where T == Swift.UInt64
    /// @   specialized where T == Swift.UInt
    /// ?:  Color 
    ///     Packs an array of grayscale-alpha pixels to an image data storage buffer.
    /// 
    ///     For a grayscale color `format`, this function selects the [`v`] 
    ///     component of each grayscale-alpha pixel.
    ///
    ///     For an RGB or BGR color `format`, this function assigns all 
    ///     channels to the [`v`] component of each grayscale-alpha pixel.
    ///
    ///     For an RGBA or BGRA color `format`, this function assigns all opaque 
    ///     channels to the [`v`] component of each grayscale-alpha pixel, and 
    ///     the alpha channel to the [`a`] component.
    ///
    ///     The components in each grayscale-alpha pixel are assumed to fill the entire 
    ///     range of [`T`]. 
    /// - pixels : [Self] 
    ///     An array of grayscale-alpha pixels.
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
    ///     will be interpreted as (*gray*, *alpha*) quadruplets.
    /// 
    ///     See the [indexed color tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#using-indexed-images) 
    ///     for more about the semantics of this function.
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. The packed samples in this buffer appear 
    ///     in the same order as the pixels in the `pixels` array. 
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
