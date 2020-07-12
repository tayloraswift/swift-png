//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/. 

extension LZ77.Huffman 
{
    struct Codeword 
    {
        // bits are stored starting from least-significant bit to most-significant bit
        let bits:UInt16 
        @General.Storage<UInt8> 
        var length:Int 
    }
}
extension LZ77.Huffman.Codeword 
{
    init(counter:UInt16, length:Int) 
    {
        // this branch should be well-predicted 
        if length <= 8 
        {
            let low:UInt16  = LZ77.Reversed[counter]
            self.init(bits:         low  &>> ( 8 - length), length: length)
        }
        else 
        {
            let high:UInt16 = LZ77.Reversed[counter & 0xff] << 8, 
                low:UInt16  = LZ77.Reversed[counter >> 8]
            self.init(bits: (high | low) &>> (16 - length), length: length)
        }
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
                assert(.init(symbol) < count, "symbol out of range")
                
                destination[.init(symbol)]  = .init(counter: counter, length: length)
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
        precondition(8 ..< 16 ~= exponent, "exponent cannot be less than 8 or greater than 15")
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
        .init(x) & ~(.max << self.exponent)
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
            guard $0.count >= 3 
            else 
            {
                return nil 
            }
            
            // cannot encode run longer than 258 elements 
            let limit:Int       = min($0.count, 258) 
            let front:UInt16    = self.modular(self.endIndex)
            
            //  these always succeed, but may contain garbage values if 
            //  self.endIndex < 2
            let a:UInt8         = self[self.modular(front &- 1)].value, 
                b:UInt8         = self[self.modular(front &- 2)].value
            var best:(length:Int, distance:Int)
            //  check for internal matches 
            //      A | A : A : A
            if      self.endIndex > 0, 
                $0[0] == a, 
                $0[1] == a, 
                $0[2] == a 
            {
                best = (length:    3, distance: 1)
            }
            //  B : A | B : A : B
            else if self.endIndex > 1, 
                $0[0] == b, 
                $0[1] == a, 
                $0[2] == b 
            {
                best = (length:    3, distance: 2)
            }
            else 
            {
                best = (length: .min, distance: 3)
            }
            
            //  |<----- window ---->|<--- lookahead --->|
            //  [   :   :   :   :   |   :   :   :   :   ]
            //                      ~~~~~~~~~~~~
            //                         prefix
            let prefix:Prefix   = .init($0[0], $0[1], $0[2])
            guard var current:UInt16 = self.head[prefix] 
            else 
            {
                return best.length >= 3 ? best : nil 
            }
            var distance:Int    = self.distance(from: current, to: front)
            
            while best.length  <= limit 
            {
                var length:Int  =                         3, 
                    m:UInt16    = self.modular(current &+ 3) 
                // match up to front 
                while   m                   != front, 
                        length              <  limit, 
                        self[m].value       == $0[length]
                {
                    m           = self.modular(m &+ 1)
                    length     += 1
                }
                // match lookahead 
                let delay:Int   = length
                while   length              <  limit, 
                        $0[length - delay]  == $0[length]
                {
                    length     += 1
                }
                
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
        struct Term
        {
            private 
            let storage:UInt32
        }
        
        struct Stream 
        {
            var input:In 
            var terms:[Term]
            var window:Window
            var output:Out
            
            init(exponent:Int, hint:Int) 
            {
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
extension LZ77.Deflator.Term 
{
    //  it takes about 28 bits to represent a length-distance pair, and  
    //  we can save ourselves some branching by using the remaining 4 
    //  bits to encode a literal as-is
    //  32              24              16              8               0
    //  [ : : : : :D:D:D|D:D:D:D:D:D:D:D|D:D:R:R:R:R:R: | : : : : : : : ]
    //   ~~~~~~~~~^                                    ~~~~~~~~~~~~~~~~~^
    //     distance                                            runliteral
    var symbol:(runliteral:Int, distance:Int) 
    {
        (.init(self.storage & 0x00_00_01_ff), .init(self.storage >> 27))
    }
    
    var decade:(run:UInt8, distance:UInt8) 
    {
        (.init(self.storage & 0x00_00_00_ff), .init(self.storage >> 27))
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
    init(hint:Int = 1 << 12) 
    {
        self.stream = .init(exponent: 15, hint: hint)
        self.stream.start()
    }
    mutating 
    func push(_ data:[UInt8], last:Bool = false) 
    {
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
            self.stream.end()
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
        while    self.input.count >= 258 || 
                (self.input.count != 0 && all)
        {
            if self.terms.count >= 1024 
            {
                return ()
            }
            
            let term:LZ77.Deflator.Term 
            if let match:(length:Int, distance:Int) = self.window.match(self.input) 
            {
                for _:Int in 0 ..< match.length 
                {
                    self.window.register(input.dequeue())
                }
                term = .init(run: match.length, distance: match.distance)
            }
            else 
            {
                let literal:UInt8 = input.dequeue()
                window.register(literal)
                term = .init(literal: literal)
            }
            self.terms.append(term)
        }
        
        return nil 
    }
    
    mutating 
    func block(last:Bool) 
    {
        // create fixed table 
        let runliteral:[LZ77.Huffman<UInt16>.Codeword] = 
            .init(unsafeUninitializedCapacity: 288) 
        {
            guard let base:UnsafeMutablePointer<LZ77.Huffman<UInt16>.Codeword> = 
                $0.baseAddress 
            else 
            {
                $1 = 0
                return 
            }
            LZ77.FixedHuffman.runliteral.codewords(initializing: base, count: 288)
            $1 = 288
        }
        let distance:[LZ77.Huffman<UInt8>.Codeword] = 
            .init(unsafeUninitializedCapacity: 32) 
        {
            guard let base:UnsafeMutablePointer<LZ77.Huffman<UInt8>.Codeword> = 
                $0.baseAddress 
            else 
            {
                $1 = 0
                return 
            }
            LZ77.FixedHuffman.distance.codewords(initializing: base, count: 32)
            $1 = 32
        }
        
        // fixed compression
        self.output.append(last ? 0b01_1 : 0b01_0, count: 3)
        for term:LZ77.Deflator.Term in self.terms 
        {
            let symbol:(runliteral:Int, distance:Int)       = term.symbol 
            let codeword:
            (
                runliteral:LZ77.Huffman<UInt16>.Codeword, 
                distance:LZ77.Huffman<UInt8>.Codeword
            )
            
            codeword.runliteral = runliteral[symbol.runliteral]
            self.output.append(codeword.runliteral.bits, count: codeword.runliteral.length)
            
            if symbol.runliteral > 256 
            {
                // there are extra bits and a distance code to follow 
                let decade:(run:UInt8, distance:UInt8)  = term.decade,
                    bits:(run:UInt16, distance:UInt16)  = term.bits 
                let count:(run:Int, distance:Int)       = 
                (
                    .init(LZ77.Composites[run:      decade.run     ].extra),
                    .init(LZ77.Composites[distance: decade.distance].extra)
                )
                
                codeword.distance = distance[symbol.distance]
                
                self.output.append(bits.run,               count: count.run)
                self.output.append(codeword.distance.bits, count: codeword.distance.length)
                self.output.append(bits.distance,          count: count.distance)
            }
        }
        // end-of-block symbol 
        let end:LZ77.Huffman<UInt16>.Codeword = runliteral[256]
        self.output.append(end.bits, count: end.length)
    }
    
    mutating 
    func end() 
    {
        
    }
}
