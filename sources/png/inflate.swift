/* This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. */

enum LZ77 
{
    enum DecompressionError:Swift.Error
    {
        case truncatedBitstream 
        // stream errors
        case invalidStreamMethod
        case invalidStreamWindowSize(exponent:Int)
        case invalidStreamHeaderCheckBits
        case unexpectedStreamDictionary
        case invalidStreamChecksum
        // block errors 
        case invalidBlockType
        case invalidBlockElementCountParity
        case invalidHuffmanRunLiteralSymbolCount(Int)
        case invalidHuffmanCodelengthHuffmanTable
        case invalidHuffmanCodelengthSequence
        case invalidHuffmanTable
        
        case invalidStringReference
    }
    
    struct Bitstream 
    {
        private 
        var atoms:[UInt16]
        private(set)
        var bytes:Int
        
        var count:Int 
        {
            self.bytes << 3
        }
    }
}
extension LZ77.Bitstream 
{
    // Bitstreams are indexed from LSB to MSB within each atom 
    //      
    // atom 0   16 [ ← ← ← ← ← ← ← ← ]  0
    // atom 1   32 [ ← ← ← ← ← ← ← ← ] 16
    // atom 2   48 [ ← ← ← ← ← ← ← ← ] 32
    // atom 3   64 [ ← ← ← ← ← ← ← ← ] 48
    init(_ data:[UInt8])
    {
        self.atoms = [0x0000, 0x0000, 0x0000]
        self.bytes = 0 
        
        var b:Int  = 0
        self.rebase(data, pointer: &b)
    }
    
    // discards all bits before the pointer `b`
    mutating 
    func rebase(_ data:[UInt8], pointer b:inout Int)  
    {
        guard !data.isEmpty 
        else 
        {
            return 
        }
        
        let a:Int = b >> 4 
        // calculate new buffer size 
        let capacity:Int = (self.atoms.count - a as Int) + 
            (data.count >> 1                     as Int) + 
            // extra word only required if existing stream is even and new data is odd
            (~self.bytes & data.count & 1        as Int)
        
        if a > 0 
        {
            var new:[UInt16] = [] 
            new.reserveCapacity(capacity)
            new.append(contentsOf: self.atoms.dropFirst(a).dropLast(3))
            self.atoms  = new 
            self.bytes -=  2 * a
            b          -= 16 * a
        }
        else 
        {
            self.atoms.reserveCapacity(capacity)
            self.atoms.removeLast(3) // remove padding words
        }
        
        let integral:ArraySlice<UInt8>
        if self.bytes & 1 != 0 
        {
            // odd number of bytes in the stream: move over 1 byte from the new data
            let i:Int = self.bytes >> 1
            self.atoms[i] &= .max           >> 8 
            self.atoms[i] |= .init(data[0]) << 8 
            integral = data.dropFirst()
        }
        else 
        {
            integral = data[...]
        }
        
        for i:Int in stride(from: integral.startIndex, to: integral.endIndex - 1, by: 2)
        {
            self.atoms.append(.init(integral[i + 1]) << 8 | .init(integral[i]))
        }
        if integral.count & 1 != 0
        {
            self.atoms.append(.init(integral[integral.endIndex - 1]))
        }
        self.bytes += data.count
        // 48-bits of padding at the end 
        self.atoms.append(0x0000)
        self.atoms.append(0x0000)
        self.atoms.append(0x0000)
    }
    
    // puts bits in low end of outputted integer 
    // 
    //  { b.15, b.14, b.13, b.12, b.11, b.10, b.9, b.8, b.7, b.6, b.5, b.4, b.3, b.2, b.1, b.0 }
    //                                  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                                                                   ^  
    //                                       [4, count: 6, as: UInt16.self]
    //      produces 
    //  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, b.10, b.9, b.8, b.7, b.6, b.5, b.4}
    subscript<I>(i:Int, count count:Int, as _:I.Type) -> I 
        where I:FixedWidthInteger
    {
        guard count > 0 
        else 
        {
            return .zero 
        }
        
        let a:Int = i >> 4, 
            b:Int = i & 0x0f
        //    a + 2           a + 1             a
        //      [ : : :x:x:x:x:x|x:x: : : : : : ]
        //             ~~~~~~~~~~~~~^
        //            count = 14, b = 12
        //
        //      →               [ :x:x:x:x:x|x:x]
        
        // must use << and not &<< to correctly handle shift of 16
        let interval:UInt16 = self.atoms[a + 1] << (UInt16.bitWidth &- b) | self.atoms[a] &>> b, 
            mask:UInt16     = ~(UInt16.max << count)
        return .init(interval & mask)
    }
    
    subscript(i:Int, as _:UInt16.Type) -> UInt16 
    {
        let a:Int = i >> 4, 
            b:Int = i & 0x0f
        //    a + 2           a + 1             a
        //      [ : :x:x:x:x:x:x|x:x: : : : : : ]
        //           ~~~~~~~~~~~~~~~^
        //            count = 16, b = 12
        //
        //      →   [x:x|x:x:x:x:x:x]
        
        // must use << and not &<< to correctly handle shift of 16
        return self.atoms[a + 1] << (UInt16.bitWidth &- b) | self.atoms[a] &>> b
    }
    // puts bits in high end of outputted integer 
    // 
    //  { ... b.18, b.17, b.16 | b.15, b.14, b.13, b.12, b.11, b.10, b.9, b.8, b.7, b.6, b.5, b.4, b.3, b.2, b.1, b.0 }
    //        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                                                                                           ^  
    //                                                                                          [4]
    //      produces 
    //  { b.4, b.5, b.6, b.7, b.8, b.9, b.10, b.11, b.12, b.13, b.14, b.15, b.16, b.17, b.18 }
    subscript(i:Int) -> UInt16 
    {        
        return Self.reverse(self[i, as: UInt16.self])
    }
    
