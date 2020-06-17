/* This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. */

extension PNG 
{
    enum DecompressionError:Swift.Error
    {
        case truncatedBitstream 
        case invalidHuffmanRunLiteralSymbolCount(Int)
        case invalidHuffmanCodelengthHuffmanTable
        case invalidHuffmanCodelengthSequence
        case invalidHuffmanTable
    }
}

extension PNG 
{
    struct Bitstream 
    {
        private 
        var atoms:[UInt16]
        private(set)
        var count:Int
    }
}
extension PNG.Bitstream 
{
    // Bitstreams are indexed from LSB to MSB within each atom 
    //      
    // atom 0   16 [ ← ← ← ← ← ← ← ← ]  0
    // atom 1   32 [ ← ← ← ← ← ← ← ← ] 16
    // atom 2   48 [ ← ← ← ← ← ← ← ← ] 32
    // atom 3   64 [ ← ← ← ← ← ← ← ← ] 48
    init(_ data:[UInt8])
    {
        // convert byte array to little-endian UInt16 array 
        var atoms:[UInt16] = stride(from: data.startIndex, to: data.endIndex - 1, by: 2).map
        {
            UInt16.init(data[$0 | 1]) << 8 | .init(data[$0])
        }
        if data.count & 1 != 0
        {
            atoms.append(.init(data[data.endIndex - 1]))
        }
        // 16-bits of padding at the end 
        atoms.append(0x0000)
        
        self.atoms = atoms
        self.count = 8 * data.count
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
        let a:Int = i >> 4, 
            b:Int = i & 0x0f
        //    a + 2           a + 1             a
        //      [ : :x:x:x:x:x:x|x:x: : : : : : ]
        //           ~~~~~~~~~~~~~~~^
        //            count = 16, b = 12
        //
        //      →   [x:x|x:x:x:x:x:x]
        
        // must use << and not &<< to correctly handle shift of 16
        let reversed:UInt16 = self.atoms[a + 1] << (UInt16.bitWidth &- b) | self.atoms[a] &>> b
        return Self.reverse(reversed & 0x00ff) << 8 | Self.reverse(reversed >> 8)
    }
    
    // https://graphics.stanford.edu/~seander/bithacks.html#ReverseByteWith64Bits
    // bits go into the low end of the UInt16
    @inline(__always)
    private static 
    func reverse(_ byte:UInt16) -> UInt16 
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
extension PNG.Bitstream:ExpressibleByArrayLiteral 
{
    //  init PNG.Bitstream.init(arrayLiteral...:)
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

// symbol types 
extension PNG.Bitstream 
{
    enum Symbol 
    {
    }
}
extension PNG.Bitstream.Symbol 
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
        case run(UInt8)
        
        static 
        let allSymbols:[Self] = 
            (0 ... 255).map(Self.literal(_:)) + 
            [.end] + 
            (0 ...  28).map(Self.run(_:))
    }
}

