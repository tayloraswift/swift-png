extension PNG 
{
    /// struct PNG.PhysicalDimensions 
    ///     A physical dimensions descriptor.
    /// 
    ///     This type models the information stored in a [`(Chunk).pHYs`] chunk.
    /// # [Parsing and serialization](physicaldimensions-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct PhysicalDimensions
    {
        /// enum PNG.PhysicalDimensions.Unit 
        ///     A unit of measurement.
        public 
        enum Unit 
        {
            /// case PNG.PhysicalDimensions.Unit.meter 
            ///     The meter. 
            /// 
            ///     For conversion purposes, one inch is assumed to equal exactly 
            ///     `254 / 10000` meters.
            case meter
        }
        
        /// let PNG.PhysicalDimensions.density : (x:Swift.Int, y:Swift.Int, unit:Unit?)
        ///     The number of pixels in each dimension per the given `unit` of 
        ///     measurement. 
        /// 
        ///     If `unit` is `nil`, the pixel density is unknown, 
        ///     and the `x` and `y` values specify the pixel aspect ratio only.
        public 
        let density:(x:Int, y:Int, unit:Unit?)
        
        /// init PNG.PhysicalDimensions.init(density:) 
        ///     Creates a physical dimensions descriptor. 
        /// - density : (x:Swift.Int, y:Swift.Int, unit:Unit?)
        ///     The number of pixels in each dimension per the given `unit` of 
        ///     measurement. 
        /// 
        ///     If `unit` is `nil`, the pixel density is unknown, 
        ///     and the `x` and `y` values specify the pixel aspect ratio only.
        public 
        init(density:(x:Int, y:Int, unit:Unit?)) 
        {
            self.density = density 
        }
    }
}
extension PNG.PhysicalDimensions 
{
    /// init PNG.PhysicalDimensions.init(parsing:) 
    /// throws 
    ///     Creates a physical dimensions descriptor by parsing the given chunk data.
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).pHYs`] chunk to parse. 
    /// ## (physicaldimensions-parsing-and-serialization)
    public 
    init(parsing data:[UInt8]) throws 
    {
        guard data.count == 9
        else 
        {
            throw PNG.ParsingError.invalidPhysicalDimensionsChunkLength(data.count)
        }
        
        self.density.x = data.load(bigEndian: UInt32.self, as: Int.self, at: 0)
        self.density.y = data.load(bigEndian: UInt32.self, as: Int.self, at: 4)
        
        switch data[8]
        {
        case 0:     self.density.unit = nil 
        case 1:     self.density.unit = .meter 
        case let code:    
            throw PNG.ParsingError.invalidPhysicalDimensionsDensityUnitCode(code)
        }
    }
    /// var PNG.PhysicalDimensions.serialized : [Swift.UInt8] { get }
    ///     Encodes this physical dimensions descriptor as the contents of a 
    ///     [`(Chunk).pHYs`] chunk.
    /// ## (physicaldimensions-parsing-and-serialization)
    public 
    var serialized:[UInt8]
    {
        .init(unsafeUninitializedCapacity: 9) 
        {
            $0.store(self.density.x, asBigEndian: UInt32.self, at:  0)
            $0.store(self.density.y, asBigEndian: UInt32.self, at:  4)
            
            switch self.density.unit 
            {
            case nil:       $0[8] = 0
            case .meter?:   $0[8] = 1
            }
            $1 = $0.count
        }
    }
}
extension PNG.PhysicalDimensions:CustomStringConvertible
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.pHYs)) 
        {
            density     : (x: \(self.density.x), y: \(self.density.y)) \(self.density.unit.map{ "/ \($0)" } ?? "(no units)")
        }
        """
    }
}
