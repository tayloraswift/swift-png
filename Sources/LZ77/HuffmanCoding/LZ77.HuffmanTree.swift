extension LZ77
{
    @available(*, deprecated)
    typealias Huffman = HuffmanTree

    struct HuffmanTree<Symbol> where Symbol:Comparable
    {
        let symbols:[Symbol]
        let levels:[Range<Int>]
        // these are size parameters generated by the structural validator.
        // we store them here as proof of tree validity, so that the
        // constructor for the huffman Decoder type can just read it from here
        let size:(n:Int, z:Int)

        private
        init(symbols:[Symbol], levels:[Range<Int>], size:(n:Int, z:Int))
        {
            self.symbols = symbols
            self.levels  = levels
            self.size    = size
        }
    }
}
extension LZ77.HuffmanTree<UInt16>
{
    static
    var runliteral:Self
    {
        .init(symbols: [256 ... 279, 0 ... 143, 280 ... 287, 144 ... 255].flatMap{ $0 },
            levels:
                .init(repeating:   0 ..<   0, count: 6) + // L1 ... L6
                [0 ..< 24, 24 ..< 176, 176 ..< 288]     + // L7, L8, L9
                .init(repeating: 288 ..< 288, count: 6))  // L10 ... L15
    }
}
extension LZ77.HuffmanTree<UInt8>
{
    static
    var distance:Self
    {
        .init(symbols: .init(0 ... 31),
            levels:
                .init(repeating:  0 ..<  0, count:  4)  +
                [0 ..< 32]                              +
                .init(repeating: 32 ..< 32, count: 10))
    }
}
//  Inflator.
extension LZ77.HuffmanTree where Symbol:BinaryInteger
{
    // empty or single-element tree
    init(stub:Symbol?)
    {
        if let stub:Symbol = stub
        {
            self.symbols    = [stub]
            self.levels     = [0 ..< 1] + repeatElement(1 ..< 1, count: 14)
        }
        else
        {
            self.symbols    = []
            self.levels     = [0 ..< 0] + repeatElement(0 ..< 0, count: 14)
        }
        self.size = (n: 256, z: 256)
    }

    // non validating initializer, crashes on invalid input
    init(symbols:[Symbol], levels:[Range<Int>])
    {
        guard let size:(n:Int, z:Int) = Self.size(levels)
        else
        {
            fatalError("invalid huffman table leaf list")
        }
        self.init(symbols: symbols, levels: levels, size: size)
    }

    // validate leaf counts
    private static
    func size(_ levels:[Range<Int>]) -> (n:Int, z:Int)?
    {
        // count the interior nodes
        var interior:Int = 1 // count the root
        for leaves:Range<Int> in levels[0 ..< 8]
        {
            // every interior node on the level above generates two new nodes.
            // some of the new nodes are leaf nodes, the rest are interior nodes.
            interior    = 2 * interior - leaves.count
        }

        // the number of interior nodes remaining is the number of child trees
        let n:Int       = 256 - interior
        var z:Int       = 256 // n
        // finish validating the tree
        for (i, leaves):(Int, Range<Int>) in levels[8 ..< 15].enumerated()
        {
            z       += leaves.count << (6 - i)
            interior = 2 * interior - leaves.count
        }

        guard interior == 0
        else
        {
            return nil
        }

        return (n, z)
    }

    // handles 0-symbol and 1-symbol edge cases
    static
    func validate<Symbols, Lengths>(symbols:Symbols, normalizing lengths:Lengths)
        -> Self?
        where   Symbols:Collection,        Lengths:Collection,
                Symbols.Element == Symbol, Lengths.Element == Int
    {
        var first:Symbol?
        for (symbol, length):(Symbol, Int) in zip(symbols, lengths) where length > 0
        {
            if first == nil, length == 1
            {
                first = symbol
            }
            else
            {
                // only way to get here is if we have already encountered a symbol,
                // or we have encountered a symbol with a codelength greater than 1,
                // either of which means there are at least two symbols, so we can
                // use the normal constructor.
                return Self.validate(symbols: symbols, lengths: lengths)
            }
        }
        // zero- and single-symbol cases
        return .init(stub: first)
    }

    static
    func validate<Symbols, Lengths>(symbols:Symbols, lengths:Lengths) -> Self?
        where   Symbols:Collection,        Lengths:Collection,
                Symbols.Element == Symbol, Lengths.Element == Int
    {
        var counts:[Int] = .init(repeating: 0, count: 16)
        for length:Int in lengths
        {
            counts[length] += 1
        }
        let ranges:[Range<Int>] = .init(unsafeUninitializedCapacity: 15)
        {
            var base:Int = 0
            for (i, count):(Int, Int) in counts.dropFirst().enumerated()
            {
                $0[i] = base ..< base + count
                base += count
            }
            $1 = 15
        }

        guard let size:(n:Int, z:Int) = Self.size(ranges)
        else
        {
            return nil
        }

        let packed:[Symbol] = .init(unsafeUninitializedCapacity: ranges[14].upperBound)
        {
            for (symbol, length):(Symbol, Int) in zip(symbols, lengths) where length > 0
            {
                $0[ranges[length - 1].upperBound - counts[length]] = symbol
                counts[length] -= 1
            }
            $1 = ranges[14].upperBound
        }
        return .init(symbols: packed, levels: ranges, size: size)
    }

    func table<Pattern>(initializing destination:UnsafeMutablePointer<Pattern>)
        where Pattern:LZ77.HuffmanPattern<Symbol>
    {
        var current:UnsafeMutablePointer<Pattern> = destination
        for (l, level):(Int, Range<Int>) in zip(1 ... 8, self.levels.prefix(8))
        {
            let clones:Int  = 256 >> l
            for symbol:Symbol in self.symbols[level]
            {
                let pattern:Pattern = .init(symbol, length: l)
                current.initialize(repeating: pattern, count: clones)
                current += clones
            }
        }
        current = destination + 256
        for (l, level):(Int, Range<Int>) in zip(9 ... 15, self.levels.dropFirst(8))
        {
            let clones:Int  = 32768 >> l
            for symbol:Symbol in self.symbols[level]
            {
                let pattern:Pattern = .init(symbol, length: l)
                current.initialize(repeating: pattern, count: clones)
                current += clones
            }
        }
    }
}
// Deflator.
extension LZ77.HuffmanTree where Symbol:BinaryInteger
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