extension PNG 
{
    struct Huffman<Symbol> where Symbol:Comparable 
    {
        let symbols:[[Symbol]]
        // these are size parameters generated by the structural validator. 
        // we store them here as proof of tree validity, so that the 
        // constructor for the huffman Decoder type can just read it from here 
        let size:(n:Int, z:Int)
    }
}
extension PNG.Huffman 
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
                return nil
            }
            
            // every interior node on the level above generates two new nodes.
            // some of the new nodes are leaf nodes, the rest are interior nodes.
            interior = 2 * interior - leaves
        }
        
        // the number of interior nodes remaining is the number of child trees, with 
        // the possible exception of a fake all-ones branch 
        let n:Int      = 256 - interior 
        var z:Int      = n
        // finish validating the tree 
        for (i, leaves):(Int, Int) in levels[8 ..< 16].enumerated()
        {
            guard interior > 0 
            else 
            {
                return nil
            }
            
            z       += leaves << (7 - i)
            interior = 2 * interior - leaves 
        }
        
        guard interior > 0
        else 
        {
            return nil
        }
        
        return (n, z)
    }
    
    init?<S>(_ assignments:S) where S:Sequence, S.Element == (Symbol, Int)
    {
        let groups:[Int: [(Symbol, Int)]] = .init(grouping: assignments, by: \.1)
        let symbols:[[Symbol]] = (1 ... 16).map 
        {
            groups[$0, default: []].map(\.0).sorted()
        }
        self.init(symbols: symbols)
    }
    
    //  init PNG.Huffman.init?(symbols:)
    //      Creates a huffman tree from the given leaf nodes.
    //  
    //      This initializer determines the shape of the tree from the shape of 
    //      the leaf array input. It has no knowledge of symbol frequencies or 
    //      priority. 
    //  
    //      This initializer will return `nil` if the sizes of the given leaf arrays do not 
    //      describe a [full binary tree](https://en.wikipedia.org/wiki/Binary_tree#full). 
    //      (The last level is allowed to be incomplete.)
    //      For example, the leaf counts (3,\ 0,\ 0,\ …\ ) are invalid because 
    //      no binary tree can have three leaf nodes in its first level.
    //  - symbols   : [[Symbol]]
    //      The leaf nodes in each level of the tree. The tree root is always 
    //      assumed to be internal, so the 0th sub-array of this array should 
    //      contain the leaves in the first level of the tree. This array must 
    //      contain 16 sub-arrays, even if the deeper levels of the tree are 
    //      empty, or this initializer will suffer a precondition failure.
    init?(symbols:[[Symbol]])
    {
        // validate leaf counts 
        guard let size:(n:Int, z:Int) = Self.size(symbols.map(\.count))
        else 
        {
            return nil
        }
        
        self.symbols = symbols
        self.size    = size
    } 
}
// huffman decoder 
extension PNG.Huffman 
{
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
            n:Int, // number of level 0 entries
            ζ:Int  // logical size of the table (where the n level 0 entries are each 256 units big)
        
