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
        // fastest bit twiddle in the west,, now that i measured it
        // now i know why everyone at apple asks this same coding interview question
        let reversed:[UInt8] =
        [
          0x00, 0x80, 0x40, 0xC0, 0x20, 0xA0, 0x60, 0xE0, 0x10, 0x90, 0x50, 0xD0, 0x30, 0xB0, 0x70, 0xF0,
          0x08, 0x88, 0x48, 0xC8, 0x28, 0xA8, 0x68, 0xE8, 0x18, 0x98, 0x58, 0xD8, 0x38, 0xB8, 0x78, 0xF8,
          0x04, 0x84, 0x44, 0xC4, 0x24, 0xA4, 0x64, 0xE4, 0x14, 0x94, 0x54, 0xD4, 0x34, 0xB4, 0x74, 0xF4,
          0x0C, 0x8C, 0x4C, 0xCC, 0x2C, 0xAC, 0x6C, 0xEC, 0x1C, 0x9C, 0x5C, 0xDC, 0x3C, 0xBC, 0x7C, 0xFC,
          0x02, 0x82, 0x42, 0xC2, 0x22, 0xA2, 0x62, 0xE2, 0x12, 0x92, 0x52, 0xD2, 0x32, 0xB2, 0x72, 0xF2,
          0x0A, 0x8A, 0x4A, 0xCA, 0x2A, 0xAA, 0x6A, 0xEA, 0x1A, 0x9A, 0x5A, 0xDA, 0x3A, 0xBA, 0x7A, 0xFA,
          0x06, 0x86, 0x46, 0xC6, 0x26, 0xA6, 0x66, 0xE6, 0x16, 0x96, 0x56, 0xD6, 0x36, 0xB6, 0x76, 0xF6,
          0x0E, 0x8E, 0x4E, 0xCE, 0x2E, 0xAE, 0x6E, 0xEE, 0x1E, 0x9E, 0x5E, 0xDE, 0x3E, 0xBE, 0x7E, 0xFE,
          0x01, 0x81, 0x41, 0xC1, 0x21, 0xA1, 0x61, 0xE1, 0x11, 0x91, 0x51, 0xD1, 0x31, 0xB1, 0x71, 0xF1,
          0x09, 0x89, 0x49, 0xC9, 0x29, 0xA9, 0x69, 0xE9, 0x19, 0x99, 0x59, 0xD9, 0x39, 0xB9, 0x79, 0xF9,
          0x05, 0x85, 0x45, 0xC5, 0x25, 0xA5, 0x65, 0xE5, 0x15, 0x95, 0x55, 0xD5, 0x35, 0xB5, 0x75, 0xF5,
          0x0D, 0x8D, 0x4D, 0xCD, 0x2D, 0xAD, 0x6D, 0xED, 0x1D, 0x9D, 0x5D, 0xDD, 0x3D, 0xBD, 0x7D, 0xFD,
          0x03, 0x83, 0x43, 0xC3, 0x23, 0xA3, 0x63, 0xE3, 0x13, 0x93, 0x53, 0xD3, 0x33, 0xB3, 0x73, 0xF3,
          0x0B, 0x8B, 0x4B, 0xCB, 0x2B, 0xAB, 0x6B, 0xEB, 0x1B, 0x9B, 0x5B, 0xDB, 0x3B, 0xBB, 0x7B, 0xFB,
          0x07, 0x87, 0x47, 0xC7, 0x27, 0xA7, 0x67, 0xE7, 0x17, 0x97, 0x57, 0xD7, 0x37, 0xB7, 0x77, 0xF7,
          0x0F, 0x8F, 0x4F, 0xCF, 0x2F, 0xAF, 0x6F, 0xEF, 0x1F, 0x9F, 0x5F, 0xDF, 0x3F, 0xBF, 0x7F, 0xFF
        ]
        return .init(reversed[.init(word & 0x00ff)]) << 8 | .init(reversed[.init(word >> 8)])
        /*
        let low:UInt64  = .init(word & 0x00ff),
            high:UInt64 = .init(word >> 8)
        let a:UInt64    = ((low &*
            0x00_00_00_00__80_20_08_02) &
            0x00_00_00_08__84_42_21_10) &*
            0x00_00_00_01__01_01_01_01
        let b:UInt64    = ((high &*
            0x00_00_00_00__80_20_08_02) &
            0x00_00_00_08__84_42_21_10) &*
            0x00_00_00_01__01_01_01_01
        // select byte 4
        return .init(truncatingIfNeeded: a >> 24 & 0xff00 | b >> 32 & 0x00ff)
        */
        /*
        // swap adjacent bits   (0101)
        let v1:UInt16 = word >> 1 & 0b0101_0101_0101_0101 | (word & 0b0101_0101_0101_0101) << 1
        // swap pairs           (0011)
        let v2:UInt16 = v1   >> 2 & 0b0011_0011_0011_0011 | (v1   & 0b0011_0011_0011_0011) << 2
        // swap half-bytes
        let v4:UInt16 = v2   >> 4 & 0b0000_1111_0000_1111 | (v2   & 0b0000_1111_0000_1111) << 4
        // swap bytes
        return          v4   >> 8                         |  v4                            << 8
         */
    }
    /* @inline(__always)
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
    }*/
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
    
    private static
    func group<S>(_ assignments:S) -> [[Symbol]]
        where S:Sequence, S.Element == (Symbol, Int)
    {
        var groups:[[Symbol]] = .init(repeating: [], count: 16)
        for (symbol, length):(Symbol, Int) in assignments where length > 0
        {
            groups[length - 1].append(symbol)
        }
        return groups
    }
    
    static
    func validate<S>(_ assignments:S) -> Self? 
        where S:Sequence, S.Element == (Symbol, Int)
    {
        return .validate(symbols: Self.group(assignments))
    }
    static
    func validate<S>(unsorted assignments:S) -> Self?
        where S:Sequence, S.Element == (Symbol, Int)
    {
        return .validate(symbols: Self.group(assignments).map{ $0.sorted() })
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
    private static
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
        var capacity:Int
        
        private 
        var storage:ManagedBuffer<Void, UInt8>
        
        private
        var integral:(single:UInt32, double:UInt32)
        
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
            
            self.integral       = (1, 0)
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
                    (front + i &* offset).assign(from: front - offset, count: offset)
                }
                (front + q &* offset).assign(from: front - offset, count: r)
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
                    let offset:Int  = self.startIndex - self.baseIndex
                    self.integral   = Self.update(checksum: self.integral, from: $0, count: offset)
                    $0.assign(from: $0 + offset, count: count)
                    self.baseIndex  = self.startIndex
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
                        let offset:Int  = self.startIndex - self.baseIndex
                        self.integral   = Self.update(checksum: self.integral, from: body, count: offset)
                        $0.assign(from: body + offset, count: count)
                    }
                    self.baseIndex = self.startIndex
                    return new 
                }
            }
        }
        private static 
        func update(checksum:(single:UInt32, double:UInt32), 
            from start:UnsafePointer<UInt8>, count:Int) 
            -> (single:UInt32, double:UInt32)
        {
            // https://software.intel.com/content/www/us/en/develop/articles/fast-computation-of-adler32-checksums.html
            let (q, r):(Int, Int) = count.quotientAndRemainder(dividingBy: 5552)
            var (single, double):(UInt32, UInt32) = checksum
            for i:Int in 0 ..< q 
            {
                for j:Int in 5552 * i ..< 5552 * (i + 1)
                {
                    single &+= .init(start[j])
                    double &+= single 
                }
                single %= 65521
                double %= 65521
            }
            for j:Int in 5552 * q ..< 5552 * q + r
            {
                single &+= .init(start[j])
                double &+= single 
            }
            return (single % 65521, double % 65521)
        }
        // this vectorized version does not perform well at all
        /* private static 
        func update(checksum:(single:UInt32, double:UInt32), 
            from start:UnsafePointer<UInt8>, count:Int) 
            -> (single:UInt32, double:UInt32)
        {
            var (single, double):(UInt32, UInt32) = checksum
            let linear:SIMD16<UInt16> = .init(16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
            
            var current:UnsafePointer<UInt8> = start, 
                remaining:Int                = count 
            
            while remaining >= 16 
            {
                let k:Int  = min(remaining, 5552) & ~15
                remaining -= k 
                
                var a:SIMD4<UInt32> = .init(0, 0, 0, single)
                var b:SIMD4<UInt32> = .init(0, 0, 0, double)
                for g:Int in 0 ..< k >> 4
                {
                    b                     &+= a &<< 4
                    
                    let bytes:SIMD16<UInt8> = 
                        .init(UnsafeBufferPointer.init(start: current + g << 4, count: 16))
                    // gather first-order sum 
                    let a16:SIMD16<UInt16>  = .init(truncatingIfNeeded: bytes)
                    let a8:SIMD8<UInt32>    = .init(truncatingIfNeeded: a16.evenHalf &+ a16.oddHalf)
                    let a4:SIMD4<UInt32>    =        a8.evenHalf &+  a8.oddHalf
                    a                     &+= a4
                    // gather second-order sum
                    let b16:SIMD16<UInt16>  = a16 &* linear
                    let b8:SIMD8<UInt32>    = .init(truncatingIfNeeded: b16.evenHalf &+ b16.oddHalf)
                    let b4:SIMD4<UInt32>    =        b8.evenHalf &+  b8.oddHalf
                    b                     &+= b4
                }
                // no vectorized hardware modulo
                let combined2:SIMD4<UInt32> = .init(
                    lowHalf:  a.evenHalf &+ a.oddHalf, 
                    highHalf: b.evenHalf &+ b.oddHalf)
                let combined:SIMD2<UInt32>  = combined2.evenHalf &+ combined2.oddHalf
                single = (single &+ combined.x) % 65521
                double = (double &+ combined.y) % 65521
                
                current += k
            }
            while remaining > 0 
            {
                single &+= .init(current.pointee)
                double &+= single 
                
                current   += 1
                remaining -= 1
            }
            
            return (single % 65521, double % 65521)
        } */
        mutating 
        func checksum() -> UInt32 
        {
            // everything still in the storage buffer has not yet been integrated 
            self.storage.withUnsafeMutablePointerToElements 
            {
                let (single, double):(UInt32, UInt32) = 
                    Self.update(checksum: self.integral, from: $0, count: self.endIndex &- self.baseIndex)
                return double << 16 | single
            }
        }
    }
    
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
            guard let table:LZ77.Huffman<LZ77.Symbol.CodeLength> = .validate(unsorted:
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
        let bytes:(UInt32, UInt32, UInt32, UInt32) = 
        (
            self.input[boundary,      count: 8, as: UInt32.self],
            self.input[boundary +  8, count: 8, as: UInt32.self],
            self.input[boundary + 16, count: 8, as: UInt32.self],
            self.input[boundary + 24, count: 8, as: UInt32.self]
        )
        let checksum:UInt32   = bytes.0 << 24 |
                                bytes.1 << 16 |
                                bytes.2 <<  8 |
                                bytes.3
        guard self.output.checksum() == checksum
        else 
        {
            throw LZ77.DecompressionError.invalidStreamChecksum
        } 
        self.b = boundary + 32
        return ()
    }
}
