extension FixedWidthInteger
{
    // rounds up to the next power of two, with 0 rounding up to 1.
    // numbers that are already powers of two return themselves
    @inline(__always)
    var nextPowerOfTwo:Self
    {
        1 &<< (Self.bitWidth &- (self &- 1).leadingZeroBitCount)
    }
}
