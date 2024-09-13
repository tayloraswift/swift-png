extension LZ77
{
    @frozen public
    struct InflatorIn
    {
        private
        var capacity:Int, // units in atoms
            bytes:Int
        private
        var storage:ManagedBuffer<Void, UInt16>

        // Bitstreams are indexed from LSB to MSB within each atom
        //
        // atom 0   16 [ ← ← ← ← ← ← ← ← ]  0
        // atom 1   32 [ ← ← ← ← ← ← ← ← ] 16
        // atom 2   48 [ ← ← ← ← ← ← ← ← ] 32
        // atom 3   64 [ ← ← ← ← ← ← ← ← ] 48
        init(_ data:ArraySlice<UInt8>)
        {
            self.capacity   = 0
            self.bytes      = 0
            self.storage    = .create(minimumCapacity: 0){ _ in () }

            var b:Int  = 0
            self.rebase(data, pointer: &b)
        }
    }
}
extension LZ77.InflatorIn
{
    var count:Int
    {
        self.bytes << 3
    }

    // calculates number of atoms given byte count
    @inline(__always)
    private static
    func atoms(bytes:Int) -> Int
    {
        (bytes + 1) >> 1 + 3 // 3 padding shorts
    }


    /// Discards all bits before the pointer `b`
    mutating
    func rebase(_ data:ArraySlice<UInt8>, pointer b:inout Int)
    {
        if  data.isEmpty
        {
            return
        }

        let a:Int = b >> 4
        // calculate new buffer size
        let rollover:Int    = self.bytes - 2 * a
        let minimum:Int     = Self.atoms(bytes: rollover + data.count)

        #if WARN_COPY_ON_WRITE
        if !isKnownUniquelyReferenced(&self.storage)
        {
            print("warning: managed buffer in type '\(String.init(reflecting: Self.self))' has multiple references; buffer is being copied to preserve value semantics")
        }
        #endif

        if self.capacity < minimum || !isKnownUniquelyReferenced(&self.storage)
        {
            // reallocate storage
            var capacity:Int = minimum.nextPowerOfTwo
            let new:ManagedBuffer<Void, UInt16> = .create(minimumCapacity: capacity)
            {
                capacity    = $0.capacity
                return ()
            }
            // transfer leftover elements
            self.capacity   = capacity
            self.storage    = self.storage.withUnsafeMutablePointerToElements
            {
                (old:UnsafeMutablePointer<UInt16>) in
                new.withUnsafeMutablePointerToElements
                {
                    $0.update(from: old + a, count: (rollover + 1) >> 1)
                }
                return new
            }
        }
        else if a > 0
        {
            // shift to beginning
            self.storage.withUnsafeMutablePointerToElements
            {
                $0.update(from: $0 + a, count: (rollover + 1) >> 1)
            }
        }

        b         -= a << 4
        // write new data
        data.withUnsafeBufferPointer
        {
            (data:UnsafeBufferPointer<UInt8>) in
            self.storage.withUnsafeMutablePointerToElements
            {
                // already checked !data.isEmpty
                let count:Int
                var start:UnsafePointer<UInt8>  = data.baseAddress!
                let i:Int                       = (rollover + 1) >> 1
                if rollover & 1 != 0
                {
                    // odd number of bytes in the stream: move over 1 byte from the new data
                    $0[i - 1]  &= 0x00ff
                    $0[i - 1]  |= .init(start.pointee) << 8
                    start      += 1
                    count       = data.count - 1
                }
                else
                {
                    count       = data.count
                }

                // in debug mode, the majority of the time spent in the for loop is
                // spent in the iterator implemenation for Range<Int>. so in debug
                // mode we use a manual while loop. when first introduced, this change made
                // LZ77.InflatorIn.rebase(_:pointer:) about 4.5x faster. this change didn't
                // affect release mode performance at all, so we just use it for both debug
                // mode and release mode.
                let iters:Int = count >> 1
                var j:Int = 0
                while j < iters
                {
                    let upper:UInt8 = start[j << 1 | 1]
                    let lower:UInt8 = start[j << 1    ]
                    let value:UInt16
                    #if DEBUG
                        // in debug mode this hacky integer conversion makes
                        // LZ77.InflatorIn.rebase(_:pointer:) about 26x faster
                        let tuple:(UInt8, UInt8) = (lower, upper)
                        value = unsafeBitCast(tuple, to: UInt16.self)
                    #else
                        value = .init(upper) << 8 |
                                .init(lower)
                    #endif
                    $0[i &+ j] = value
                    j += 1
                }
                let k:Int = i + (count + 1) >> 1
                if count & 1 != 0
                {
                    $0[k &-         1]    = .init(start[count  - 1])
                }
                // write 48 bits of padding
                $0[k    ] = 0x0000
                $0[k + 1] = 0x0000
                $0[k + 2] = 0x0000
            }

            self.bytes = rollover + data.count
        }
    }

