extension LZ77.Inflator
{
    @frozen @usableFromInline
    struct In
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
        init(_ data:[UInt8])
        {
            self.capacity   = 0
            self.bytes      = 0
            self.storage    = .create(minimumCapacity: 0){ _ in () }

            var b:Int  = 0
            self.rebase(data, pointer: &b)
        }
    }
}
extension LZ77.Inflator.In
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
    func rebase(_ data:[UInt8], pointer b:inout Int)
    {
        guard !data.isEmpty
        else
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

                for j:Int in 0 ..< count >> 1
                {
                    $0[i &+          j]   = .init(start[j << 1 | 1]) << 8 |
                                            .init(start[j << 1    ])
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

    /// Returns bits in the low end of the returned integer.
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
            let extended:UInt32 = .init($0[a &+ 1]) << 16 | .init($0[a]),
                mask:UInt32     = ~(UInt32.max &<< count)
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
            let extended:UInt32 = .init($0[a &+ 1]) << 16 | .init($0[a])
            return .init(truncatingIfNeeded: extended &>> b)
        }
    }
}
extension LZ77.Inflator.In:ExpressibleByArrayLiteral
{
    @usableFromInline
    init(arrayLiteral:UInt8...)
    {
        self.init(arrayLiteral)
    }
}
