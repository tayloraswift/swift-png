//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/. 

extension LZ77 
{
    struct Codeword 
    {
        // bits are stored starting from least-significant bit to most-significant bit
        let bits:UInt16 
        @General.Storage<UInt8> 
        var length:Int 
        @General.Storage<UInt8> 
        var extra:Int
    }
}
extension LZ77.Codeword 
{
    init(counter:UInt16, length:Int, extra:Int) 
    {
        // this branch should be well-predicted 
        if length <= 8 
        {
            let low:UInt16  = LZ77.Reversed[counter]
            self.init(bits:         low  &>> ( 8 - length), length: length, extra: extra)
        }
        else 
        {
            let high:UInt16 = LZ77.Reversed[counter & 0xff] << 8, 
                low:UInt16  = LZ77.Reversed[counter >> 8]
            self.init(bits: (high | low) &>> (16 - length), length: length, extra: extra)
        }
    }
}
extension LZ77.Huffman where Symbol:BinaryInteger 
{
    func codewords(initializing destination:UnsafeMutablePointer<LZ77.Codeword>, 
        count:Int, extra:(Symbol) -> Int) 
    {
        // initialize all entries to 0, as symbols with frequency 0 are omitted 
        // from self.symbols 
        destination.initialize(repeating: .init(bits: 0, length: 0, extra: 0), 
            count: count)
        
        var counter:UInt16  = 0
        for (length, level):(Int, Range<Int>) in zip(1 ... 15, self.levels) 
        {
            for symbol:Symbol in self.symbols[level]
            {
                assert(.init(symbol) < count, "symbol out of range")
                
                destination[.init(symbol)]  = 
                    .init(counter: counter, length: length, extra: extra(symbol))
                counter                    += 1
            }
            
            counter <<= 1
        }
    }
    
    // message length, in bits
    func mass<C>(frequencies:C) -> Int 
        where C:RandomAccessCollection, C.Index == Int, C.Element == Int 
    {
        var total:Int = 0
        for (length, level):(Int, Range<Int>) in zip(1 ... 15, self.levels) 
        {
            total += length * self.symbols[level].reduce(0)
            {
                $0 + frequencies[frequencies.startIndex + .init($1)]
            }
        }
        return total
    }
    
    init<C>(frequencies:C, limit:Int) 
        where C:RandomAccessCollection, C.Index == Int, C.Element == Int 
    {
        // sort non-zero symbols by (decreasing) frequency
        let symbols:[Symbol] = frequencies.indices.compactMap 
        {
            frequencies[$0] > 0 ? .init($0 - frequencies.startIndex) : nil 
        }.sorted
        {
            frequencies[frequencies.startIndex + .init($0)] > 
            frequencies[frequencies.startIndex + .init($1)]
        }
        
        // cover 0-symbol and 1-symbol cases 
        guard let first:Symbol = symbols.first 
        else 
        {
            self.init(symbols: [.zero, .zero], 
                levels: [0 ..< 2] + .init(repeating: 2 ..< 2, count: 14))
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
            (frequencies[frequencies.startIndex + .init($0)], [1])
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
                for (i, k):(Int, Int) in zip(merged.indices.reversed(), mergee.reversed())
                {
                    merged[i] += k
                }
                merged.append(0)
                heap.enqueue(key: first.key + second.key, value: merged)
                continue 
            }
            
            // drop the first (last) level count, since it corresponds to 
            // the tree root, and convert level counts to codeword assignments 
            let leaves:[Int] = Self.limitHeight(first.value.dropLast().reversed(), to: limit)
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
            
            // symbols with the same length are sorted by symbol value. this 
            // ordering may be different from the plain frequency-keyed order.
            let resorted:[Symbol] = .init(unsafeUninitializedCapacity: symbols.count) 
            {
                guard let base:UnsafeMutablePointer<Symbol> = $0.baseAddress 
                else 
                {
                    fatalError("unreachable")
                }
                for level:Range<Int> in levels 
                {
                    (base + level.lowerBound).initialize(
                        from: symbols[level].sorted(), count: level.count)
                }
                $1 = symbols.count 
            }
            
            self.init(symbols: resorted, levels: levels)
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
        self.startIndex     = 0 
        self.endIndex       = 0 
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
                    $0.assign(from: body, count: self.endIndex)
                }
                return new 
            } 
        }
    }
    
    mutating 
    func dequeue() -> UInt8
    {
        assert(self.count > 0)
        let value:UInt8 = self.storage.withUnsafeMutablePointerToElements 
        {
            $0[self.startIndex]
        }
        self.startIndex += 1
        return value 
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
    }
    
    mutating 
    func checksum() -> UInt32 
    {
        // everything still in the storage buffer has not yet been integrated 
        self.storage.withUnsafeMutablePointerToElements 
        {
            let (single, double):(UInt32, UInt32) = 
                LZ77.MRC32.update(self.integral, from: $0, count: self.endIndex)
            return double << 16 | single
        }
    }
    
    func withUnsafeBufferPointer<R>(_ body:(UnsafeBufferPointer<UInt8>) throws -> R) 
        rethrows -> R 
    {
        try self.storage.withUnsafeMutablePointerToElements 
        {
            try body(.init(start: $0 + self.startIndex, count: self.count))
        }
    }
}