        init(_ storage:[Entry], n:Int, ζ:Int) 
        {
            guard ζ == (1 << 16) - 1 
            else 
            {
                fatalError("table incomplete (\(ζ) entries)")
            }
            self.storage    = storage 
            self.n          = n
            self.ζ          = ζ
        }
    }
}
extension PNG.Huffman 
{
    // this is a (relatively) expensive function. however most jpegs define a 
    // fresh set of huffman tables for each scan, so it is very unlikely that 
    // this function will get called redundantly.
    func decoder() -> Decoder
    {
        /*
        idea:    jpeg huffman tables are encoded gzip style, as sequences of
                 leaf counts and leaf values. the leaf counts tell you the
                 number of leaf nodes at each level of the tree. combined with
                 a rule that says that leaf nodes always occur on the “leftmost”
                 side of the tree, this uniquely determines a huffman tree.
        
                 Given: leaves per level = [0, 3, 1, 1, ... ]
        
                         ___0___[root]___1___
                       /                      \
                __0__[ ]__1__            __0__[ ]__1__
              /              \         /               \
             [a]            [b]      [c]            _0_[ ]_1_
                                                  /           \
                                                [d]        _0_[ ]_1_
                                                         /           \
                                                       [e]        reserved
        
                 note that in a huffman tree, level 0 always contains 0 leaf
                 nodes (why?) so the huffman table omits level 0 in the leaf
                 counts list.
        
                 we *could* build a tree data structure, and traverse it as
                 we read in the coded bits, but that would be slow and require
                 a shift for every bit. instead we extend the huffman tree
                 into a perfect tree, and assign the new leaf nodes the
                 values of their parents.
        
                             ________[root]________
                           /                        \
                   _____[ ]_____                _____[ ]_____
                  /             \             /               \
                 [a]           [b]          [c]            ___[ ]___
               /     \       /     \       /   \         /           \
             (a)     (a)   (b)     (b)   (c)   (c)      [d]          ...
        
                 this lets us make a table of huffman codes where all the
                 codes are “padded” to the same length. note that codewords
                 that occur higher up the tree occur multiple times because
                 they have multiple children. of course, since the extra bits
                 aren’t actually part of the code, we have to store separately
                 the length of the original code so we know how many bits
                 we should advance the current bit position by once we match
                 a code.
        
                   code       value     length
                 —————————  —————————  ————————
                    000        'a'         2
                    001        'a'         2
                    010        'b'         2
                    011        'b'         2
                    100        'c'         2
                    101        'c'         2
                    110        'd'         3
                    111        ...        >3
        
                 decoding coded data then becomes a matter of matching a fixed
                 length bitstream against the table (the code works as an integer
                 index!) since all possible combinations of trailing “padding”
                 bits are represented in the table.
        
                 in jpeg, codewords can be a maximum of 16 bits long. this
                 means in theory we need a table with 2^16 entries. that’s a
                 huge table considering there are only 256 actual encoded
                 values, and since this is the kind of thing that really needs
                 to be optimized for speed, this needs to be as cache friendly
                 as possible.
        
                 we can reduce the table size by splitting the 16-bit table
                 into two 8-bit levels. this means we have one 8-bit “root”
                 tree, and k 8-bit child trees rooted on the internal nodes
                 at level 8 of the original tree.
        
                 so far, we’ve looked at the huffman tree as a tree. however 
                 it actually makes more sense to look at it as a table, just 
                 like its implementation. remember that the tree is right-heavy, 
                 so the first 8 levels will look something like 
        
                 +———————————————————+ 0
                 |                   |
                 |                   |
                 |                   |
                 |                   |
                 |                   |
                 |                   |
                 |                   |
                 +———————————————————+
                 |                   |
                 |                   |
                 |                   |
                 +———————————————————+
                 |                   |
                 |                   |
                 |                   |
                 +———————————————————+ -
                 |                   |
                 +———————————————————+
                 |                   |
                 +———————————————————+
                 |                   |
                 +———————————————————+
                 |                   |
                 +———————————————————+ -
                 |                   |
                 +———————————————————+
                 +———————————————————+
               n +———————————————————+ -    —    +———————————————————+ s = 0
                 +-------------------+      ↑    |                   |
                 +-------------------+      s    |                   |
                 +-------------------+      ↓    |                   |
           n + s +-------------------+ 256  —    +———————————————————+
                                                 |                   |
                                                 |                   |
                                                 |                   |
                                                 +———————————————————+
                                                 |                   |
                                                 |                   |
                                                 |                   |
                                                 +———————————————————+
                                                 |                   |
                                                 +———————————————————+
                                                 |                   |
                 /                               /////////////////////
        
                 this is awesome because we don’t need to store anything in 
                 the table entries themselves to know if they are direct entries 
                 or indirect entries. if the index of the entry is greater than 
                 or equal to `n` (the number of direct entries), it is an 
                 indirect entry, and its indirect index is given by the first 
                 byte of the codeword with `n` subtracted from it. 
                 level-1 subtables are always 256 entries long since they are 
                 leaf tables. this means their positions can be computed in 
                 constant time, given `n`, which is also the position of the 
                 first level-1 table.
                 
                 (for computational ease, we store `s = 256 - n` instead. 
                 `s` can be interpreted as the number of level-1 subtables 
                 trail the level-0 table in the storage buffer)
        
                 how big can `s` be? well, remember that there are only 256
                 different encoded values which means the original tree can
                 only have 256 leaves. any full binary tree with height at
                 least 1 *must* contain at least 2 leaf nodes (why?). since
                 the child trees must have a height > 0 (otherwise they would
                 be 0-bit trees), every child tree except possibly the right-
                 most one must have at least 2 leaf nodes. the rightmost child
                 tree is an exception because in jpeg, the all-ones codeword
                 does not represent any value, so the right-most tree can
                 possibly only contain one “real” leaf node. we can pigeonhole
                 this to show that we can only have up to k ≤ 129 child trees.
                 in fact, we can reduce this even further to k ≤ 128 because
                 if the rightmost tree only contains 1 leaf, there has to be at
                 least one other tree with an odd number of leaves to make the  
                 total add up to 256, and that number has to be at least 3. 
                 in reality, k is rarely bigger than 7 or 8 yielding a significant 
                 size savings.
        
                 because we don’t need to store pointers, each table entry can 
                 be just 2 bytes long — 1 byte for the encoded value, and 1 byte 
                 to store the length of the codeword.
        
                 a buffer like this will never have size greater than
                 2 * 256 × (128 + 1) = 65_792 bytes, compared with
                 2 × (1 << 16)  = 131_072 bytes for the 16-bit table. in
                 reality the 2 layer table is usually on the order of 2–4 kB.
        
                 why not compact the child trees further, since not all of them
                 actually have height 8? we could do that, and get some serious
                 worst-case memory savings, but then we couldn’t access the
                 child tables at constant offsets from the buffer base. we’d
                 need to store whole ≥16-bit pointers to the specific byte offset 
                 where the variable-length child table lives, and perform a 
                 conditional bit shift to transform the input bits into an 
                 appropriate index into the table. not a good look.
        */
        
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
        return .init(storage, n: n, ζ: z + n * 255)
    }
}
// table accessors 
extension PNG.Huffman.Decoder 
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
            guard j < self.ζ 
            else 
            {
                fatalError("unreachable")
            }
            
            return self.storage[j - self.n * 255]
        }
    }
}