    /// Returns bits in the low end of the returned integer. The maximum meaningful bit `count`
    /// is 16.
    ///
    /// The best way to think about the bit order is to imagine the bitstream as a single,
    /// arbitrarily-precision integer. This means if you load a slice of the integer into a
    /// ``UInt16``, the most-significant bits in the result will correspond to the bits that
    /// appear later in the bitstream.
    ///
    /// ```text
    /// { b.15, b.14, b.13, b.12, b.11, b.10, b.9, b.8, b.7, b.6, b.5, b.4, b.3, b.2, b.1, b.0 }
    ///                                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ///                                                                  ^
    ///                                      [4, count: 6, as: UInt16.self]
    ///     produces
    /// { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, b.10, b.9, b.8, b.7, b.6, b.5, b.4}
    /// ```
    subscript<I>(i:Int, count count:Int, as _:I.Type) -> I
        where I:FixedWidthInteger
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            guard count > 0
            else
            {
                return .zero
            }

            let a:Int = i >> 4,
                b:Int = i & 0x0f

            //    a + 2           a + 1             a
            //      [ : : :x:x:x:x:x|x:x: : : : : : ]
            //             ~~~~~~~~~~~~~^
            //            count = 14, b = 12
            //
            //      →               [ :x:x:x:x:x|x:x]
            #if DEBUG
                // in debug mode this makes a huge different. without it, these integer
                // conversions took up to 10% of the time spent decoding the PNG. now it's
                // basically negligible. in release mode there's no issue with the regular
                // way so we just use that so that the compiler has more semantic information
                // to go off when optimizing the code.
                let extended:UInt32 = unsafeBitCast(($0[a], $0[a &+ 1]), to: UInt32.self)
            #else
                let extended:UInt32 = .init($0[a &+ 1]) << 16 | .init($0[a])
            #endif
            let mask:UInt32     = ~(UInt32.max &<< count)
            return .init(extended &>> b & mask)
        }
    }

    subscript(i:Int) -> UInt16
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            let a:Int = i >> 4,
                b:Int = i & 0x0f
            //    a + 2           a + 1             a
            //      [ : :x:x:x:x:x:x|x:x: : : : : : ]
            //           ~~~~~~~~~~~~~~~^
            //            count = 16, b = 12
            //
            //      →   [x:x:x:x:x:x|x:x]
            //  creating a uint32 and shifting that is faster than shifting
            //  the two components individually
            #if DEBUG
                // in debug mode this makes a huge different. without it, these integer
                // conversions took up to 10% of the time spent decoding the PNG. now it's
                // basically negligible. in release mode there's no issue with the regular
                // way so we just use that so that the compiler has more semantic information
                // to go off when optimizing the code.
                let extended:UInt32 = unsafeBitCast(($0[a], $0[a &+ 1]), to: UInt32.self)
            #else
                let extended:UInt32 = .init($0[a &+ 1]) << 16 | .init($0[a])
            #endif
            return .init(truncatingIfNeeded: extended &>> b)
        }
    }
}
extension LZ77.InflatorIn:ExpressibleByArrayLiteral
{
    public
    init(arrayLiteral:UInt8...)
    {
        self.init(arrayLiteral[...])
    }
}
