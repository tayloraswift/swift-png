extension LZ77
{
    /// Modular redundancy check (similar to ``CRC32``)
    @frozen @usableFromInline
    struct MRC32
    {
        @usableFromInline
        var single:UInt32
        @usableFromInline
        var double:UInt32

        @inlinable
        init()
        {
            self.single = 1
            self.double = 0
        }
    }
}
extension LZ77.MRC32:LZ77.StreamIntegral
{
    // software.intel.com/content/www/us/en/develop/articles/fast-computation-of-adler32-checksums
    // link also says to use simd vectorization, but that just seems to slow
    // things down (probably because llvm is already autovectorizing it)
    @inlinable mutating
    func update(from start:UnsafePointer<UInt8>, count:Int)
    {
        let (q, r):(Int, Int) = count.quotientAndRemainder(dividingBy: 5552)
        var i:Int = 0
        while i < q
        {
            var j:Int = 5552 * i
            while j < 5552 * (i + 1)
            {
                #if DEBUG
                    // these hacky integer conversions make MRC32.update(from:count:)
                    // about 9x faster in debug mode.
                    let singleTuple:(UInt8, UInt8, UInt8, UInt8) = (start[j], 0, 0, 0)
                    self.single &+= unsafeBitCast(singleTuple, to: UInt32.self)
                #else
                    self.single &+= .init(start[j])
                #endif
                self.double &+= self.single
                j += 1
            }
            self.single %= 65521
            self.double %= 65521
            i += 1
        }
        var j:Int = 5552 * q
        while j < 5552 * q + r
        {
            #if DEBUG
                let singleTuple:(UInt8, UInt8, UInt8, UInt8) = (start[j], 0, 0, 0)
                self.single &+= unsafeBitCast(singleTuple, to: UInt32.self)
            #else
                self.single &+= .init(start[j])
            #endif
            self.double &+= self.single
            j += 1
        }

        self.single %= 65521
        self.double %= 65521
    }

    @inlinable
    var checksum:UInt32 { self.double << 16 | self.single }
}
