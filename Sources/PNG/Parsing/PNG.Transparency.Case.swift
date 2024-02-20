extension PNG.Transparency
{
    /// A transparency case. This is a separate type for validation purposes.
    @frozen public
    enum Case
    {
        /// A transparency descriptor for an indexed image.
        /// -   Parameter alpha:
        ///     An array of alpha samples, where each sample augments an
        ///     RGB triple in an image ``Palette``. This array can contain no
        ///     more elements than entries in the image palette, but it can
        ///     contain fewer.
        ///
        ///     It is acceptable (though pointless) for the `alpha` array to be
        ///     empty.
        case palette(alpha:[UInt8])
        /// A transparency descriptor for an RGB or BGR image.
        /// -   Parameter key:
        ///     A chroma key used to display transparency. Pixels
        ///     matching this key will be displayed as transparent, if possible.
        ///
        ///     Note that the chroma key components are unscaled samples. If
        ///     the image color depth is less than `16`, only the least-significant
        ///     bits of each sample are inhabited.
        case rgb(key:(r:UInt16, g:UInt16, b:UInt16))
        /// A transparency descriptor for a grayscale image.
        /// -   Parameter key:
        ///     A chroma key used to display transparency. Pixels
        ///     matching this key will be displayed as transparent, if possible.
        ///
        ///     Note that the chroma key is an unscaled sample. If
        ///     the image color depth is less than `16`, only the least-significant
        ///     bits are inhabited.
        case v(key:UInt16)
    }
}