    // https://graphics.stanford.edu/~seander/bithacks.html#ReverseByteWith64Bits
    @inline(__always)
    static 
    func reverse(_ word:UInt16) -> UInt16 
    {
        Self.reverse(lowBits: word & 0x00ff) << 8 | Self.reverse(lowBits: word >> 8)
    }
    @inline(__always)
    private static 
    func reverse(lowBits byte:UInt16) -> UInt16 
    {
        let u64:UInt64 = .init(byte)
        let fan:UInt64 = ((u64 &* 
            0x00_00_00_00__80_20_08_02) & 
            0x00_00_00_08__84_42_21_10) &* 
            0x00_00_00_01__01_01_01_01
        // select byte 4 
        return .init((fan >> 32) & 0x00_00_00_00__00_00_00_ff as UInt64)
    }
}
extension LZ77.Bitstream:ExpressibleByArrayLiteral 
{
    //  init LZ77.Bitstream.init(arrayLiteral...:)
    //  ?:  Swift.ExpressibleByArrayLiteral 
    //      Creates a bitstream from the given array literal.
    // 
    //      This type stores the bitstream in 16-bit atoms. If the array literal 
    //      does not contain an even number of bytes, the last atom is padded 
    //      with 1-bits.
    //  - arrayLiteral  : Swift.UInt8
    //      The raw bytes making up the bitstream. The more significant bits in 
    //      each byte come first in the bitstream. If the bitstream does not 
    //      correspond to a whole number of bytes, the least significant bits 
    //      in the last byte should be padded with 1-bits.
    init(arrayLiteral:UInt8...) 
    {
        self.init(arrayLiteral)
    }
}

// huffman tables
extension LZ77 
{
    struct Huffman<Symbol> where Symbol:Comparable 
    {
        let symbols:[[Symbol]]
        // these are size parameters generated by the structural validator. 
        // we store them here as proof of tree validity, so that the 
        // constructor for the huffman Decoder type can just read it from here 
        let size:(n:Int, z:Int)
        
        // restrict access to this init 
        private 
        init(symbols:[[Symbol]], size:(n:Int, z:Int)) 
        {
            self.symbols = symbols
            self.size    = size
        }
    }
}
extension LZ77.Huffman 
{
    // determine the value of n, explained in `Huffman.decode()`,
    // as well as the useful size of the table (often, a large region of the high codeword 
    // space is unused so it can be excluded)
    // also validates leaf counts to make sure they define a valid 16-bit tree
    private static
    func size(_ levels:[Int]) -> (n:Int, z:Int)?
    {
        // count the interior nodes 
        var interior:Int = 1 // count the root 
        for leaves:Int in levels[0 ..< 8] 
        {
            guard interior > 0 
            else 
            {
                break
            }
            
            // every interior node on the level above generates two new nodes.
            // some of the new nodes are leaf nodes, the rest are interior nodes.
            interior = 2 * interior - leaves
        }
        
        // the number of interior nodes remaining is the number of child trees
        let n:Int      = 256 - interior 
        var z:Int      = n
        // finish validating the tree 
        for (i, leaves):(Int, Int) in levels[8 ..< 16].enumerated()
        {
            guard interior > 0 
            else 
            {
                break
            }
            
            z       += leaves << (7 - i)
            interior = 2 * interior - leaves 
        }
        
        guard interior == 0
        else 
        {
            return nil
        }
        
        return (n, z)
    }
    
    static 
    func validate<S>(_ assignments:S) -> Self? 
        where S:Sequence, S.Element == (Symbol, Int)
    {
        let groups:[Int: [(Symbol, Int)]] = .init(grouping: assignments, by: \.1)
        let symbols:[[Symbol]] = (1 ... 16).map 
        {
            groups[$0, default: []].map(\.0).sorted()
        }
        return .validate(symbols: symbols)
    }
    