extension LZ77.Deflator 
{
    struct Window 
    {
        struct Element 
        {
            // stores a modular index
            var next:UInt16?
            let value:UInt8 
        }
        struct Prefix:Hashable
        {
            // can change this to a tuple in 5.4
            let a:UInt8, 
                b:UInt8, 
                c:UInt8
            
            init(_ a:UInt8, _ b:UInt8, _ c:UInt8) 
            {
                self.a = a
                self.b = b
                self.c = c
            }
        }
        
        let exponent:Int 
        private 
        var storage:ManagedBuffer<Void, Element>, 
            head:[Prefix: UInt16] // modular index 
        private 
        var endIndex:Int // absolute index
    }
}
extension LZ77.Deflator.Window 
{
    init(exponent:Int) 
    {
        self.exponent   = exponent 
        self.endIndex   = 0
        self.head       = [:]
        self.storage    = .create(minimumCapacity: 1 << exponent){ _ in () }
    }
    
    subscript(modular:UInt16) -> Element 
    {
        get 
        {
            self.storage.withUnsafeMutablePointerToElements 
            {
                $0[.init(modular)]
            }
        }
        set(value) 
        {
            self.storage.withUnsafeMutablePointerToElements 
            {
                $0[.init(modular)] = value
            }
        }
    }
    
    private 
    func modular<T>(_ x:T) -> UInt16 where T:BinaryInteger
    {
        .init(truncatingIfNeeded: x) & ~(.max << self.exponent)
    }
    
    private 
    func distance(from a:UInt16, to b:UInt16) -> Int 
    {
        .init((b &- a) & ~(.max << self.exponent))
    }
    
    mutating 
    func register(_ value:UInt8) 
    {
        //  a   b   c   d   e  e+1
        //  [   :   |   :   :   ]
        //  ~~~~~~~~~~~~ remove
        //  add     ~~~~~~~~~~~~
        let c:UInt16        = self.modular(self.endIndex)
        self.endIndex      += 1
        
        guard self.endIndex > 2 
        else 
        {
            self[c]         = .init(value: value)
            return 
        }
        
        let a:UInt16        = self.modular(c &- 2),
            b:UInt16        = self.modular(c &- 1)
        let new:Prefix      = .init(self[a].value, self[b].value, value)
        if self.endIndex    > 1 << self.exponent 
        {
            // remove overwritten entry 
            let d:UInt16    = self.modular(c &+ 1),
                e:UInt16    = self.modular(c &+ 2)
            let old:Prefix  = .init(self[c].value, self[d].value, self[e].value)
            self.head[old]  = nil 
        }
        self[c]             = .init(value: value)
        if let m:UInt16     = self.head.updateValue(.init(a), forKey: new)
        {
            // we know `m` is within the window range, because we preemptively 
            // remove dictionary entries when they go out of range
            self[a].next    = m
        }
    }
    
