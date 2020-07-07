//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/. 

extension LZ77.Huffman 
{
    struct Codeword 
    {
        let bits:UInt16 
        @General.Storage<UInt8> 
        var length:Int 
    }
}
extension LZ77.Huffman where Symbol:BinaryInteger 
{
    func codewords(initializing destination:UnsafeMutablePointer<Codeword>, count:Int) 
    {
        // initialize all entries to 0, as symbols with frequency 0 are omitted 
        // from self.symbols 
        destination.initialize(repeating: .init(bits: 0, length: 0), count: count)
        
        var counter:UInt16  = 0
        for (length, level):(Int, Range<Int>) in zip(1 ... 15, self.levels) 
        {
            for symbol:Symbol in self.symbols[level]
            {
                destination[.init(symbol)]  = .init(bits: counter, length: length)
                counter                    += 1
            }
            
            counter <<= 1
        }
    }
    
    init(frequencies:[Int]) 
    {
        // sort non-zero symbols by (decreasing) frequency
        let symbols:[Symbol] = frequencies.indices.compactMap 
        {
            frequencies[$0] > 0 ? .init($0) : nil 
        }.sorted
        {
            frequencies[.init($0)] > frequencies[.init($1)]
        }
        
        // cover 0-symbol and 1-symbol cases 
        guard let first:Symbol = symbols.first 
        else 
        {
            self.init(symbols: [], 
                levels:             .init(repeating: 0 ..< 0, count: 15))
            return 
        }
        guard symbols.count > 1 
        else 
        {
            self.init(symbols: [first, first], 
                levels: [0 ..< 2] + .init(repeating: 2 ..< 2, count: 14))
            return 
        }
        
        // reversing (to get canonically sorted array) gets the heapify below 
        // to its best-case O(n) time, not that O matters for n = 256 
        var heap:General.Heap<Int, [Int]> = .init(symbols.reversed().map  
        {
            (frequencies[.init($0)], [1])
        })
        
        // standard huffman tree construction algorithm. builds a list of leaf-level 
        // counts, with the root count at the end 
        while let first:(key:Int, value:[Int]) = heap.dequeue() 
        {
            if let second:(key:Int, value:[Int]) = heap.dequeue() 
            {
                var merged:[Int] 
                let mergee:[Int]
                if first.value.count > second.value.count 
                {
                    merged = first.value 
                    mergee = second.value 
                }
                else 
                {
                    merged = second.value 
                    mergee = first.value 
                }
                for (i, k):(Int, Int) in zip(merged.indices.reversed(), mergee)
                {
                    merged[i] += k
                }
                merged.append(0)
                heap.enqueue(key: first.key + second.key, value: merged)
                continue 
            }
            
            // drop the first (last) level count, since it corresponds to 
            // the tree root, and convert level counts to codeword assignments 
            let leaves:[Int] = Self.limitHeight(first.value.dropLast().reversed(), to: 15)
            // split symbols list into levels 
            let levels:[Range<Int>] = .init(unsafeUninitializedCapacity: 15) 
            {
                var base:Int = symbols.startIndex 
                for (i, count):(Int, Int) in zip($0.indices, leaves)
                {
                    $0[i] = base ..< base + count 
                    base += count 
                }
                // symbols array must have length exactly equal to 16
                for i:Int in $0.indices.dropFirst(leaves.count) 
                {
                    $0[i] = base ..< base
                }
                $1 = $0.count 
            }
            
            self.init(symbols: symbols, levels: levels)
            return  
        }
        
        fatalError("unreachable")
    }
    
    // limit the height of the generated tree to the given height
    private static 
    func limitHeight<S>(_ uncompacted:S, to height:Int) -> [Int] 
        where S:Sequence, S.Element == Int
    {
        var levels:[Int] = .init(uncompacted)
        guard levels.count > height
        else 
        {
            return levels 
        }
        
        // collect unhoused nodes: from the bottom to level 17, we gather up 
        // node pairs (since huffman trees are always full trees). one of the 
        // child nodes gets promoted to the level above, the other node goes 
        // into a pool of unhoused nodes 
        var unhoused:Int = 0 
        for l:Int in (height ..< levels.endIndex).reversed() 
        {
            assert(levels[l] & 1 == 0)
            
            let pairs:Int  = levels[l] >> 1
            unhoused      += pairs 
            levels[l - 1] += pairs 
        }
        levels.removeLast(levels.count - height)
        
        // for the remaining unhoused nodes, our strategy is to look for a level 
        // at least 1 step above the bottom (meaning, indices 0 ..< 15) and split 
        // one of its leaves, reducing the leaf count of that level by 1, and 
        // increasing the leaf count of the level below it by 2
        var split:Int = height - 2
        while unhoused > 0 
        {
            guard levels[split] > 0 
            else 
            {
                split -= 1
                // traversal pattern should make it impossible to go below 0 so 
                // long as total leaf population is less than 2^16 (it can never 
                // be greater than 300 anyway)
                assert(split > 0)
                continue 
            }
            
            let resettled:Int  = min(levels[split], unhoused)
            unhoused          -=     resettled 
            levels[split]     -=     resettled 
            levels[split + 1] += 2 * resettled 
            
            if split < height - 2 
            {
                // since we have added new leaves to this level
                split += 1
            } 
        }
        
        return levels
    }
}

extension LZ77.Deflator 
{
    struct In 
    {
        let window:Int 
        
        private 
        var startIndex:Int, 
            endIndex:Int 
        
        private 
        var capacity:Int
        private 
        var storage:ManagedBuffer<Void, UInt8>
    }
}
extension LZ77.Deflator.In 
{
    init(window:Int) 
    {
        var capacity:Int    = 0
        self.storage = .create(minimumCapacity: 0)
        {
            capacity = $0.capacity 
            return ()
        }
        self.window         = window
        self.startIndex     = 0 
        self.endIndex       = 0 
        self.capacity       = capacity
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
                    $0.assign(from: body, count: self.endIndex)
                }
                return new 
            } 
        }
    }
    
    mutating 
    func enqueue(contentsOf elements:[UInt8]) 
    {
        self.reserve(elements.count)
        self.storage.withUnsafeMutablePointerToElements 
        {
            ($0 + self.endIndex).assign(from: elements, count: elements.count)
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
                $0.assign(from: $0 + self.startIndex, count: count)
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
                    $0.assign(from: body + self.startIndex, count: count)
                }
                self.endIndex      -= self.startIndex
                self.startIndex     = 0
                return new 
            }
        }
    }
}

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
                        $0.assign(from: body, count: self.capacity)
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
    
    // content in low-bits, count must be <= 15
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
    
    private mutating 
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
extension LZ77 
{
    struct Deflator 
    {
        private 
        var input:In, 
            output:Out
    }
}
extension LZ77.Deflator 
{
    init(hint:Int) 
    {
        self.input      = .init(window: 258)
        self.output     = .init(hint: hint)
    }
    mutating 
    func push(_ data:[UInt8]) 
    {
        // rebase input buffer 
        self.input.enqueue(contentsOf: data)
        // always maintain at least 258 bytes in the input buffer 
        // while self.input.endIndex - self.current >= 258
        // {
        //     
        // }
    }
    mutating 
    func pop() -> [UInt8]?
    {
        self.output.pop()
    }
    mutating 
    func pull() -> [UInt8]
    {
        self.output.pull()
    }
}
