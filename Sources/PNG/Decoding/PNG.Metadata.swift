extension PNG 
{
    /// struct PNG.Metadata 
    ///     The metadata in an image.
    /// ## (2:images)
    public 
    struct Metadata 
    {
        /// var PNG.Metadata.time : TimeModified?
        ///     The image modification time. 
        public 
        var time:PNG.TimeModified?, 
        /// var PNG.Metadata.chromaticity : Chromaticity? 
        ///     The image chromaticity.
            chromaticity:PNG.Chromaticity?,
        /// var PNG.Metadata.colorProfile : ColorProfile? 
        ///     The image color profile.
            colorProfile:PNG.ColorProfile?,
        /// var PNG.Metadata.colorRendering : ColorRendering? 
        ///     The image color rendering mode. 
            colorRendering:PNG.ColorRendering?,
        /// var PNG.Metadata.gamma : Gamma? 
        ///     The image gamma. 
            gamma:PNG.Gamma?,
        /// var PNG.Metadata.histogram : Histogram? 
        ///     The frequency histogram of the image palette.
            histogram:PNG.Histogram?,
        /// var PNG.Metadata.physicalDimensions : PhysicalDimensions? 
        ///     The physical dimensions of the image.
            physicalDimensions:PNG.PhysicalDimensions?,
        /// var PNG.Metadata.significantBits : SignificantBits? 
        ///     The image color precision.
            significantBits:PNG.SignificantBits?
        /// var PNG.Metadata.suggestedPalettes : [SuggestedPalette]
        ///     The suggested palettes of the image.
        public 
        var suggestedPalettes:[PNG.SuggestedPalette]        = [],
        /// var PNG.Metadata.text : [Text]
        ///     The text comments in the image.
            text:[PNG.Text]                                 = [],
        /// var PNG.Metadata.application : [(type:Chunk, data:[Swift.UInt8])] 
        ///     An array containing any unparsed application-specific chunks 
        ///     in the image.
            application:[(type:PNG.Chunk, data:[UInt8])]    = []
        
        /// init PNG.Metadata.init(time:chromaticity:colorProfile:colorRendering:gamma:histogram:physicalDimensions:significantBits:suggestedPalettes:text:application:)
        ///     Creates a metadata structure. 
        /// - time : TimeModified?
        ///     An optional modification time. 
        /// - chromaticity : Chromaticity? 
        ///     An optional chromaticity descriptor.
        /// - colorProfile : ColorProfile? 
        ///     An optional color profile.
        /// - colorRendering : ColorRendering? 
        ///     An optional color rendering mode. 
        /// - gamma : Gamma? 
        ///     An optional gamma descriptor. 
        /// - histogram : Histogram? 
        ///     An optional palette frequency histogram.
        /// - physicalDimensions : PhysicalDimensions? 
        ///     An optional physical dimensions descriptor.
        /// - significantBits : SignificantBits? 
        ///     An optional color precision descriptor.
        /// - suggestedPalettes : [SuggestedPalette]
        ///     An array of suggested palettes.
        /// - text : [Text]
        ///     An array of text comments.
        /// - application : [(type:Chunk, data:[Swift.UInt8])] 
        ///     An array of unparsed application-specific chunks.
        /// 
        ///     This array is allowed to contain public PNG chunks, though it 
        ///     is recommended to use the library’s strongly-typed interfaces 
        ///     instead for such chunks.
        public 
        init(time:PNG.TimeModified?                     = nil,
            chromaticity:PNG.Chromaticity?              = nil,
            colorProfile:PNG.ColorProfile?              = nil,
            colorRendering:PNG.ColorRendering?          = nil,
            gamma:PNG.Gamma?                            = nil,
            histogram:PNG.Histogram?                    = nil,
            physicalDimensions:PNG.PhysicalDimensions?  = nil,
            significantBits:PNG.SignificantBits?        = nil, 
            
            
            suggestedPalettes:[PNG.SuggestedPalette]        = [], 
            text:[PNG.Text]                                 = [], 
            application:[(type:PNG.Chunk, data:[UInt8])]    = [])
        {
            self.time               = time
            self.chromaticity       = chromaticity
            self.colorProfile       = colorProfile
            self.colorRendering     = colorRendering
            self.gamma              = gamma
            self.histogram          = histogram
            self.physicalDimensions = physicalDimensions
            self.significantBits    = significantBits
            self.suggestedPalettes  = suggestedPalettes
            self.text               = text
            self.application        = application
        }
    }
}
extension PNG.Metadata 
{
    static 
    func unique<T>(assign type:PNG.Chunk, to destination:inout T?, 
        parser:() throws -> T) throws 
    {
        guard destination == nil 
        else 
        {
            throw PNG.DecodingError.duplicate(chunk: type)
        }
        destination = try parser()
    }
    /// mutating func PNG.Metadata.push(ancillary:pixel:palette:background:transparency:)
    /// throws 
    ///     Parses an ancillary chunk, and either adds it to this metadata instance, 
    ///     or stores it in one of the two `inout` parameters. 
    /// 
    ///     If the given `chunk` is a [`(Chunk).bKGD`] or [`(Chunk).tRNS`] chunk, 
    ///     it will be stored in its respective `inout` variable. Otherwise it 
    ///     will be stored within this metadata instance.
    /// 
    ///     This function parses and validates the given `chunk` according to the 
    ///     image `pixel` format and `palette`. It also validates its multiplicity, and 
    ///     its chunk ordering with respect to the [`(Chunk).PLTE`] chunk. 
    /// - chunk : (type:Chunk, data:[Swift.UInt8])
    ///     The chunk to process. 
    /// 
    ///     The `type` identifier of this chunk must not be a critical chunk type. 
    ///     (Critical chunk types are [`(Chunk).CgBI`], [`(Chunk).IHDR`], 
    ///     [`(Chunk).PLTE`], [`(Chunk).IDAT`], and [`(Chunk).IEND`].) Passing 
    ///     a critical chunk to this function will result in a precondition 
    ///     failure. 
    /// - pixel : Format.Pixel 
    ///     The image pixel format.
    /// - palette : Palette? 
    ///     The image palette, if available. Client applications are expected to 
    ///     set this parameter to `nil` if the [`(Chunk).PLTE`] chunk has not 
    ///     yet been encountered.
    /// - background : inout Background? 
    ///     The background descriptor, if available. If this function receives 
    ///     a [`(Chunk).bKGD`] chunk, it will be parsed and stored in this 
    ///     variable. Client applications are expected to initialize it to `nil`, 
    ///     and should not overwrite it between subsequent calls while processing 
    ///     the same image.
    /// - transparency : inout Transparency? 
    ///     The transparency descriptor, if available. If this function receives 
    ///     a [`(Chunk).tRNS`] chunk, it will be parsed and stored in this 
    ///     variable. Client applications are expected to initialize it to `nil`, 
    ///     and should not overwrite it between subsequent calls while processing 
    ///     the same image.
    public mutating 
    func push(ancillary chunk:(type:PNG.Chunk, data:[UInt8]), 
        pixel:PNG.Format.Pixel, palette:PNG.Palette?, 
        background:inout PNG.Background?, 
        transparency:inout PNG.Transparency?) throws 
    {
        switch chunk.type 
        {
        // check before-palette chunk ordering 
        case .cHRM, .gAMA, .sRGB, .iCCP, .sBIT:
            guard palette == nil 
            else 
            {
                throw PNG.DecodingError.unexpected(chunk: chunk.type, after: .PLTE)
            } 
        // check that chunk is not a critical chunk 
        case .CgBI, .IHDR, .PLTE, .IDAT, .IEND: 
            fatalError("Metadata.push(ancillary:pixel:palette:background:transparency:) cannot be used with critical chunk type '\(chunk.type)'")
        default:
            break 
        }
        
        switch chunk.type 
        {
        case .bKGD:
            try Self.unique(assign: chunk.type, to: &background) 
            {
                try .init(parsing: chunk.data, pixel: pixel, palette: palette)
            }
        case .tRNS:
            try Self.unique(assign: chunk.type, to: &transparency) 
            {
                try .init(parsing: chunk.data, pixel: pixel, palette: palette)
            }
            
        case .hIST:
            guard let palette:PNG.Palette = palette 
            else 
            {
                throw PNG.DecodingError.required(chunk: .PLTE, before: .hIST)
            }
            try Self.unique(assign: chunk.type, to: &self.histogram) 
            {
                try .init(parsing: chunk.data, palette: palette)
            }
        
        case .cHRM:
            try Self.unique(assign: chunk.type, to: &self.chromaticity) 
            {
                try .init(parsing: chunk.data)
            }
        case .gAMA:
            try Self.unique(assign: chunk.type, to: &self.gamma) 
            {
                try .init(parsing: chunk.data)
            }
        case .sRGB:
            try Self.unique(assign: chunk.type, to: &self.colorRendering) 
            {
                try .init(parsing: chunk.data)
            }
        case .iCCP:
            try Self.unique(assign: chunk.type, to: &self.colorProfile) 
            {
                try .init(parsing: chunk.data)
            }
        case .sBIT:
            try Self.unique(assign: chunk.type, to: &self.significantBits) 
            {
                try .init(parsing: chunk.data, pixel: pixel)
            }
        
        case .pHYs:
            try Self.unique(assign: chunk.type, to: &self.physicalDimensions) 
            {
                try .init(parsing: chunk.data)
            }
        case .tIME:
            try Self.unique(assign: chunk.type, to: &self.time) 
            {
                try .init(parsing: chunk.data)
            }
        
        case .sPLT:
            self.suggestedPalettes.append(try .init(parsing: chunk.data))
        case .iTXt:
            self.text.append(try .init(parsing: chunk.data))
        case .tEXt, .zTXt:
            self.text.append(try .init(parsing: chunk.data, unicode: false))
        
        default:
            self.application.append(chunk)
        }
    }
}
extension PNG.Metadata:CustomStringConvertible 
{
    public 
    var description:String 
    {
        [
            // singletons 
            [
                self.time.map               (\.description),
                self.chromaticity.map       (\.description),
                self.colorProfile.map       (\.description),
                self.colorRendering.map     (\.description),
                self.gamma.map              (\.description),
                self.histogram.map          (\.description),
                self.physicalDimensions.map (\.description),
                self.significantBits.map    (\.description),
            ].compactMap{ $0 },
            self.suggestedPalettes.map      (\.description),
            self.text.map                   (\.description),
            self.application.map 
            {
                """
                <unknown> (\($0.type)) 
                {
                    data        : <\($0.data.count) bytes>
                }
                """
            },
        ].flatMap{ $0 }.joined(separator: "\n")
    }
}
