extension LZ77.Deflator.Window
{
    struct Element
    {
        // stores a modular index
        var next:UInt16?
        let value:UInt8
    }
}
