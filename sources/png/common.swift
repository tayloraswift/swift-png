//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/. 

//  enum General 
//      A namespace for general functionality.
//  #  [Integer storage](general-storage-types)
//  #  [See also](top-level-namespaces)
//  ## (1:top-level-namespaces)
public 
enum General    
{
}

extension General  
{
    //  struct General.Storage<I> 
    //  where I:Swift.FixedWidthInteger & Swift.BinaryInteger 
    //  @propertyWrapper 
    //      A property wrapper providing an immutable [`Swift.Int`] interface backed 
    //      by a different integer type.
    //  #  [See also](general-storage-types)
    //  ## (general-storage-types)
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

extension General 
{    
    struct Heap<Key, Value> where Key:Comparable 
    {
        private 
        var storage:[(Key, Value)]
        
        // support 1-based indexing
        private
        subscript(index:Int) -> (key:Key, value:Value)
        {
            get
            {
                self.storage[index - 1]
            }
            set(item)
            {
                self.storage[index - 1] = item
            }
        }

        var count:Int
        {
            self.storage.count
        }
        var first:(key:Key, value:Value)?
        {
            self.storage.first
        }
        var isEmpty:Bool 
        {
            self.storage.isEmpty 
        }
        
        private 
        var startIndex:Int 
        {
            1
        }
        private 
        var endIndex:Int 
        {
            1 + self.count
        }
    }
}
extension General.Heap
{
    @inline(__always)
    private static 
    func left(index:Int) -> Int
    {
        return index << 1
    }
    @inline(__always)
    private static 
    func right(index:Int) -> Int
    {
        return index << 1 + 1
    }
    @inline(__always)
    private static 
    func parent(index:Int) -> Int
    {
        return index >> 1
    }
    
    private
    func highest(above child:Int) -> Int?
    {
        let p:Int = Self.parent(index: child)
        // make sure it’s not the root
        guard p >= self.startIndex 
        else 
        {
            return nil 
        }
                
        // and the element is higher than the parent
        return self[child].key < self[p].key ? p : nil
    }
    private
    func lowest(below parent:Int) -> Int?
    {
        let r:Int = Self.right(index: parent),
            l:Int = Self.left (index: parent)

        guard l < self.endIndex
        else
        {
            return nil
        }

        guard r < self.endIndex
        else
        {
            return  self[l].key < self[parent].key ? l : nil 
        }
        
        let c:Int = self[r].key < self[l].key      ? r : l
        return      self[c].key < self[parent].key ? c : nil 
    }
    

    @inline(__always)
    private mutating
    func swapAt(_ i:Int, _ j:Int)
    {
        self.storage.swapAt(i - 1, j - 1)
    }
    private mutating
    func siftUp(index:Int)
    {
        guard let parent:Int = self.highest(above: index)
        else
        {
            return
        }

        self.swapAt(index, parent)
        self.siftUp(index: parent)
    }
    private mutating
    func siftDown(index:Int)
    {
        guard let child:Int = self.lowest(below: index)
        else
        {
            return
        }
        
        self.swapAt  (index, child)
        self.siftDown(index: child)
    }

    mutating
    func enqueue(key:Key, value:Value)
    {
        self.storage.append((key, value))
        self.siftUp(index: self.endIndex - 1)
    }
    
    mutating
    func dequeue() -> (key:Key, value:Value)?
    {
        switch self.count 
        {
        case 0:
            return nil 
        case 1:
            return self.storage.removeLast()
        default:
            self.swapAt(self.startIndex, self.endIndex - 1)
            defer 
            {
                self.siftDown(index: self.startIndex)
            }
            return self.storage.removeLast()
        }
    }
    
    init<S>(_ sequence:S) where S:Sequence, S.Element == (Key, Value) 
    {
        self.storage    = .init(sequence)
        // heapify 
        let halfway:Int = Self.parent(index: self.endIndex - 1) + 1
        for i:Int in (self.startIndex ..< halfway).reversed()
        {
            self.siftDown(index: i)
        }
    }
}
extension General.Heap:ExpressibleByArrayLiteral 
{
    init(arrayLiteral:(key:Key, value:Value)...) 
    {
        self.init(arrayLiteral)
    }
}

extension Array where Element == UInt8
{
    func load<T, U>(bigEndian:T.Type, as type:U.Type, at byte:Int) -> U
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self[byte ..< byte + MemoryLayout<T>.size].load(bigEndian: T.self, as: U.self)
    }
}
extension UnsafeMutableBufferPointer where Element == UInt8 
{
    func store<U, T>(_ value:U, asBigEndian type:T.Type, at byte:Int = 0)
        where U:BinaryInteger, T:FixedWidthInteger
    {
        let cast:T = .init(truncatingIfNeeded: value)
        withUnsafeBytes(of: cast.bigEndian) 
        {
            guard   let source:UnsafeRawPointer             = $0.baseAddress, 
                    let destination:UnsafeMutableRawPointer = 
                self.baseAddress.map(UnsafeMutableRawPointer.init(_:))
            else 
            {
                return 
            }
            
            (destination + byte).copyMemory(from: source, byteCount: MemoryLayout<T>.size)
        }
    }
}

extension ArraySlice where Element == UInt8
{
    func load<T, U>(bigEndian:T.Type, as type:U.Type) -> U
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self.withUnsafeBufferPointer
        {
            (buffer:UnsafeBufferPointer<UInt8>) in

            assert(buffer.count >= MemoryLayout<T>.size,
                "attempt to load \(T.self) from slice of size \(buffer.count)")

            var storage:T = .init()
            let value:T   = withUnsafeMutablePointer(to: &storage)
            {
                $0.deinitialize(count: 1)

                let source:UnsafeRawPointer     = .init(buffer.baseAddress!),
                    raw:UnsafeMutableRawPointer = .init($0)

                raw.copyMemory(from: source, byteCount: MemoryLayout<T>.size)

                return raw.load(as: T.self)
            }

            return U(T(bigEndian: value))
        }
    }
}
