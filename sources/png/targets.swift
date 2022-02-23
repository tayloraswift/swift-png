/// protocol PNG.Color 
///     A color target. 
/// 
///     The library provides two built-in color targets, [`VA`] and [`RGBA`]. 
///     A worked example of how to implement a custom 
///     color target can be found in the 
///     [custom color targets tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#custom-color-targets).
/// # [Unpacking functions](unpacking-functions)
/// # [Packing functions](packing-functions)
/// # [See also](builtin-color-targets, custom-color-targets)
/// ## (1:color-targets)
public 
protocol _PNGColor 
{
    /// associatedtype PNG.Color.Aggregate 
    /// required 
    ///     A palette aggregate type. 
    /// 
    ///     This type is the return type of a dereferencing function produced by a 
    ///     deindexer, and the parameter type of a referencing function produced 
    ///     by an indexer. 
    associatedtype Aggregate 
    
    /// static func PNG.Color.unpack(_:of:deindexer:) 
    /// required
    ///     Unpacks an image data storage buffer to an array of this color target, 
    ///     using a custom deindexing function.
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
    ///     generate a dereferencing function. This function should only be invoked 
    ///     if the color `format` is an indexed format.
    /// 
    ///     See the [indexed color tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#using-indexed-images) 
    ///     for more about the semantics of this function.
    /// - -> : [Self]
    ///     A pixel array containing instances of this color target. The pixels 
    ///     should appear in the same order as they do in the image data buffer.
    /// # [See also](unpacking-functions)
    /// ## (unpacking-functions)
    static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format, 
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> Aggregate) 
        -> [Self]
    /// static func PNG.Color.pack(_:as:indexer:)
    /// required 
    ///     Packs an array of this color target to an image data storage buffer, 
    ///     using a custom indexing function.
    /// - pixels : [Self] 
    ///     A pixel array containing instances of this color target.
    /// - format : Format 
    ///     The color format to pack the given pixels as in the returned data buffer. 
    ///
    ///     When the library uses an implementation of this function to construct 
    ///     a [`(Data).Rectangular`] image, this color format will be stored in 
    ///     its [`(Data.Rectangular).layout``(Layout).format`] property.
    /// - indexer : ([(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8, a:Swift.UInt8)]) -> (Aggregate) -> Swift.Int 
    ///     A function which uses the palette entries in the color `format` to 
    ///     generate a referencing function. This function should only be invoked 
    ///     if the color `format` is an indexed format.
    /// 
    ///     See the [indexed color tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#using-indexed-images) 
    ///     for more about the semantics of this function.
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. The packed samples in this buffer should appear 
    ///     in the same order as the pixels in the `pixels` array. (But not 
    ///     necessarily in the same order within each individual pixel.)
    ///
    ///     When the library uses an implementation of this function to construct 
    ///     a [`(Data).Rectangular`] image, this data buffer will be stored in 
    ///     its [`(Data.Rectangular).storage`] property.
    /// # [See also](packing-functions)
    /// ## (packing-functions)
    static 
    func pack(_ pixels:[Self], as format:PNG.Format, 
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Aggregate) -> Int) 
        -> [UInt8] 
    
    /// static func PNG.Color.unpack(_:of:) 
    /// defaulted where Aggregate == (Swift.UInt8, Swift.UInt8)
    /// defaulted where Aggregate == (Swift.UInt8, Swift.UInt8, Swift.UInt8, Swift.UInt8)
    ///     Unpacks an image data storage buffer to an array of this color target. 
    /// 
    ///     If [`Aggregate`] is 
    ///     [[`(Swift.UInt8, Swift.UInt8)`]], the default implementation of this 
    ///     function will use the red and alpha components of the *i*th palette 
    ///     entry, in that order, as the palette aggregate, given an index *i*, 
    ///     when unpacking from an indexed color format.
    /// 
    ///     If [`Aggregate`] is 
    ///     [[`(Swift.UInt8, Swift.UInt8, Swift.UInt8, Swift.UInt8)`]], 
    ///     the default implementation of this function will use the red, green, 
    ///     blue, and alpha components of the *i*th palette entry, in that order, 
    ///     as the palette aggregate, given an index *i*.
    ///  
    ///     See the [indexed color tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#using-indexed-images) 
    ///     for more about the semantics of the default implementations.
    /// - interleaved : [Swift.UInt8] 
    ///     An image data buffer. It is expected to be obtained from the 
    ///     [`(Data.Rectangular).storage`] property of a [`(Data).Rectangular`]
    ///     image.
    /// - format : Format 
    ///     The color format associated with the given data buffer.
    ///     It is expected to be obtained from the the 
    ///     [`(Data.Rectangular).layout``(Layout).format`] property of a 
    ///     [`(Data).Rectangular`] image.
    /// - -> : [Self]
    ///     A pixel array containing instances of this color target. The pixels 
    ///     should appear in the same order as they do in the image data buffer.
    /// # [See also](unpacking-functions)
    /// ## (unpacking-functions)
    static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format) -> [Self]
    /// static func PNG.Color.pack(_:as:)
    /// defaulted where Aggregate == (Swift.UInt8, Swift.UInt8)
    /// defaulted where Aggregate == (Swift.UInt8, Swift.UInt8, Swift.UInt8, Swift.UInt8)
    ///     Packs an array of this color target to an image data storage buffer.
    /// 
    ///     If [`Aggregate`] is 
    ///     [[`(Swift.UInt8, Swift.UInt8)`]], the default implementation of this 
    ///     function will search for a matching palette entry by treating the 
    ///     first member of the palette aggregate as the red, green, and blue 
    ///     components, and the second member as the alpha component, 
    ///     when packing to an indexed color format. 
    /// 
    ///     If [`Aggregate`] is 
    ///     [[`(Swift.UInt8, Swift.UInt8, Swift.UInt8, Swift.UInt8)`]], 
    ///     the default implementation of this function will search for a 
    ///     matching palette entry by treating the 
    ///     first member of the palette aggregate as the red component, the 
    ///     second member as the green component, the third member as the blue 
    ///     component, and the fourth member as the alpha component, 
    ///     when packing to an indexed color format. 
    /// 
    ///     In either case, if more than one 
    ///     palette entry matches, the matching entry is chosen arbitrarily. 
    ///     If there is no matching palette entry, it chooses the first palette entry.
    ///  
    ///     See the [indexed color tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#using-indexed-images) 
    ///     for more about the semantics of the default implementations.
    /// - pixels : [Self] 
    ///     A pixel array containing instances of this color target.
    /// - format : Format 
    ///     The color format to pack the given pixels as in the returned data buffer. 
    ///
    ///     When the library uses an implementation of this function to construct 
    ///     a [`(Data).Rectangular`] image, this color format will be stored in 
    ///     its [`(Data.Rectangular).layout``(Layout).format`] property.
    /// - -> : [Swift.UInt8]
    ///     An image data buffer. The packed samples in this buffer should appear 
    ///     in the same order as the pixels in the `pixels` array. (But not 
    ///     necessarily in the same order within each individual pixel.)
    ///
    ///     When the library uses an implementation of this function to construct 
    ///     a [`(Data).Rectangular`] image, this data buffer will be stored in 
    ///     its [`(Data.Rectangular).storage`] property.
    /// # [See also](packing-functions)
    /// ## (packing-functions)
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
    /// static func PNG.premultiply<T>(_:alpha:)
    /// where T:Swift.FixedWidthInteger & Swift.UnsignedInteger
    /// @   inlinable 
    ///     Premultiplies a color component with an alpha value. 
    /// 
    ///     The `color` and `alpha` parameters are interpreted as rational numbers 
    ///     in the range [0, 1], where `T.min` maps to 0, 
    ///     and `T.max` maps to 1. 
    /// 
    ///     This function uses no floating point operations, and satisfies the 
    ///     property that 
    /// 
    ///     [`premultiply(_:alpha:)`]
    /// 
    ///     is equivalent to  
    ///
    ///     [`premultiply(_:alpha:)`] ∘ [`straighten(_:alpha:)`] ∘ [`premultiply(_:alpha:)`]
    /// 
    ///     The computed properties [`RGBA.premultiplied`] and [`VA.premultiplied`] 
    ///     can be used to premultiply an entire instance of one of the built-in 
    ///     color targets.
    ///     
    ///     Premultiplication is a destructive operation. In the most extreme case, 
    ///     if `alpha` is `T.min`, this function will return `T.min` for any 
    ///     value of `color`.
    /// - color : T 
    ///     The color component to premultiply. 
    /// - alpha : T 
    ///     The alpha component to premultiply `color` with.
    /// - ->    : T 
    ///     The premultiplied color component, rounded to the nearest integer.
    /// # [See also](componentwise-premultiplication)
    /// ## (componentwise-premultiplication)
    /// ## (color-targets)
    @inlinable
    public static
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
    /// static func PNG.straighten<T>(_:alpha:)
    /// where T:Swift.FixedWidthInteger & Swift.UnsignedInteger
    /// @   inlinable 
    ///     Straightens a premultiplied color component given an alpha value. 
    /// 
    ///     The `color` and `alpha` parameters are interpreted as rational numbers 
    ///     in the range [0, 1], where `T.min` maps to 0, 
    ///     and `T.max` maps to 1. 
    /// 
    ///     This function uses no floating point operations, and satisfies the 
    ///     property that 
    /// 
    ///     [`premultiply(_:alpha:)`]
    /// 
    ///     is equivalent to  
    ///
    ///     [`premultiply(_:alpha:)`] ∘ [`straighten(_:alpha:)`] ∘ [`premultiply(_:alpha:)`]
    /// 
    ///     The computed properties [`RGBA.straightened`] and [`VA.straightened`] 
    ///     can be used to straighten an entire instance of one of the built-in 
    ///     color targets.
    /// 
    ///     Premultiplication is a destructive operation. This function cannot 
    ///     recover the original color unless `alpha` is `T.max`, in which case 
    ///     this function performs a division by 1, and returns the original 
    ///     `premultiplied` argument.
    /// - premultiplied : T 
    ///     The premultiplied color component to straighten. 
    /// - alpha : T 
    ///     The alpha component that `premultiplied` was premultiplied by.
    /// - ->    : T 
    ///     The straightened color component, rounded to the nearest integer. 
    ///     If `alpha` is `T.min`, this function returns the original 
    ///     `premultiplied` argument.
    /// # [See also](componentwise-premultiplication)
    /// ## (componentwise-premultiplication)
    /// ## (color-targets)
    @inlinable
    public static
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
extension PNG.RGBA:Sendable where T:Sendable 
{
}
extension PNG.VA:Sendable where T:Sendable 
{
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
    /// func PNG.Data.Rectangular.unpack<Color>(as:deindexer:)
    /// where Color:Color 
    /// @   inlinable
    ///     Unpacks this image to a pixel array, using a custom deindexing 
    ///     function.
    /// - _ : Color.Type 
    ///     A color target type. This type provides the [`(Color).unpack(_:of:deindexer:)`]
    ///     implementation used to unpack the image data. 
    /// - deindexer : ([(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8, a:Swift.UInt8)]) -> (Swift.Int) -> Color.Aggregate
    ///     A function which uses the palette entries in the color [`(Layout).format`] to 
    ///     generate a dereferencing function. This function is only expected to 
    ///     be invoked if [`layout``(Layout).format`] is an indexed format. 
    /// 
    ///     See the [indexed color tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#using-indexed-images) 
    ///     for more about the semantics of this function.
    /// - -> : [Color]
    ///     A pixel array. Its elements are arranged in row-major order. The 
    ///     first pixel in this array corresponds to the top-left corner of 
    ///     the image. Its length is equal to [`size`x`] multiplied by [`size`y`].
    /// # [See also](unpacking-pixels)
    /// ## (1:unpacking-pixels)
    @inlinable 
    public 
    func unpack<Color>(as _:Color.Type, 
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> Color.Aggregate) 
        -> [Color] 
        where Color:PNG.Color
    {
        Color.unpack(self.storage, of: self.layout.format, deindexer: deindexer)
    }
    /// func PNG.Data.Rectangular.unpack<T>(as:deindexer:)
    /// where T:Swift.FixedWidthInteger & Swift.UnsignedInteger
    /// @   inlinable
    ///     Unpacks this image to a scalar pixel array, using a custom deindexing 
    ///     function.
    /// 
    ///     For an image with a grayscale-alpha color [`(Layout).format`], 
    ///     this function selects the *v* component from pixels of the form (*v*, *a*)
    /// 
    ///     For an image with an RGB color [`(Layout).format`], 
    ///     this function selects the *r* component from pixels of the form (*r*, *g*, *b*).
    /// 
    ///     For an image with an RGBA color [`(Layout).format`], this function selects the *r* component from  
    ///     pixels of the form (*r*, *g*, *b*, *a*).
    /// 
    ///     For an image with a BGR color [`(Layout).format`], 
    ///     this function selects the *r* component from pixels of the form (*b*, *g*, *r*). 
    ///
    ///     For an image with a BGRA color [`(Layout).format`], 
    ///     this function selects the *r* component from pixels of the form (*b*, *g*, *r*, *a*).
    /// 
    ///     This function ignores chroma keys, as its scalar color target is not 
    ///     capable of representing transparency. The unpacked components 
    ///     are scaled to fill the range of `T`, according to the color depth 
    ///     computed from the color [`(Layout).format`].
    /// - _ : T.Type 
    ///     A scalar color target type. 
    /// - deindexer : ([(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8, a:Swift.UInt8)]) -> (Swift.Int) -> Swift.UInt8
    ///     A function which uses the palette entries in the color [`(Layout).format`] to 
    ///     generate a dereferencing function. This function will only 
    ///     be invoked if [`layout``(Layout).format`] is an indexed format. 
    /// 
    ///     See the [indexed color tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#using-indexed-images) 
    ///     for more about the semantics of this function.
    /// - -> : [T]
    ///     A scalar pixel array. Its elements are arranged in row-major order. The 
    ///     first pixel in this array corresponds to the top-left corner of 
    ///     the image. Its length is equal to [`size`x`] multiplied by [`size`y`].
    /// # [See also](unpacking-pixels)
    /// ## (3:unpacking-pixels)
    @inlinable 
    public 
    func unpack<T>(as _:T.Type, 
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> UInt8) 
        -> [T] 
        where T:FixedWidthInteger & UnsignedInteger
    {
        Self.unpack(self.storage, of: self.layout.format, as: T.self, deindexer: deindexer)
    }
    /// init PNG.Data.Rectangular.init<Color>(packing:size:layout:metadata:indexer:)
    /// where Color:Color
    /// @   inlinable
    ///     Creates an image from a pixel array, using a custom indexing function.
    /// - pixels : [Color] 
    ///     A pixel array. Its elements are arranged in row-major order. The 
    ///     first pixel in this array corresponds to the top-left corner of 
    ///     the image. The `Color` type provides the [`(Color).pack(_:as:indexer:)`] 
    ///     implementation used to pack the image data.
    /// 
    ///     The length of this array must match `size.x * size.y`. Passing an 
    ///     array of the wrong length will result in a precondition failure.
    /// - size : (x:Swift.Int, y:Swift.Int)
    ///     The size of the image. Both dimensions must be greater than zero. 
    ///     Passing an invalid image size will result in a precondition failure. 
    /// - layout : Layout 
    ///     An image layout.
    /// - metadata : Metadata 
    ///     A metadata structure. The default value is an empty metadata structure.
    /// - indexer : ([(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8, a:Swift.UInt8)]) -> (Color.Aggregate) -> Swift.Int 
    ///     A function which uses the palette entries in the color [`(Layout).format`] to 
    ///     generate a referencing function. This function is only expected to 
    ///     be invoked if the image color [`(Layout).format`] is an indexed format. 
    /// 
    ///     See the [indexed color tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#using-indexed-images) 
    ///     for more about the semantics of this function.
    /// # [See also](packing-pixels)
    /// ## (1:packing-pixels)
    @inlinable 
    public 
    init<Color>(packing pixels:[Color], 
        size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata = .init(), 
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Color.Aggregate) -> Int) 
        where Color:PNG.Color
    {
        precondition(size.x > 0 && size.y > 0, 
            "image dimensions must be greater than zero")
        precondition(pixels.count == size.x * size.y, 
            "pixel array `count` must be equal to `size.x * size.y`")
        self.init(size: size, layout: layout, metadata: metadata, 
            storage: Color.pack(pixels, as: layout.format, indexer: indexer))
    }
    /// init PNG.Data.Rectangular.init<T>(packing:size:layout:metadata:indexer:)
    /// where T:Swift.FixedWidthInteger & Swift.UnsignedInteger
    /// @   inlinable
    ///     Creates an image from a scalar pixel array, using a custom indexing 
    ///     function.
    /// 
    ///     For an image with a grayscale-alpha color [`(Layout).format`], 
    ///     this function assigns the gray channel to the given scalars, and 
    ///     sets the alpha channel to `T.max`.
    /// 
    ///     For an image with an RGB or BGR color [`(Layout).format`], 
    ///     this function assigns all channels to the given scalars, replicating 
    ///     each scalar three times.
    /// 
    ///     For an image with an RGBA or BGRA color [`(Layout).format`], this 
    ///     function assigns all opaque channels to the given scalars, replicating 
    ///     each scalar three times, and sets the alpha channel to `T.max`.
    /// 
    ///     The scalar values are assumed to fill the entire range of `T`. 
    /// - pixels : [T] 
    ///     A scalar pixel array. Its elements are arranged in row-major order. The 
    ///     first pixel in this array corresponds to the top-left corner of 
    ///     the image. 
    /// 
    ///     The length of this array must match `size.x * size.y`. Passing an 
    ///     array of the wrong length will result in a precondition failure.
    /// - size : (x:Swift.Int, y:Swift.Int)
    ///     The size of the image. Both dimensions must be greater than zero. 
    ///     Passing an invalid image size will result in a precondition failure. 
    /// - layout : Layout 
    ///     An image layout.
    /// - metadata : Metadata 
    ///     A metadata structure. The default value is an empty metadata structure.
    /// - indexer : ([(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8, a:Swift.UInt8)]) -> (Swift.UInt8) -> Swift.Int 
    ///     A function which uses the palette entries in the color [`(Layout).format`] to 
    ///     generate a referencing function. This function will only  
    ///     be invoked if the image color [`(Layout).format`] is an indexed format. 
    /// 
    ///     See the [indexed color tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#using-indexed-images) 
    ///     for more about the semantics of this function.
    /// # [See also](packing-pixels)
    /// ## (3:packing-pixels)
    @inlinable 
    public 
    init<T>(packing pixels:[T], 
        size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata = .init(), 
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (UInt8) -> Int) 
        where T:FixedWidthInteger & UnsignedInteger
    {
        precondition(size.x > 0 && size.y > 0, 
            "image dimensions must be greater than zero")
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
    /// func PNG.Data.Rectangular.unpack<Color>(as:)
    /// where Color:Color 
    /// @   inlinable
    ///     Unpacks this image to a pixel array.
    /// - _ : Color.Type 
    ///     A color target type. This type provides the [`(Color).unpack(_:of:)`]
    ///     implementation used to unpack the image data. 
    /// - -> : [Color]
    ///     A pixel array. Its elements are arranged in row-major order. The 
    ///     first pixel in this array corresponds to the top-left corner of 
    ///     the image. Its length is equal to [`size`x`] multiplied by [`size`y`].
    /// # [See also](unpacking-pixels)
    /// ## (0:unpacking-pixels)
    @inlinable 
    public 
    func unpack<Color>(as _:Color.Type) -> [Color] where Color:PNG.Color
    {
        Color.unpack(self.storage, of: self.layout.format)
    }
    /// init PNG.Data.Rectangular.init<Color>(packing:size:layout:metadata:)
    /// where Color:Color
    /// @   inlinable
    ///     Creates an image from a pixel array.
    /// - pixels : [Color] 
    ///     A pixel array. Its elements are arranged in row-major order. The 
    ///     first pixel in this array corresponds to the top-left corner of 
    ///     the image. The `Color` type provides the [`(Color).pack(_:as:)`] 
    ///     implementation used to pack the image data.
    /// 
    ///     The length of this array must match `size.x * size.y`. Passing an 
    ///     array of the wrong length will result in a precondition failure.
    /// - size : (x:Swift.Int, y:Swift.Int)
    ///     The size of the image. Both dimensions must be greater than zero. 
    ///     Passing an invalid image size will result in a precondition failure. 
    /// - layout : Layout 
    ///     An image layout.
    /// - metadata : Metadata 
    ///     A metadata structure. The default value is an empty metadata structure.
    /// # [See also](packing-pixels)
    /// ## (0:packing-pixels)
    @inlinable 
    public 
    init<Color>(packing pixels:[Color], 
        size:(x:Int, y:Int), layout:PNG.Layout, metadata:PNG.Metadata = .init()) 
        where Color:PNG.Color
    {
        precondition(size.x > 0 && size.y > 0, 
            "image dimensions must be greater than zero")
        precondition(pixels.count == size.x * size.y, 
            "pixel array `count` must be equal to `size.x * size.y`")
        self.init(size: size, layout: layout, metadata: metadata, 
            storage: Color.pack(pixels, as: layout.format))
    }
    /// func PNG.Data.Rectangular.unpack<T>(as:)
    /// where T:Swift.FixedWidthInteger & Swift.UnsignedInteger
    /// @   inlinable
    ///     Unpacks this image to a scalar pixel array.
    /// 
    ///     For an image with a grayscale-alpha color [`(Layout).format`], 
    ///     this function selects the *v* component from pixels of the form (*v*, *a*)
    /// 
    ///     For an image with an RGB color [`(Layout).format`], 
    ///     this function selects the *r* component from pixels of the form (*r*, *g*, *b*).
    /// 
    ///     For an image with an indexed color [`(Layout).format`], 
    ///     this function selects the *r* component from palette entries of the 
    ///     form (*r*, *g*, *b*, *a*). The palette entry is chosen by taking the 
    ///     *i*th element in the palette, from pixels of the form (*i*).
    /// 
    ///     For an image with an RGBA color [`(Layout).format`], this function 
    ///     selects the *r* component from pixels of the form (*r*, *g*, *b*, *a*).
    /// 
    ///     For an image with a BGR color [`(Layout).format`], 
    ///     this function selects the *r* component from pixels of the form (*b*, *g*, *r*). 
    ///
    ///     For an image with a BGRA color [`(Layout).format`], 
    ///     this function selects the *r* component from pixels of the form (*b*, *g*, *r*, *a*).
    /// 
    ///     This function ignores chroma keys, as its scalar color target is not 
    ///     capable of representing transparency. The unpacked components 
    ///     are scaled to fill the range of `T`, according to the color depth 
    ///     computed from the color [`(Layout).format`]. 
    /// - _ : T.Type 
    ///     A scalar color target type. 
    /// - -> : [T]
    ///     A scalar pixel array. Its elements are arranged in row-major order. The 
    ///     first pixel in this array corresponds to the top-left corner of 
    ///     the image. Its length is equal to [`size`x`] multiplied by [`size`y`].
    /// # [See also](unpacking-pixels)
    /// ## (2:unpacking-pixels)
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
    /// init PNG.Data.Rectangular.init<T>(packing:size:layout:metadata:)
    /// where T:Swift.FixedWidthInteger & Swift.UnsignedInteger
    /// @   inlinable
    ///     Creates an image from a scalar pixel array.
    /// 
    ///     For an image with a grayscale-alpha color [`(Layout).format`], 
    ///     this function assigns the gray channel to the given scalars, and 
    ///     sets the alpha channel to `T.max`.
    /// 
    ///     For an image with an indexed color [`(Layout).format`], 
    ///     this function expands the given scalars, each of the form (*v*), to 
    ///     RGBA quadruplets (*v*, *v*, *v*, `T.max`), and assigns the index 
    ///     channel to the index of a matching palette entry. If more than one 
    ///     palette entry matches, the matching entry is chosen arbitrarily. 
    ///     If no palette entries match, the first palette entry is chosen.
    /// 
    ///     For an image with an RGB or BGR color [`(Layout).format`], 
    ///     this function assigns all channels to the given scalars, replicating 
    ///     each scalar three times.
    /// 
    ///     For an image with an RGBA or BGRA color [`(Layout).format`], this 
    ///     function assigns all opaque channels to the given scalars, replicating 
    ///     each scalar three times, and sets the alpha channel to `T.max`.
    /// 
    ///     The scalar values are assumed to fill the entire range of `T`. 
    /// - pixels : [T] 
    ///     A scalar pixel array. Its elements are arranged in row-major order. The 
    ///     first pixel in this array corresponds to the top-left corner of 
    ///     the image. 
    /// 
    ///     The length of this array must match `size.x * size.y`. Passing an 
    ///     array of the wrong length will result in a precondition failure.
    /// - size : (x:Swift.Int, y:Swift.Int)
    ///     The size of the image. Both dimensions must be greater than zero. 
    ///     Passing an invalid image size will result in a precondition failure. 
    /// - layout : Layout 
    ///     An image layout.
    /// - metadata : Metadata 
    ///     A metadata structure. The default value is an empty metadata structure.
    /// # [See also](packing-pixels)
    /// ## (2:packing-pixels)
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
