extension PNG 
{
    /// struct PNG.Context 
    ///     A decoding context. 
    /// 
    ///     This type provides support for custom decoding schemes. You can 
    ///     work through an example of its usage in the 
    ///     [online decoding tutorial](https://github.com/kelvin13/swift-png/tree/master/examples#online-decoding).
    /// ## (contextual-decoding)
    public 
    struct Context 
    {
        /// var PNG.Context.image : Data.Rectangular { get } 
        ///     The current image state.
        public private(set)
        var image:PNG.Data.Rectangular 
        
        private 
        var decoder:PNG.Decoder 
    }
}
extension PNG.Context 
{
    /// init PNG.Context.init?(standard:header:palette:background:transparency:metadata:uninitialized:)
    ///     Creates a fresh decoding context. 
    /// 
    ///     It is expected that client applications will initialize a decoding 
    ///     context upon encountering the first [`(Chunk).IDAT`] chunk in the image.
    /// - standard : Standard 
    ///     The PNG standard of the image being decoded. This should be [`(Standard).ios`]
    ///     if the image began with a [`(Chunk).CgBI`] chunk, and [`(Standard).common`]
    ///     otherwise.
    /// - header : Header 
    ///     The header of the image being decoded. This is expected to have been 
    ///     parsed from a previously-encountered [`(Chunk).IHDR`] chunk.
    /// - palette : Palette? 
    ///     The palette of the image being decoded, if present. If not `nil`, 
    ///     this is expected to have been parsed from a previously-encountered 
    ///     [`(Chunk).PLTE`] chunk.
    /// - background : Background? 
    ///     The background descriptor of the image being decoded, if present. 
    ///     If not `nil`, this is expected to have been parsed from a 
    ///     previously-encountered [`(Chunk).bKGD`] chunk.
    /// - transparency : Transparency? 
    ///     The transparency descriptor of the image being decoded, if present. 
    ///     If not `nil`, this is expected to have been parsed from a 
    ///     previously-encountered [`(Chunk).tRNS`] chunk.
    /// - metadata : Metadata 
    ///     A metadata instance. It is expected to contain metadata from all 
    ///     previously-encountered ancillary chunks, with the exception of 
    ///     [`(Chunk).bKGD`] and [`(Chunk).tRNS`].
    /// - uninitialized : Swift.Bool 
    ///     Specifies if the [`image`] [`(Data.Rectangular).storage`] should 
    ///     be initialized. If `false`, the storage buffer will be initialized 
    ///     to all zeros. This can be safely set to `true` if there is no need 
    ///     to access the image while it is in a partially-decoded state.
    /// 
    ///     The default value is `true`.
    public 
    init?(standard:PNG.Standard, header:PNG.Header, 
        palette:PNG.Palette?, background:PNG.Background?, transparency:PNG.Transparency?, 
        metadata:PNG.Metadata, 
        uninitialized:Bool = true) 
    {
        guard let image:PNG.Data.Rectangular = PNG.Data.Rectangular.init(
            standard:       standard, 
            header:         header, 
            palette:        palette, 
            background:     background, 
            transparency:   transparency, 
            metadata:       metadata, 
            uninitialized:  uninitialized)
        else 
        {
            return nil 
        }
        
        self.image      = image 
        self.decoder    = .init(standard: standard, interlaced: image.layout.interlaced)
    }
    /// mutating func PNG.Context.push(data:overdraw:)
    /// throws 
    ///     Decompresses the contents of an [`(Chunk).IDAT`] chunk, and updates 
    ///     the image state with the newly-decompressed image data. 
    /// - data : [Swift.UInt8]
    ///     The contents of the [`(Chunk).IDAT`] chunk to process.
    /// - overdraw : Swift.Bool 
    ///     If `true`, pixels that are not yet available will be filled-in 
    ///     with values from nearby available pixels. This option only has an 
    ///     effect for [`(Layout).interlaced`] images. 
    /// 
    ///     The default value is `false`.
    /// ## ()
    public mutating 
    func push(data:[UInt8], overdraw:Bool = false) throws 
    {
        try self.decoder.push(data, size: self.image.size, 
            pixel: self.image.layout.format.pixel, 
            delegate: overdraw ? 
        {
            let s:(x:Int, y:Int) = ($1.x == 0 ? 0 : 1, $1.y & 0b111 == 0 ? 0 : 1)
            self.image.assign(scanline: $0, at: $1, stride: $2.x)
            self.image.overdraw(            at: $1, brush: ($2.x >> s.x, $2.y >> s.y))
        } 
        : 
        {
            self.image.assign(scanline: $0, at: $1, stride: $2.x)
        }) 
    }
    /// mutating func PNG.Context.push(ancillary:)
    /// throws 
    ///     Parses an ancillary chunk appearing after the last [`(Chunk).IDAT`] 
    ///     chunk, and adds it to the [`image`] [`(Data.Rectangular).metadata`]. 
    /// 
    ///     This function validates the multiplicity of the given `chunk`, and 
    ///     its chunk ordering with respect to the [`(Chunk).IDAT`] chunks. The 
    ///     caller is expected to have consumed all preceeding [`(Chunk).IDAT`] 
    ///     chunks in the image being decoded.
    /// 
    ///     Despite its name, this function can also accept an [`(Chunk).IEND`] 
    ///     critical chunk, in which case this function will verify that the 
    ///     compressed image data stream has been properly-terminated.
    /// - chunk : (type:Chunk, data:[Swift.UInt8])
    ///     The chunk to process. Its `type` must be one of [`(Chunk).tIME`], 
    ///     [`(Chunk).iTXt`], [`(Chunk).tEXt`], [`(Chunk).zTXt`], or [`(Chunk).IEND`], 
    ///     or a private application data chunk type. 
    /// 
    ///     All other chunk types will `throw` appropriate errors.
    /// ## ()
    public mutating 
    func push(ancillary chunk:(type:PNG.Chunk, data:[UInt8])) throws 
    {
        switch chunk.type 
        {
        case .tIME:
            try PNG.Metadata.unique(assign: chunk.type, to: &self.image.metadata.time) 
            {
                try .init(parsing: chunk.data)
            }
        case .iTXt:
            self.image.metadata.text.append(try .init(parsing: chunk.data))
        case .tEXt, .zTXt:
            self.image.metadata.text.append(try .init(parsing: chunk.data, unicode: false))
        case .CgBI, .IHDR, .PLTE, .bKGD, .tRNS, .hIST, 
            .cHRM, .gAMA, .sRGB, .iCCP, .sBIT, .pHYs, .sPLT, .IDAT:
            throw PNG.DecodingError.unexpected(chunk: chunk.type, after: .IDAT) 
        case .IEND: 
            guard self.decoder.continue == nil 
            else 
            {
                throw PNG.DecodingError.incompleteImageDataCompressedDatastream
            } 
        default:
            self.image.metadata.application.append(chunk)
        }
    }
}
