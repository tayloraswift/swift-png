import PNG

extension PNG.SuggestedPalette:CustomStringConvertible
{
    public
    var description:String
    {
        let swatches:[String]
        switch self.entries
        {
        case .rgba8(let entries):
            swatches = entries.enumerated().map{ "        [\($0.0)]: \(String.swatch($0.1.color)) (\($0.1.frequency))" }
        case .rgba16(let entries):
            swatches = entries.enumerated().map{ "        [\($0.0)]: \(String.swatch($0.1.color)) (\($0.1.frequency))" }
        }
        return """
        PNG.\(Self.self) (\(PNG.Chunk.sPLT))
        {
            name        : '\(self.name)'
            entries     :
            [
        \(swatches.joined(separator: "\n"))
            ]
        }
        """
    }
}
