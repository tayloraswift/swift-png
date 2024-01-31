extension LZ77
{
    struct DeflatorDicing
    {
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
        let tree:(runliteral:LZ77.HuffmanTree<UInt16>, distance:LZ77.HuffmanTree<UInt8>) =
        (
            .init(frequencies: frequencies[base       ..< base + 286], limit: 15),
            .init(frequencies: frequencies[base + 288 ..< base + 318], limit: 15)
        )
        // compute combined metatree
        let meta:
        (
            tree:LZ77.HuffmanTree<UInt8>,
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
    func metatree(for tree:(runliteral:LZ77.HuffmanTree<UInt16>, distance:LZ77.HuffmanTree<UInt8>))
        ->
    (
        tree:LZ77.HuffmanTree<UInt8>,
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

        let metatree:LZ77.HuffmanTree<UInt8>    = .init(frequencies: frequencies, limit: 7),
            mass:Int                        = metatree.mass(frequencies: frequencies)
        return (metatree, mass: mass, runliterals: r, distances: d, terms)
    }
} */
