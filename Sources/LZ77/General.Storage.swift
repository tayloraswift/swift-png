extension General
{
    /// A property wrapper providing an immutable ``Int`` interface backed by a different
    /// integer type.
    @propertyWrapper
    struct Storage<I>:Equatable where I:FixedWidthInteger & BinaryInteger
    {
        private
        var storage:I
        //  init General.Storage.init(wrappedValue:)
        //      Creates an instance of this property wrapper, with the given value
        //      truncated to the width of the storage type [`I`].
        //  - wrappedValue : Swift.Int
        //      The value to wrap.
        init(wrappedValue:Int)
        {
            self.storage = .init(truncatingIfNeeded: wrappedValue)
        }
        //  var General.Storage.wrappedValue : Swift.Int { get }
        //      The value wrapped by this property wrapper, expanded to an [`Swift.Int`].
        var wrappedValue:Int
        {
            .init(self.storage)
        }
    }
}
extension General.Storage:Sendable where I:Sendable
{
}
