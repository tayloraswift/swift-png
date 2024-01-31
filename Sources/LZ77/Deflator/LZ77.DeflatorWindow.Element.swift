extension LZ77.DeflatorWindow
{
    @frozen @usableFromInline
    struct Element
    {
        // stores a modular index
        var next:UInt16?
        let value:UInt8
    }
}