    func match(_ lookahead:LZ77.Deflator.In) -> (length:Int, distance:Int)?
    {
        lookahead.withUnsafeBufferPointer 
        {
            (buffer:UnsafeBufferPointer<UInt8>) in 
            
            guard buffer.count >= 3 
            else 
            {
                return nil 
            }
            
            // cannot encode run longer than 258 elements 
            let limit:Int       = min(buffer.count, 258) 
            let front:UInt16    = self.modular(self.endIndex)
            
            //  these always succeed, but may contain garbage values if 
            //  self.endIndex < 2
            let a:UInt8         = self[self.modular(front &- 1)].value, 
                b:UInt8         = self[self.modular(front &- 2)].value
            var best:(length:Int, distance:Int) = (length: .min, distance: 0)
            //  check for internal matches 
            //      A | A : A : A
            if  self.endIndex > 0, 
                buffer[0] == a, 
                buffer[1] == a, 
                buffer[2] == a 
            {
                var length:Int = 3
                while length < limit, buffer[length] == a 
                {
                    length += 1
                }
                
                if length > best.length 
                {
                    best = (length: length, distance: 1)
                }
            }
            //  B : A | B : A : B
            if  self.endIndex > 1, 
                buffer[0] == b, 
                buffer[1] == a, 
                buffer[2] == b 
            {
                var length:Int = 3
                while length < limit, buffer[length] == a 
                {
                    length += 1
                    guard length < limit, buffer[length] == b 
                    else 
                    {
                        break 
                    } 
                    length += 1
                }
                
                if length > best.length 
                {
                    best = (length: length, distance: 2)
                }
            }
            
            //  |<----- window ---->|<--- lookahead --->|
            //  [   :   :   :   :   |   :   :   :   :   ]
            //                      ~~~~~~~~~~~~
            //                         prefix
            let prefix:Prefix   = .init(buffer[0], buffer[1], buffer[2])
            guard var current:UInt16 = self.head[prefix] 
            else 
            {
                return best.length >= 3 ? best : nil 
            }
            
            var distance:Int    = self.distance(from: current, to: front)
            while best.length  <= limit 
            {
                let length:Int = 
                {
                    (start:UInt16) in 
                    
                    var length:Int  =                       3, 
                        m:UInt16    = self.modular(start &+ 3) 
                    while length < limit, m != front
                    {
                        // match up to front 
                        guard self[m].value == buffer[length]
                        else 
                        {
                            return length
                        }
                        
                        m       = self.modular(m &+ 1)
                        length += 1
                    }
                    // match lookahead 
                    let delay:Int = length
                    while length < limit, buffer[length - delay] == buffer[length]
                    {
                        length += 1
                    }
                    return length
                }(current)
                
                if length > best.length 
                {
                    best = (length: length, distance: distance)
                }
                
                guard let next:UInt16 = self[current].next 
                else 
                {
                    break 
                }
                
                distance += self.distance(from: next, to: current)
                guard distance < 1 << self.exponent 
                else 
                {
                    break 
                }
                current = next
            }
            
            return best
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
    
    // content in low-bits
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
                self.queued += 1
                
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
    
    mutating 
    func pad(to _:UInt8.Type)
    {
        self.append(0, count: -self.count & 7)
    }
    
    private  
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
        struct Term
        {
            private 
            let storage:UInt32
            
            struct Meta 
            {
                // its possible to encode a metaterm in 8 bits, but it 
                // complicates the accessors so much it’s not worth it
                private 
                let storage:(symbol:UInt8, bits:UInt8)
            }
        }
        
        struct Stream 
        {
            var input:In 
            var terms:[Term]
            var window:Window
            var output:Out
            
            init(exponent:Int, hint:Int) 
            {
                precondition(8 ..< 16 ~= exponent, "exponent cannot be less than 8 or greater than 15")
                
                self.input  = .init()
                self.terms  = []
                self.window = .init(exponent: exponent)
                self.output = .init(hint: hint)
            }
        }
        
        private 
        var stream:Stream 
    }
}
extension LZ77.Deflator.Term.Meta 
{
    var symbol:UInt8 
    {
        self.storage.symbol
    }
    var bits:UInt16 
    {
        .init(self.storage.bits)
    }
    
    static 
    func literal(_ literal:UInt8) -> Self
    {
        .init(storage: (symbol: literal, bits: 0))
    }
    static 
    func `repeat`(count:Int) -> Self
    {
        .init(storage: (symbol: 16, bits: .init(count - 3)))
    }
    static 
    func zeros(count:Int) -> Self
    {
        if count < 11 
        {
            return .init(storage: (symbol: 17, bits: .init(count - 3)))
        }
        else 
        {
            return .init(storage: (symbol: 18, bits: .init(count - 11)))
        }
    }
}
extension LZ77.Deflator.Term 
{
    //  it takes about 28 bits to represent a length-distance pair, and  
    //  we can save ourselves some branching by using the remaining 4 
    //  bits to encode a literal as-is
    //  32              24              16              8               0
    //  [ : : : : :D:D:D|D:D:D:D:D:D:D:D|D:D:R:R:R:R:R: | : : : : : : : ]
    //   ~~~~~~~~~^                                    ~~~~~~~~~~~~~~~~~^
    //     distance                                            runliteral
    var symbol:(runliteral:UInt16, distance:UInt8) 
    {
        (.init(self.storage & 0x00_00_01_ff), .init(self.storage >> 27))
    }
    var bits:(run:UInt16, distance:UInt16) 
    {
        (.init(self.storage >> 9 & 0x00_1f), .init(self.storage >> 14 & 0x1f_ff))
    }
    
