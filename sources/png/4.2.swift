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
