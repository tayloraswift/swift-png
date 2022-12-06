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
