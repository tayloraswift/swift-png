extension Gzip
{
    @frozen public
    struct Inflator
    {
        private
        var buffers:LZ77.InflatorBuffers<Gzip.Format>
        private
        var state:InflatorState
    }
}
extension Gzip.Inflator
{
    public
    init()
    {
        self.buffers = .init(format: .gzip)
        self.state = .initial
    }
}
extension Gzip.Inflator
{
    /// Pushes **compressed** data to the inflator, returning nil once a complete gzip DEFLATE
    /// stream has been received.
    public mutating
    func push(_ data:ArraySlice<UInt8>) throws -> Void?
    {
        self.buffers.stream.push(data)

        advancing:
        do
        {
            switch try self.buffers.advance(state: self.state)
            {
            case .terminal?:
                return nil

            case let next?:
                self.state = next
                continue advancing

            case nil:
                return ()
            }
        }
    }

    public mutating
    func pull(_ count:Int) -> [UInt8]?
    {
        self.buffers.stream.pull(count)
    }
    public mutating
    func pull() -> [UInt8]
    {
        self.buffers.stream.pull()
    }
}
