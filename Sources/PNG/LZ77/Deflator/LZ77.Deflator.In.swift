extension LZ77.Deflator
{
    struct In
    {
        private
        var startIndex:Int,
            endIndex:Int

        private
        var capacity:Int

        private
        var storage:ManagedBuffer<Void, UInt8>

        private
        var integral:(single:UInt32, double:UInt32)
    }
}
extension LZ77.Deflator.In
{
    init()
    {
        var capacity:Int    = 0
        self.storage = .create(minimumCapacity: 0)
        {
            capacity = $0.capacity
            return ()
        }
        // self.startIndex     = 0
        // self.endIndex       = 0
        self.startIndex     = 4
        self.endIndex       = 4
        self.capacity       = capacity

        self.integral       = (1, 0)
    }

    var count:Int
    {
        self.endIndex - self.startIndex
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
                (body:UnsafeMutablePointer<UInt8>) in

                let new:ManagedBuffer<Void, UInt8> =
                    .create(minimumCapacity: self.capacity)
                {
                    self.capacity = $0.capacity
                    return ()
                }
                new.withUnsafeMutablePointerToElements
                {
                    // cannot do shift here, since the checksum has to be updated
                    $0.update(from: body, count: self.endIndex)
                }
                return new
            }
        }
    }

    var first:UInt8
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            $0[self.startIndex]
        }
    }

    mutating
    func dequeue() -> UInt8
    {
        let value:UInt8  = self.first
        self.startIndex += 1
        return value
    }

    mutating
    func enqueue(contentsOf elements:[UInt8])
    {
        // always allocate 4 extra tail elements to allow for limited reads
        // from beyond the end of the buffer
        self.reserve(elements.count + 4)
        self.storage.withUnsafeMutablePointerToElements
        {
            ($0 + self.endIndex).update(from: elements, count: elements.count)
        }
        self.endIndex += elements.count
    }

    private mutating
    func reserve(_ count:Int)
    {
        if self.capacity < self.endIndex &+ count
        {
            self.shift(allocating: count)
        }
    }

    /* private mutating
    func shift(allocating extra:Int)
    {
        // optimal new capacity
        let capacity:Int  = (self.count + Swift.max(16, extra)).nextPowerOfTwo
        if self.capacity >= capacity
        {
            // rebase without reallocating
            self.storage.withUnsafeMutablePointerToElements
            {
                self.integral   = LZ77.MRC32.update(self.integral,
                            from: $0,                   count: self.startIndex)
                $0.assign(  from: $0 + self.startIndex, count: self.count)
                self.endIndex      -= self.startIndex
                self.startIndex     = 0
            }
        }
        else
        {
            self.storage = self.storage.withUnsafeMutablePointerToElements
            {
                (body:UnsafeMutablePointer<UInt8>) in

                let new:ManagedBuffer<Void, UInt8> = .create(minimumCapacity: capacity)
                {
                    self.capacity = $0.capacity
                    return ()
                }

                new.withUnsafeMutablePointerToElements
                {
                    self.integral   = LZ77.MRC32.update(self.integral,
                                from: body,                   count: self.startIndex)
                    $0.assign(  from: body + self.startIndex, count: self.count)
                }
                self.endIndex      -= self.startIndex
                self.startIndex     = 0
                return new
            }
        }
    } */

    private mutating
    func shift(allocating extra:Int)
    {
        // optimal new capacity. buffer 4 old elements at the beginning
        let capacity:Int  = (4 + self.count + Swift.max(16, extra)).nextPowerOfTwo
        if self.capacity >= capacity
        {
            // rebase without reallocating
            self.storage.withUnsafeMutablePointerToElements
            {
                self.integral   = LZ77.MRC32.update(self.integral,
                            from: $0 + 4,                   count: self.startIndex - 4)
                $0.update(  from: $0 - 4 + self.startIndex, count: self.count      + 4)
                self.endIndex   = 4 + self.count
                self.startIndex = 4
            }
        }
        else
        {
            self.storage = self.storage.withUnsafeMutablePointerToElements
            {
                (body:UnsafeMutablePointer<UInt8>) in

                let new:ManagedBuffer<Void, UInt8> = .create(minimumCapacity: capacity)
                {
                    self.capacity = $0.capacity
                    return ()
                }

                new.withUnsafeMutablePointerToElements
                {
                    self.integral   = LZ77.MRC32.update(self.integral,
                                from: body + 4,                   count: self.startIndex - 4)
                    $0.update(  from: body - 4 + self.startIndex, count: self.count      + 4)
                }
                self.endIndex   = 4 + self.count
                self.startIndex = 4
                return new
            }
        }
    }

    mutating
    func checksum() -> UInt32
    {
        // everything still in the storage buffer has not yet been integrated
        self.storage.withUnsafeMutablePointerToElements
        {
            let (single, double):(UInt32, UInt32) =
                //LZ77.MRC32.update(self.integral, from: $0, count: self.endIndex)
                LZ77.MRC32.update(self.integral, from: $0 + 4, count: self.endIndex - 4)
            return double << 16 | single
        }
    }

    // pointer to offset at -4
    func withUnsafePointer<R>(_ body:(UnsafePointer<UInt8>) throws -> R)
        rethrows -> R
    {
        try self.storage.withUnsafeMutablePointerToElements
        {
            try body($0 - 4 + self.startIndex)
        }
    }
    /* func withUnsafeBufferPointer<R>(_ body:(UnsafeBufferPointer<UInt8>) throws -> R)
        rethrows -> R
    {
        try self.storage.withUnsafeMutablePointerToElements
        {
            try body(.init(start: $0 + self.startIndex, count: self.count))
        }
    } */
}