    //  static func LZ77.Huffman.validate(symbols:)
    //      Creates a huffman tree from the given leaf nodes.
    //  
    //      This initializer determines the shape of the tree from the shape of 
    //      the leaf array input. It has no knowledge of symbol frequencies or 
    //      priority. 
    //  
    //      This initializer will return `nil` if the sizes of the given leaf arrays do not 
    //      describe a [full binary tree](https://en.wikipedia.org/wiki/Binary_tree#full). 
    //
    //      For example, the leaf counts (3,\ 0,\ 0,\ …\ ) are invalid because 
    //      no binary tree can have three leaf nodes in its first level.
    //
    //      The exception is the single-symbol huffman tree, which is allowed to 
    //      have one symbol in its first level. 
    //  - symbols   : [[Symbol]]
    //      The leaf nodes in each level of the tree. The tree root is always 
    //      assumed to be internal, so the 0th sub-array of this array should 
    //      contain the leaves in the first level of the tree. This array must 
    //      contain 16 sub-arrays, even if the deeper levels of the tree are 
    //      empty, or this initializer will suffer a precondition failure.
    static 
    func validate(symbols:[[Symbol]]) -> Self?
    {
        let padded:[[Symbol]]
        if symbols[0].count == 1, (symbols[1...].allSatisfy{ $0.count == 0 })
        {
            // handle single-symbol case 
            padded = [[symbols[0][0], symbols[0][0]]] + repeatElement([], count: 15)
        }
        else 
        {
            padded = symbols 
        }
        
        // validate leaf counts 
        guard let size:(n:Int, z:Int) = Self.size(padded.map(\.count))
        else 
        {
            return nil
        }
        
        return .init(symbols: padded, size: size)
    } 
    
    // non validating initializer, crashes on invalid input 
    init(symbols:[[Symbol]]) 
    {
        guard let size:(n:Int, z:Int) = Self.size(symbols.map(\.count))
        else 
        {
            preconditionFailure("invalid huffman table leaf list")
        }
        self.init(symbols: symbols, size: size)
    }
    
    // decoder type 
    struct Decoder 
    {
        struct Entry 
        {
            let symbol:Symbol
            @General.Storage<UInt8> 
            var length:Int 
        }
        
        private 
        let storage:[Entry], 
            n:Int // number of level 0 entries
        
        init(_ storage:[Entry], n:Int) 
        {
            self.storage    = storage 
            self.n          = n
        }
    }
    
    func decoder() -> Decoder
    {
        // z is the physical size of the table in memory
        let (n, z):(Int, Int) = self.size 
        
        var storage:[Decoder.Entry] = []
            storage.reserveCapacity(z)
        
        for (l, symbols):(Int, [Symbol]) in self.symbols.enumerated()
        {
            guard storage.count < z 
            else 
            {
                break
            }            
            
            let clones:Int  = 0x8080 >> l & 0xff
            for symbol:Symbol in symbols 
            {
                let entry:Decoder.Entry = .init(symbol: symbol, length: l + 1)
                storage.append(contentsOf: repeatElement(entry, count: clones))
            }
        }
        
        assert(storage.count == z)
        //print("created huffman decoder (size \(storage.count * MemoryLayout<Decoder.Entry>.stride) bytes)")
        return .init(storage, n: n)
    }
}
// table accessors 
extension LZ77.Huffman.Decoder 
{
    // codeword is big-endian
    subscript(codeword:UInt16) -> Entry 
    {
        // [ level 0 index  |    offset    ]
        let i:Int = .init(codeword >> 8)
        if i < self.n 
        {
            return self.storage[i]
        }
        else 
        {
            let j:Int = .init(codeword)
            return self.storage[j - self.n * 255]
        }
    }
}

// symbol types 
extension LZ77 
{    
    enum Symbol 
    {
        //  from the RFC 1951: 
        //  0 - 15: Represent code lengths of 0 - 15
        //      16: Copy the previous code length 3 - 6 times.
        //          The next 2 bits indicate repeat length
        //                (0 = 3, ... , 3 = 6)
        //             Example:  Codes 8, 16 (+2 bits 11),
        //                       16 (+2 bits 10) will expand to
        //                       12 code lengths of 8 (1 + 6 + 5)
        //      17: Repeat a code length of 0 for 3 - 10 times.
        //          (3 bits of length)
        //      18: Repeat a code length of 0 for 11 - 138 times
        //          (7 bits of length)
        enum CodeLength:Comparable
        {
            // use smaller integers to reduce LUT footprint
            case literal(UInt8)
            case extend 
            case zeros3
            case zeros7
            
            //  let allSymbols:[Self] = 
            //      (0 ..< 16).map(Self.literal(_:)) + [.extend, .zeros3, .zeros7]
        }
        
        enum RunLiteral:Comparable
        {
            case literal(UInt8)
            case end 
            case run(Run)
            
            static 
            let allSymbols:[Self] = 
                (0 ... 255).map(Self.literal(_:)) + 
                [.end] + 
                (0 ...  28).map(Self.run(_:))
            
            static 
            func run(_ run:Int) -> Self 
            {
                .run(.init(run: run))
            }
            
            struct Run:Comparable
            {
                private static 
                let decades:[(extra:Int, base:Int)] = 
                [
                    (0,   3),
                    (0,   4),
                    (0,   5),
                    (0,   6),
                    (0,   7),
                    
                    (0,   8),
                    (0,   9),
                    (0,  10),
                    (1,  11),
                    (1,  13),
                    
                    (1,  15),
                    (1,  17),
                    (2,  19),
                    (2,  23),
                    (2,  27),
                    
                    (2,  31),
                    (3,  35),
                    (3,  43),
                    (3,  51),
                    (3,  59),
                    
                    (4,  67),
                    (4,  83),
                    (4,  99),
                    (4, 115),
                    (5, 131),
                    
                    (5, 163),
                    (5, 195),
                    (5, 227),
                    (0, 258),
                    
                    // padding values, because out-of-bounds symbols occur
                    // in fixed huffman trees, and may be erroneously decoded 
                    // if the decoder goes beyond the end-of-stream (which it is 
                    // temporarily allowed to do, for performance)
                    (0,   0),
                    (0,   0),
                ]
                
