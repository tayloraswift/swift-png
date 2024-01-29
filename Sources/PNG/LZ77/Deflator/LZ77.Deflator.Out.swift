extension LZ77.Deflator
{
    struct Out
    {
        private
        var capacity:Int, // units in atoms
            count:Int // units in bits
        private
        var storage:ManagedBuffer<Void, UInt16>
        private
        var queue:[[UInt8]],
            queued:Int
    }
}
extension LZ77.Deflator.Out
{
    var bytes:Int
    {
        self.count >> 3
    }

    private static
    func atoms(bytes:Int) -> Int
    {
        (bytes + 1) >> 1 + 3 // 3 padding shorts
    }

    init(hint:Int)
    {
        self.count          = 0

        var capacity:Int    = hint
        self.storage        = .create(minimumCapacity: hint)
        {
            capacity = $0.capacity
            return ()
        }
        self.capacity       = capacity
        self.queue          = []
        self.queued         = 0
    }

    mutating
    func exclude()
    {
        if !isKnownUniquelyReferenced(&self.storage)
        {
            #if WARN_COPY_ON_WRITE
            print("warning: managed buffer in type '\(String.init(reflecting: Self.self))' has multiple references; buffer is being copied to preserve value semantics")
            #endif

            self.storage = self.storage.withUnsafeMutablePointerToElements
            {
                (body:UnsafeMutablePointer<UInt16>) in

                .create(minimumCapacity: self.capacity)
                {
                    $0.withUnsafeMutablePointerToElements
                    {
                        $0.update(from: body, count: self.capacity)
                    }
                    self.capacity = $0.capacity
                    return ()
                }
            }
        }
    }

    mutating
    func pop() -> [UInt8]?
    {
        guard self.queued > 0
        else
        {
            return nil
        }

        let data:[UInt8] = self.queue[self.queue.endIndex - self.queued]
        self.queued -= 1
        // release all the buffered data chunks. this isn’t ideal (we should
        // be releasing them as soon as they are dequeued, but the semantics
        // of Array<T> don’t allow for this)
        if self.queued <= 0
        {
            self.queue.removeAll(keepingCapacity: true)
        }
        return data
    }

    // this flushes everything in the current buffer, including padding bits.
    // the returned array includes padding bits.
    mutating
    func pull() -> [UInt8]
    {
        let data:[UInt8]    = self.copy(bytes: (self.count + 7) >> 3)
        self.count          = 0
        return data
    }

    // content in low-bits
    mutating
    func append(_ bits:UInt16, count:Int)
    {
        let a:Int = self.count >> 4,
            b:Int = self.count & 15
        guard a + 1 < self.capacity
        else
        {
            let shifted:UInt32  = .init(bits) &<< b,
                mask:UInt16     = .max        &<< b
            self.storage.withUnsafeMutablePointerToElements
            {
                $0[a] = $0[a] & ~mask | .init(truncatingIfNeeded: shifted)
            }

            if b + count >= 16
            {
                self.queue.append(self.copy(bytes: 2 * self.capacity))
                self.queued += 1

                self.storage.withUnsafeMutablePointerToElements
                {
                    $0[0]   = .init(shifted >> 16)
                }
                self.count  = (b + count) & 15
            }
            else
            {
                self.count += count
            }
            return
        }

        let shifted:UInt32  = .init(bits) &<< b,
            mask:UInt16     = .max        &<< b
        self.storage.withUnsafeMutablePointerToElements
        {
            $0[a    ] = $0[a] & ~mask | .init(truncatingIfNeeded: shifted      )
            $0[a + 1] =                 .init(                    shifted >> 16)
        }
        self.count += count
    }

    mutating
    func pad(to _:UInt8.Type)
    {
        self.append(0, count: -self.count & 7)
    }

    private
    func copy(bytes:Int) -> [UInt8]
    {
        .init(unsafeUninitializedCapacity: bytes)
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            self.storage.withUnsafeMutablePointerToElements
            {
                for a:Int in 0 ..< bytes >> 1
                {
                    let atom:UInt16     = $0[a]
                    buffer[a << 1    ]  = .init(truncatingIfNeeded: atom     )
                    buffer[a << 1 | 1]  = .init(                    atom >> 8)
                }
                if bytes & 1 != 0
                {
                    let a:Int           = bytes >> 1
                    buffer[a << 1    ]  = .init(truncatingIfNeeded: $0[a]    )
                }
            }

            count = bytes
        }
    }
}
