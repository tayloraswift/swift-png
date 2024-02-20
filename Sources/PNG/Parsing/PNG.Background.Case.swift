extension PNG.Background
{
    /// A background case. This is a separate type for validation purposes.
    @frozen public
    enum Case
    {
        /// A background descriptor for an indexed image.
        /// -   Parameter index:
        ///     The index of the palette entry to be used as a background color.
        ///
        ///     This index must be within the index range of the image palette.
        case palette(index:Int)
        /// A background descriptor for an RGB, BGR, RGBA, or BGRA image.
        /// -   Parameter _:
        ///     A background color.
        ///
        ///     Note that the background components are unscaled samples. If
        ///     the image color depth is less than `16`, only the least-significant
        ///     bits of each sample are inhabited.
        case rgb((r:UInt16, g:UInt16, b:UInt16))
        /// A background descriptor for a grayscale or grayscale-alpha image.
        /// -   Parameter _:
        ///     A background color.
        ///
        ///     Note that the background value is an unscaled sample. If
        ///     the image color depth is less than `16`, only the least-significant
        ///     bits are inhabited.
        case v(UInt16)
    }
}
