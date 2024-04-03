extension LZ77
{
    @frozen @usableFromInline
    struct DeflatorBuffers<Format> where Format:LZ77.FormatType
    {
        var stream:Stream
        let format:Format

        private
        init(format:Format, stream:Stream)
        {
            self.format = format
            self.stream = stream
        }
    }
}
extension LZ77.DeflatorBuffers
{
    private
    init(format:Format, exponent:Int, level:Int, hint:Int)
    {
        precondition(8 ..< 16 ~= exponent,
            "exponent cannot be less than 8 or greater than 15")

        let search:LZ77.DeflatorSearch = .init(level: level)

        let matches:LZ77.DeflatorMatches
        // match buffer is either a vector of terms, or a directed-graph
        switch search
        {
        case .greedy:   matches = .terms(capacity: 1 << 15)
        case .lazy:     matches = .terms(capacity: 1 << 15)
        case .full:     matches = .graph(capacity: 1 << 16)
        }

        self.init(format: format, stream: .init(search: search,
            matches: matches,
            window: .init(exponent: exponent),
            output: .init(hint: hint),
            input: .init()))
    }
}
extension LZ77.DeflatorBuffers<LZ77.Format>
{
    init(format:LZ77.Format, level:Int, exponent:Int, hint:Int)
    {
        let header:LZ77.StreamHeader

        switch format
        {
        case .zlib: header = .init(exponent: exponent)
        case .ios : header = .init(exponent: 15)
        }

        self.init(format: format,
            exponent: header.exponent,
            level: level,
            hint: hint)

        switch format
        {
        case .zlib: header.write(&self.stream.output)
        case .ios:  break
        }
    }

    mutating
    func push(_ data:ArraySlice<UInt8>, last:Bool)
    {
        // rebase input buffer
        if !data.isEmpty
        {
            self.stream.input.enqueue(contentsOf: data)
        }
        guard self.stream.input.count > 4096 || last
        else
        {
            return
        }

        self.stream.compressBlocks(final: last)

        guard last,
        case .zlib = self.format
        else
        {
            return
        }
        // checksum is written big-endian, which means it has to go into the
        // bitstream msb-first
        let checksum:UInt32 = self.stream.input.checksum()
        self.stream.writeBigEndianUInt32(checksum)
    }
}
//  TODO: this currently only supports one member.
extension LZ77.DeflatorBuffers<Gzip.Format>
{
    init(format:Gzip.Format, level:Int, exponent:Int, hint:Int)
    {
        self.init(format: format,
            exponent: exponent,
            level: level,
            hint: hint)

        let header:Gzip.StreamHeader = .init(
            flag: (false, false, false, false, false),
            xlen: 0)

        header.write(&self.stream.output)
    }

    mutating
    func push(_ data:ArraySlice<UInt8>, last:Bool)
    {
        if !data.isEmpty
        {
            self.stream.input.enqueue(contentsOf: data)
        }
        guard self.stream.input.count > 4096 || last
        else
        {
            return
        }

        self.stream.compressBlocks(final: last)

        guard last
        else
        {
            return
        }

        let checksum:UInt32 = self.stream.input.checksum()
        let bytes:UInt32 = self.stream.input.integral.bytes
        self.stream.writeLittleEndianUInt32(checksum)
        self.stream.writeLittleEndianUInt32(bytes)
    }
}
extension LZ77.DeflatorBuffers
{
    mutating
    func pull() -> [UInt8]?
    {
        if  let complete:[UInt8] = self.pop()
        {
            return complete
        }

        let flushed:[UInt8] = self.stream.output.pull()
        return flushed.isEmpty ? nil : flushed
    }

    mutating
    func pop() -> [UInt8]?
    {
        self.stream.output.pop()
    }
}
