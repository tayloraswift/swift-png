extension PNG 
{
    /// struct PNG.Histogram 
    ///     A palette frequency histogram.
    /// 
    ///     This type models the information stored in a [`(Chunk).hIST`] chunk.
    /// # [Parsing and serialization](histogram-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct Histogram 
    {
        /// let PNG.Histogram.frequencies : [Swift.UInt16]
        ///     The frequency values of this histogram.
        /// 
        ///     The *i*th frequency value corresponds to the *i*th entry in the 
        ///     image palette.
        public 
        let frequencies:[UInt16]
    }
}
extension PNG.Histogram 
{
    /// init PNG.Histogram.init(frequencies:palette:)
    ///     Creates a palette histogram.
    /// 
    ///     This initializer validates the background information against the 
    ///     given image palette.
    /// - frequencies : [Swift.UInt16]
    ///     The frequency of each palette entry in the image. The *i*th frequency 
    ///     value corresponds to the *i*th palette entry. This array must have the 
    ///     the exact same number of elements as entries in the image palette. 
    ///     Passing an array of the wrong length will result in a precondition 
    ///     failure.
    /// - palette   : PNG.Palette 
    ///     The image palette this histogram provides frequency information for.
    public 
    init(frequencies:[UInt16], palette:PNG.Palette)
    {
        guard frequencies.count == palette.entries.count
        else 
        {
            fatalError("number of histogram entries (\(frequencies.count)) must match number of palette entries (\(palette.entries.count))")
        }
        
        self.frequencies = frequencies
    }
    /// init PNG.Histogram.init(parsing:palette:) 
    /// throws 
    ///     Creates a palette histogram by parsing the given chunk data, 
    ///     validating it according to the given image `palette`.
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).hIST`] chunk to parse. 
    /// - palette   : Palette
    ///     The image palette the chunk data is to be validated against.
    /// ## (histogram-parsing-and-serialization)
    public 
    init(parsing data:[UInt8], palette:PNG.Palette) throws
    {
        guard data.count == 2 * palette.entries.count
        else 
        {
            throw PNG.ParsingError.invalidHistogramChunkLength(data.count, 
                expected: 2 * palette.entries.count)
        }
        self.frequencies = (0 ..< data.count >> 1).map 
        {
            data.load(bigEndian: UInt16.self, as: UInt16.self, at: $0 << 1)
        }
    }
    /// var PNG.Histogram.serialized : [Swift.UInt8] { get }
    ///     Encodes this histogram as the contents of a 
    ///     [`(Chunk).hIST`] chunk.
    /// ## (histogram-parsing-and-serialization)
    public 
    var serialized:[UInt8] 
    {
        .init(unsafeUninitializedCapacity: 2 * self.frequencies.count) 
        {
            for (i, frequency):(Int, UInt16) in self.frequencies.enumerated()
            {
                $0.store(frequency, asBigEndian: UInt16.self, at: i << 1)
            }
            $1 = 2 * self.frequencies.count
        }
    }
}
extension PNG.Histogram:CustomStringConvertible
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.hIST)) 
        {
            frequencies : <\(self.frequencies.count) entries> 
        }
        """
    }
}
