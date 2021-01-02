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
        guard symbols.count > 1 
        else 
        {
            self.init(stub: symbols.first)
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
        // self.startIndex     = 0 
        // self.endIndex       = 0 
        self.startIndex     = 4 
        self.endIndex       = 4 
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
    func enqueue(contentsOf elements:[UInt8]) 
    {
        // always allocate 4 extra tail elements to allow for limited reads 
        // from beyond the end of the buffer 
        self.reserve(elements.count + 4)
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
                self.integral   = LZ77.MRC32.update(self.integral, 
                            from: $0 + 4,                   count: self.startIndex - 4)
                $0.assign(  from: $0 - 4 + self.startIndex, count: self.count      + 4)
                self.endIndex   = 4 + self.count 
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
                    self.integral   = LZ77.MRC32.update(self.integral,
                                from: body + 4,                   count: self.startIndex - 4)
                    $0.assign(  from: body - 4 + self.startIndex, count: self.count      + 4)
                }
                self.endIndex   = 4 + self.count 
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
            let (single, double):(UInt32, UInt32) = 
                //LZ77.MRC32.update(self.integral, from: $0, count: self.endIndex)
                LZ77.MRC32.update(self.integral, from: $0 + 4, count: self.endIndex - 4)
            return double << 16 | single
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

extension LZ77.Deflator 
{
    struct Window 
    {
        private 
        struct Element 
        {
            // stores a modular index
            var next:UInt16?
            let value:UInt8 
        }
        
        private 
        var storage:ManagedBuffer<Void, Element>, 
            head:General.Dictionary
        
        private(set) 
        var endIndex:Int // absolute index
        private 
        var w:UInt32, 
            v:UInt32
        
        private 
        let mask:Int
    }
}
extension LZ77.Deflator.Window 
{
    init(exponent:Int) 
    {
        self.endIndex   = -3
        self.w          = 0 
        self.v          = 0
        self.mask       = ~(.max << exponent)
        
        self.storage    = .create(minimumCapacity: 1 << exponent){ _ in () }
        self.head       = .init(exponent: exponent)
    }
    
    private 
    subscript(modular:Int) -> Element
    {
        get
        {
            self.storage.withUnsafeMutablePointerToElements
            {
                $0[modular]
            }
        }
        set(value)
        {
            self.storage.withUnsafeMutablePointerToElements
            {
                $0[modular] = value
            }
        }
    }
    
    var literal:UInt8 
    {
        .init(self.v >> 24)
    }
    
    mutating 
    func initialize(with v:UInt8)
    {
        assert(self.endIndex < 0)
        // we don’t need to update `self.w` because `self.mask` is always at 
        // least 255.
        self.v = self.v << 8 | .init(v)
        //               01..11  00..00  00..01  00..10  00..11
        //  ╴╴╴╴╴╴╴╴┬───────┬───────┰───────┬───────┬───────┬───────┬╶╶╶╶╶╶╶╶
        //          │  ///  ╎  ///  ╏  w.1  ╎  w.0  │       ╎       ╎        
        //  ╴╴╴╴╴╴╴╴┴───────┴───────┸───────┴───────┴───────┴───────┴╶╶╶╶╶╶╶╶
        //          a      a+1     a+2      b      b+1
        //                          ┌───────┬───────┬───────┬───────┬╶╶╶╶╶╶╶╶
        //             ///     ///  │  v.1  ╎  v.0  │       ╎       ╎        
        //                          └───────┴───────┴───────┴───────┴╶╶╶╶╶╶╶╶
        self.endIndex += 1
    }
    
    @discardableResult
    mutating 
    func update(with v:UInt8) -> (index:Int, next:UInt16?) 
    {
        assert(self.endIndex >= 0)
        
        let a:Int       =  self.endIndex       & self.mask, 
            b:Int       = (self.endIndex &+ 3) & self.mask 
        let w:UInt8     =  self[b].value
        
        self.w = self.w << 8 | .init(w)
        self.v = self.v << 8 | .init(v)
        
        if self.endIndex > self.mask
        {
            //               01..11  10..00  10..01  10..10  10..11
            //  ╴╴╴╴╴╴╴╴┬───────┬───────┰───────┬───────┬───────┬───────┬╶╶╶╶╶╶╶╶
            //          ╎       ╎       ┃  w.3  ╎  w.2  ╎  w.1  ╎  w.0  │        
            //  ╴╴╴╴╴╴╴╴┴───────┴───────┸───────┴───────┴───────┴───────┴╶╶╶╶╶╶╶╶
            //                          a      a+1     a+2      b      b+1
            //                          ┌───────┬───────┬───────┬───────┬╶╶╶╶╶╶╶╶
            //                          │  v.3  ╎  v.2  ╎  v.1  ╎  v.0  │        
            //                          └───────┴───────┴───────┴───────┴╶╶╶╶╶╶╶╶
            // a match has gone out of range. delete the match corresponding 
            // to the key in the window at the current position, but only if 
            // it has not already been overwritten with a more recent position.
            self.head.remove(key: self.w, value: .init(a))
        }
        let next:UInt16?    = 
            self.head.update(key: self.v, value: .init(a))
        self[a]             = .init(next: next, value: self.literal)
        
        self.endIndex += 1
        
        // print("lookup (\(self.v >> 24), \(self.v >> 16 & 0xff), \(self.v >> 8 & 0xff), \(self.v & 0xff)): \(next)")
        
        return (a, next)
    }
    
    func match(from head:(index:Int, next:UInt16?), lookahead:LZ77.Deflator.In, attempts:Int, goal:Int) 
        -> (run:Int, distance:Int)?
    {
        var best:(run:Int, distance:Int) = (run: 5, distance: 1)
        self.match(from: head, lookahead: lookahead, attempts: attempts, goal: goal)
        {
            (run:Int, distance:Int) in
            if best.run < run 
            {
                best = (run: run, distance: distance)
            }
        }
        return best.run > 5 ? best : nil
    }
    
    func match(from head:(index:Int, next:UInt16?), lookahead:LZ77.Deflator.In, 
        attempts:Int, goal:Int, delegate:(_ run:Int, _ distance:Int) -> ()) 
    {
        lookahead.withUnsafePointer 
        {
            (v:UnsafePointer<UInt8>) in 
            
            self.storage.withUnsafeMutablePointerToElements 
            {
                (w:UnsafeMutablePointer<Element>) in 
                
                guard let next:UInt16 = head.next
                else 
                {
                    return 
                }
                
                let limit:Int       = min(lookahead.count + 4, 258)
                
                let mask:Int        = self.mask 
                var current:Int     = .init(next)
                var distance:Int    = (head.index &- current) & mask 
                var remaining:Int   = attempts
                while true 
                {
                    var run:Int = 4
                    scan: 
                    do 
                    {
                        let a:Int = min(distance, limit)
                        while run < a
                        {
                            let i:Int = (current &+ run) & mask
                            guard w[i].value == v[run] 
                            else 
                            {
                                break scan
                            }
                            run += 1
                        }
                        
                        var i:Int = max(0, 4 - distance)
                        while run < limit, v[i] == v[run]
                        {
                            i   += 1
                            run += 1
                        }
                    }
                    
                    delegate(run, distance)
                    
                    remaining -= 1
                    
                    guard remaining > 0, goal > run  
                    else 
                    {
                        break 
                    }
                    
                    guard let next:UInt16 = self[current].next 
                    else 
                    {
                        break 
                    }
                    
                    let previous:Int    = current
                    current             = .init(next)
                    distance           += (previous &- current) & mask 
                    
                    guard distance < mask 
                    else 
                    {
                        break 
                    }
                }
            }
        } 
    }
}
extension LZ77.Deflator 
{
    struct Term
    {
        let storage:UInt32
        
        struct Meta 
        {
            // its possible to encode a metaterm in 8 bits, but it 
            // complicates the accessors so much it’s not worth it
            private 
            let storage:(symbol:UInt8, bits:UInt8)
        }
    }
    
    struct Matches 
    {
        private 
        var storage:ManagedBuffer<Void, UInt32>
        
        let capacity:Int 
        private(set)
        var count:Int 
        private 
        var limit:Int 
        
        private 
        var depths:Depths 
        
        struct Depths 
        {
            private 
            var storage:[UInt8]
            private(set)
            var generic:Bool 
        }
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
extension LZ77.Deflator.Matches.Depths 
{
    //  depth table layout:
    // 
    //    0 ┌───────────────────────┐   0
    //      │                       │ 
    //      │     256 literals      │ 
    //      │                       │ 
    //  256 ├───────────────────────┤ 256/3
    //      │                       │ 
    //      │     256 lengths       │ 
    //      │                       │ 
    //  512 ├───────────────────────┤ 258/0
    //      │  30 distance decades  │ 
    //  542 └───────────────────────┘  30
    // 
    //  to take full advantage of the 8-bit storage space, we use 0.125-bit 
    //  fixed-point fractional bit lengths 
    
    private static // literal cost: 8.25 bps 
    let `default`:[UInt8] = .init(repeating: 33, count: 256) 
    // base run composite cost: 7.5 bps
    + (3 ... 258).map 
    {
        (run:Int) -> UInt8 in
        30 + .init(LZ77.Composites[run: LZ77.Decades[run: run]].extra) << 2
    }
    // base distance composite cost: 4.75 bps 
    + (0 ... 29).map 
    {
        (decade:UInt8) -> UInt8 in
        19 + .init(LZ77.Composites[distance: decade           ].extra) << 2
    }
    
    init() 
    {
        self.storage = Self.default
        self.generic = true 
    }
    
    mutating 
    func update(runliteral:LZ77.Huffman<UInt16>, distance:LZ77.Huffman<UInt8>) 
    {
        for (length, level):(UInt8, Range<Int>) in zip(1 ... 15, runliteral.levels)
        {
            for symbol:UInt16 in runliteral.symbols[level] 
            {
                if      symbol < 256 
                {
                    self.storage[.init(symbol)] = length << 2
                }
                else if symbol > 256 
                {
                    let decade:(extra:UInt16, base:UInt16) = 
                        LZ77.Composites[run: .init(truncatingIfNeeded: symbol)]
                    let length:UInt8    = length + .init(decade.extra)
                    let base:Int        = 253 +    .init(decade.base ), 
                        count:Int       =   1 <<         decade.extra 
                    for l:Int in base ..< base + count 
                    {
                        self.storage[l] = length << 2
                    }
                }
            }
        }
        for (length, level):(UInt8, Range<Int>) in zip(1 ... 15, distance.levels)
        {
            for symbol:UInt8 in distance.symbols[level] 
            {
                let extra:UInt8 = .init(LZ77.Composites[distance: symbol].extra)
                self.storage[512 + .init(symbol)] = (length + extra) << 2
            }
        }
        self.generic = false 
    }
    mutating 
    func generalize() 
    {
        for i:Int in self.storage.indices 
        {
            let specialized:UInt8 = self.storage[i], 
                generalized:UInt8 = Self.default[i]
            self.storage[i] = (specialized & generalized) &+ (specialized ^ generalized) >> 1
        }
        // don’t reset self.generic because the depths still contain some 
        // specialized information 
    }
    
    subscript(literal literal:UInt8) -> UInt32 
    {
        .init(self.storage[.init(literal)])
    }
    subscript(run run:Int) -> UInt32 
    {
        .init(self.storage[253 + run])
    }
    subscript(distance decade:UInt8) -> UInt32 
    {
        .init(self.storage[512 + .init(decade)])
    }
}
extension LZ77.Deflator.Matches 
{
    //  match buffer either contains a linear vector of LZ77 terms, 
    //  or a directed graph.
    
    //  upstream token layout:
    //  32          24          16          8           0
    //  ┌───────────┬───────────┬───────────┬───────────┐     ┌───────────┬───────────┐
    //  │                       ╎           │           │ ... │ distance  ╎ maxlength │
    //  └───────────┴───────────┴───────────┴───────────┘     └───────────┴───────────┘
    //                         ↗↗↗
    //  ┌───────────┬───────────┬───────────┬───────────┐
    //  │      length > 2       ╎  decade   │           │
    //  └───────────┴───────────┴───────────┴───────────┘
    //
    //  ┌───────────┬───────────┬───────────┬───────────┐
    //  │                       ╎           │  literal  │
    //  └───────────┴───────────┴───────────┴───────────┘
    //                         ↗↗↗
    //  ┌───────────┬───────────┬───────────┬───────────┐
    //  │      length == 1      ╎           │           │
    //  └───────────┴───────────┴───────────┴───────────┘
    //  ╵                                               ╵
    //  ╵           ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
    //  ╵           ╵
    // +0          +4          +8          +12         +16  +124        +128
    //  ┌─────┬──┬──┬───────────┬─────┬─────┬─────┬─────┐     ┌─────┬─────┐   0
    //  │  upstream │   depth   │     0     │     1     │ ... │    29     │
    //  ├─────┼──┼──┼───────────┼─────┼─────┼─────┼─────┤     ├─────┼─────┤ 128
    //  │        │  │           │           │           │ ... │           │
    //  ├─────┼──┼──┼───────────┼─────┼─────┼─────┼─────┤     ├─────┼─────┤ 256
    //  │        │  │           │           │           │ ... │           │
    //  ├─────┼──┼──┼───────────┼─────┼─────┼─────┼─────┤     ├─────┼─────┤ 384
    //  ╎        ╎  ╎           ╎           ╎           ╎     ╎           ╎
    
    static 
    func graph(capacity:Int) -> Self 
    {
        .init(capacity: capacity << 5, limit: min(2048, capacity))
    }
    static 
    func terms(capacity:Int) -> Self 
    {
        .init(capacity: capacity     , limit: min(1024, capacity))
    }
    
    private 
    init(capacity:Int, limit:Int) 
    {
        self.storage    = .create(minimumCapacity: 32 * capacity){ _ in () }
        self.capacity   = capacity 
        self.limit      = min(2048, capacity)
        self.count      = 0 
        
        self.depths     = .init()
    }
    
    var startIndex:Int 
    {
        0
    }
    var endIndex:Int 
    {
        self.count
    }
    var unfilled:Int 
    {
        self.limit - 1 - self.count
    }
    var indices:Range<Int> 
    {
        self.startIndex ..< self.endIndex
    }
    
    subscript(offset offset:Int) -> UInt32 
    {
        get 
        {
            self.storage.withUnsafeMutablePointerToElements 
            {
                $0[offset]
            }
        }
        set(value)
        {
            self.storage.withUnsafeMutablePointerToElements 
            {
                $0[offset] = value
            }
        }
    }
    
    // APIs that assume the match buffer is a vector of LZ77 terms:
    mutating 
    func store(literal:UInt8) 
    {
        assert(self.unfilled > 0) 
        
        self[offset: self.endIndex] = 
            LZ77.Deflator.Term.init(literal: literal).storage
        self.count += 1
    }
    mutating 
    func store(match:(run:Int, distance:Int)) 
    {
        assert(self.unfilled > 0) 
        
        self[offset: self.endIndex] = 
            LZ77.Deflator.Term.init(run: match.run, distance: match.distance).storage
        self.count += 1
    }
    
    mutating 
    func resetTerms() 
    {
        self.count = 0 
    }
    
    mutating 
    func trees() -> (runliteral:LZ77.Huffman<UInt16>, distance:LZ77.Huffman<UInt8>)
    {
        var frequencies:[Int] = .init(repeating: 0, count: 320)
        for index:Int in self.indices
        {
            let term:LZ77.Deflator.Term = .init(storage: self[offset: index])
            // no need to differentiate between literals and run-distance pairs, 
            // because literal terms have the distance symbol set to a non-
            // existent symbol (32)
            let symbol:(runliteral:UInt16, distance:UInt8) = term.symbol 
            frequencies[      .init(symbol.runliteral)] += 1
            frequencies[288 + .init(symbol.distance)  ] += 1
        }
        frequencies[256] = 1
        
        let tree:(runliteral:LZ77.Huffman<UInt16>, distance:LZ77.Huffman<UInt8>) = 
        (
            .init(frequencies: frequencies[0   ..< 286], limit: 15),
            .init(frequencies: frequencies[288 ..< 318], limit: 15)
        )
        return tree 
    }
    
    // APIs that assume the match buffer is a directed graph:
    @discardableResult
    mutating 
    func store(vertex literal:UInt8) -> Int
    {
        assert(self.unfilled > 0)
         
        // clear node 
        let base:Int = self.endIndex << 5
        // store literal 
        self[offset:        base    ] = .init(literal)
        // initialize depth to infinity
        self[offset:        base | 1] = .max 
        // clear edges 
        for  offset:Int in  base | 2 ... base | 31
        {
            self[offset: offset     ] = 0
        }
        self.count += 1
        return base | 2
    }
    mutating 
    func set(edge:(run:Int, distance:Int), at base:Int) 
    {
        // must be one empty space at the end to be the sink node
        assert(base >> 5 < self.limit - 1) 
        
        let position:Int        = base + .init(LZ77.Decades[distance: edge.distance])
        let candidate:UInt32    = .init(edge.run)
        if  candidate > self[offset: position] & 0x00_00_ff_ff 
        {
            self[offset: position] = .init(edge.distance) << 16 | candidate
        }
    }
    
    mutating 
    func resetGraph() 
    {
        self.count = 0 
        self.depths.generalize()
    }
    
    
    subscript(index:Int) -> (upstream:UInt32, depth:UInt32) 
    {
        get 
        {
            (self[offset: index << 5], self[offset: index << 5 | 1])
        }
        set(value)
        {
            (self[offset: index << 5], self[offset: index << 5 | 1]) = value
        }
    }
    
    subscript(index:Int, decade decade:UInt8) -> Int 
    {
        self.storage.withUnsafeMutablePointerToElements 
        {
            .init($0[index << 5 | (.init(decade) + 2)] & 0x00_00_ff_ff)
        }
    }
    
    mutating 
    func trees(iterations:Int) 
        -> (runliteral:LZ77.Huffman<UInt16>, distance:LZ77.Huffman<UInt8>)
    {
        // increase the graph size limit 
        self.limit = min(2 * self.limit, self.capacity)
        // add additional iterations if this is the first block ever 
        
        // [ A (Δ_) ] <- [ B (ΔA) ] <- [ C (ΔB) ] <- [ D (ΔC) ] <- [ _ (ΔD) ]
        // 
        // [ A (ΔA) ] -> [ B (ΔB) ] -> [ C (ΔC) ] -> [ D (ΔC) ] -> [ _ (ΔD) ]
        var i:Int = self.depths.generic ? -iterations : 0
        while true 
        {
            let frequencies:[Int] = self.minimize()
            let tree:(runliteral:LZ77.Huffman<UInt16>, distance:LZ77.Huffman<UInt8>) = 
            (
                .init(frequencies: frequencies[0   ..< 286], limit: 15),
                .init(frequencies: frequencies[288 ..< 318], limit: 15)
            )
            
            i += 1
            
            guard i < iterations  
            else 
            {
                return tree
            }
            
            self.depths.update(runliteral: tree.runliteral, distance: tree.distance)
            // reset vertex depths 
            for i:Int in self.indices 
            {
                self[offset: i << 5 | 1] = .max 
            }
        }
    }
    
    // after calling this function, the graph contains a linked list starting 
    // from self.startIndex and ending at self.endIndex
    private mutating 
    func minimize() -> [Int] 
    {
        // perform minimum-cost search, after this, there is a linked list 
        // containing the minimum-cost path starting at self.endIndex and 
        // ending at self.startIndex
        
        // initialize source node 
        self[offset: self.startIndex << 5 | 1] = 0
        // initialize sink node 
        self[offset: self.endIndex   << 5 | 1] = .max 
        
        for node:Int in self.indices 
        {
            self.explore(from: node)
        }
        
        // tally symbol frequencies and reverse the linked list
        var frequencies:[Int]   = .init(repeating: 0, count: 318)
        var current:(index:Int, upstream:UInt32) 
        current.index           = self.endIndex
        current.upstream        = self[offset: current.index << 5]
        repeat 
        {
            let length:Int      = .init(current.upstream >> 16)
            let next:(index:Int, upstream:UInt32) 
            next.index          = current.index - length 
            next.upstream       = self[offset: next.index << 5]
            
            self[offset: next.index << 5] = 
                current.upstream & 0xff_ff_ff_00 |
                next.upstream    & 0x00_00_00_ff 
            
            if length == 1 
            {
                let symbol:Int          = .init(next.upstream & 0x00_00_00_ff)
                frequencies[symbol]    += 1
            }
            else 
            {
                let symbol:(run:Int, distance:Int) = 
                (
                    256 | .init(LZ77.Decades[run: length]),
                    288 + .init(current.upstream >> 8 & 0x00_00_00_ff)
                )
                
                frequencies[symbol.run     ] += 1
                frequencies[symbol.distance] += 1
            }
            
            current = next 
        }
        while current.index > self.startIndex
        
        // set end-of-block symbol frequency to 1 
        frequencies[256] = 1
        return frequencies
    }
    
    private mutating 
    func explore(from index:Int) 
    {
        let current:(upstream:UInt32, depth:UInt32) = self[index    ], 
            next:(upstream:UInt32, depth:UInt32)    = self[index + 1]
        let literal:(value:UInt8, depth:UInt32)
        literal.value = .init(truncatingIfNeeded: current.upstream)
        literal.depth = current.depth + self.depths[literal: literal.value]
        
        if literal.depth < next.depth
        {
            self[index + 1] = 
            (
                // length = 1, decade = undefined
                upstream:   0x00_01_ff_00 | next.upstream & 0x00_00_00_ff, 
                depth:      literal.depth
            )
        }
        
        // no point exploring any matches if there is less than the minimum 
        // match length’s worth of nodes in the graph remaining 
        let remaining:Int = self.endIndex - index 
        guard remaining >= 3 
        else 
        {
            return
        }
        
        for decade:UInt8 in 0 ..< 30 
        {
            let maxlength:Int = min(self[index, decade: decade], remaining)
            guard maxlength > 0 
            else 
            {
                continue 
            }
            
            let depth:UInt32 = current.depth + self.depths[distance: decade]
            for length:Int in 3 ... maxlength 
            {
                let depth:UInt32 = depth + self.depths[run: length]
                let next:(upstream:UInt32, depth:UInt32) = self[index + length]
                guard depth < next.depth 
                else
                {
                    continue 
                }
                
                let slug:UInt32 = .init(length) << 16 | .init(decade) << 8
                self[index + length] = 
                (
                    upstream:   slug | next.upstream & 0x00_00_00_ff, 
                    depth:      depth
                )
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
        enum Search  
        {
            case greedy(attempts:Int, goal:Int)
            case lazy(attempts:Int, goal:Int)
            case full(attempts:Int, goal:Int, iterations:Int)
        }
        
        struct Stream 
        {
            let format:Format 
            let search:Search 
            
            var input:In 
            //var queued:(run:Int, extend:Int, distance:Int)?
            //var terms:[Term]
            var window:Window
            var matches:Matches
            var output:Out
            
            init(format:Format, level:Int, exponent:Int, hint:Int) 
            {
                precondition(8 ..< 16 ~= exponent, "exponent cannot be less than 8 or greater than 15")
                
                switch level 
                {
                case .min ... 0:
                    self.search = .greedy(attempts:   1, goal:   6)
                case  1:
                    self.search = .greedy(attempts:   2, goal:   8)
                case  2:
                    self.search = .greedy(attempts:   4, goal:  10)
                case  3:
                    self.search = .greedy(attempts:  40, goal:  24)
                
                case  4:
                    self.search = .lazy(  attempts:  20, goal:  32)
                case  5:
                    self.search = .lazy(  attempts:  40, goal:  54)
                case  6:
                    self.search = .lazy(  attempts:  64, goal:  80)
                case  7:
                    self.search = .lazy(  attempts: 100, goal: 160)
                
                case  8:
                    self.search = .full(  attempts:  14, goal:  20, iterations: 1)
                case  9:
                    self.search = .full(  attempts:  20, goal:  32, iterations: 2)
                case 10:
                    self.search = .full(  attempts:  30, goal:  50, iterations: 3)
                case 11:
                    self.search = .full(  attempts:  60, goal:  80, iterations: 4)
                case 12:
                    self.search = .full(  attempts: 100, goal: 133, iterations: 5)
                default:
                    self.search = .full(  attempts:.max, goal: 258, iterations: 6)
                }
                // match buffer is either a vector of terms, or a directed-graph 
                switch self.search 
                {
                case .greedy, .lazy:
                    self.matches = .terms(capacity: 1 << 15)
                case .full:
                    self.matches = .graph(capacity: 1 << 16)
                }
                
                self.format = format
                
                self.input  = .init()
                self.window = .init(exponent: exponent)
                self.output = .init(hint: hint)
            }
        }
        
        private 
        var stream:Stream 
    }
}
extension LZ77.Deflator 
{
    init(format:LZ77.Format = .zlib, level:Int, exponent:Int = 15, hint:Int = 1 << 12) 
    {
        let e:Int 
        switch format 
        {
        case .zlib: e = exponent 
        case .ios : e = 15
        }
        
        self.stream = .init(format: format, level: level, exponent: e, hint: hint)
        self.stream.start(exponent: e)
    }
    mutating 
    func push(_ data:[UInt8], last:Bool = false) 
    {
        // rebase input buffer 
        if !data.isEmpty 
        {
            self.stream.input.enqueue(contentsOf: data) 
        }
        guard self.stream.input.count > 4096 || last 
        else 
        {
            return 
        }
        
        while let _:Void = self.stream.compress(all: last) 
        {
            self.stream.block(final: false)
        }
        if last 
        {
            self.stream.block(final: true)
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
    func start(exponent:Int) 
    {
        if case .ios = self.format 
        {
            return 
        }
        
        let unpaired:UInt16 = .init(exponent - 8) << 4 | 0x08
        let check:UInt16    = ~((unpaired << 8 | unpaired >> 8) % 31) & 31
        
        self.output.append(check << 8 | unpaired, count: 16)
    }
    
    mutating 
    func compress(all:Bool) -> Void?
    {
        //         -3      -2      -1       0       1       2       3       4       5       6
        //          ┌╴╴╴╴╴╴╴┬╴╴╴╴╴╴╴┬╴╴╴╴╴╴╴┰───────┬───────┬───────┬───────┬───────┬───────┬
        //          │  ???  ╎  ???  ╎  ???  ┃       ╎       ╎       ╎       ╎       ╎       ╎
        //          └╴╴╴╴╴╴╴┴╴╴╴╴╴╴╴┴╴╴╴╴╴╴╴┸───────┴───────┴───────┴───────┴───────┴───────┴
        //          a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬───────┬───────┬───────┬
        //                                  │  x.0  ╎  x.1  ╎  x.2  ╎  x.3  ╎  x.4  ╎  x.5  ╎
        //                                  └───────┴───────┴───────┴───────┴───────┴───────┴
        //                                  n      n-1     n-2     n-3     n-4     n-5     n-6
        //
        //  PROLOGUE (while a < 0)
        //
        // -3      -2      -1       0       1       2       3       4       5       6       7
        //  ┌╴╴╴╴╴╴╴┬╴╴╴╴╴╴╴┬╴╴╴╴╴╴╴┰───────┬───────┬───────┬───────┬───────┬───────┬───────┬
        //  │  ???  ╎  ???  ╎  ???  ╏  x.0  │       ╎       ╎       ╎       ╎       ╎       ╎
        //  └╴╴╴╴╴╴╴┴╴╴╴╴╴╴╴┴╴╴╴╴╴╴╴┸───────┴───────┴───────┴───────┴───────┴───────┴───────┴
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬───────┬───────┬───────┬
        //                                  │  x.1  ╎  x.2  ╎  x.3  ╎  x.4  ╎  x.5  ╎  x.6  ╎
        //                                  └───────┴───────┴───────┴───────┴───────┴───────┴
        //                                 n-1     n-2     n-3     n-4     n-5     n-6     n-7
        //
        // -2      -1       0       1       2       3       4       5       6       7       8
        //  ┬╴╴╴╴╴╴╴┬╴╴╴╴╴╴╴┰───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬
        //  │  ???  ╎  ???  ╏  x.0  ╎  x.1  │       ╎       ╎       ╎       ╎       ╎       ╎
        //  ┴╴╴╴╴╴╴╴┴╴╴╴╴╴╴╴┸───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬───────┬───────┬───────┬
        //                                  │  x.2  ╎  x.3  ╎  x.4  ╎  x.5  ╎  x.6  ╎  x.8  ╎
        //                                  └───────┴───────┴───────┴───────┴───────┴───────┴
        //                                 n-2     n-3     n-4     n-5     n-6     n-7     n-8
        //
        // -1       0       1       2       3       4       5       6       7       8       9
        //  ┬╴╴╴╴╴╴╴┰───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬
        //  │  ???  ╏  x.0  ╎  x.1  ╎  x.2  │       ╎       ╎       ╎       ╎       ╎       ╎
        //  ┴╴╴╴╴╴╴╴┸───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬───────┬───────┬───────┬
        //                                  │  x.3  ╎  x.4  ╎  x.5  ╎  x.6  ╎  x.7  ╎  x.8  ╎
        //                                  └───────┴───────┴───────┴───────┴───────┴───────┴
        //                                 n-3     n-4     n-5     n-6     n-7     n-8     n-9
        // 
        //  BODY (while b > 0, match.run <= b)
        //
        //  0       1       2       3       4       5       6       7       8       9      10
        //  ┰───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬
        //  ╏  x.0  ╎  x.1  ╎  x.2  ╎  x.3  │       ╎       ╎       ╎       ╎       ╎       ╎
        //  ┸───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬───────┬───────┬───────┬
        //                                  │  x.4  ╎  x.5  ╎  x.6  ╎  x.7  ╎  x.8  ╎  x.9  ╎
        //                                  └───────┴───────┴───────┴───────┴───────┴───────┴
        //                                 n-4     n-5     n-6     n-7     n-8     n-9     n-10
        //
        //                                  . . .
        // 
        //  |<--------- match (6 ..< 11) ---------->|
        //  6       7       8       9      10      11      12      n=13
        //  ┼───────┬───────┬───────┬───────┬───────┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬
        //  │  x.6  ╎  x.7  ╎  x.8  ╎  x.9  │       │       ╎       │       ╎       ╎       ╎
        //  ┼───────┴───────┴───────┴───────┴───────┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬
        //                                  │  x.10 ╎  x.11 ╎  x.12 │  ???  ╎  ???  ╎  ???  ╎
        //                                  └───────┴───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴
        //                                 n-10     2       1       0      -1      -2      -3
        // 
        //  CONSUME (while a <= match.end)
        // 
        //  --- match (6 ..< 11) ---------->|
        //  7       8       9      10      11      12      n=13
        //  ┬───────┬───────┬───────┬───────┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  ╎  x.7  ╎  x.8  ╎  x.9  ╎  x.10 │       ╎       │       ╎       ╎       ╎       │
        //  ┴───────┴───────┴───────┴───────┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //                                  │  x.11 ╎  x.12 │  ???  ╎  ???  ╎  ???  ╎  ???  │
        //                                  └───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        //                                 n-11     1       0      -1      -2      -3      -4
        //
        //    (6 ..< 11) ---------->|
        //  8       9      10      11      12      n=13
        //  ┬───────┬───────┬───────┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  ╎  x.8  ╎  x.9  ╎  x.10 │  x.11 ╎       │       ╎       ╎       ╎       │
        //  ┴───────┴───────┴───────┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //                                  │  x.12 │  ???  ╎  ???  ╎  ???  ╎  ???  │
        //                                  └───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        //                                  1       0      -1      -2      -3      -4
        //
        //       ---------->|
        //  9      10      11      12      n=13
        //  ┬───────┬───────┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  ╎  x.9  ╎  x.10 │  x.11 ╎  x.12 │       ╎       ╎       ╎       │
        //  ┴───────┴───────┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //                                  │  ???  ╎  ???  ╎  ???  ╎  ???  │
        //                                  └╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        //                                  0      -1      -2      -3      -4
        //
        //  ------->|
        // 10      11      12      n=13
        //  ┬───────┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  ╎  x.10 │  x.11 ╎  x.12 │  ???  ╎       ╎       ╎       │
        //  ┴───────┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //                                  │  ???  ╎  ???  ╎  ???  │
        //                                  └╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        //                                 -1      -2      -3      -4
        //
        //  |
        // 11      12      n=13
        //  ┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  │  x.11 ╎  x.12 │  ???  ╎  ???  ╎       ╎       │
        //  ┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1     b-2
        //                                  ┌╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //                                  │  ???  ╎  ???  │
        //                                  └╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        //                                 -2      -3      -4
        // 
        //  EPILOGUE (while b > -3)
        //  
        // 12      n=13
        //  ┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  ╎  x.12 │  ???  ╎  ???  ╎  ???  ╎       │
        //  ┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1
        //                                  ┌╶╶╶╶╶╶╶┐
        //                                  │  ???  │
        //                                  └╶╶╶╶╶╶╶┘
        //                                 -3      -4
        //  
        // n=13
        //  ┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  │  ???  ╎  ???  ╎  ???  ╎  ???  │
        //  ┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b
        switch self.search 
        {
        case .greedy(attempts: let attempts, goal: let goal):
            let lookahead:Int = all ? 0 : 258
            while   self.window.endIndex < 0, 
                    self.input.count > lookahead
            {
                self.window.initialize(with: self.input.dequeue())
            }
            
            while   self.input.count > lookahead 
            {
                guard self.matches.unfilled > 0 
                else 
                {
                    return ()
                }
                
                let head:(index:Int, next:UInt16?)  = 
                    self.window.update(with: self.input.dequeue())
                
                if  let match:(run:Int, distance:Int)   = 
                    self.window.match(from: head, lookahead: self.input, 
                        attempts: attempts, goal: goal) 
                {
                    // consume match. this may cause `self.input.count` to go negative 
                    // (in which case, garbage values will be written, which is okay.)
                    for _:Int in 1 ..< match.run 
                    {
                        self.window.update(with: self.input.dequeue())
                    }
                    
                    self.matches.store(match: match)
                }
                else 
                {
                    self.matches.store(literal: self.window.literal)
                }
            }
            
            guard all 
            else 
            {
                return nil 
            }
            
            // epilogue: get the matches still sitting in the pipeline 
            let epilogue:Int = -3 - min(0, self.window.endIndex)
            while   self.input.count > epilogue
            {
                guard self.matches.unfilled > 0 
                else 
                {
                    return ()
                }
                
                self.window.update(with: self.input.dequeue())
                self.matches.store(literal: self.window.literal)
            }

        
        case .lazy(attempts: let attempts, goal: let goal):
            let lookahead:Int = all ? 0 : 259
            while   self.window.endIndex < 0, 
                    self.input.count > lookahead
            {
                self.window.initialize(with: self.input.dequeue())
            }
            while self.input.count > lookahead 
            {
                guard self.matches.unfilled > 1 
                else 
                {
                    return ()
                }
                
                let head:(index:Int, next:UInt16?)  = 
                    self.window.update(with: self.input.dequeue())
                let first:UInt8                     = 
                    self.window.literal
                
                if  let eager:(run:Int, distance:Int)   = 
                    self.window.match(from: head, lookahead: self.input, 
                        attempts: attempts, goal: goal) 
                {
                    // save the literal at `head`
                    let head:(index:Int, next:UInt16?)      = 
                        self.window.update(with: self.input.dequeue())
                    // look for a better match at offset a+1 
                    if  let lazy:(run:Int, distance:Int)    = 
                        self.window.match(from: head, lookahead: self.input, 
                            attempts: attempts, goal: goal), 
                        eager.run < lazy.run
                    {
                        // found a longer match. emit the leading literal, and the 
                        // improved match. 
                        self.matches.store(literal: first)
                        self.matches.store(match: lazy)
                        for _:Int in 1 ..< lazy.run 
                        {
                            self.window.update(with: self.input.dequeue())
                        }
                    }
                    else 
                    {
                        self.matches.store(match: eager)
                        for _:Int in 2 ..< eager.run 
                        {
                            self.window.update(with: self.input.dequeue())
                        }
                    }
                }
                else 
                {
                    self.matches.store(literal: first)
                }
            }
            
            guard all 
            else 
            {
                return nil 
            }
            
            let epilogue:Int = -3 - min(0, self.window.endIndex)
            while   self.input.count > epilogue
            {
                guard self.matches.unfilled > 0 
                else 
                {
                    return ()
                }
                
                self.window.update(with: self.input.dequeue())
                self.matches.store(literal: self.window.literal)
            }
        
        case .full(attempts: let attempts, goal: let goal, iterations: _):
            let lookahead:Int = all ? 0 : 258
            while   self.window.endIndex < 0, 
                    self.input.count > lookahead
            {
                self.window.initialize(with: self.input.dequeue())
            }
            while   self.input.count > lookahead 
            {
                guard self.matches.unfilled > 0 
                else 
                {
                    return ()
                }
                
                // must save base index because this call increments the endindex
                let head:(index:Int, next:UInt16?)  = 
                    self.window.update(with: self.input.dequeue())
                
                let index:Int   = self.matches.store(vertex: self.window.literal)
                var extent:Int  = 1
                self.window.match(from: head, lookahead: self.input, 
                    attempts: attempts, goal: goal) 
                {
                    (run:Int, distance:Int) in 
                    
                    extent = max(extent, run)
                    self.matches.set(edge: (run: run, distance: distance), at: index)
                }
                
                // for long matches, skip some of the intermediate vertices 
                // to avoid degenerate behavior
                for _:Int in 0 ..< max(0, min(extent - 100, self.matches.unfilled))
                {
                    self.window.update(with: self.input.dequeue())
                    self.matches.store(vertex: self.window.literal)
                } 
            } 
            
            guard all 
            else 
            {
                return nil 
            }
            
            let epilogue:Int = -3 - min(0, self.window.endIndex)
            while   self.input.count > epilogue
            {
                guard self.matches.unfilled > 0 
                else 
                {
                    return ()
                }
                
                self.window.update(with: self.input.dequeue())
                self.matches.store(vertex: self.window.literal)
            }
        }
        
        return nil 
    }
    
    private mutating 
    func blockStart(final:Bool, runliterals:Int, distances:Int, metatree:LZ77.Huffman<UInt8>)  
    {
        let codelengths:[UInt16] = .init(unsafeUninitializedCapacity: 19) 
        {
            $0.initialize(repeating: 0)
            for (length, level):(UInt16, Range<Int>) in zip(1 ... 8, metatree.levels)
            {
                for symbol:UInt8 in metatree.symbols[level] 
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
        
        self.output.append(final ? 0b10_1 : 0b10_0,        count: 3)
        
        self.output.append(.init(runliterals       - 257), count: 5)
        self.output.append(.init(distances         -   1), count: 5)
        self.output.append(.init(codelengths.count -   4), count: 4)
        for codelength:UInt16 in codelengths 
        {
            self.output.append(codelength, count: 3)
        }
    }
    
    private mutating 
    func blockTables(_ metaterms:[LZ77.Deflator.Term.Meta], semistatic:LZ77.Deflator.Semistatic) 
    {
        for metaterm:LZ77.Deflator.Term.Meta in metaterms 
        {
            let codeword:LZ77.Codeword = semistatic[meta: metaterm.symbol]
            self.output.append(codeword.bits, count: codeword.length)
            self.output.append(metaterm.bits, count: codeword.extra)
        }
    }
    
    private mutating 
    func blockCompressed(semistatic:LZ77.Deflator.Semistatic) 
    {
        switch self.search 
        {
        case .greedy, .lazy:
            for index:Int in self.matches.indices 
            {
                let term:LZ77.Deflator.Term = .init(storage: self.matches[offset: index])
                
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
            
            self.matches.resetTerms()
        
        case .full:
            var index:Int = self.matches.startIndex 
            while index < self.matches.endIndex 
            {
                let upstream:UInt32 = self.matches[offset: index << 5]
                let count:Int       = .init(upstream >> 16) 
                if count == 1 
                {
                    let literal:UInt16 = .init(upstream & 0x00_00_00_ff)
                    let codeword:LZ77.Codeword = semistatic[runliteral: literal]
                    self.output.append(codeword.bits, count: codeword.length)
                }
                else 
                {
                    let decade:(run:UInt8, distance:UInt8) = 
                    (
                        run:        LZ77.Decades[run: count], 
                        distance:   .init(truncatingIfNeeded: upstream >> 8)
                    )
                    let offset:UInt16 = 
                        .init(self.matches[offset: index << 5 | (2 + .init(decade.distance))] >> 16)
                    
                    let bits:(run:UInt16, distance:UInt16) = 
                    (
                        run:        .init(count) - LZ77.Composites[run: decade.run].base, 
                        distance:   offset - LZ77.Composites[distance: decade.distance].base 
                    )
                    
                    let codeword:(run:LZ77.Codeword, distance:LZ77.Codeword) = 
                    (
                        run:        semistatic[runliteral:  256 | .init(decade.run)],
                        distance:   semistatic[distance:    decade.distance]
                    )
                    
                    self.output.append(codeword.run.bits,      count: codeword.run.length)
                    self.output.append(bits.run,               count: codeword.run.extra)
                    self.output.append(codeword.distance.bits, count: codeword.distance.length)
                    self.output.append(bits.distance,          count: codeword.distance.extra)
                }
                
                index += count 
            }
            // emit end-of-block code 
            let end:LZ77.Codeword = semistatic[runliteral: 256]
            self.output.append(end.bits, count: end.length)
            
            self.matches.resetGraph()
        }
    }
    
    mutating 
    func block(final:Bool) 
    {
        let tree:
        (
            runliteral:LZ77.Huffman<UInt16>, 
            distance:LZ77.Huffman<UInt8>, 
            meta:LZ77.Huffman<UInt8>
        ) 
        
        switch self.search 
        {
        case .greedy, .lazy:
            (tree.runliteral, tree.distance) = self.matches.trees()
        case .full(attempts: _, goal: _, iterations: let iterations):
            (tree.runliteral, tree.distance) = self.matches.trees(iterations: iterations)
        }
        
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
        
        tree.meta = .init(frequencies: frequencies, limit: 7)
        
        self.blockStart(final: final, runliterals: r, distances: d, metatree: tree.meta)
        
        let semistatic:LZ77.Deflator.Semistatic = .init(
            runliteral: tree.runliteral, 
            distance: tree.distance, 
            meta: tree.meta)
        
        self.blockTables(terms, semistatic: semistatic)
        self.blockCompressed(semistatic: semistatic)
        
        /* let dicing:LZ77.Deflator.Dicing = .init(self.terms, unit: 1 << 12)
        self.block(dicing.startIndex, dicing: dicing, last: last)
        // empty literal buffer 
        self.terms.removeAll(keepingCapacity: true) */
    }
    
    /* private mutating 
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
    } */
    
    mutating 
    func checksum() 
    {
        if case .ios = self.format 
        {
            return
        }
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
/* extension LZ77.Deflator.Dicing 
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
            
            #if DUMP_LZ77_BLOCKS
            if k == 0 
            {
                if minimum.score < min(score.dynamic, score.fixed) 
                {
                    print("> [\(a) ..< \(b)]: partitioned (\(minimum.score)) is BETTER than unpartitioned (\(min(score.dynamic, score.fixed)))")
                    var stack:[(Int, Int)]      = [minimum.i]
                    var partitions:[Range<Int>] = []
                    while let i:(Int, Int) = stack.popLast() 
                    {
                        switch memo[i.0].node
                        {
                        case .leaf(terms: let terms, dynamic: _):
                            partitions.append(terms)
                        case .interior(prefix: let prefix, suffix: let suffix):
                            stack.append((prefix, suffix))
                        }
                        switch memo[i.1].node
                        {
                        case .leaf(terms: let terms, dynamic: _):
                            partitions.append(terms)
                        case .interior(prefix: let prefix, suffix: let suffix):
                            stack.append((prefix, suffix))
                        }
                    }
                    print("> \(partitions)")
                }
                else 
                {
                    print("> [\(a) ..< \(b)]: partitioned (\(minimum.score)) is NOT better than unpartitioned (\(min(score.dynamic, score.fixed)))")
                }
            }
            #endif
            
            if  minimum.score < score.dynamic, 
                minimum.score < score.fixed 
            {
                return (index: k, element: 
                (
                    weight: minimum.score, 
                    node:  .interior(prefix: minimum.i.0, suffix: minimum.i.1)
                ))
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
} */
