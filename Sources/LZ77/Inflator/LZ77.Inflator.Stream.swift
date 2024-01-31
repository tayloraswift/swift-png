extension LZ77.Inflator
{
    @frozen @usableFromInline
    struct Stream<Integral> where Integral:LZ77.StreamIntegral
    {
        // Stream.In manages its own COW in rebase(_:pointer:)
        var input:LZ77.InflatorInput
        var b:Int
        var lengths:[Int]
        // Meta and Stream.Out need to have COW manually implemented with
        // exclude() on each, to avoid redundant exclusions inside loops,,
        // reuse the same buffer since the size is fixed
        var meta:LZ77.InflatorTables.Meta
        var output:LZ77.InflatorOutput<Integral>

        #if DUMP_LZ77_BLOCKS || DUMP_LZ77_SYMBOL_HISTOGRAM
        // histogram, no match can ever cost more than 17 bits per literal
        var statistics:
        (
            literals:[Int],
            matches:[Int],
            symbols:[Int]
        )
        =
        (
            literals:   .init(repeating: 0, count: 16),
            matches:    .init(repeating: 0, count: 17),
            // 2d symbol histogram (run, distance)
            symbols:    .init(repeating: 0, count: 29 * 30)
        )
        #endif

        init()
        {
            self.b          = 0
            self.input      = []
            self.lengths    = []
            self.meta       = .init()
            self.output     = .init()
        }
    }
}
extension LZ77.Inflator.Stream
{
    mutating
    func blockStart() throws -> (final:Bool, type:LZ77.BlockType)?
    {
        guard self.b + 3 <= self.input.count
        else
        {
            return nil
        }

        // read block header bits
        let final:Bool = self.input[self.b, count: 1, as: UInt8.self] != 0
        let type:LZ77.BlockType
        switch self.input[self.b + 1, count: 2, as: UInt8.self]
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
                throw LZ77.DecompressionError.invalidBlockElementCountParity(l, m)
            }

            type = .bytes(.init(l))
            self.b  = boundary + 32

        case 1:
            type = .fixed
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

            let runliterals:Int = 257 + self.input[self.b +  3, count: 5, as: Int.self]
            let distances:Int   =   1 + self.input[self.b +  8, count: 5, as: Int.self]
            // other counts don’t need to be checked because the number of bits
            // matches the acceptable range
            guard 257 ... 286 ~= runliterals
            else
            {
                throw LZ77.DecompressionError.invalidHuffmanRunLiteralSymbolCount(runliterals)
            }

            var lengths:[Int] = .init(repeating: 0, count: 19)
            for (i, d):(Int, Int) in zip(0 ..< codelengths,
                [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15])
            {
                lengths[d] = self.input[self.b + 17 + 3 * i, count: 3, as: Int.self]
            }
            guard
            let tree:LZ77.HuffmanTree<UInt8> = .validate(symbols: 0 ... 18, lengths: lengths)
            else
            {
                throw LZ77.DecompressionError.invalidHuffmanCodelengthHuffmanTable
            }

            self.meta.replace(tree: tree)

            self.b += 17 + 3 * codelengths
            type = .dynamic(runliterals: runliterals, distances: distances)

