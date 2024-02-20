extension PNG
{
    /// Premultiplies a color component with an alpha value.
    ///
    /// - Parameters:
    ///     -   color:
    ///         The color component to premultiply.
    ///     -   alpha:
    ///         The alpha component to premultiply `color` with.
    ///
    /// -   Returns:
    ///     The premultiplied color component, rounded to the nearest integer.
    ///
    /// The `color` and `alpha` parameters are interpreted as rational numbers in the range
    /// [0, 1], where `T.min` maps to 0, and `T.max` maps to 1.
    ///
    /// This function uses no floating point operations, and satisfies the property that
    /// ``premultiply(_:alpha:)`` is equivalent to
    ///
    /// ``premultiply(_:alpha:)`` ∘ ``straighten(_:alpha:)`` ∘ ``premultiply(_:alpha:)``
    ///
    /// The computed properties ``RGBA.premultiplied`` and ``VA.premultiplied`` can be used to
    /// premultiply an entire instance of one of the built-in color targets.
    ///
    /// Premultiplication is a destructive operation. In the most extreme case, if `alpha` is
    /// `T.min`, this function will return `T.min` for any value of `color`.
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
    /// Straightens a premultiplied color component given an alpha value.
    ///
    /// -   Parameters:
    ///     -   premultiplied:
    ///         The premultiplied color component to straighten.
    ///     -   alpha:
    ///         The alpha component that `premultiplied` was premultiplied by.
    ///
    /// -   Returns:
    ///     The straightened color component, rounded to the nearest integer.
    ///     If `alpha` is `T.min`, this function returns the original
    ///     `premultiplied` argument.
    ///
    /// The `color` and `alpha` parameters are interpreted as rational numbers
    /// in the range [0, 1], where `T.min` maps to 0,
    /// and `T.max` maps to 1.
    ///
    /// This function uses no floating point operations, and satisfies the
    /// property that ``premultiply(_:alpha:)``
    ///
    /// is equivalent to
    ///
    /// ``premultiply(_:alpha:)`` ∘ ``straighten(_:alpha:)`` ∘ ``premultiply(_:alpha:)``
    ///
    /// The computed properties ``RGBA.straightened`` and ``VA.straightened``
    /// can be used to straighten an entire instance of one of the built-in
    /// color targets.
    ///
    /// Premultiplication is a destructive operation. This function cannot
    /// recover the original color unless `alpha` is `T.max`, in which case
    /// this function performs a division by 1, and returns the original
    /// `premultiplied` argument.
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
