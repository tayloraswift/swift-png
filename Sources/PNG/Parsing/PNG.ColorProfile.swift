extension PNG 
{
    /// struct PNG.ColorProfile 
    ///     An embedded color profile.
    /// 
    ///     This type models the information stored in an [`(Chunk).iCCP`] chunk.
    /// # [Parsing and serialization](colorprofile-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct ColorProfile
    {
        /// let PNG.ColorProfile.name : Swift.String 
        ///     The name of this profile. 
        public 
        let name:String 
        /// let PNG.ColorProfile.profile : [Swift.UInt8]
        ///     The uncompressed [ICC](http://www.color.org/index.xalter) color 
        ///     profile data. 
        public 
        let profile:[UInt8]
        
        /// init PNG.ColorProfile.init(name:profile:)
        ///     Creates a color profile. 
        /// - name : Swift.String 
        ///     The profile name. 
        /// 
        ///     This string must contain only unicode scalars 
        ///     in the ranges `"\u{20}" ... "\u{7d}"` or `"\u{a1}" ... "\u{ff}"`. 
        ///     Leading, trailing, and consecutive spaces are not allowed. 
        ///     Passing an invalid string will result in a precondition failure.
        /// - profile : [Swift.UInt8]
        ///     The uncompressed [ICC](http://www.color.org/index.xalter) color 
        ///     profile data. The data will be compressed when this color profile 
        ///     is [`serialized`] into an [`(Chunk).iCCP`] chunk.
        public 
        init(name:String, profile:[UInt8])
        {
            guard PNG.Text.validate(name: name.unicodeScalars) 
            else 
            {
                PNG.ParsingError.invalidColorProfileName(name).fatal 
            }
            
            self.name       = name 
            self.profile    = profile 
        }
    }
}
extension PNG.ColorProfile 
{
    /// init PNG.ColorProfile.init(parsing:) 
    /// throws 
    ///     Creates a color profile by parsing the given chunk data.
    /// - data      : [Swift.UInt8]
    ///     The contents of an [`(Chunk).iCCP`] chunk to parse. 
    /// ## (colorprofile-parsing-and-serialization)
    public 
    init(parsing data:[UInt8]) throws 
    {
        //  ┌ ╶ ╶ ╶ ╶ ╶ ╶┬───┬───┬ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶┐
        //  │    name    │ 0 │ M │        profile         │
        //  └ ╶ ╶ ╶ ╶ ╶ ╶┴───┴───┴ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶ ╶┘
        //               k  k+1 k+2
        let k:Int 
        
        (self.name, k) = try PNG.Text.name(parsing: data[...]) 
        {
            PNG.ParsingError.invalidColorProfileName($0)
        }
        
        // assert existence of method byte
        guard k + 1 < data.endIndex 
        else 
        {
            throw PNG.ParsingError.invalidColorProfileChunkLength(data.count, min: k + 2)
        }
        
        guard data[k + 1] == 0
        else 
        {
            throw PNG.ParsingError.invalidColorProfileCompressionMethodCode(data[k + 1])
        }
        
        var inflator:LZ77.Inflator = .init()
        guard try inflator.push(.init(data.dropFirst(k + 2))) == nil 
        else 
        {
            throw PNG.ParsingError.incompleteColorProfileCompressedDatastream
        }
        
        self.profile = inflator.pull()
    }
    /// var PNG.ColorProfile.serialized : [Swift.UInt8] { get }
    ///     Encodes this color profile as the contents of an 
    ///     [`(Chunk).iCCP`] chunk.
    /// ## (colorprofile-parsing-and-serialization)
    public 
    var serialized:[UInt8]
    {
        var data:[UInt8] = []
        data.reserveCapacity(2 + self.name.count)
        
        data.append(contentsOf: self.name.unicodeScalars.map{ .init($0.value) })
        data.append(0)
        data.append(0) // compression method
        
        var deflator:LZ77.Deflator = .init(level: 13, exponent: 15, hint: 4096)
        deflator.push(self.profile, last: true)
        while true 
        {
            let segment:[UInt8] = deflator.pull()
            guard !segment.isEmpty 
            else 
            {
                break 
            }
            
            data.append(contentsOf: segment)
        }
        
        return data
    }
}
extension PNG.ColorProfile:CustomStringConvertible
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.iCCP)) 
        {
            name        : '\(self.name)' 
            profile     : <\(self.profile.count) bytes>
        }
        """
    }
}