                @General.Storage<UInt8> 
                var run:Int 
                
                var decade:(extra:Int, base:Int) 
                {
                    Self.decades[self.run]
                }
                
                static 
                func < (lhs:Self, rhs:Self) -> Bool 
                {
                    lhs.run < rhs.run
                }
            }
        }
        
        // namespace for the decades LUT 
        struct Distance:Comparable
        {
            private static 
            let decades:[(extra:Int, base:Int)] = 
            [
                ( 0,     1),
                ( 0,     2),
                ( 0,     3),
                ( 0,     4),
                ( 1,     5),
                
                ( 1,     7),
                ( 2,     9),
                ( 2,    13),
                ( 3,    17),
                ( 3,    25),
                
                ( 4,    33),
                ( 4,    49),
                ( 5,    65),
                ( 5,    97),
                ( 6,   129),
                
                ( 6,   193),
                ( 7,   257),
                ( 7,   385),
                ( 8,   513),
                ( 8,   769),
                
                ( 9,  1025),
                ( 9,  1537),
                (10,  2049),
                (10,  3073),
                (11,  4097),
                
                (11,  6145),
                (12,  8193),
                (12, 12289),
                (13, 16385),
                (13, 24577),
                
                // padding values, because out-of-bounds symbols occur
                // in fixed huffman trees, and may be erroneously decoded 
                // if the decoder goes beyond the end-of-stream (which it is 
                // temporarily allowed to do, for performance)
                ( 0,     0),
                ( 0,     0),
            ]
            
            @General.Storage<UInt8> 
            var distance:Int 
            
            var decade:(extra:Int, base:Int) 
            {
                Self.decades[self.distance]
            }
            
            init(_ distance:Int) 
            {
                self._distance = .init(wrappedValue: distance)
            }
            
            static 
            func < (lhs:Self, rhs:Self) -> Bool 
            {
                lhs.distance < rhs.distance
            }
        }
    }
}
// fixed trees 
extension LZ77.Huffman.Decoder where Symbol == LZ77.Symbol.RunLiteral 
{
    static 
    let fixed:Self = LZ77.Huffman<Symbol>.init(symbols: 
    [
        // L1 ... L6
        [], [], [], [], [], [], 
        // L7 
        [.end] + 
        (  0 ...  22).map(LZ77.Symbol.RunLiteral.run(_:)),
        // L8
        (  0 ... 143).map(LZ77.Symbol.RunLiteral.literal(_:)) + 
        ( 23 ...  30).map(LZ77.Symbol.RunLiteral.run(_:)), 
        // L9
        (144 ... 255).map(LZ77.Symbol.RunLiteral.literal(_:)), 
        // L10 ... L16
        [], [], [], [], [], [], []
    ]).decoder()
}
extension LZ77.Huffman.Decoder where Symbol == LZ77.Symbol.Distance 
{
    static 
    let fixed:Self = LZ77.Huffman<Symbol>.init(symbols: 
    [
        // L1 ... L4
        [], [], [], [], 
        // L5 
        (  0 ...  31).map(LZ77.Symbol.Distance.init(_:)),
        // L6 ... L16
        [], [], [], [], [], [], [], [], [], [], []
    ]).decoder()
}

extension FixedWidthInteger 
{
    // rounds up to the next power of two, with 0 rounding up to 1. 
    // numbers that are already powers of two return themselves
    @inline(__always)
    var nextPowerOfTwo:Self 
    {
        1 &<< (Self.bitWidth &- (self &- 1).leadingZeroBitCount)
    }
}
extension LZ77 
{
    enum Compression  
    {
        case none(bytes:Int)
        case fixed 
        case dynamic(Huffman<Symbol.CodeLength>, count:(runliteral:Int, distance:Int))
    }
    struct Buffer 
    {
        var window:Int
         
        private(set)
        var baseIndex:Int,
            startIndex:Int, 
            currentIndex:Int,
            endIndex:Int 
        // storing this instead of using `ManagedBuffer.capacity` because 
        // the apple docs said so
        private 
        var capacity:Int, 
            storage:ManagedBuffer<Void, UInt8>
        
        var count:Int 
        {
            self.endIndex - self.startIndex
        }
        
        init() 
        {
            var capacity:Int    = 0
            self.storage = .create(minimumCapacity: 0)
            {
                capacity = $0.capacity 
                return ()
            }
            self.window         = 0
            self.baseIndex      = 0
            self.startIndex     = 0
            self.currentIndex   = 0
            self.endIndex       = 0
            self.capacity       = capacity
        }
        
        mutating 
        func release(bytes count:Int) -> [UInt8]? 
        {
            self.storage.withUnsafeMutablePointerToElements  
            {
                guard self.endIndex >= self.currentIndex + count 
                else 
                {
                    return nil 
                }
                
                let i:Int = self.currentIndex - self.baseIndex
                let slice:UnsafeBufferPointer<UInt8>    = .init(start: $0 + i, count: count)
                defer 
                {
                    let limit:Int       = Swift.max(self.endIndex - self.window, self.startIndex)
                    self.currentIndex  += count 
                    self.startIndex     = Swift.min(self.currentIndex, limit)
                }
                return .init(slice)
            }
        }

