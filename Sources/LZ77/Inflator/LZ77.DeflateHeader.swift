extension LZ77
{
    @frozen public
    struct DeflateHeader
    {
        public
        let exponent:Int

        @inlinable public
        init(exponent:Int)
        {
            self.exponent = exponent
        }
    }
}
extension LZ77.DeflateHeader:LZ77.StreamHeader
{
    public
    var window:Int { 1 << self.exponent }
}
