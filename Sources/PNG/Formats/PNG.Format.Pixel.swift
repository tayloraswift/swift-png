extension PNG.Format
{
    /// A pixel format.
    ///
    /// A pixel format specifies the color model and bit depth used by an
    /// image. They do not specify the ordering of the color samples within
    /// the internal representation of a PNG image. For example, the color formats
    /// ``Format/rgba8(palette:fill:)`` and ``Format/bgra8(palette:fill:)``
    /// both correspond to the pixel format ``Pixel/rgba8``.
    ///
    /// The pixel format associated with a color format can be accessed
    /// through the ``Format/pixel`` instance property.
    @frozen public
    enum Pixel
    {
        /// Pixels are stored as 1-bit grayscale values.
        ///
        /// An image with this pixel format has a bit depth and a color
        /// depth of `1`. Each sample is in the range `0 ... 1`.
        case v1
        /// Pixels are stored as 2-bit grayscale values.
        ///
        /// An image with this pixel format has a bit depth and a color
        /// depth of `2`. Each sample is in the range `0 ... 3`.
        case v2
        /// Pixels are stored as 4-bit grayscale values.
        ///
        /// An image with this pixel format has a bit depth and a color
        /// depth of `4`. Each sample is in the range `0 ... 15`.
        case v4
        /// Pixels are stored as 8-bit grayscale values.
        ///
        /// An image with this pixel format has a bit depth and a color
        /// depth of `8`. Each sample is in the range `0 ... 255`.
        case v8
        /// Pixels are stored as 16-bit grayscale values.
        ///
        /// An image with this pixel format has a bit depth and a color
        /// depth of `16`. Each sample is in the range `0 ... 65535`.
        case v16

        /// Pixels are stored as 8-bit RGB triplets.
        ///
        /// An image with this pixel format has a bit depth and a color
        /// depth of `8`, for a total stride of `24` bits.
        /// Each sample is in the range `0 ... 255`.
        case rgb8
        /// Pixels are stored as 16-bit RGB triplets.
        ///
        /// An image with this pixel format has a bit depth and a color
        /// depth of `16`, for a total stride of `48` bits.
        /// Each sample is in the range `0 ... 65535`.
        case rgb16

        /// Pixels are stored as 1-bit indices.
        ///
        /// An image with this pixel format has a bit depth of `1`, and
        /// a color depth of `8`. Each index is in the range `0 ... 1`,
        /// and can reference an entry in a palette with at most `2` elements.
        case indexed1
        /// Pixels are stored as 2-bit indices.
        ///
        /// An image with this pixel format has a bit depth of `2`, and
        /// a color depth of `8`. Each index is in the range `0 ... 3`,
        /// and can reference an entry in a palette with at most `4` elements.
        case indexed2
        /// Pixels are stored as 4-bit indices.
        ///
        /// An image with this pixel format has a bit depth of `4`, and
        /// a color depth of `8`. Each index is in the range `0 ... 15`,
        /// and can reference an entry in a palette with at most `16` elements.
        case indexed4
        /// Pixels are stored as 8-bit indices.
        ///
        /// An image with this pixel format has a bit depth and color depth
        /// of `8`. Each index is in the range `0 ... 255`, and can reference
        /// an entry in a palette with at most `256` elements.
        case indexed8

        /// Pixels are stored as 8-bit grayscale-alpha pairs.
        ///
        /// An image with this pixel format has a bit depth and a color
        /// depth of `8`, for a total stride of `16` bits. Each sample
        /// is in the range `0 ... 255`.
        case va8
        /// Pixels are stored as 16-bit grayscale-alpha pairs.
        ///
        /// An image with this pixel format has a bit depth and a color
        /// depth of `16`, for a total stride of `32` bits. Each sample
        /// is in the range `0 ... 65535`.
        case va16

        /// Pixels are stored as 8-bit RGBA quadruplets.
        ///
        /// An image with this pixel format has a bit depth and a color
        /// depth of `8`, for a total stride of `32` bits.
        /// Each sample is in the range `0 ... 255`.
        case rgba8
        /// Pixels are stored as 16-bit RGBA quadruplets.
        ///
        /// An image with this pixel format has a bit depth and a color
        /// depth of `16`, for a total stride of `64` bits.
        /// Each sample is in the range `0 ... 65535`.
        case rgba16
    }
}
extension PNG.Format.Pixel
{
    /// Indicates whether an image with this pixel format contains more than one
    /// non-alpha color component.
    ///
    /// This property is `true` for all RGB, RGBA, and indexed pixel formats,
    /// and `false` otherwise.
    @inlinable
    public
    var hasColor:Bool
    {
        switch self
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
            return false
        case .rgb8, .rgb16, .indexed1, .indexed2, .indexed4, .indexed8, .rgba8, .rgba16:
            return true
        }
    }
    /// Indicates whether an image with this pixel format contains an alpha
    /// component.
    ///
    /// This property is `true` for all grayscale-alpha and RGBA pixel formats,
    /// and `false` otherwise. Note that indexed pixel formats are not
    /// considered transparent pixel formats, even though images using them
    /// can contain per-pixel alpha information.
    @inlinable
    public
    var hasAlpha:Bool
    {
        switch self
        {
        case .v1, .v2, .v4, .v8, .v16, .rgb8, .rgb16,
            .indexed1, .indexed2, .indexed4, .indexed8:
            return false
        case .va8, .va16, .rgba8, .rgba16:
            return true
        }
    }

    @inlinable
    var volume:Int
    {
        self.depth * self.channels
    }

    /// The number of channels encoded per-pixel in the internal representation
    /// of an image with this pixel format.
    ///
    /// This number is *not* the number of components in the encoded image;
    /// it indicates the dimensionality of the stored image data. Notably,
    /// indexed images are defined as having one channel, even though each
    /// scalar index represents a four-component color value.
    ///
    /// This property returns `1` for all grayscale and indexed pixel formats.
    ///
    /// This property returns `2` for all grayscale-alpha pixel formats.
    ///
    /// This property returns `3` for all RGB pixel formats.
    ///
    /// This property returns `4` for all RGBA pixel formats.
    @inlinable
    public
    var channels:Int
    {
        switch self
        {
        case .v1, .v2, .v4, .v8, .v16,
            .indexed1, .indexed2, .indexed4, .indexed8:     return 1
        case .va8,   .va16:                                 return 2
        case .rgb8,  .rgb16:                                return 3
        case .rgba8, .rgba16:                               return 4
        }
    }
    /// The bit depth of an image with this pixel format.
    ///
    /// This number is *not* the color depth the encoded image;
    /// it indicates the bit depth of the stored image data. Notably,
    /// indexed images always have a color depth of `8`, even though they may
    /// have a bit depth less than `8`.
    ///
    /// This property returns `1` for the ``v1`` and ``indexed1`` pixel formats.
    ///
    /// This property returns `2` for the ``v2`` and ``indexed2`` pixel formats.
    ///
    /// This property returns `4` for the ``v4`` and ``indexed4`` pixel formats.
    ///
    /// This property returns `8` for the ``v8``, ``va8``, ``indexed8``,
    /// ``rgb8``, and ``rgba8`` pixel formats.
    ///
    /// This property returns `16` for the ``v16``, ``va16``,
    /// ``rgb16``, and ``rgba16`` pixel formats.
    @inlinable
    public
    var depth:Int
    {
        switch self
        {
        case    .v1,          .indexed1:                    return  1
        case    .v2,          .indexed2:                    return  2
        case    .v4,          .indexed4:                    return  4
        case    .v8,  .rgb8,  .indexed8, .va8,  .rgba8:     return  8
        case    .v16, .rgb16,            .va16, .rgba16:    return 16
        }
    }

    var code:(depth:UInt8, type:UInt8)
    {
        switch self
        {
        case .v1:        return ( 1, 0)
        case .v2:        return ( 2, 0)
        case .v4:        return ( 4, 0)
        case .v8:        return ( 8, 0)
        case .v16:       return (16, 0)

        case .rgb8:      return ( 8, 2)
        case .rgb16:     return (16, 2)

        case .indexed1:  return ( 1, 3)
        case .indexed2:  return ( 2, 3)
        case .indexed4:  return ( 4, 3)
        case .indexed8:  return ( 8, 3)

        case .va8:       return ( 8, 4)
        case .va16:      return (16, 4)

        case .rgba8:     return ( 8, 6)
        case .rgba16:    return (16, 6)
        }
    }

    static
    func recognize(code:(depth:UInt8, type:UInt8)) -> Self?
    {
        switch code
        {
        case ( 1, 0):   return .v1
        case ( 2, 0):   return .v2
        case ( 4, 0):   return .v4
        case ( 8, 0):   return .v8
        case (16, 0):   return .v16

        case ( 8, 2):   return .rgb8
        case (16, 2):   return .rgb16

        case ( 1, 3):   return .indexed1
        case ( 2, 3):   return .indexed2
        case ( 4, 3):   return .indexed4
        case ( 8, 3):   return .indexed8

        case ( 8, 4):   return .va8
        case (16, 4):   return .va16

        case ( 8, 6):   return .rgba8
        case (16, 6):   return .rgba16

        default:        return nil
        }
    }
}
