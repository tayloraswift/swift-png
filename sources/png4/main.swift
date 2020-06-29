extension PNG 
{
    enum Data 
    {
    }
}
extension PNG.Data 
{
    struct Rectangular 
    {
    }
}
extension PNG.Data.Rectangular 
{
    static 
    func decompress<Source>(stream:inout Source) throws -> Self 
        where Source:PNG.Bytestream.Source
    {
        try stream.signature()
        switch try stream.chunk()
        {
        case (.CgBI, let data):
            break
        case (.IHDR, let data):
            print(data)
        default:
            break
        }
        fatalError()
    }
}

guard let _:Void = 
    (try System.File.Source.open(path: "tests/integration/png/PngSuite.png")
{
    let _:PNG.Data.Rectangular = try .decompress(stream: &$0)
})
else 
{
    fatalError("failed to open file")
}
