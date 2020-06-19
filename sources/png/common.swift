/* This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. */

/// enum General 
///     A namespace for general functionality.
/// #  [Range types](general-range-types)
/// #  [Integer storage](general-storage-types)
/// #  [See also](top-level-namespaces)
/// ## (1:top-level-namespaces)
public 
enum General    
{
}

extension General  
{
    /// struct General.Storage<I> 
    /// where I:Swift.FixedWidthInteger & Swift.BinaryInteger 
    /// @propertyWrapper 
    ///     A property wrapper providing an immutable [`Swift.Int`] interface backed 
    ///     by a different integer type.
    /// #  [See also](general-storage-types)
    /// ## (general-storage-types)
    @propertyWrapper 
    public 
    struct Storage<I>:Equatable where I:FixedWidthInteger & BinaryInteger 
    {
        private 
        var storage:I 
        /// init General.Storage.init(wrappedValue:)
        ///     Creates an instance of this property wrapper, with the given value 
        ///     truncated to the width of the storage type [`I`].
        /// - wrappedValue : Swift.Int 
        ///     The value to wrap.
        public 
        init(wrappedValue:Int) 
        {
            self.storage = .init(truncatingIfNeeded: wrappedValue)
        }
        /// var General.Storage.wrappedValue : Swift.Int { get }
        ///     The value wrapped by this property wrapper, expanded to an [`Swift.Int`].
        public 
        var wrappedValue:Int 
        {
            .init(self.storage)
        }
    }
}
