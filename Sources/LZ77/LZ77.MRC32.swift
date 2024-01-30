extension LZ77
{
    /// Modular redundancy check (similar to ``CRC32``)
    enum MRC32
    {
    }
}
extension LZ77.MRC32
{
    // software.intel.com/content/www/us/en/develop/articles/fast-computation-of-adler32-checksums
    // link also says to use simd vectorization, but that just seems to slow
    // things down (probably because llvm is already autovectorizing it)
    static
    func update(_ checksum:(single:UInt32, double:UInt32),
        from start:UnsafePointer<UInt8>, count:Int)
        -> (single:UInt32, double:UInt32)
    {
        let (q, r):(Int, Int) = count.quotientAndRemainder(dividingBy: 5552)
        var (single, double):(UInt32, UInt32) = checksum
        for i:Int in 0 ..< q
        {
            for j:Int in 5552 * i ..< 5552 * (i + 1)
            {
                single &+= .init(start[j])
                double &+= single
            }
            single %= 65521
            double %= 65521
        }
        for j:Int in 5552 * q ..< 5552 * q + r
        {
            single &+= .init(start[j])
            double &+= single
        }
        return (single % 65521, double % 65521)
    }
}
