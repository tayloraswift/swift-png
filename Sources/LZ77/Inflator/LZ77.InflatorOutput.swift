extension LZ77
{
    @frozen @usableFromInline
    struct InflatorOutput<Integral> where Integral:LZ77.StreamIntegral
    {
        var window:Int

        private(set)
        var startIndex:Int,
            currentIndex:Int,
            endIndex:Int
        // storing this instead of using `ManagedBuffer.capacity` because
        // the apple docs said so
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
            self.window         = 0
            self.startIndex     = 0
            self.currentIndex   = 0
            self.endIndex       = 0
            self.capacity       = capacity
            self.integral       = .init()
        }
    }
}
extension LZ77.InflatorOutput
{
    mutating
    func exclude()
    {
        if !isKnownUniquelyReferenced(&self.storage)
        {
            #if WARN_COPY_ON_WRITE
            print("""
                warning: managed buffer in type '\(String.init(reflecting: Self.self))' has \
                multiple references; buffer is being copied to preserve value semantics
                """)
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

    mutating
    func release(bytes count:Int) -> [UInt8]?
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            guard self.endIndex >= self.currentIndex + count
            else
            {
                return nil
            }

            let slice:UnsafeBufferPointer<UInt8> =
                .init(start: $0 + self.currentIndex, count: count)
            defer
            {
                let limit:Int       = Swift.max(self.endIndex - self.window, self.startIndex)
                self.currentIndex  += count
                self.startIndex     = Swift.min(self.currentIndex, limit)
            }
            return .init(slice)
        }
    }

    // releases everything
    mutating
    func release() -> [UInt8]
    {
        self.storage.withUnsafeMutablePointerToElements
        {
            let count:Int = self.endIndex - self.currentIndex
            let slice:UnsafeBufferPointer<UInt8>
                = .init(start: $0 + self.currentIndex, count: count)
            defer
            {
                self.currentIndex   =           self.endIndex
                self.startIndex     = Swift.max(self.endIndex - self.window, self.startIndex)
            }
            return .init(slice)
        }
    }

    mutating
    func append(_ value:UInt8)
    {
        self.reserve(1)
        self.storage.withUnsafeMutablePointerToElements
        {
            $0[self.endIndex] = value
        }
        self.endIndex &+= 1
    }
    mutating
    func expand(offset:Int, count:Int)
    {
        self.reserve(count)
        self.storage.withUnsafeMutablePointerToElements
        {
            let start:UnsafeMutablePointer<UInt8>   = $0 + self.endIndex
            // cannot use update(from:count:) because the standard library implementation
            // copies from the back to the front if the ranges overlap
            // https://github.com/apple/swift/blob/master/stdlib/public/core/UnsafePointer.swift#L745
            for current:UnsafeMutablePointer<UInt8> in start ..< start + count
            {
                current.pointee = (current - offset).pointee
            }
        }
        self.endIndex &+= count
    }

    @inline(__always)
    private mutating
    func reserve(_ count:Int)
    {
        if self.capacity < self.endIndex &+ count
        {
            self.shift(allocating: count)
        }
    }
    // may discard array elements before `startIndex`, adjusts capacity so that
    // at least one more byte can always be written without a reallocation
    private mutating
    func shift(allocating extra:Int)
    {
        // optimal new capacity
        let count:Int       = self.endIndex - self.startIndex,
            capacity:Int    = (count + Swift.max(16, extra)).nextPowerOfTwo
        if self.capacity >= capacity
        {
            // rebase without reallocating
            self.storage.withUnsafeMutablePointerToElements
            {
                self.integral.update(from: $0, count: self.startIndex)

                $0.update(from: $0 + self.startIndex, count: count)

                self.currentIndex  -= self.startIndex
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
                    self.integral.update(from: body, count: self.startIndex)

                    $0.update(from: body + self.startIndex, count: count)
                }
                self.currentIndex  -= self.startIndex
                self.endIndex      -= self.startIndex
                self.startIndex     = 0
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
            self.integral.update(from: $0, count: self.endIndex)
            return self.integral.checksum
        }
    }
}
