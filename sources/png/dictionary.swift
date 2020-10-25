#if arch(x86_64) && !NO_INTRINSICS

import _Builtin_intrinsics.intel

extension SIMD16 where Scalar == UInt8 
{
    func find(_ key:UInt8) -> UInt16 
    {
        let repeated:Self       = .init(repeating: key)
        let mask:SIMD2<Int64>   = _mm_cmpeq_epi8(
            unsafeBitCast(self,     to: SIMD2<Int64>.self), 
            unsafeBitCast(repeated, to: SIMD2<Int64>.self))
        return .init(truncatingIfNeeded: _mm_movemask_epi8(mask))
    }
}

#else 

extension SIMD16 where Scalar == UInt8 
{
    func find(_ key:UInt8) -> UInt16
    {
        // (key: 5, vector: (1, 5, 1, 1, 5, 5, 1, 1, 1, 1, 1, 1, 5, 1, 1, 5))
        let places:SIMD16<UInt8>    = 
            .init(128, 64, 32, 16, 8, 4, 2, 1, 128, 64, 32, 16, 8, 4, 2, 1),
            match:SIMD16<UInt8>     = places.replacing(with: 0, where: self .!= key)
        // match: ( 0, 64,  0,  0,  8,  4,  0,  0,  0,  0,  0,  0,  8,  0,  0,  1)
        let r8:SIMD8<UInt8> =    match.evenHalf |    match.oddHalf, 
            r4:SIMD4<UInt8> =       r8.evenHalf |       r8.oddHalf,
            r2:SIMD2<UInt8> =       r4.evenHalf |       r4.oddHalf
        return .init(r2.x) << 8  | .init(r2.y)
    }
}

#endif

extension General 
{
    // simple (UInt32) -> UInt16 hashmap based on F14
    struct Dictionary 
    {
        struct Hash 
        {
            private 
            let value:Int 
        }
        
        struct District
        {
            typealias Row = (key:UInt32, value:UInt16, displaced:UInt16)
            struct Index:Equatable 
            {
                let offset:Int 
            }
            
            let base:UnsafeMutableRawPointer 
        }
        
        private 
        var storage:ManagedBuffer<Void, UInt8>, 
            mask:Int
    }
}
extension General.Dictionary.Hash 
{
    // stackoverflow.com/questions/664014/what-integer-hash-function-are-good-that-accepts-an-integer-hash-key
    init(_ x:UInt32) 
    {
        let a:UInt32 = ((x >> 16) ^ x) &* 0x04_5d_9f_3b,
            b:UInt32 = ((a >> 16) ^ a) &* 0x04_5d_9f_3b,
            c:UInt32 =  (b >> 16) ^ b
        self.value = .init(c)
    }
    
    //  we use the following bits in the hash:
    // 
    // 64        32    28            19                 7         0
    //  ┌─ ╶ ╶ ╶ ╶┬─────┬─────┬─────┬─┬───┬─────┬─────┬─┬───┬─────┐
    //  │         ╎     ╎   probe   ╎1╎    district     ╎   tag   │
    //  └─ ╶ ╶ ╶ ╶┴─────┴─────┴─────┴─┴───┴─────┴─────┴─┴───┴─────┘
    //                                |<-<- self.mask ->|
    var tag:UInt8 
    {
        .init(self.value & 0x7f | 0x80)
    }
    
    func startIndex(mask:Int) 
        -> General.Dictionary.District.Index 
    {
        .init(offset: self.value & mask)
    }
    func index(before current:General.Dictionary.District.Index, mask:Int) 
        -> General.Dictionary.District.Index
    {
        .init(offset: (current.offset &- self.probe) & mask)
    }
    func index(after current:General.Dictionary.District.Index, mask:Int) 
        -> General.Dictionary.District.Index
    {
        .init(offset: (current.offset &+ self.probe) & mask)
    }
    
    private 
    var probe:Int 
    {
        (self.value >> 12 | 0x00_80) & 0xff_80
    }
}
extension General.Dictionary.District.Index 
{
    static 
    func + (rhs:UnsafeMutableRawPointer, lhs:Self) -> General.Dictionary.District  
    {
        .init(base: rhs + lhs.offset)
    }
}
extension General.Dictionary.District 
{
    var header:SIMD16<UInt8> 
    {
        self.base.load(as: SIMD16<UInt8>.self)
    } 
    var tags:UnsafeMutablePointer<UInt8>
    {
        self.base.bindMemory(to: UInt8.self, capacity: 14)
    } 
    subscript(index:Int) -> Row 
    {
        _read 
        {
            yield ((self.base + (16 + 8 * index)).bindMemory(to: Row.self, capacity: 1).pointee)
        }
        nonmutating 
        _modify
        {
            yield &(self.base + (16 + 8 * index)).bindMemory(to: Row.self, capacity: 1).pointee
        }
    }
    
