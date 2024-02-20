extension PNG
{
    /// struct PNG.Percentmille
    /// :   Swift.AdditiveArithmetic
    /// :   Swift.ExpressibleByIntegerLiteral
    ///     A rational percentmille value.
    /// ## (currency-types)
    public
    struct Percentmille:AdditiveArithmetic, ExpressibleByIntegerLiteral
    {
        /// var PNG.Percentmille.points : Swift.Int
        ///     The numerator of this percentmille value.
        ///
        ///     The numerical value of this percentmille instance is this integer
        ///     divided by `100000`.
        public
        var points:Int

        /// static let PNG.Percentmille.zero : Self
        /// ?:  Swift.AdditiveArithmetic
        ///     A percentmille value of zero.
        public static
        let zero:Self = 0

        /// init PNG.Percentmille.init<T>(_:)
        /// where T:Swift.BinaryInteger
        ///     Creates a percentmille value with the given numerator.
        ///
        ///     The numerical value of this percentmille value will be the given
        ///     numerator divided by `100000`.
        /// -   Parameter points:
        ///     The numerator.
        public
        init<T>(_ points:T) where T:BinaryInteger
        {
            self.points = .init(points)
        }

        /// init PNG.Percentmille.init(integerLiteral:)
        /// ?:  Swift.ExpressibleByIntegerLiteral
        ///     Creates a percentmille value using the given integer literal as
        ///     the numerator.
        ///
        ///     The provided integer literal is *not* the numerical value of the
        ///     created percentmille value. It will be interpreted as the numerator
        ///     of a rational value.
        /// -   Parameter integerLiteral:
        ///     The integer literal.
        public
        init(integerLiteral:Int)
        {
            self.init(integerLiteral)
        }

        /// static func PNG.Percentmille.(+)(_:_:)
        /// ?:  Swift.AdditiveArithmetic
        ///     Adds two percentmille values and produces their sum.
        /// -   Parameter lhs:
        ///     The first value to add.
        /// -   Parameter rhs:
        ///     The second value to add.
        /// -   Returns:
        ///     The sum of the two given percentmille values.
        public static
        func + (lhs:Self, rhs:Self) -> Self
        {
            .init(lhs.points + rhs.points)
        }
        /// static func PNG.Percentmille.(+=)(_:_:)
        /// ?:  Swift.AdditiveArithmetic
        ///     Adds two percentmille values and stores the result in the
        ///     left-hand-side variable.
        /// -   Parameter lhs:
        ///     The first value to add.
        /// -   Parameter rhs:
        ///     The second value to add.
        public static
        func += (lhs:inout Self, rhs:Self)
        {
            lhs.points += rhs.points
        }
        /// static func PNG.Percentmille.(-)(_:_:)
        /// ?:  Swift.AdditiveArithmetic
        ///     Subtracts one percentmille value from another and produces their
        ///     difference.
        /// -   Parameter lhs:
        ///     A percentmille value.
        /// -   Parameter rhs:
        ///     The value to subtract from `lhs`.
        /// -   Returns:
        ///     The difference of the two given percentmille values.
        public static
        func - (lhs:Self, rhs:Self) -> Self
        {
            .init(lhs.points - rhs.points)
        }
        /// static func PNG.Percentmille.(-=)(_:_:)
        /// ?:  Swift.AdditiveArithmetic
        ///     Subtracts one percentmille value from another and stores the
        ///     result in the left-hand-side variable.
        /// -   Parameter lhs:
        ///     A percentmille value.
        /// -   Parameter rhs:
        ///     The value to subtract from `lhs`.
        public static
        func -= (lhs:inout Self, rhs:Self)
        {
            lhs.points -= rhs.points
        }
    }
}
extension PNG.Percentmille:CustomStringConvertible
{
    public
    var description:String
    {
        "\(self.points) / 100000"
    }
}
