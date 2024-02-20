extension PNG.SignificantBits
{
    /// A color precision case. This is a separate type for validation purposes.
    @frozen public
    enum Case
    {
        /// A color precision descriptor for a grayscale image.
        /// -   Parameter _:
        ///     The number of significant bits in each grayscale sample.
        ///
        ///     This value must be greater than zero, and can be no greater
        ///     than the color depth of the image color format.
        case v(Int)
        /// A color precision descriptor for a grayscale-alpha image.
        /// -   Parameter _:
        ///     The number of significant bits in each grayscale and alpha
        ///     sample, respectively.
        ///
        ///     Both precision values must be greater than zero, and neither
        ///     can be greater than the color depth of the image color format.
        case va((v:Int, a:Int))
        /// A color precision descriptor for an RGB, BGR, or indexed image.
        /// -   Parameter _:
        ///     The number of significant bits in each red, green, and blue
        ///     sample, respectively. If the image uses an indexed color format,
        ///     the precision values refer to the precision of the palette
        ///     entries, not the indices. The ``Chunk/sBIT`` chunk type is
        ///     not capable of specifying the precision of the alpha component
        ///     of the palette entries. If the image palette was augmented with
        ///     alpha samples from a ``Transparency`` descriptor, the precision
        ///     of those samples is left undefined.
        ///
        ///     The meaning of a color precision descriptor is
        ///     poorly-defined for BGR images. It is strongly recommended that
        ///     iphone-optimized images use ``PNG/SignificantBits`` only if all
        ///     samples have the same precision.
        ///
        ///     Each precision value must be greater than zero, and none of them
        ///     can be greater than the color depth of the image color format.
        case rgb((r:Int, g:Int, b:Int))
        /// A color precision descriptor for an RGBA or BGRA image.
        /// -   Parameter _:
        ///     The number of significant bits in each red, green, blue, and alpha
        ///     sample, respectively.
        ///
        ///     The meaning of a color precision descriptor is
        ///     poorly-defined for BGRA images. It is strongly recommended that
        ///     iphone-optimized images use ``PNG/SignificantBits`` only if all
        ///     samples have the same precision.
        ///
        ///     Each precision value must be greater than zero, and none of them
        ///     can be greater than the color depth of the image color format.
        case rgba((r:Int, g:Int, b:Int, a:Int))
    }
}
