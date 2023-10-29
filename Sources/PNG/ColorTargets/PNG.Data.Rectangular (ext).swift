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
    ///     See the [indexed color tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#using-indexed-images)
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
    ///     See the [indexed color tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#using-indexed-images)
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
    ///     See the [indexed color tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#using-indexed-images)
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
    ///     See the [indexed color tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#using-indexed-images)
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