    init(literal:UInt8) 
    {
        // put bitpattern for 31 in distance field, to streamline 
        // frequency counting later on 
        self.storage = 0b11111000_00000000_00000000_00000000 | .init(literal)
    }
    
    static 
    let end:Self = .init(storage: 0b11111000_00000000_00000001_00000000)
    
    init(run:Int, distance:Int) 
    {
        let decade:(run:UInt8, distance:UInt8) = 
        (
            run:            LZ77.Decades[run:      run     ], 
            distance:       LZ77.Decades[distance: distance]
        )
        let base:(run:UInt32, distance:UInt32) = 
        (
            run:      .init(LZ77.Composites[run:      decade.run     ].base),
            distance: .init(LZ77.Composites[distance: decade.distance].base)
        )
        
        let symbols:UInt32 = 
            .init(decade.distance) << 27 | 0x0000_0100 | 
            .init(decade.run) 
        let bits:UInt32    = 
            (.init(distance) - base.distance) << 14 | 
            (.init(run     ) - base.run     ) <<  9
        self.storage = symbols | bits
    }
}
extension LZ77.Deflator 
{
    init(exponent:Int = 15, hint:Int = 1 << 12) 
    {
        self.stream = .init(exponent: exponent, hint: hint)
        self.stream.start()
    }
    mutating 
    func push(_ data:[UInt8], last:Bool = false) 
    {
        // print("out", data)
        // rebase input buffer 
        if !data.isEmpty 
        {
            self.stream.input.enqueue(contentsOf: data) 
        }
        while let _:Void = self.stream.compress(all: last) 
        {
            self.stream.block(last: false)
        }
        if last 
        {
            self.stream.block(last: true)
            self.stream.checksum()
        }
    }
    mutating 
    func pop() -> [UInt8]?
    {
        self.stream.output.pop()
    }
    mutating 
    func pull() -> [UInt8]
    {
        return self.pop() ?? self.stream.output.pull()
    }
}
extension LZ77.Deflator.Stream 
{
    mutating 
    func start() 
    {
        let unpaired:UInt16 = .init(self.window.exponent - 8) << 4 | 0x08
        let check:UInt16    = ~((unpaired << 8 | unpaired >> 8) % 31) & 31
        
        self.output.append(check << 8 | unpaired, count: 16)
    }
    
    mutating 
    func compress(all:Bool) -> Void?
    {
        // always maintain at least 258 bytes in the input buffer 
        while       self.input.count >= 258 || 
            (all && self.input.count !=   0)
        {
            if self.terms.count >= 1 << 14 
            {
                return ()
            }
            
            let term:LZ77.Deflator.Term 
            if let match:(length:Int, distance:Int) = self.window.match(self.input) 
            {
                for _:Int in 0 ..< match.length 
                {
                    self.window.register(self.input.dequeue())
                }
                term = .init(run: match.length, distance: match.distance)
            }
            else 
            {
                let literal:UInt8 = self.input.dequeue()
                self.window.register(literal)
                term = .init(literal: literal)
            }
            self.terms.append(term)
        }
        
        return nil 
    }
    
    mutating 
    func block(last:Bool) 
    {
        let dicing:LZ77.Deflator.Dicing = .init(self.terms, unit: 1 << 10)
        self.block(dicing.startIndex, dicing: dicing, last: last)
        // empty literal buffer 
        self.terms.removeAll(keepingCapacity: true)
    }
    