        mutating 
        func append(_ value:UInt8) 
        {
            self.reserve(1)
            self.storage.withUnsafeMutablePointerToElements 
            {
                $0[self.endIndex &- self.baseIndex] = value 
            }
            self.endIndex &+= 1
        }
        mutating 
        func expand(offset:Int, count:Int) 
        {
            self.reserve(count)
            self.storage.withUnsafeMutablePointerToElements 
            {
                let (q, r):(Int, Int) = count.quotientAndRemainder(dividingBy: offset)
                let front:UnsafeMutablePointer<UInt8> = $0 + (self.endIndex &- self.baseIndex)
                for i:Int in 0 ..< q
                {
                    (front + i &* offset).initialize(from: front - offset, count: offset)
                }
                (front + q &* offset).initialize(from: front - offset, count: r)
            }
            self.endIndex &+= count
        }
        
        @inline(__always)
        private mutating 
        func reserve(_ count:Int) 
        {
            if self.capacity < self.endIndex &- self.baseIndex &+ count 
            {
                self.shift(allocating: count)
            }
        }
        // may discard array elements before `startIndex`, adjusts capacity so that 
        // at least one more byte can always be written without a reallocation
        private mutating 
        func shift(allocating extra:Int) 
        {
            // optimal new capacity
            let count:Int       = self.count, 
                capacity:Int    = (count + Swift.max(16, extra)).nextPowerOfTwo
            if self.capacity >= capacity 
            {
                // rebase without reallocating 
                self.storage.withUnsafeMutablePointerToElements 
                {
                    let vacant:Int = self.startIndex - self.baseIndex
                    $0.initialize(from: $0 + vacant, count: count)
                    self.baseIndex = self.startIndex
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
                        let vacant:Int = self.startIndex - self.baseIndex
                        $0.initialize(from: $0 + vacant, count: count)
                    }
                    self.baseIndex = self.startIndex
                    return new 
                }
            }
        }
    }
    /* struct _Buffer:RandomAccessCollection
    {
        var window:Int 
        private 
        var baseIndex:Int
        private(set) 
        var startIndex:Int, 
            currentIndex:Int
        var endIndex:Int 
        {
            self.baseIndex + self.storage.count 
        }
        private 
        var storage:[UInt8]
        private
        var integral:(single:UInt32, double:UInt32)
        
        var checksum:UInt32 
        {
            self.integral.double << 16 | self.integral.single
        }
        
        subscript(index:Int) -> UInt8 
        {
            self.storage[index - self.baseIndex]
        }
        
        init() 
        {
            self.window         = 0
            self.baseIndex      = 0
            self.startIndex     = 0
            self.currentIndex   = 0
            self.storage        = []
            self.integral       = (1, 0)
        }
        
        mutating 
        func release(bytes count:Int) -> [UInt8]? 
        {
            guard self.endIndex >= self.currentIndex + count 
            else 
            {
                return nil 
            }
            
            let i:Int = self.currentIndex - self.baseIndex
            defer 
            {
                let limit:Int       = Swift.max(self.endIndex - self.window, self.startIndex)
                self.currentIndex  += count 
                self.startIndex     = Swift.min(self.currentIndex, limit)
            }
            return .init(self.storage[i ..< i + count])
        }
        mutating 
        func append(_ value:UInt8) 
        {
            while self.storage.capacity < self.storage.count + 1 
            {
                self.shift(allocating: 1)
            }
            self.storage.append(value)
            // update checksums. additions have to be done 32-bit because 65520 + 255 
            // overflows a UInt16 
            self.integral.single = (self.integral.single &+         .init(value)) % 65521
            self.integral.double = (self.integral.double &+ self.integral.single) % 65521
        }
        mutating 
        func _reserve(_ count:Int) 
        {
            while self.storage.capacity < self.storage.count + count 
            {
                self.shift(allocating: count)
            }
        }
        mutating 
        func _append(_ value:UInt8) 
        {
            self.storage.append(value)
            // self.integral.single = (self.integral.single &+         .init(value)) % 65521
            // self.integral.double = (self.integral.double &+ self.integral.single) % 65521
        }
        // may discard array elements before `startIndex`, adjusts capacity so that 
        // at least one more byte can always be written without a reallocation
        private mutating 
        func shift(allocating extra:Int) 
        {
            // optimal new capacity
            let count:Int       = self.count, 
                capacity:Int    = (count + Swift.max(16, extra)).nextPowerOfTwo
            let vacant:Int      = self.startIndex - self.baseIndex
            if self.storage.capacity >= capacity 
            {
                // rebase without reallocating 
                self.storage.withUnsafeMutableBufferPointer 
                {
                    $0.baseAddress?.initialize(from: $0.baseAddress! + vacant, count: count)
                    //for i:Int in 0 ..< count
                    //{
                    //    $0[i] = $0[i + vacant]
                    //}
                }
                // remove duplicated elements at the end 
                self.storage.removeLast(vacant)
            }
            else 
            {
                var new:[UInt8] = []
                new.reserveCapacity(capacity)
                new.append(contentsOf: self.storage.dropFirst(vacant))
                self.storage = new
            }
            self.baseIndex = self.startIndex 
        }
    } */
    
    struct Inflator 
    {
        private 
        enum State 
        {
            case streamStart 
            case blockStart
            case blockTables(
                final:Bool, 
                table:Huffman<Symbol.CodeLength>.Decoder,
                count:(runliteral:Int, distance:Int)
            )
            case blockUncompressed(final:Bool, end:Int)
            case blockCompressed(
                final:Bool, 
                table:
                (
                    runliteral:Huffman<Symbol.RunLiteral>.Decoder, 
                    distance:Huffman<Symbol.Distance>.Decoder
                )
            )
            case streamChecksum
            case streamEnd 
            
            /* var _description:String 
            {
                switch self 
                {
                case .streamStart:
                    return "stream start"
                case .blockStart:
                    return "block start"
                case .blockTables(final: let final, table: _, count: _):
                    return "block tables (final: \(final))"
                case .blockUncompressed(final: let final, end: let end):
                    return "block uncompressed (final: \(final), end: \(end))"
                case .blockCompressed(final: let final, table: _):
                    return "block compressed (final: \(final))"
                case .streamChecksum:
                    return "stream checksum"
                case .streamEnd:
                    return "stream end"
                }
            } */
        }
        
        struct Stream 
        {
            var input:Bitstream, 
                b:Int 
            var lengths:[Int]
            var output:Buffer 
        }
        
        private 
        var state:State, 
            stream:Stream 
    }
}
extension LZ77.Inflator.Stream 
{
    init() 
    {
        self.b          = 0
        self.input      = []
        self.lengths    = []
        self.output     = .init()
    }
}
extension LZ77.Inflator
{
    init() 
    {
        self.state  = .streamStart
        self.stream = .init()
    }
    