    var displaced:UInt16 
    {
        _read 
        {
            yield  self[0].displaced
        }
        
        nonmutating 
        _modify
        {
            yield &self[0].displaced
        }
    }
}
extension General.Dictionary 
{
    
    //  memory layout:
    // 
    //   +0 ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
    //      │  0  ╎  1  ╎  2  ╎  3  ╎  4  ╎  5  ╎  6  ╎  7  │
    //      ├ ─ ─ ┼ ─ ─ ┼ ─ ─ ┼ ─  tags ─ ┼ ─ ─ ┼ ─ ─ ┼ ─ ─ ┤   SIMD16<UInt8>
    //      │  8  ╎  9  ╎ 10  ╎ 11  ╎ 12  ╎ 13  ╎     ╎     │
    //      └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
    //  +16 ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
    //      │         key 0         ╎  value 0  │ displaced │
    //  +32 ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤ 
    //      │         key 1         ╎  value 1  │     ╎     │
    //  +48 ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤ 
    //      │         key 2         ╎  value 2  │     ╎     │
    //  +64 ├─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┤
    //      ╷                     . . .                     ╷
    // +112 ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
    //      │         key 13        ╎  value 13 │     ╎     │
    // +120 ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤ 
    //      │         key 14        ╎  value 14 │     ╎     │
    // +128 └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
    // 
    //  note: unlike F14, we store the displaced keys count outside of the SIMD 
    //  vector, because it’s not always efficient to extract a UInt16 from a 
    //  vector register, and the first 64B of the district should be in the 
    //  cache already anyway.
    init(exponent:Int) 
    {
        assert(MemoryLayout<District.Row>.stride == 8)
        // to ensure a power-of-two number of districts, we size the table so 
        // that there is an average of 8 key-value pairs per district, implying 
        // a load factor of ~57 percent.
        let districts:Int = 1 << (exponent - 3)
        // allocate with additional bytes to allow for alignment to 128-byte 
        // cache boundaries
        self.storage    = .create(minimumCapacity: districts << 7 + 0x80){ _ in () }
        self.mask       = (districts &- 1) << 7
        // initialize memory to zero 
        self.withUnsafeMutableAlignedBytes 
        {
            (buffer:UnsafeMutableRawPointer) -> () in
            buffer.initializeMemory(as: UInt8.self, repeating: 0, count: districts << 7)
        }
    }
    
    func find(_ key:UInt32) -> UInt16?
    {
        self.withUnsafeMutableAlignedBytes
        {
            (buffer:UnsafeMutableRawPointer) -> UInt16? in 
            
            let hash:Hash               = .init(key)
            
            let tag:UInt8               = hash.tag,
                start:District.Index    = hash.startIndex(mask: self.mask)
            var current:District.Index  = start
            repeat
            {
                let district:District   = buffer + current, 
                    tagged:UInt16       = district.header.find(tag)
                
                var i:Int = tagged.trailingZeroBitCount
                while i < 14 
                {
                    guard district[i].key == key 
                    else 
                    {
                        // the 7-bit tags matched, but the full key did not.
                        // go to the next matching 7-bit tag.
                        i += 1 + (tagged &>> (i + 1)).trailingZeroBitCount
                        continue 
                    }
                    // key was found. return the value.
                    return district[i].value
                }
                
                if district.displaced == 0 
                {
                    // key was not found, and there have been no additional 
                    // keys displaced from this district. the key is not 
                    // in the dictionary.
                    return nil 
                }
                // key was not found, but this district has displaced keys, so 
                // maybe subsequent districts will contain it. the max probing
                // `stride` is 511 districts, and `stride` is always an odd 
                // number, so it is relatively prime compared to the number 
                // of districts. this means every district will get visited 
                // eventually, should the probing go on long enough.
                current = hash.index(after: current, mask: self.mask)
            } 
            while current != start
            // displacement counts indicated the existence of displaced keys, 
            // but all districts have been searched, so the key is not in the 
            // dictionary. (extremely unlikely.)
            return nil
        }
    }
    
