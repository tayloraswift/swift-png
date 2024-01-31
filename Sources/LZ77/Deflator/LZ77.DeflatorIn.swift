extension LZ77
{
    @frozen @usableFromInline
    struct DeflatorIn<Integral> where Integral:LZ77.StreamIntegral
    {
        private
        var startIndex:Int,
            endIndex:Int

        private
        var capacity:Int
        private
        var integral:Integral
        private
        var storage:ManagedBuffer<Void, UInt8>

        init()
        {
            var capacity:Int = 0
            self.storage = .create(minimumCapacity: 0)
            {
                capacity = $0.capacity
            }
            // self.startIndex     = 0
            // self.endIndex       = 0
            self.startIndex = 4
            self.endIndex = 4
            self.capacity = capacity
            self.integral = .init()
        }
    }
}
extension LZ77.DeflatorIn
{
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
    func enqueue(contentsOf elements:ArraySlice<UInt8>)
    {
        elements.withUnsafeBufferPointer
        {
            guard
            let base:UnsafePointer<UInt8> = $0.baseAddress
            else
            {
                return
            }
            let count:Int = $0.count
            // always allocate 4 extra tail elements to allow for limited reads
            // from beyond the end of the buffer
            self.reserve(count + 4)
            self.storage.withUnsafeMutablePointerToElements
            {
                ($0 + self.endIndex).update(from: base, count: count)
            }
            self.endIndex += count
        }
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
                self.integral.update(from: $0 + 4, count: self.startIndex - 4)

                $0.update(from: $0 - 4 + self.startIndex, count: self.count + 4)

                self.endIndex = 4 + self.count
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
                    self.integral.update(from: body + 4, count: self.startIndex - 4)

                    $0.update(from: body - 4 + self.startIndex, count: self.count + 4)
                }
                self.endIndex = 4 + self.count
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
            self.integral.update(from: $0 + 4, count: self.endIndex - 4)
            return self.integral.checksum
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
