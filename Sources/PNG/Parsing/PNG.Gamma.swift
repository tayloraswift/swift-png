extension PNG
{
    /// A gamma descriptor.
    ///
    /// This type models the information stored in a ``Chunk/gAMA`` chunk.
    public
    struct Gamma
    {
        /// The gamma value of an image, expressed as a fraction.
        public
        let value:Percentmille
        /// Creates a gamma descriptor with the given value.
        /// -   Parameter value:
        ///     A rational gamma value.
        public
        init(value:Percentmille)
        {
            self.value = value
        }
    }
}
extension PNG.Gamma
{
    /// Creates a gamma descriptor by parsing the given chunk data.
    /// -   Parameter data:
    ///     The contents of a ``Chunk/gAMA`` chunk to parse.
    public
    init(parsing data:[UInt8]) throws
    {
        guard data.count == 4
        else
        {
            throw PNG.ParsingError.invalidGammaChunkLength(data.count)
        }

        self.value = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 0))
    }
    /// Encodes this gamma descriptor as the contents of a
    /// ``Chunk/gAMA`` chunk.
    public
    var serialized:[UInt8]
    {
        .init(unsafeUninitializedCapacity: MemoryLayout<UInt32>.size)
        {
            $0.store(self.value.points, asBigEndian: UInt32.self, at: 0)
            $1 = $0.count
        }
    }
}
extension PNG.Gamma:CustomStringConvertible
{
    public
    var description:String
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.gAMA))
        {
            value       : \(self.value)
        }
        """
    }
}
