extension LZ77.InflatorBuffers
{
    @frozen @usableFromInline
    struct Stream
    {
        var output:LZ77.InflatorOut<Format.Integral>
        // Stream.In manages its own COW in rebase(_:pointer:)
        var input:LZ77.InflatorIn
        var b:Int

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
            self.output     = .init()
            self.input      = []
            self.b          = 0
        }
    }
}
extension LZ77.InflatorBuffers.Stream
{
    mutating
    func push(_ data:ArraySlice<UInt8>)
    {
        self.input.rebase(data, pointer: &self.b)
    }
    mutating
    func pull(_ count:Int) -> [UInt8]?
    {
        self.output.exclude()
        return self.output.release(bytes: count)
    }
    mutating
    func pull() -> [UInt8]
    {
        self.output.exclude()
        return self.output.release()
    }
}
extension LZ77.InflatorBuffers.Stream
{
    mutating
    func readBlockMetadata(into metadata:inout LZ77.BlockMetadata) throws -> LZ77.BlockType?
    {
        guard self.b + 3 <= self.input.count
        else
        {
            return nil
        }

        // read block header bits
        let final:Bool = self.input[self.b, count: 1, as: UInt8.self] != 0
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

            self.b = boundary + 32
            return .bytes(final: final, count: .init(l))

        case 1:
            self.b += 3
            return .fixed(final: final)

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

            let literals:Int = 257 + self.input[self.b +  3, count: 5, as: Int.self]
            let distances:Int =  1 + self.input[self.b +  8, count: 5, as: Int.self]
            // other counts don’t need to be checked because the number of bits
            // matches the acceptable range
            guard 257 ... 286 ~= literals
            else
            {
                throw LZ77.DecompressionError.invalidHuffmanRunLiteralSymbolCount(literals)
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

            metadata.replace(tree: tree)

            self.b += 17 + 3 * codelengths
            return .dynamic(final: final, literals: literals, distances: distances)

        case let code:
            throw LZ77.DecompressionError.invalidBlockTypeCode(code)
        }
    }

    mutating
    func readBlockTables(
        metadata:LZ77.BlockMetadata,
        lengths count:(literals:Int, total:Int),
        reusing lengths:inout [Int]) throws -> LZ77.InflatorTables?
    {
        // code lengths form an unbroken sequence
        codelengths:
        while lengths.count < count.total
        {
            guard self.b < self.input.count
            else
            {
                return nil
            }

            let meta:LZ77.Metaword = metadata[.init(truncatingIfNeeded: self.input[self.b])]
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
                lengths.append(.init(meta.symbol))
                self.b += meta.length
                continue codelengths

            case 16:
                guard
                let last:Int = lengths.last
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

            lengths.append(contentsOf: repeatElement(element, count: repetitions))
            self.b += meta.length + extra
        }
        defer
        {
            // important
            lengths.removeAll(keepingCapacity: true)
        }
        guard lengths.count == count.total
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
        let literalTree:LZ77.HuffmanTree<UInt16> = .validate(symbols: 0 ... 287,
            lengths: lengths.prefix(count.literals)),
        let distanceTree:LZ77.HuffmanTree<UInt8> = .validate(symbols: 0 ... 31,
            normalizing: lengths.dropFirst(count.literals))
        else
        {
            throw LZ77.DecompressionError.invalidHuffmanTable
        }

        return .init(literals: literalTree, distances: distanceTree)
    }

    mutating
    func readBlock(with tables:LZ77.InflatorTables) throws -> Void?
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
            let runliteral:LZ77.RunLiteral = tables[first, as: LZ77.RunLiteral.self]

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

                composite.count     = tables.composite(decade: runliteral)
                let count:Int       = composite.count.base &+
                    .init(truncatingIfNeeded: slug & ~(.max &<< composite.count.extra))

                slug &>>= composite.count.extra

                let distance:LZ77.Distance =
                    tables[.init(truncatingIfNeeded: slug), as: LZ77.Distance.self]
                slug &>>= distance.length

                composite.offset    = tables.composite(decade: distance)
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
    func readBlock(upTo end:Int) -> Void?
    {
        while self.output.endIndex < end
        {
            if  let byte:UInt8 = self.readByte()
            {
                self.output.append(byte)
            }
            else
            {
                return nil
            }
        }

        return ()
    }

    mutating
    func readBigEndianUInt32() -> UInt32?
    {
        // skip to next byte boundary, read 4 bytes
        let boundary:Int = (self.b + 7) & ~7
        if  boundary + 32 <= input.count
        {
            b = boundary + 32
        }
        else
        {
            return nil
        }

        // mrc-32 is big-endian
        let bytes:(UInt32, UInt32, UInt32, UInt32) =
        (
            input[boundary,      count: 8, as: UInt32.self],
            input[boundary +  8, count: 8, as: UInt32.self],
            input[boundary + 16, count: 8, as: UInt32.self],
            input[boundary + 24, count: 8, as: UInt32.self]
        )
        let checksum:UInt32   = bytes.0 << 24 |
                                bytes.1 << 16 |
                                bytes.2 <<  8 |
                                bytes.3

        return checksum
    }

    mutating
    func readLittleEndianUInt32() -> UInt32?
    {
        self.readBigEndianUInt32()?.byteSwapped
    }

    mutating
    func readString() -> Void?
    {
        reading:
        do
        {
            switch self.readByte()
            {
            case nil:   return nil
            case 0?:    return ()
            case _?:    continue reading
            }
        }
    }

    @inline(__always)
    mutating
    func readByte() -> UInt8?
    {
        guard self.b + 8 <= self.input.count
        else
        {
            return nil
        }
        defer
        {
            self.b += 8
        }

        return self.input[self.b, count: 8, as: UInt8.self]
    }

    mutating
    func _dumpPerfStats()
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
    }
}
