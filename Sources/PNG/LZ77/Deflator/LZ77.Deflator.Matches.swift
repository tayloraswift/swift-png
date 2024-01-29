extension LZ77.Deflator
{
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
    func trees() -> (runliteral:LZ77.HuffmanTree<UInt16>, distance:LZ77.HuffmanTree<UInt8>)
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

        let tree:(runliteral:LZ77.HuffmanTree<UInt16>, distance:LZ77.HuffmanTree<UInt8>) =
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
        -> (runliteral:LZ77.HuffmanTree<UInt16>, distance:LZ77.HuffmanTree<UInt8>)
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
            let tree:(runliteral:LZ77.HuffmanTree<UInt16>, distance:LZ77.HuffmanTree<UInt8>) =
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
