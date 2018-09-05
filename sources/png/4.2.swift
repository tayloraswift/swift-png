extension Array {
    public init(
        unsafeUninitializedCapacity: Int,
        initializingWith initializer: (
            _ buffer: inout UnsafeMutableBufferPointer<Element>,
            _ initializedCount: inout Int
        ) throws -> Void
    ) rethrows {
        self = []
        try self.withUnsafeMutableBufferPointerToStorage(capacity: unsafeUninitializedCapacity, initializer)
    }

    public mutating func withUnsafeMutableBufferPointerToStorage<Result>(
        capacity: Int,
        _ body: (
            _ buffer: inout UnsafeMutableBufferPointer<Element>,
            _ initializedCount: inout Int
        ) throws -> Result
    ) rethrows -> Result {
        var buffer = UnsafeMutableBufferPointer<Element>.allocate(capacity: capacity)
        buffer.initialize(from: self)
        var initializedCount = self.count
        defer {
            buffer.baseAddress?.deinitialize(count: initializedCount)
            buffer.deallocate()
        }
        
        let result = try body(&buffer, &initializedCount)
        self = Array(buffer[..<initializedCount])
        self.reserveCapacity(capacity)
        return result
    }
}

// ...you win this round, swift evolution
extension BinaryInteger 
{
    @inlinable
    func isMultiple(of other:Self) -> Bool 
    {
        // Nothing but zero is a multiple of zero.
        if other == 0 
        { 
            return self == 0 
        }
        
        // Special case to avoid overflow on .min / -1 for signed types.
        if Self.isSigned && other == -1 
        { 
            return true 
        }
        
        // Having handled those special cases, this is safe.
        return self % other == 0
    }
}
