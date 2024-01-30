extension LZ77.Deflator.Window
{
    @frozen @usableFromInline
    struct Element
    {
        // stores a modular index
        var next:UInt16?
        let value:UInt8
    }
}
