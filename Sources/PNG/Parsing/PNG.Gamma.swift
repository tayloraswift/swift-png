extension PNG 
{
    /// struct PNG.Gamma 
    ///     A gamma descriptor.
    /// 
    ///     This type models the information stored in a [`(Chunk).gAMA`] chunk.
    /// # [Parsing and serialization](gamma-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct Gamma 
    {
        /// let PNG.Gamma.value : Percentmille 
        ///     The gamma value of an image, expressed as a fraction.
        public 
        let value:Percentmille 
        /// init PNG.Gamma.init(value:)
        ///     Creates a gamma descriptor with the given value.
        /// - value : Percentmille 
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
    /// init PNG.Gamma.init(parsing:) 
    /// throws 
    ///     Creates a gamma descriptor by parsing the given chunk data.
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).gAMA`] chunk to parse. 
    /// ## (gamma-parsing-and-serialization)
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
    /// var PNG.Gamma.serialized : [Swift.UInt8] { get }
    ///     Encodes this gamma descriptor as the contents of a 
    ///     [`(Chunk).gAMA`] chunk.
    /// ## (gamma-parsing-and-serialization)
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