        case let code:
            throw LZ77.DecompressionError.invalidBlockTypeCode(code)
        }

        return (final, type)
    }
    mutating
    func blockTables(runliterals:Int, distances:Int)
        throws -> (runliteral:LZ77.HuffmanTree<UInt16>, distance:LZ77.HuffmanTree<UInt8>)?
    {
        // code lengths form an unbroken sequence
        codelengths:
        while self.lengths.count < runliterals + distances
        {
            guard self.b < self.input.count
            else
            {
                return nil
            }

            let meta:LZ77.Metaword = self.meta[.init(truncatingIfNeeded: self.input[self.b])]
            // if the codeword length is longer than the available input
            // then we know the match is invalid (due to padding 0-bits)
            guard self.b + meta.length <= self.input.count
            else
            {
                return nil
            }

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
            let element:Int,
                extra:Int,
                base:Int
            switch meta.symbol
            {
            case 0 ..< 16:
                self.lengths.append(.init(meta.symbol))
                self.b += meta.length
                continue codelengths

            case 16:
                guard
                let last:Int = self.lengths.last
                else
                {
                    throw LZ77.DecompressionError.invalidHuffmanCodelengthSequence
                }
                element = last
                extra   = 2
                base    = 3

            case 17:
                element = 0
                extra   = 3
                base    = 3

            case 18:
                element = 0
                extra   = 7
                base    = 11

            default:
                fatalError("unreachable")
            }

            guard self.b + meta.length + extra <= self.input.count
            else
            {
                return nil
            }
            let repetitions:Int = base +
                self.input[self.b + meta.length, count: extra, as: Int.self]

            self.lengths.append(contentsOf: repeatElement(element, count: repetitions))
            self.b += meta.length + extra
        }
        defer
        {
            // important
            self.lengths.removeAll(keepingCapacity: true)
        }
        guard self.lengths.count == runliterals + distances
        else
        {
            throw LZ77.DecompressionError.invalidHuffmanCodelengthSequence
        }

        #if DUMP_LZ77_TERMS
        print("< dynamic run-literal codelengths:")
        for (i, length):(Int, Int) in self.lengths.prefix(runliterals).enumerated()
            where length > 0
        {
            print("    [\(String.pad("\(i)", left: 3))]: \(length)")
        }
        print("< dynamic distance codelengths:")
        for (i, length):(Int, Int) in self.lengths.dropFirst(runliterals).enumerated()
            where length > 0
        {
            print("    [\(String.pad("\(i)", left: 3))]: \(length)")
        }
        #endif

        guard
        let runliteral:LZ77.HuffmanTree<UInt16> = .validate(
            symbols: 0 ... 287,
            lengths: self.lengths.prefix(runliterals)),
        let distance:LZ77.HuffmanTree<UInt8> = .validate(
            symbols: 0 ... 31,
            normalizing: self.lengths.dropFirst(runliterals))
        else
        {
            throw LZ77.DecompressionError.invalidHuffmanTable
        }
        return (runliteral, distance)
    }
    mutating
    func blockCompressed(semistatic:LZ77.InflatorTables) throws -> Void?
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
            let first:UInt16 = self.input[self.b]
            let runliteral:LZ77.RunLiteral = semistatic[first, as: LZ77.RunLiteral.self]

            if      runliteral.symbol <  256
            {
                guard self.b + runliteral.length <= self.input.count
                else
                {
                    return nil
                }
                self.b += runliteral.length
                self.output.append(runliteral.literal)

                #if DUMP_LZ77_TERMS
                print("< literal(\(runliteral.literal))")
                #endif
                #if DUMP_LZ77_BLOCKS || DUMP_LZ77_SYMBOL_HISTOGRAM
                self.statistics.literals[runliteral.length] += 1
                #endif
            }
            else if runliteral.symbol == 256
            {
                guard self.b + runliteral.length <= self.input.count
                else
                {
                    return nil
                }
                self.b += runliteral.length

                #if DUMP_LZ77_TERMS
                print("< end-of-block\n")
                #endif
                #if DUMP_LZ77_BLOCKS || DUMP_LZ77_SYMBOL_HISTOGRAM
                self.statistics.literals[runliteral.length] += 1
                #endif

                return ()
            }
            else
            {
                // get the next two words to form a 48-bit value
                // (in the low bits bits of a UInt64)
                // we put it in the low bits so that we can do masking shifts instead
                // of checked shifts
                var slug:UInt64 =
                    .init(self.input[self.b + 32]) << 32 |
                    .init(self.input[self.b + 16]) << 16 |
                    .init(first)
                slug &>>= runliteral.length

                let composite:
                (
                    count:(extra:Int, base:Int),
                    offset:(extra:Int, base:Int)
                )

                composite.count     = semistatic.composite(decade: runliteral)
                let count:Int       = composite.count.base &+
                    .init(truncatingIfNeeded: slug & ~(.max &<< composite.count.extra))

                slug &>>= composite.count.extra

                let distance:LZ77.Distance =
                    semistatic[.init(truncatingIfNeeded: slug), as: LZ77.Distance.self]
                slug &>>= distance.length

                composite.offset    = semistatic.composite(decade: distance)
                let offset:Int      = composite.offset.base &+
                    .init(truncatingIfNeeded: slug & ~(.max &<< composite.offset.extra))

                let b:Int = self.b      +
                    runliteral.length   + composite.count.extra +
                    distance.length     + composite.offset.extra
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

                #if DUMP_LZ77_TERMS
                print("< match(offset: \(-offset), run: \(count))")
                #endif
                #if DUMP_LZ77_BLOCKS || DUMP_LZ77_SYMBOL_HISTOGRAM
                let n:Int = 29 * .init(distance.decade) + .init(runliteral.symbol - 257)
                let m:Int =
                    runliteral.length + composite.count.extra +
                    distance.length   + composite.offset.extra
                self.statistics.symbols[n]          += 1
                self.statistics.matches[m / count]  += 1
                #endif

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
    func check(declared checksum:UInt32?) throws
    {
        #if DUMP_LZ77_BLOCKS
        let efficiency:Double = self.statistics.literals.enumerated().reduce(0.0){ $0 + .init($1.0 * $1.1) } /
            .init(self.statistics.literals.reduce(0, +))
        print("< average literal coding efficiency: \(efficiency)")
        print("< match coding efficiency histogram:")
        for (bin, frequency):(Int, Int) in self.statistics.matches.enumerated()
        {
            print("    [\(bin) ..< \(bin + 1) bits]: \(frequency)")
        }
        print("< run-distance symbol histogram:")
        #endif
        #if DUMP_LZ77_BLOCKS || DUMP_LZ77_SYMBOL_HISTOGRAM
        print(String.init(histogram: self.statistics.symbols, size: (29, 30), pad: 4))
        #endif

        guard
        let checksum:UInt32
        else
        {
            return // Checksum missing.
        }

        let computed:UInt32   = self.output.checksum()
        if  computed != checksum
        {
            throw LZ77.DecompressionError.invalidStreamChecksum(
                declared: checksum,
                computed: computed)
        }
    }
}