    func remove(key:UInt32, value:UInt16) 
    {
        self.withUnsafeMutableAlignedBytes
        {
            (buffer:UnsafeMutableRawPointer) in 
            
            let hash:Hash               = .init(key)
            
            let tag:UInt8               = hash.tag,
                start:District.Index    = hash.startIndex(mask: self.mask)
            var current:District.Index  = start
            repeat
            {
                let district:District   = buffer + current, 
                    tagged:UInt16       = district.header.find(tag)
                
                var i:Int = tagged.trailingZeroBitCount
                while i < 14 
                {
                    guard district[i].key == key 
                    else 
                    {
                        i += 1 + (tagged &>> (i + 1)).trailingZeroBitCount
                        continue 
                    }
                    
                    guard district[i].value == value 
                    else 
                    {
                        // key was found, but value does not match. 
                        // do nothing.
                        return 
                    }
                    
                    // (key, value) pair was found. delete the pair by 
                    // marking its status as vacant.
                    district.tags[i] = 0
                    
                    // roll down the displacement counts up to, but not 
                    // including the deletion point.
                    while current != start 
                    {
                        current = hash.index(before: current, mask: self.mask)
                        (buffer + current).displaced -= 1
                    }
                    return 
                }
                
                if district.displaced == 0 
                {
                    return 
                }
                
                current = hash.index(after: current, mask: self.mask)
            } 
            while current != start
        }
    } 
    
    @discardableResult
    func update(key:UInt32, value:UInt16) -> UInt16?
    {
        self.withUnsafeMutableAlignedBytes
        {
            (buffer:UnsafeMutableRawPointer) in 
            
            let hash:Hash               = .init(key)
            
            let tag:UInt8               = hash.tag,
                start:District.Index    = hash.startIndex(mask: self.mask)
            var current:District.Index  = start
            repeat
            {
                let district:District   = buffer + current, 
                    tagged:UInt16       = district.header.find(tag)
                
                var i:Int = tagged.trailingZeroBitCount
                while i < 14 
                {
                    guard district[i].key == key 
                    else 
                    {
                        i += 1 + (tagged &>> (i + 1)).trailingZeroBitCount
                        continue 
                    }
                    
                    // key was found. update the value and return the old value
                    let old:UInt16      = district[i].value
                    district[i].value   = value
                    return old 
                }
                
                // key was not found. check for an empty slot 
                let available:UInt16 = district.header.find(0)

                let j:Int = available.trailingZeroBitCount 
                guard j < 14 
                else 
                {
                    // no matching key, or empty slot. maybe there is one in the 
                    // next district over. 
                    current = hash.index(after: current, mask: self.mask) 
                    continue 
                }
                
                // found an empty slot. now we need to check if a matching 
                // (key, value) pair is still in the dictionary, and delete 
                // it if necessary.
                district.tags[j]    = tag
                district[j].key     = key 
                district[j].value   = value
                
                // print("insert(district: \(current.offset), slot: \(j))")
                
                let insertion:District.Index    = current  
                var displaced:UInt16            = district.displaced
                while displaced > 0
                {
                    current = hash.index(after: current, mask: self.mask)
                    
                    guard current != start 
                    else 
                    {
                        // displacement counts indicated the existence of displaced keys, 
                        // but all districts have been searched, so no duplicate key is 
                        // in the dictionary. (extremely unlikely.)
                        break 
                    }
                    
                    let district:District   = buffer + current, 
                        tagged:UInt16       = district.header.find(tag)
                    
                    var i:Int = tagged.trailingZeroBitCount
                    while i < 14 
                    {
                        guard district[i].key == key 
                        else 
                        {
                            i += 1 + (tagged &>> (i + 1)).trailingZeroBitCount
                            continue 
                        }
                        
                        // key was found. delete it, and roll down all the 
                        // displacement counts starting from the insertion point 
                        // up to (but not including) the deletion point 
                        district.tags[i] = 0
                        repeat 
                        {
                            current = hash.index(before: current, mask: self.mask)
                            (buffer + current).displaced -= 1
                        }
                        while current != insertion 
                        
                        return district[i].value
                    }
                    
                    displaced = district.displaced
                } 

                // the inserted key is new to the dictionary. roll up 
                // all the displacement counts up to (but not including)
                // the insertion point.
                current = insertion 
                while current != start  
                {
                    current = hash.index(before: current, mask: self.mask)
                    (buffer + current).displaced += 1
                }
                
                return nil 
            } 
            while current != start
            
            // dictionary has more empty slots than it will ever use (32K), 
            // so it should be impossible to get here 
            fatalError("unreachable")
        }
    } 
    
    private 
    func withUnsafeMutableAlignedBytes<R>(_ body:(UnsafeMutableRawPointer) throws -> R) rethrows -> R 
    {
        try self.storage.withUnsafeMutablePointerToElements 
        {
            (allocation:UnsafeMutablePointer<UInt8>) -> R in 
            
            // can use ! here because a null pointer bitpattern is impossible here
            let aligned:Int = (.init(bitPattern: allocation) &+ 0x7f) & ~0x7f
            let buffer:UnsafeMutableRawPointer = 
                UnsafeMutableRawPointer.init(bitPattern: aligned)!
            return try body(buffer)
        }
    }
}
