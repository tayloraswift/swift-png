extension Array {
    init(
        unsafeUninitializedCapacity: Int,
        initializingWith initializer: (
            _ buffer: inout UnsafeMutableBufferPointer<Element>,
            _ initializedCount: inout Int
        ) throws -> Void
    ) rethrows {
        self = []
        try self.withUnsafeMutableBufferPointerToStorage(capacity: unsafeUninitializedCapacity, initializer)
    }

    mutating func withUnsafeMutableBufferPointerToStorage<Result>(
        capacity: Int,
        _ body: (
            _ buffer: inout UnsafeMutableBufferPointer<Element>,
            _ initializedCount: inout Int
        ) throws -> Result
    ) rethrows -> Result {
        var buffer = UnsafeMutableBufferPointer<Element>.allocate(capacity: capacity)
        let _ = buffer.initialize(from: self)
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

// goodies from the future (5.0)
extension Sequence {
  /// Returns the number of elements in the sequence that satisfy the given
  /// predicate.
  ///
  /// You can use this method to count the number of elements that pass a test.
  /// For example, this code finds the number of names that are fewer than
  /// five characters long:
  ///
  ///     let names = ["Jacqueline", "Ian", "Amy", "Juan", "Soroush", "Tiffany"]
  ///     let shortNameCount = names.count(where: { $0.count < 5 })
  ///     // shortNameCount == 3
  ///
  /// To find the number of times a specific element appears in the sequence,
  /// use the equal-to operator (`==`) in the closure to test for a match.
  ///
  ///     let birds = ["duck", "duck", "duck", "duck", "goose"]
  ///     let duckCount = birds.count(where: { $0 == "duck" })
  ///     // duckCount == 4
  ///
  /// The sequence must be finite.
  ///
  /// - Parameter predicate: A closure that takes each element of the sequence
  ///   as its argument and returns a Boolean value indicating whether
  ///   the element should be included in the count.
  /// - Returns: The number of elements in the sequence that satisfy the given
  ///   predicate.
  @inlinable
  func count(
    where predicate: (Element) throws -> Bool
  ) rethrows -> Int {
    var count = 0
    for e in self {
      if try predicate(e) {
        count += 1
      }
    }
    return count
  }
}
