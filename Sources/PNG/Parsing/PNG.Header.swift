extension PNG 
{
    /// struct PNG.Header 
    ///     An image header.
    /// 
    ///     This type models the information stored in a [`(Chunk).IHDR`] chunk.
    /// # [Parsing and serialization](header-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct Header
    {
        /// let PNG.Header.size         : (x:Swift.Int, y:Swift.Int) 
        ///     The size of an image, measured in pixels.
        public
        let size:(x:Int, y:Int), 
        /// let PNG.Header.pixel        : Format.Pixel
        ///     The pixel format of an image.
            pixel:PNG.Format.Pixel, 
        /// let PNG.Header.interlaced   : Swift.Bool 
        ///     Indicates whether an image uses interlacing.
            interlaced:Bool
        
        /// init PNG.Header.init(size:pixel:interlaced:standard:)
        ///     Creates an image header. 
        /// 
        ///     This initializer validates the image `size`, and validates the 
        ///     `pixel` format against the given PNG `standard`.
        /// - size      : (x:Swift.Int, y:Swift.Int) 
        ///     An image size, measured in pixels.
        /// 
        ///     Passing a `size` with a zero or negative dimension 
        ///     will result in a precondition failure.
        /// - pixel     : Format.Pixel
        ///     A pixel format.
        /// - interlaced: Swift.Bool 
        ///     Indicates if interlacing is enabled.
        /// - standard  : Standard 
        ///     Specifies if the header is for a standard image, 
        ///     or an iphone-optimized image. 
        /// 
        ///     If `standard` is [`(Standard).ios`], then the `pixel` format 
        ///     must be either [`(Format.Pixel).rgb8`] or [`(Format.Pixel).rgba8`].
        ///     Otherwise, this initializer will suffer a precondition failure.
        public 
        init(size:(x:Int, y:Int), pixel:PNG.Format.Pixel, interlaced:Bool, 
            standard:PNG.Standard) 
        {
            guard size.x > 0, size.y > 0 
            else 
            {
                PNG.ParsingError.invalidHeaderSize(size).fatal
            }
            // iphone-optimized PNG can only have pixel type rgb8 or rgb16
            switch (standard, pixel)
            {
            case    (.common, _):   break 
            case    (.ios, .rgb8), 
                    (.ios, .rgba8): break
            default: 
                PNG.ParsingError.invalidHeaderPixelFormat(pixel, standard: standard).fatal
            }
            self.size       = size 
            self.pixel      = pixel 
            self.interlaced = interlaced
        }
    }
}
extension PNG.Header 
{
    /// init PNG.Header.init(parsing:standard:) 
    /// throws 
    ///     Creates an image header by parsing the given chunk data, interpreting it 
    ///     according to the given PNG `standard`.
    /// - data      : [Swift.UInt8]
    ///     The contents of an [`(Chunk).IHDR`] chunk to parse. 
    /// - standard  : Standard 
    ///     Specifies if the header should be interpreted as a standard PNG header, 
    ///     or an iphone-optimized PNG header. 
    /// ## (header-parsing-and-serialization)
    public 
    init(parsing data:[UInt8], standard:PNG.Standard) throws 
    {
        guard data.count == 13
        else
        {
            throw PNG.ParsingError.invalidHeaderChunkLength(data.count)
        }
        
        guard let pixel:PNG.Format.Pixel = .recognize(code: (data[8], data[9]))
        else
        {
            throw PNG.ParsingError.invalidHeaderPixelFormatCode((data[8], data[9]))
        }
        
        // iphone-optimized PNG can only have pixel type rgb8 or rgb16
        switch (standard, pixel)
        {
        case    (.common, _):   break 
        case    (.ios, .rgb8), 
                (.ios, .rgba8): break
        default: 
            throw PNG.ParsingError.invalidHeaderPixelFormat(pixel, standard: standard)
        }
        
        self.pixel = pixel 

        // validate other fields
        guard data[10] == 0
        else
        {
            throw PNG.ParsingError.invalidHeaderCompressionMethodCode(data[10])
        }
        guard data[11] == 0
        else
        {
            throw PNG.ParsingError.invalidHeaderFilterCode(data[11])
        }

        switch data[12]
        {
        case 0:
            self.interlaced = false
        case 1:
            self.interlaced = true
        case let code:
            throw PNG.ParsingError.invalidHeaderInterlacingCode(code)
        }
        
        self.size.x = data.load(bigEndian: UInt32.self, as: Int.self, at: 0)
        self.size.y = data.load(bigEndian: UInt32.self, as: Int.self, at: 4)
        // validate size 
        guard self.size.x > 0, self.size.y > 0 
        else 
        {
            throw PNG.ParsingError.invalidHeaderSize(self.size)
        }
    }
    
    /// var PNG.Header.serialized   : [Swift.UInt8] { get }
    ///     Encodes this image header as the contents of an [`(Chunk).IHDR`] chunk.
    /// ## (header-parsing-and-serialization)
    public 
    var serialized:[UInt8] 
    {
        .init(unsafeUninitializedCapacity: 13) 
        {
            $0.store(self.size.x, asBigEndian: UInt32.self, at: 0)
            $0.store(self.size.y, asBigEndian: UInt32.self, at: 4)
            ($0[8], $0[9])  = self.pixel.code 
            $0[10]          = 0
            $0[11]          = 0
            $0[12]          = self.interlaced ? 1 : 0
            $1              = 13
        }
    }
}
