extension PNG.SuggestedPalette
{
    /// A variant array of palette colors and frequencies.
    @frozen public
    enum Entries
    {
        /// A suggested palette with an 8-bit color depth.
        /// -   Parameter _:
        ///     An array of 8-bit palette colors and frequencies.
        case rgba8( [(color:(r:UInt8,  g:UInt8,  b:UInt8,  a:UInt8),  frequency:UInt16)])
        /// A suggested palette with a 16-bit color depth.
        /// -   Parameter _:
        ///     An array of 16-bit palette colors and frequencies.
        case rgba16([(color:(r:UInt16, g:UInt16, b:UInt16, a:UInt16), frequency:UInt16)])
    }
}
