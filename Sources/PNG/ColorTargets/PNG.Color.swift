extension PNG
{
    /// A color target.
    ///
    /// The library provides two built-in color targets, ``PNG.VA`` and ``PNG.RGBA``. A worked
    /// example of how to implement a custom color target can be found in the <doc:CustomColor>
    /// tutorial.
    public
    typealias Color = _PNGColor
}

/// The name of this protocol is ``PNG.Color``.
public
protocol _PNGColor<Aggregate>
{
    /// A palette aggregate type.
    ///
    /// This type is the return type of a dereferencing function produced by a
    /// deindexer, and the parameter type of a referencing function produced
    /// by an indexer.
    associatedtype Aggregate

    /// Unpacks an image data storage buffer to an array of this color target,
    /// using a custom deindexing function.
    ///
    /// -   Parameters:
    ///     -   interleaved:
    ///         An image data buffer. It is expected to be obtained from the
    ///         ``Image/storage`` property of a ``Image`` image.
    ///     -   format:
    ///         The color format associated with the given data buffer.
    ///         It is expected to be obtained from the the ``PNG/Layout/format`` property of a
    ///         ``PNG/Image`` image.
    ///     -   deindexer:
    ///         A function which uses the palette entries in the color `format` to
    ///         generate a dereferencing function. This function should only be invoked
    ///         if the color `format` is an indexed format.
    ///
    /// See the [indexed color tutorial](Indexing) for more about the semantics of this
    /// function.
    ///
    /// -   Returns:
    ///     A pixel array containing instances of this color target. The pixels
    ///     should appear in the same order as they do in the image data buffer.
    static
    func unpack(_ interleaved:[UInt8],
        of format:PNG.Format,
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> Aggregate) -> [Self]

    /// Packs an array of this color target to an image data storage buffer,
    /// using a custom indexing function.
    ///
    /// -   Parameters:
    ///     -   pixels:
    ///         A pixel array containing instances of this color target.
    ///     -   format:
    ///         The color format to pack the given pixels as in the returned data buffer.
    ///
    ///         When the library uses an implementation of this function to construct
    ///         a ``PNG/Image`` image, this color format will be stored in
    ///         its ``PNG/Layout/format`` property.
    ///     -   indexer:
    ///         A function which uses the palette entries in the color `format` to
    ///         generate a referencing function. This function should only be invoked
    ///         if the color `format` is an indexed format.
    ///
    /// See the [indexed color tutorial](Indexing)
    /// for more about the semantics of this function.
    ///
    /// -   Returns:
    ///     An image data buffer. The packed samples in this buffer should appear
    ///     in the same order as the pixels in the `pixels` array. (But not
    ///     necessarily in the same order within each individual pixel.)
    ///
    /// When the library uses an implementation of this function to construct
    /// a ``PNG/Image`` image, this data buffer will be stored in
    /// its ``PNG/Image/storage`` property.
    static
    func pack(_ pixels:[Self],
        as format:PNG.Format,
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Aggregate) -> Int) -> [UInt8]

    /// Unpacks an image data storage buffer to an array of this color target.
    ///
    /// If ``Aggregate`` is `(UInt8, UInt8)`, the default implementation of this
    /// function will use the red and alpha components of the *i*th palette
    /// entry, in that order, as the palette aggregate, given an index *i*,
    /// when unpacking from an indexed color format.
    ///
    /// If ``Aggregate`` is `(UInt8, UInt8, UInt8, UInt8)`, the default
    /// implementation of this function will use the red, green, blue, and
    /// alpha components of the *i*th palette entry, in that order, as the
    /// palette aggregate, given an index *i*.
    ///
    /// See the [indexed color tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#using-indexed-images)
    /// for more about the semantics of the default implementations.
    ///
    /// -   Parameters:
    ///     -   interleaved:
    ///         An image data buffer. It is expected to be obtained from the
    ///        ``PNG/Image/storage`` property of a ``PNG/Image``
    ///         image.
    ///     -   format:
    ///         The color format associated with the given data buffer. It is
    ///         expected to be obtained from the the ``PNG/Layout/format`` property of a
    ///         ``PNG/Image`` image.
    /// -   Returns:
    ///     A pixel array containing instances of this color target. The pixels
    ///     should appear in the same order as they do in the image data buffer.
    static
    func unpack(_ interleaved:[UInt8], of format:PNG.Format) -> [Self]

    /// Packs an array of this color target to an image data storage buffer.
    ///
    /// If ``Aggregate`` is `(UInt8, UInt8)`, the default implementation of this
    /// function will search for a matching palette entry by treating the
    /// first member of the palette aggregate as the red, green, and blue
    /// components, and the second member as the alpha component,
    /// when packing to an indexed color format.
    ///
    /// If ``Aggregate`` is `(UInt8, UInt8, UInt8, UInt8)`, the default
    /// implementation of this function will search for a
    /// matching palette entry by treating the
    /// first member of the palette aggregate as the red component, the
    /// second member as the green component, the third member as the blue
    /// component, and the fourth member as the alpha component,
    /// when packing to an indexed color format.
    ///
    /// In either case, if more than one
    /// palette entry matches, the matching entry is chosen arbitrarily.
    /// If there is no matching palette entry, it chooses the first palette entry.
    ///
    /// See the [indexed color tutorial](https://github.com/tayloraswift/swift-png/tree/master/examples#using-indexed-images)
    /// for more about the semantics of the default implementations.
    ///
    /// -   Parameters:
    ///     -   pixels:
    ///         A pixel array containing instances of this color target.
    ///     -   format:
    ///         The color format to pack the given pixels as in the returned data buffer.
    ///
    ///         When the library uses an implementation of this function to construct
    ///         a ``PNG/Image`` image, this color format will be stored in
    ///         its ``PNG/Layout/format`` property.
    ///
    /// -   Returns:
    ///     An image data buffer. The packed samples in this buffer should appear
    ///     in the same order as the pixels in the `pixels` array. (But not
    ///     necessarily in the same order within each individual pixel.)
    ///
    ///     When the library uses an implementation of this function to construct
    ///     a ``PNG/Image`` image, this data buffer will be stored in
    ///     its ``PNG/Image/storage`` property.
    static
    func pack(_ pixels:[Self], as format:PNG.Format) -> [UInt8]
}

// default-indexer implementations
extension PNG.Color<(UInt8, UInt8)>
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
extension PNG.Color<(UInt8, UInt8, UInt8, UInt8)>
{
    @inlinable public static
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
    @inlinable public static
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
