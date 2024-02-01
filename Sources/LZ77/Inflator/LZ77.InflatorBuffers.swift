extension LZ77
{
    @frozen @usableFromInline
    struct InflatorBuffers<Format> where Format:LZ77.FormatType
    {
        //  Reusable buffers
        var metadata:BlockMetadata
        var buffer:[Int]
        var stream:Stream

        let format:Format

        init(format:Format)
        {
            self.metadata   = .init()
            self.buffer    = []
            self.stream     = .init()
            self.format     = format
        }
    }
}
extension LZ77.InflatorBuffers
{
    private mutating
    func advance(state:LZ77.BlockState) throws -> LZ77.BlockState??
    {
        switch state
        {
        case .metadata:
            if  let block:LZ77.BlockType = try self.stream.readBlockMetadata(
                    into: &self.metadata)
            {
                #if DUMP_LZ77_BLOCKS
                defer
                {
                    print("< \(block)")
                }
                #endif

                switch block
                {
                case .dynamic   (final: let final, literals: let l, distances: let d):
                    return .tables(final: final, literals: l, distances: d)

                case .fixed     (final: let final):
                    return .compressed(final: final, tables: .fixed)

                case .bytes     (final: let final, count: let count):
                    // compute endindex
                    let end:Int = self.stream.output.endIndex + count
                    return .uncompressed(final: final, end: end)
                }
            }

        case .tables(final: let final, literals: let l, distances: let d):
            if  let tables:LZ77.InflatorTables = try self.stream.readBlockTables(
                    metadata: self.metadata,
                    lengths: (l, l + d),
                    reusing: &self.buffer)
            {
                return .compressed(final: final, tables: tables)
            }

        case .uncompressed(final: let final, end: let end):
            if  let _:Void = self.stream.readBlock(upTo: end)
            {
                return final ? .some(nil) : .metadata
            }

        case .compressed(final: let final, tables: let tables):
            if  let _:Void = try self.stream.readBlock(with: tables)
            {
                return final ? .some(nil) : .metadata
            }
        }

        return .none
    }
}
extension LZ77.InflatorBuffers<LZ77.Format>
{
    mutating
    func advance(state:LZ77.InflatorState) throws -> LZ77.InflatorState?
    {
        // pool cow-exclusions here instead of checking the reference count
        // on every loop iteration
        self.metadata.exclude()
        self.stream.output.exclude()

        switch state
        {
        case .initial:
            if  case .ios = self.format
            {
                self.stream.output.window = 1 << 15
                return .block(.metadata)
            }
            else if
                let header:LZ77.StreamHeader = try .read(&self.stream.input,
                    from: &self.stream.b)
            {
                self.stream.output.window = 1 << header.exponent
                return .block(.metadata)
            }

        case .block(let block):
            if  let next:LZ77.BlockState? = try self.advance(state: block)
            {
                return next.map { .block($0) } ?? .checksum
            }

        case .checksum:
            self.stream._dumpPerfStats()

            if  case .ios = self.format
            {
                return .terminal
            }
            else if
                let declared:UInt32 = self.stream.readBigEndianUInt32()
            {
                let computed:UInt32   = self.stream.output.checksum()
                if  computed != declared
                {
                    throw LZ77.DecompressionError.invalidStreamChecksum(
                        declared: declared,
                        computed: computed)
                }
                return .terminal
            }

        case .terminal:
            break
        }

        return nil
    }
}
extension LZ77.InflatorBuffers<Gzip.Format>
{
    mutating
    func advance(state:Gzip.InflatorState) throws -> Gzip.InflatorState?
    {
        // pool cow-exclusions here instead of checking the reference count
        // on every loop iteration
        self.metadata.exclude()
        self.stream.output.exclude()

        switch state
        {
        case .initial:
            if  let header:Gzip.StreamHeader = try .read(&self.stream.input,
                    from: &self.stream.b)
            {
                self.stream.output.window = 1 << 15

                var count:Int = 0

                if  header.flag.3
                {
                    count += 1
                }
                if  header.flag.4
                {
                    count += 1
                }

                guard header.xlen == 0, count == 0
                else
                {
                    return .strings(skip: 8 * Int.init(header.xlen), count: count)
                }

                return .block(.metadata)
            }

        case .strings(skip: let skip, count: var count):
            if  skip == 0
            {
                precondition(count > 0)

                if  case ()? = self.stream.readString()
                {
                    count -= 1
                }
                else
                {
                    break
                }

                return count == 0 ? .block(.metadata) : .strings(skip: 0, count: count)
            }
            else if
                self.stream.b + skip <= self.stream.input.count
            {
                self.stream.b += skip
                return count == 0 ? .block(.metadata) : .strings(skip: 0, count: count)
            }

        case .block(let block):
            if  let next:LZ77.BlockState? = try self.advance(state: block)
            {
                return next.map { .block($0) } ?? .checksum
            }

        case .checksum:
            if  let declared:UInt32 = self.stream.readLittleEndianUInt32()
            {
                let computed:UInt32   = self.stream.output.checksum()
                if  computed != declared
                {
                    throw LZ77.DecompressionError.invalidStreamChecksum(
                        declared: declared,
                        computed: computed)
                }
                return .epilogue
            }

        case .epilogue:
            if  let _:UInt32 = self.stream.readLittleEndianUInt32()
            {
                return .terminal
            }

        case .terminal:
            preconditionFailure("Attempted to advance past terminal state!")
        }

        return nil
    }
}