    // returns `nil` if the stream is finished
    mutating 
    func push(_ data:[UInt8]) throws -> Void?
    {
        self.stream.input.rebase(data, pointer: &self.stream.b)
        while let _:Void = try self.advance() 
        {
        }
        if case .streamEnd = self.state 
        {
            return nil 
        }
        else 
        {
            return ()
        }
    }
    mutating 
    func pull(_ count:Int) -> [UInt8]? 
    {
        self.stream.output.release(bytes: count)
    }
    var retained:Int 
    {
        self.stream.output.endIndex - self.stream.output.currentIndex
    }
    // returns nil if unable to advance 
    private mutating 
    func advance() throws -> Void?
    {
        switch self.state 
        {
        case .streamStart:
            guard let window:Int = try self.stream.start()
            else 
            {
                return nil
            }
            self.stream.output.window   = window 
            self.state                  = .blockStart
        
        case .blockStart:
            guard let (final, compression):(Bool, LZ77.Compression) = try self.stream.blockStart() 
            else 
            {
                return nil 
            }
            
            switch compression 
            {
            case .dynamic(let table, count: let count):
                self.state = .blockTables(final: final, table: table.decoder(), count: count)
            
            case .fixed:
                self.state = .blockCompressed(final: final, table: (.fixed, .fixed))
            
            case .none(bytes: let count):
                // compute endindex 
                let end:Int = self.stream.output.endIndex + count
                self.state = .blockUncompressed(final: final, end: end)
            }
        
        case .blockTables(final: let final, table: let table, count: let count):
            guard let (runliteral, distance):
            (
                LZ77.Huffman<LZ77.Symbol.RunLiteral>, 
                LZ77.Huffman<LZ77.Symbol.Distance>
            ) = try self.stream.blockTables(table: table, count: count) 
            else 
            {
                return nil
            }
            self.state = .blockCompressed(final: final, 
                table: (runliteral.decoder(), distance.decoder()))
        
        case .blockUncompressed(final: let final, end: let end):
            guard let _:Void = try self.stream.blockUncompressed(end: end) 
            else 
            {
                return nil
            }
            self.state = final ? .streamChecksum : .blockStart
        
        case .blockCompressed(final: let final, table: let table):
            guard let _:Void = try self.stream.blockCompressed(table: table) 
            else 
            {
                return nil
            }
            self.state = final ? .streamChecksum : .blockStart
        
        case .streamChecksum:
            guard let _:Void = try self.stream.checksum()
            else 
            {
                return nil 
            }
            self.state = .streamEnd 
        case .streamEnd:
            return nil 
        }
        
        return ()
    }
}
extension LZ77.Inflator.Stream 
{
    mutating 
    func start() throws -> Int?
    {
        // read stream header 
        guard self.b + 16 <= self.input.count 
        else 
        {
            return nil 
        }
        
        switch self.input[self.b + 0, count: 4, as: UInt.self] 
        {
        case 8:
            break 
        default:
            throw LZ77.DecompressionError.invalidStreamMethod
        }
        
        let exponent:Int = self.input[self.b + 4, count: 4, as: Int.self] 
        guard exponent < 8 
        else 
        {
            throw LZ77.DecompressionError.invalidStreamWindowSize(exponent: exponent)
        }
        
        let flags:Int = self.input[self.b + 8, count: 8, as: Int.self]
        guard (exponent << 12 | 8 << 8 + flags) % 31 == 0 
        else 
        {
            throw LZ77.DecompressionError.invalidStreamHeaderCheckBits
        }
        guard flags & 0x20 == 0 
        else 
        {
            throw LZ77.DecompressionError.unexpectedStreamDictionary
        }
        
        self.b += 16
        return 1 << (8 + exponent)
    }
    mutating 
    func blockStart() throws -> 
    (
        final:Bool, 
        compression:LZ77.Compression
    )? 
    {
        guard self.b + 3 <= self.input.count 
        else 
        {
            return nil 
        }
        
        // read block header bits 
        let final:Bool = self.input[self.b, count: 1, as: UInt16.self] != 0 
        let compression:LZ77.Compression 
        switch self.input[self.b + 1, count: 2, as: UInt16.self] 
        {
        case 0:
            // skip to next byte boundary, read 4 bytes 
            let boundary:Int = (self.b + 3 + 7) & ~7
            guard boundary + 32 <= self.input.count 
            else 
            {
                return nil 
            }
            
            let l:UInt16 = self.input[boundary,      count: 16, as: UInt16.self],
                m:UInt16 = self.input[boundary + 16, count: 16, as: UInt16.self]
            guard l == ~m 
            else 
            {
                throw LZ77.DecompressionError.invalidBlockElementCountParity
            }
            
            compression = .none(bytes: .init(l))
            self.b  = boundary + 32
        
        case 1:
            compression = .fixed 
            self.b += 3
        
        case 2:
            guard self.b + 17 <= self.input.count 
            else 
            {
                return nil 
            }
        
            let codelengths:Int =   4 + self.input[self.b + 13, count: 4, as: Int.self]
            
            guard self.b + 17 + 3 * codelengths <= self.input.count 
            else 
            {
                return nil 
            }
            
            let runliteral:Int  = 257 + self.input[self.b +  3, count: 5, as: Int.self]
            let distance:Int    =   1 + self.input[self.b +  8, count: 5, as: Int.self]
            // other counts don’t need to be checked because the number of bits 
            // matches the acceptable range 
            guard 257 ... 286 ~= runliteral 
            else 
            {
                throw LZ77.DecompressionError.invalidHuffmanRunLiteralSymbolCount(runliteral)
            }
            
            let symbols:[LZ77.Symbol.CodeLength] = 
            [
                .extend, 
                .zeros3,
                .zeros7,
                .literal( 0), 
                .literal( 8), .literal( 7), 
                .literal( 9), .literal( 6), 
                .literal(10), .literal( 5), 
                .literal(11), .literal( 4), 
                .literal(12), .literal( 3), 
                .literal(13), .literal( 2), 
                .literal(14), .literal( 1), 
                .literal(15), 
            ]
            guard let table:LZ77.Huffman<LZ77.Symbol.CodeLength> = .validate(
                (0 ..< codelengths).map 
            {
                (symbols[$0], self.input[self.b + 17 + 3 * $0, count: 3, as: Int.self])
            })
            else 
            {
                throw LZ77.DecompressionError.invalidHuffmanCodelengthHuffmanTable 
            }
            
            self.b += 17 + 3 * codelengths
            compression = .dynamic(table, count: (runliteral, distance))
        
        default:
            throw LZ77.DecompressionError.invalidBlockType
        }
        
        return (final, compression)
    }
    mutating 
    func blockTables(table:LZ77.Huffman<LZ77.Symbol.CodeLength>.Decoder, 
        count:(runliteral:Int, distance:Int)) 
        throws -> 
    (
        LZ77.Huffman<LZ77.Symbol.RunLiteral>, 
        LZ77.Huffman<LZ77.Symbol.Distance>
    )?
    {
        // code lengths form an unbroken sequence 
        codelengths:
        while self.lengths.count < count.runliteral + count.distance 
        {
            guard self.b < self.input.count 
            else 
            {
                return nil 
            }
            
            let entry:LZ77.Huffman<LZ77.Symbol.CodeLength>.Decoder.Entry = 
                table[self.input[self.b]]
            // if the codeword length is longer than the available input 
            // then we know the match is invalid (due to padding 0-bits)
            guard self.b + entry.length <= self.input.count 
            else 
            {
                return nil 
            }
            
            let element:Int, 
                extra:Int, 
                base:Int
            switch entry.symbol 
            {
            case .literal(let length):
                self.lengths.append(.init(length))
                self.b += entry.length
                continue codelengths
            
            case .extend:
                guard let last:Int = self.lengths.last 
                else 
                {
                    throw LZ77.DecompressionError.invalidHuffmanCodelengthSequence
                }
                element = last 
                extra   = 2
                base    = 3
            case .zeros3:
                element = 0 
                extra   = 3
                base    = 3
            case .zeros7:
                element = 0 
                extra   = 7
                base    = 11
            }
            
            guard self.b + entry.length + extra <= self.input.count 
            else 
            {
                return nil 
            }
            let repetitions:Int = base + 
                self.input[self.b + entry.length, count: extra, as: Int.self]
            
            self.lengths.append(contentsOf: repeatElement(element, count: repetitions))
            self.b += entry.length + extra 
        }
        defer 
        {
            // important
            self.lengths.removeAll(keepingCapacity: true)
        }
        guard self.lengths.count == count.runliteral + count.distance 
        else 
        {
            throw LZ77.DecompressionError.invalidHuffmanCodelengthSequence
        }
        
        guard let runliteral:LZ77.Huffman<LZ77.Symbol.RunLiteral> = .validate(
            zip(LZ77.Symbol.RunLiteral.allSymbols, self.lengths.prefix(count.runliteral)))
        else 
        {
            throw LZ77.DecompressionError.invalidHuffmanTable 
        }
        
        let distance:LZ77.Huffman<LZ77.Symbol.Distance>
        if (self.lengths.dropFirst(count.runliteral).allSatisfy{ $0 == 0 })
        {
            distance = .init(symbols: [[.init(0), .init(0)]] + repeatElement([], count: 15)) 
        }
        else if let table:LZ77.Huffman<LZ77.Symbol.Distance> = .validate(zip(
                (0 ... 31).map(LZ77.Symbol.Distance.init(_:)), 
                self.lengths.dropFirst(count.runliteral)))
        {
            distance = table 
        }
        else 
        {
            throw LZ77.DecompressionError.invalidHuffmanTable 
        }
        
        return (runliteral, distance)
    }
    mutating 
    func blockCompressed(table:
        (
            runliteral:LZ77.Huffman<LZ77.Symbol.RunLiteral>.Decoder, 
            distance:LZ77.Huffman<LZ77.Symbol.Distance>.Decoder
        )) throws -> Void? 
    {
        while self.b < self.input.count 
        {
            //  one token (either a literal, or a length-distance pair with extra bits)
            //  never requires more than 48 bits of input:
            //  
            //  first codeword  : 15 bits 
            //  first extras    :  5 bits 
            //  second codeword : 15 bits 
            //  second extras   : 13 bits 
            //  -------------------------
            //  total           : 48 bits 
            let first:UInt16 = self.input[self.b, as: UInt16.self]
            let entry:LZ77.Huffman<LZ77.Symbol.RunLiteral>.Decoder.Entry = 
                table.runliteral[LZ77.Bitstream.reverse(first)]
            
            switch entry.symbol 
            {
            case .literal(let literal):
                guard self.b + entry.length <= self.input.count 
                else 
                {
                    return nil 
                }
                self.b += entry.length 
                self.output.append(literal)
                
            case .end:
                guard self.b + entry.length <= self.input.count 
                else 
                {
                    return nil 
                }
                self.b += entry.length 
                return () 
            
            case .run(let run):
                // get the next two words to form a 48-bit value 
                // (in the low bits bits of a UInt64)
                // we put it in the low bits so that we can do masking shifts instead 
                // of checked shifts 
                var slug:UInt64 = 
                    .init(self.input[self.b + 32, as: UInt16.self]) << 32 |
                    .init(self.input[self.b + 16, as: UInt16.self]) << 16 | 
                    .init(first)
                slug &>>= entry.length
                
                let decade:
                (
                    count:(extra:Int, base:Int),
                    offset:(extra:Int, base:Int)
                )
                
                decade.count        = run.decade 
                let count:Int       = decade.count.base &+ 
                    .init(truncatingIfNeeded: slug & ~(.max &<< decade.count.extra))
                
                slug &>>= decade.count.extra
                
                let distance:LZ77.Huffman<LZ77.Symbol.Distance>.Decoder.Entry = 
                    table.distance[LZ77.Bitstream.reverse(.init(truncatingIfNeeded: slug))]
                slug &>>= distance.length
                
                decade.offset       = distance.symbol.decade 
                let offset:Int      = decade.offset.base &+ 
                    .init(truncatingIfNeeded: slug & ~(.max &<< decade.offset.extra))
                
                let b:Int = self.b  + 
                    entry.length    + decade.count.extra + 
                    distance.length + decade.offset.extra 
                guard b <= self.input.count 
                else 
                {
                    return nil 
                }
                
                guard self.output.endIndex - offset >= self.output.startIndex 
                else 
                {
                    throw LZ77.DecompressionError.invalidStringReference
                }
                
                self.output.expand(offset: offset, count: count)
                self.b = b
            }
        }
        return nil
    }
    mutating 
    func blockUncompressed(end:Int) throws -> Void? 
    {
        while self.output.endIndex < end
        {
            guard self.b + 8 <= self.input.count 
            else 
            {
                return nil 
            }
            self.output.append(self.input[self.b, count: 8, as: UInt8.self])
            self.b += 8
        }
        
        return ()
    }
    mutating 
    func checksum() throws -> Void?
    {
        // skip to next byte boundary, read 4 bytes 
        let boundary:Int = (self.b + 7) & ~7
        guard boundary + 32 <= self.input.count 
        else 
        {
            return nil 
        }
        
        // adler 32 is big-endian 
        // let bytes:(UInt32, UInt32, UInt32, UInt32) = 
        // (
        //     self.input[boundary,      count: 8, as: UInt32.self],
        //     self.input[boundary +  8, count: 8, as: UInt32.self],
        //     self.input[boundary + 16, count: 8, as: UInt32.self],
        //     self.input[boundary + 24, count: 8, as: UInt32.self]
        // )
        // let checksum:UInt32   = bytes.0 << 24 |
        //                         bytes.1 << 16 |
        //                         bytes.2 <<  8 |
        //                         bytes.3
        // guard self.output.checksum == checksum
        // else 
        // {
        //     throw LZ77.DecompressionError.invalidStreamChecksum
        // } 
        self.b = boundary + 32
        return ()
    }
}