// block parsing 
extension PNG.Bitstream 
{
    func block(pointer b:inout Int) throws 
    {
        let table:(runliteral:PNG.Huffman<Symbol.RunLiteral>, distance:PNG.Huffman<UInt8>) = 
            try self.tables(pointer: &b)
        print(table)
    }
    
    private 
    func preamble(pointer b:inout Int) 
        throws -> (table:PNG.Huffman<Symbol.CodeLength>, count:(runliteral:Int, distance:Int))
    {
        guard b + 14 <= self.count 
        else 
        {
            throw PNG.DecompressionError.truncatedBitstream 
        }
        
        let count:(runliteral:Int, distance:Int, codelength:Int)
        
        count.runliteral    = 257 + self[b     , count: 5, as: Int.self]
        count.distance      =   1 + self[b +  5, count: 5, as: Int.self]
        count.codelength    =   4 + self[b + 10, count: 4, as: Int.self]
        b += 14 
        // other counts don’t need to be checked because the number of bits 
        // matches the acceptable range 
        guard   257 ... 286 ~= count.runliteral 
        else 
        {
            throw PNG.DecompressionError.invalidHuffmanRunLiteralSymbolCount(count.runliteral)
        }
        
        let symbols:[Symbol.CodeLength] = 
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
        
        guard b + 3 * count.codelength <= self.count 
        else 
        {
            throw PNG.DecompressionError.truncatedBitstream
        }
        guard let table:PNG.Huffman<Symbol.CodeLength> = 
            PNG.Huffman<Symbol.CodeLength>.init((0 ..< count.codelength).map 
        {
            (symbols[$0], self[b + 3 * $0, count: 3, as: Int.self])
        })
        else 
        {
            throw PNG.DecompressionError.invalidHuffmanCodelengthHuffmanTable 
        }
        b += 3 * count.codelength
        return (table, (count.runliteral, count.distance))
    }
    private 
    func tables(pointer b:inout Int) 
        throws -> (runliteral:PNG.Huffman<Symbol.RunLiteral>, distance:PNG.Huffman<UInt8>)
    {
        let (table, count):(PNG.Huffman<Symbol.CodeLength>, (runliteral:Int, distance:Int)) = 
            try self.preamble(pointer: &b)
        let decoder:PNG.Huffman<Symbol.CodeLength>.Decoder = table.decoder()
        // code lengths form an unbroken sequence 
        var lengths:[Int] = []
        codelengths:
        while lengths.count < count.runliteral + count.distance 
        {
            guard b < self.count 
            else 
            {
                throw PNG.DecompressionError.truncatedBitstream
            }
            
            let entry:PNG.Huffman<Symbol.CodeLength>.Decoder.Entry = decoder[self[b]]
            b += entry.length
            
            let element:Int, 
                extra:Int, 
                base:Int
            switch entry.symbol 
            {
            case .literal(let length):
                lengths.append(.init(length))
                continue codelengths
            case .extend:
                guard let last:Int  = lengths.last 
                else 
                {
                    break codelengths
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
            
            guard b + extra <= self.count 
            else 
            {
                throw PNG.DecompressionError.truncatedBitstream
            }
            let repetitions:Int = base + self[b, count: extra, as: Int.self]
            b += extra 
            lengths.append(contentsOf: repeatElement(element, count: repetitions))
        }
        guard lengths.count == count.runliteral + count.distance 
        else 
        {
            throw PNG.DecompressionError.invalidHuffmanCodelengthSequence
        }
        
        guard   let runliteral:PNG.Huffman<Symbol.RunLiteral>   = PNG.Huffman<Symbol.RunLiteral>.init(
            zip(Symbol.RunLiteral.allSymbols,  lengths.prefix(   count.runliteral))),
                let distance:PNG.Huffman<UInt8>                 = PNG.Huffman<UInt8>.init(
            zip(1 ... 32,                      lengths.dropFirst(count.runliteral))) 
        else 
        {
            throw PNG.DecompressionError.invalidHuffmanTable 
        }
        
        return (runliteral, distance)
    }
}