    private mutating 
    func block(_ index:Int, dicing:LZ77.Deflator.Dicing, last:Bool)
    {
        let semistatic:LZ77.Deflator.Semistatic, 
            range:Range<Int>
        switch dicing[index] 
        {
        case .interior(prefix: let a, suffix: let b):
            self.block(a, dicing: dicing, last: false)
            self.block(b, dicing: dicing, last: last)
            return 
        
        case .leaf(terms: let terms, dynamic: nil):
            // fixed compression
            semistatic  = .fixed
            range       = terms
            self.output.append(last ? 0b01_1 : 0b01_0, count: 3)
        
        case .leaf(terms: let terms, dynamic:
            (
                codelengths:    let codelengths, 
                runliterals:    let runliterals, 
                distances:      let distances, 
                metaterms:      let metaterms, 
                tree:           let tree
            )?):
            // dynamic compression
            semistatic  = .init(runliteral: tree.runliteral, distance: tree.distance, 
                meta: tree.meta)
            range       = terms 
            self.output.append(last ? 0b10_1 : 0b10_0,  count: 3)
            
            self.output.append(.init(runliterals       - 257), count: 5)
            self.output.append(.init(distances         -   1), count: 5)
            self.output.append(.init(codelengths.count -   4), count: 4)
            for codelength:UInt16 in codelengths 
            {
                self.output.append(codelength, count: 3)
            }
            for metaterm:LZ77.Deflator.Term.Meta in metaterms 
            {
                let codeword:LZ77.Codeword = semistatic[meta: metaterm.symbol]
                self.output.append(codeword.bits, count: codeword.length)
                self.output.append(metaterm.bits, count: codeword.extra)
            }
        }
        
        for term:LZ77.Deflator.Term in self.terms[range]
        {
            let symbol:(runliteral:UInt16, distance:UInt8) = term.symbol 
            let codeword:(runliteral:LZ77.Codeword, distance:LZ77.Codeword)
            
            codeword.runliteral = semistatic[runliteral: symbol.runliteral]
            
            self.output.append(codeword.runliteral.bits, count: codeword.runliteral.length)
            
            if symbol.runliteral > 256 
            {
                // there are extra bits and a distance code to follow 
                let bits:(run:UInt16, distance:UInt16) = term.bits 
                
                codeword.distance = semistatic[distance: symbol.distance]
                
                self.output.append(bits.run,               count: codeword.runliteral.extra)
                self.output.append(codeword.distance.bits, count: codeword.distance.length)
                self.output.append(bits.distance,          count: codeword.distance.extra)
            }
        }
        // end-of-block symbol 
        let end:LZ77.Codeword = semistatic[runliteral: 256]
        self.output.append(end.bits, count: end.length)
    }
    
    mutating 
    func checksum() 
    {
        // checksum is written big-endian, which means it has to go into the 
        // bitstream msb-first
        let checksum:UInt32 = self.input.checksum().byteSwapped
        self.output.pad(to: UInt8.self)
        self.output.append(.init(truncatingIfNeeded: checksum       ), count: 16)
        self.output.append(.init(                    checksum >>  16), count: 16)
    }
}

extension LZ77.Deflator 
{
    struct Semistatic 
    {
        private 
        let storage:ManagedBuffer<Void, LZ77.Codeword>
        
        //                heap
        //    0 ┌───────────────────────┐
        //      │                       │
        //      │                       │
        //      │                       │
        //      │  runliteral codewords │ : 288 * Codeword
        //      │                       │
        //      │                       │
        //      │                       │
        //  288 ├───────────────────────┤
        //      │   distance codewords  │ :  32 * Codeword
        //  320 ├───────────────────────┤
        //      │     meta codewords    │ :  19 * Codeword
        //  339 └───────────────────────┘
    }
}
extension LZ77.Deflator.Semistatic 
{
    init(runliteral:LZ77.Huffman<UInt16>, distance:LZ77.Huffman<UInt8>, 
        meta:LZ77.Huffman<UInt8>? = nil)
    {
        self.storage = .create(minimumCapacity: 339){ _ in () }
        self.storage.withUnsafeMutablePointerToElements 
        {
            runliteral.codewords(initializing: $0,       count: 288) 
            {
                $0 > 256 ? 
                .init(LZ77.Composites[run: .init(truncatingIfNeeded: $0)].extra) : 0
            }
            distance.codewords(  initializing: $0 + 288, count:  32)
            {
                .init(LZ77.Composites[distance: $0].extra)
            }
            meta?.codewords(     initializing: $0 + 320, count:  19)
            {
                switch $0 
                {
                case 18: return 7
                case 17: return 3
                case 16: return 2
                default: return 0
                }
            }
        }
    }
    
    subscript(runliteral symbol:UInt16) -> LZ77.Codeword 
    {
        self.storage.withUnsafeMutablePointerToElements 
        {
            ($0      )[.init(symbol)]
        }
    }
    subscript(distance symbol:UInt8) -> LZ77.Codeword 
    {
        self.storage.withUnsafeMutablePointerToElements 
        {
            ($0 + 288)[.init(symbol)]
        }
    }
    subscript(meta symbol:UInt8) -> LZ77.Codeword 
    {
        self.storage.withUnsafeMutablePointerToElements 
        {
            ($0 + 320)[.init(symbol)]
        }
    }
    
    static 
    let fixed:Self = .init(
        runliteral: LZ77.FixedHuffman.runliteral, 
        distance:   LZ77.FixedHuffman.distance)
}
extension LZ77.Deflator 
{
    struct Dicing 
    {
        enum Node 
        {
            case interior(prefix:Int, suffix:Int)
            case leaf(terms:Range<Int>, dynamic:
            (
                codelengths:[UInt16],
                runliterals:Int, 
                distances:Int, 
                metaterms:[LZ77.Deflator.Term.Meta], 
                tree:
                (
                    runliteral:LZ77.Huffman<UInt16>, 
                    distance:LZ77.Huffman<UInt8>, 
                    meta:LZ77.Huffman<UInt8>
                )
            )?)
        }
        
