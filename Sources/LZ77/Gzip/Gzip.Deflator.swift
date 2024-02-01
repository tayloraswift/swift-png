extension Gzip
{
    @frozen public
    struct Deflator
    {
        private
        var buffers:LZ77.DeflatorBuffers<Gzip.Format>

        public
        init(level:Int, exponent:Int = 15, hint:Int = 1 << 12)
        {
            self.buffers = .init(format: .gzip, level: level, exponent: exponent, hint: hint)
        }
    }
}
extension Gzip.Deflator
{
    public mutating
    func push(_ data:ArraySlice<UInt8>, last:Bool = false)
    {
        self.buffers.push(data, last: last)
    }

    /// Returns a block of gzip-compressed data from this deflator, if available. If no
    /// compressed data blocks have been completed yet, this method flushes and returns the
    /// incomplete block.
    public mutating
    func pull() -> [UInt8]?
    {
        self.buffers.pull()
    }

    /// Removes and returns a complete block of gzip-compressed data from this deflator, if
    /// available.
    public mutating
    func pop() -> [UInt8]?
    {
        self.buffers.pop()
    }
}