        typealias Element = (weight:Int, node:Node)
        
        private 
        let memo:[Element]
    }
}
extension LZ77.Deflator.Dicing 
{
    subscript(index:Int) -> Node
    {
        self.memo[index].node 
    }
    // root node 
    var startIndex:Int 
    {
        0
    }
    
    init(_ terms:[LZ77.Deflator.Term], unit:Int) 
    {
        //  k := `unit`
        //  n := `units`
        // 
        //                  end index
        //  1                                       n
        //  ┌─────────┬─────────┬─────────┲━━━━━━━━━┓ 0
        //  │         │         │         ┃         ┃
        //  │ 0 ..< 1 │ 0 ..< 2 │ 0 ..< 3 ┃ 0 ..< 4 ┃
        //  │         │         │         ┃         ┃
        //  └─────────┼─────────┼─────────╄━━━━━━━━━┩
        //            │         │         │         │   
        //            │ 1 ..< 2 │ 1 ..< 3 │ 1 ..< 4 │   
        //            │         │         │         │   start
        //            └─────────┼─────────┼─────────┤   index
        //                      │         │         │
        //                      │ 2 ..< 3 │ 2 ..< 4 │
        //                      │         │         │
        //                      └─────────┼─────────┤
        //                                │         │
        //                                │ 3 ..< 4 │
        //                                │         │
        //                                └─────────┘ n - 1
        
        //  indexing function:
        //  { 
        //      (i:Int, j:Int) in 
        //      let u:Int = (4 - j + i) 
        //      return u * (u + 1) / 2 + i 
        //  }
        
        //  recursive pattern:
        // 
        //  0             288 320
        //  ┌──────────────┬───╥──────────────┬───╥──────────────┬───╥──────────────┬───┐
        //  │ frequencies(0,1) ║ frequencies(1,2) ║ frequencies(2,3) ║ frequencies(3,4) │
        //  └──────────────┴───╨──────────────┴───╨──────────────┴───╨──────────────┴───┘
        //          ↓↓↓       ↙↙↙      ↓↓↓       ↙↙↙      ↓↓↓       ↙↙↙
        //  ┌──────────────┬───╥──────────────┬───╥──────────────┬───┐
        //  │ frequencies(0,2) ║ frequencies(1,3) ║ frequencies(2,4) │
        //  └──────────────┴───╨──────────────┴───╨──────────────┴───┘
        //          ↓↓↓       ↙↙↙      ↓↓↓       ↙↙↙
        //  ┌──────────────┬───╥──────────────┬───┐
        //  │ frequencies(0,3) ║ frequencies(1,4) │
        //  └──────────────┴───╨──────────────┴───┘
        //          ↓↓↓       ↙↙↙
        //  ┌──────────────┬───┐
        //  │ frequencies(0,4) │
        //  └──────────────┴───┘
        //  optimal  compression
        
        
        let units:Int   = (terms.count + unit - 1) / unit,
            count:Int   = units * (units + 1) / 2
        self.memo       = .init(unsafeUninitializedCapacity: count) 
        {
            guard let memo:UnsafeMutablePointer<Element> = $0.baseAddress 
            else 
            {
                fatalError("unreachable")
            }
            // build frequency array, has largest interval at the beginning, eg:
            //  (0, 4), 
            //  (0, 3), (1, 4), 
            //  (0, 2), (1, 3), (2, 4), 
            //  (0, 1), (1, 2), (2, 3), (3, 4)
            var frequencies:[Int] = .init(repeating: 0, count: 320 * count)
            
            // tally symbol frequencies for single-unit intervals 
            var base:Int    = 320 * (count - units),
                phase:Int   = 0
            for term:LZ77.Deflator.Term in terms 
            {
                // no need to differentiate between literals and run-distance pairs, 
                // because literal terms have the distance symbol set to a non-
                // existent symbol (32)
                let symbol:(runliteral:UInt16, distance:UInt8) = term.symbol 
                frequencies[base       + .init(symbol.runliteral)] += 1
                frequencies[base + 288 + .init(symbol.distance)  ] += 1
                
                phase += 1
                guard phase != unit 
                else 
                {
                    base += 320
                    phase = 0 
                    continue 
                }
            }
            
            // register the eob code, since it isn’t explicitly represented 
            for k:Int in count - units ..< count 
            {
                frequencies[320 * k + 256] = 1
            }
            // derive frequency counts for multi-unit intervals 
            for order:Int in 1 ..< units
            {
                for a:Int in 0 ..< units - order
                {
                    let b:Int = a + order, 
                        c:Int = b + 1
                    
                    let base:(i:Int, j:Int, k:Int) = 
                    (
                        320 * Self.linear(index: (a, b), units: units),
                        320 * Self.linear(index: (b, c), units: units),
                        320 * Self.linear(index: (a, c), units: units)
                    )
                    for s:Int in 0 ..< 318 
                    {
                        frequencies[base.k + s] = 
                            frequencies[base.j + s] + frequencies[base.i + s]
                    }
                    // reset eob frequency to 1 
                    frequencies[base.k + 256] = 1
                }
            }
            
            for order:Int in 0 ..< units
            {
                for (a, b):(Int, Int) in 
                    zip(0 ..< units - order, order + 1 ..< units + 1) 
                {
                    let (i, element):(Int, Element) = Self.fill(a, b, 
                        unit: unit, units: units, terms: terms.indices, 
                        frequencies: frequencies, memo: $0)
                    
                    (memo + i).initialize(to: element)
                }
            }
            
            $1 = count 
        }
    }
    
    private static 
    func linear(index:(a:Int, b:Int), units:Int) -> Int 
    {
        let u:Int = units + index.a - index.b
        return (u * u + u) >> 1 + index.a
    }
    private static 
    func fill<C>(_ a:Int, _ b:Int, unit:Int, units:Int, terms:Range<Int>, 
        frequencies:[Int], memo:C) 
        -> (index:Int, element:Element) 
        where C:RandomAccessCollection, C.Index == Int, C.Element == Element
    {
        let k:Int = Self.linear(index: (a, b), units: units)
        // print("\((a, b)) -> \(k)")
        
        let base:Int = 320 * k
        let tree:(runliteral:LZ77.Huffman<UInt16>, distance:LZ77.Huffman<UInt8>) = 
        (
            .init(frequencies: frequencies[base       ..< base + 286], limit: 15),
            .init(frequencies: frequencies[base + 288 ..< base + 318], limit: 15)
        )
        // compute combined metatree 
        let meta:
        (
            tree:LZ77.Huffman<UInt8>, 
            mass:Int, 
            runliterals:Int, 
            distances:Int,
            terms:[LZ77.Deflator.Term.Meta]
        ) 
        = 
        Self.metatree(for: tree)
        
        let codelengths:[UInt16] = .init(unsafeUninitializedCapacity: 19) 
        {
            $0.initialize(repeating: 0)
            for (length, level):(UInt16, Range<Int>) in zip(1 ... 8, meta.tree.levels)
            {
                for symbol:UInt8 in meta.tree.symbols[level] 
                {
                    let z:Int = 
                    [
                        3, 17, 15, 13, 11,  9,  7,  5, 
                        4,  6,  8, 10, 12, 14, 16, 18, 
                        0, 1, 2
                    ][.init(symbol)]
                    
                    $0[z] = length
                }
            }
            // max(4, _) because HCLEN cannot be less than 4
            $1 = max(4, $0.reversed().drop{ $0 == 0 }.count)
        }
        
        // compute message lengths 
        let score:(dynamic:Int, fixed:Int)
        score.dynamic = 14 + 3 * codelengths.count + meta.mass + 
            tree.runliteral.mass(frequencies: frequencies[base       ..< base + 286]) + 
            tree.distance.mass(  frequencies: frequencies[base + 288 ..< base + 318])
        score.fixed = 
            8 * frequencies[base       ..< base + 144].reduce(0, +) + 
            9 * frequencies[base + 144 ..< base + 256].reduce(0, +) + 
            7 * frequencies[base + 256 ..< base + 280].reduce(0, +) + 
            8 * frequencies[base + 280 ..< base + 286].reduce(0, +) + 
            5 * frequencies[base + 288 ..< base + 318].reduce(0, +)
        
        if b - a > 1 
        {
            // recursive case 
            var minimum:(i:(Int, Int), score:Int) = ((-1, -1), .max)
            for partition:Int in a + 1 ..< b 
            {
                let i:(Int, Int) = 
                (
                    Self.linear(index: (a, partition   ), units: units),
                    Self.linear(index: (   partition, b), units: units)
                )
                
                let score:Int = memo[i.0].weight + memo[i.1].weight
                if score < minimum.score 
                {
                    minimum = (i: i, score: score)
                }
            }
            
            if  minimum.score < score.dynamic, 
                minimum.score < score.fixed 
            {
                print("[\(a) ..< \(b)]: split (\(minimum.score)) is BETTER than whole (\(min(score.dynamic, score.fixed)))")
                return (index: k, element: 
                (
                    weight: minimum.score, 
                    node:  .interior(prefix: minimum.i.0, suffix: minimum.i.1)
                ))
            }
            else 
            {
                print("[\(a) ..< \(b)]: split (\(minimum.score)) is NOT better than whole (\(min(score.dynamic, score.fixed)))")
            }
        }
        // base case
        let start:Int   =     terms.startIndex + unit * a, 
            end:Int     = min(terms.startIndex + unit * b, terms.endIndex)
        if score.dynamic < score.fixed
        {
            return (index: k, element: 
            (
                weight: score.dynamic, 
                node:  .leaf(terms: start ..< end, dynamic:
                (
                    codelengths:    codelengths,
                    runliterals:    meta.runliterals, 
                    distances:      meta.distances, 
                    metaterms:      meta.terms, 
                    tree:           
                    (
                        runliteral: tree.runliteral, 
                        distance:   tree.distance,
                        meta:       meta.tree
                    )
                ))
            ))
        }
        else 
        {
            return (index: k, element: 
            (
                weight: score.fixed, 
                node:  .leaf(terms: start ..< end, dynamic: nil)
            ))
        }
    }
    private static 
    func metatree(for tree:(runliteral:LZ77.Huffman<UInt16>, distance:LZ77.Huffman<UInt8>)) 
        -> 
    (
        tree:LZ77.Huffman<UInt8>, 
        mass:Int, 
        runliterals:Int, 
        distances:Int,
        terms:[LZ77.Deflator.Term.Meta]
    )
    {
        // there really should be a maximum of 316 combined symbols, not 
        // 318, but the rfc 1951 specifies 218 for some reason 
        var lengths:[UInt8] = .init(repeating: 0, count: 318) 
        
        for (length, level):(UInt8, Range<Int>) in 
            zip(1 ... 15, tree.runliteral.levels) 
        {
            for symbol:UInt16 in tree.runliteral.symbols[level] 
            {
                lengths[      .init(symbol)] = length
            }
        }
        // minimum of 257 runliteral codes
        let r:Int = max(257, lengths.prefix(286).reversed().drop{ $0 == 0 }.count)
        for (length, level):(UInt8, Range<Int>) in 
            zip(1 ... 15, tree.distance.levels) 
        {
            for symbol:UInt8 in tree.distance.symbols[level] 
            {
                lengths[r + .init(symbol)] = length
            }
        }
        // minimum of 1 distance code
        let d:Int = max(1, lengths.dropFirst(r).prefix(32).reversed().drop{ $0 == 0 }.count)
        
        // segment into metaterms 
        var repetitions:Int = 1, 
            last:UInt8      = lengths[0]
        var iterator:ArraySlice<UInt8>.Iterator = lengths[1 ..< r + d].makeIterator(), 
            terms:[LZ77.Deflator.Term.Meta]     = []
        while true 
        {
            let current:UInt8? = iterator.next()
            
            if let literal:UInt8 = current, literal == last 
            {
                repetitions += 1
            }
            else 
            {
                if last == 0 
                {
                    while repetitions > 138 
                    {
                        terms.append(.zeros(count: 138))
                        repetitions -= 138
                    }
                    if repetitions > 2 
                    {
                        terms.append(.zeros(count: repetitions))
                    }
                    else 
                    {
                        terms.append(contentsOf: 
                            repeatElement(.literal(last), count: repetitions))
                    }
                }
                else 
                {
                    terms.append(.literal(last))
                    repetitions -= 1
                    while repetitions > 6
                    {
                        terms.append(.repeat(count: 6))
                        repetitions -= 6
                    }
                    if repetitions > 2 
                    {
                        terms.append(.repeat(count: repetitions))
                    }
                    else 
                    {
                        terms.append(contentsOf: 
                            repeatElement(.literal(last), count: repetitions))
                    }
                }
                
                guard let literal:UInt8 = current 
                else 
                {
                    break 
                }
                
                last        = literal 
                repetitions = 1
            }
        } 
        
        // construct metatree 
        var frequencies:[Int] = .init(repeating: 0, count: 19)
        for term:LZ77.Deflator.Term.Meta in terms 
        {
            frequencies[.init(term.symbol)] += 1
        }
        
        let metatree:LZ77.Huffman<UInt8>    = .init(frequencies: frequencies, limit: 7), 
            mass:Int                        = metatree.mass(frequencies: frequencies)
        return (metatree, mass: mass, runliterals: r, distances: d, terms)
    }
}
