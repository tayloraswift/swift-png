extension PNG 
{
    /// enum PNG.Format 
    ///     A color format.
    /// 
    ///     This color format enumeration combines two sets of PNG color formats. 
    ///     It can represent the fifteen standard color formats from the core 
    ///     [PNG specification](http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.IHDR), 
    ///     as well as two iphone-optimized color formats from Apple’s PNG extensions.
    /// 
    ///     Some color formats contain a `palette`, an optional background `fill` color, 
    ///     and an optional chroma `key`. For most use cases, the background `fill` 
    ///     and chroma `key` can be set to `nil`. For the indexed color formats, 
    ///     a non-empty `palette` is mandatory. For all other color formats, the `palette` 
    ///     can be set to the empty array `[]`. 
    /// 
    ///     Color format validation takes place when initializing a [`Layout`] instance, 
    ///     which stores the color format in a [`Data.Rectangular`] image.
    /// # [Grayscale formats](grayscale-color-formats)
    /// # [Grayscale-alpha formats](grayscale-alpha-color-formats)
    /// # [Indexed formats](indexed-color-formats)
    /// # [RGB formats](rgb-color-formats)
    /// # [RGBA formats](rgba-color-formats)
    /// # [iPhone-optimized color formats](ios-color-formats)
    /// # [See also](color-formats)
    /// ## (0:color-formats)
    public 
    enum Format 
    {
        /// enum PNG.Format.Pixel 
        ///     A pixel format. 
        /// 
        ///     A pixel format specifies the color model and bit depth used by an 
        ///     image. They do not specify the ordering of the color samples within 
        ///     the internal representation of a PNG image. For example, the color formats
        ///     [`(Format).rgba8(palette:fill:)`] and [`(Format).bgra8(palette:fill:)`] 
        ///     both correspond to the pixel format [`(Pixel).rgba8`].
        /// 
        ///     The pixel format associated with a color format can be accessed 
        ///     through the [`(Format).pixel`] instance property.
        /// # [Pixel formats](pixel-formats)
        /// # [See also](color-formats)
        /// ## (0:color-formats)
        public 
        enum Pixel 
        {
            /// case PNG.Format.Pixel.v1 
            ///     Pixels are stored as 1-bit grayscale values. 
            /// 
            ///     An image with this pixel format has a bit depth and a color 
            ///     depth of `1`. Each sample is in the range `0 ... 1`.
            /// ## (pixel-formats)
            case v1
            /// case PNG.Format.Pixel.v2 
            ///     Pixels are stored as 2-bit grayscale values.
            /// 
            ///     An image with this pixel format has a bit depth and a color 
            ///     depth of `2`. Each sample is in the range `0 ... 3`.
            /// ## (pixel-formats)
            case v2 
            /// case PNG.Format.Pixel.v4 
            ///     Pixels are stored as 4-bit grayscale values.
            /// 
            ///     An image with this pixel format has a bit depth and a color 
            ///     depth of `4`. Each sample is in the range `0 ... 15`.
            /// ## (pixel-formats)
            case v4 
            /// case PNG.Format.Pixel.v8 
            ///     Pixels are stored as 8-bit grayscale values.
            /// 
            ///     An image with this pixel format has a bit depth and a color 
            ///     depth of `8`. Each sample is in the range `0 ... 255`.
            /// ## (pixel-formats)
            case v8 
            /// case PNG.Format.Pixel.v16 
            ///     Pixels are stored as 16-bit grayscale values.
            /// 
            ///     An image with this pixel format has a bit depth and a color 
            ///     depth of `16`. Each sample is in the range `0 ... 65535`.
            /// ## (pixel-formats)
            case v16 
            
            /// case PNG.Format.Pixel.rgb8 
            ///     Pixels are stored as 8-bit RGB triplets.
            /// 
            ///     An image with this pixel format has a bit depth and a color 
            ///     depth of `8`, for a total stride of `24` bits. 
            ///     Each sample is in the range `0 ... 255`.
            /// ## (pixel-formats)
            case rgb8 
            /// case PNG.Format.Pixel.rgb16 
            ///     Pixels are stored as 16-bit RGB triplets.
            /// 
            ///     An image with this pixel format has a bit depth and a color 
            ///     depth of `16`, for a total stride of `48` bits. 
            ///     Each sample is in the range `0 ... 65535`.
            /// ## (pixel-formats)
            case rgb16 
            
            /// case PNG.Format.Pixel.indexed1 
            ///     Pixels are stored as 1-bit indices. 
            /// 
            ///     An image with this pixel format has a bit depth of `1`, and 
            ///     a color depth of `8`. Each index is in the range `0 ... 1`, 
            ///     and can reference an entry in a palette with at most `2` elements.
            /// ## (pixel-formats)
            case indexed1
            /// case PNG.Format.Pixel.indexed2 
            ///     Pixels are stored as 2-bit indices. 
            /// 
            ///     An image with this pixel format has a bit depth of `2`, and 
            ///     a color depth of `8`. Each index is in the range `0 ... 3`, 
            ///     and can reference an entry in a palette with at most `4` elements.
            /// ## (pixel-formats)
            case indexed2
            /// case PNG.Format.Pixel.indexed4 
            ///     Pixels are stored as 4-bit indices. 
            /// 
            ///     An image with this pixel format has a bit depth of `4`, and 
            ///     a color depth of `8`. Each index is in the range `0 ... 15`, 
            ///     and can reference an entry in a palette with at most `16` elements.
            /// ## (pixel-formats)
            case indexed4
            /// case PNG.Format.Pixel.indexed8 
            ///     Pixels are stored as 8-bit indices. 
            /// 
            ///     An image with this pixel format has a bit depth and color depth 
            ///     of `8`. Each index is in the range `0 ... 255`, and can reference 
            ///     an entry in a palette with at most `256` elements.
            /// ## (pixel-formats)
            case indexed8 
            
            /// case PNG.Format.Pixel.va8 
            ///     Pixels are stored as 8-bit grayscale-alpha pairs.
            /// 
            ///     An image with this pixel format has a bit depth and a color 
            ///     depth of `8`, for a total stride of `16` bits. Each sample 
            ///     is in the range `0 ... 255`.
            /// ## (pixel-formats)
            case va8 
            /// case PNG.Format.Pixel.va16 
            ///     Pixels are stored as 16-bit grayscale-alpha pairs.
            /// 
            ///     An image with this pixel format has a bit depth and a color 
            ///     depth of `16`, for a total stride of `32` bits. Each sample 
            ///     is in the range `0 ... 65535`.
            /// ## (pixel-formats)
            case va16 
            
            /// case PNG.Format.Pixel.rgba8 
            ///     Pixels are stored as 8-bit RGBA quadruplets.
            /// 
            ///     An image with this pixel format has a bit depth and a color 
            ///     depth of `8`, for a total stride of `32` bits. 
            ///     Each sample is in the range `0 ... 255`.
            /// ## (pixel-formats)
            case rgba8 
            /// case PNG.Format.Pixel.rgba16 
            ///     Pixels are stored as 16-bit RGBA quadruplets.
            /// 
            ///     An image with this pixel format has a bit depth and a color 
            ///     depth of `16`, for a total stride of `64` bits. 
            ///     Each sample is in the range `0 ... 65535`.
            /// ## (pixel-formats)
            case rgba16 
        }
        
        /// case PNG.Format.v1(fill:key:)
        ///     A 1-bit grayscale color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).v1`].
        /// - fill  : Swift.UInt8? 
        ///     An optional background color. The sample is unscaled, and must 
        ///     be in the range `0 ... 1`. Most PNG viewers ignore this field.
        /// - key   : Swift.UInt8? 
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible. The sample is 
        ///     unscaled, and must be in the range `0 ... 1`. 
        /// ## (grayscale-color-formats)
        
        /// case PNG.Format.v2(fill:key:)
        ///     A 2-bit grayscale color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).v2`].
        /// - fill  : Swift.UInt8? 
        ///     An optional background color. The sample is unscaled, and must 
        ///     be in the range `0 ... 3`. Most PNG viewers ignore this field.
        /// - key   : Swift.UInt8? 
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible. The sample is 
        ///     unscaled, and must be in the range `0 ... 3`. 
        /// ## (grayscale-color-formats)
        
        /// case PNG.Format.v4(fill:key:)
        ///     A 4-bit grayscale color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).v4`].
        /// - fill  : Swift.UInt8? 
        ///     An optional background color. The sample is unscaled, and must 
        ///     be in the range `0 ... 15`. Most PNG viewers ignore this field.
        /// - key   : Swift.UInt8? 
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible. The sample is 
        ///     unscaled, and must be in the range `0 ... 15`. 
        /// ## (grayscale-color-formats)
        
        /// case PNG.Format.v8(fill:key:)
        ///     An 8-bit grayscale color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).v8`].
        /// - fill  : Swift.UInt8? 
        ///     An optional background color. Most PNG viewers ignore this field.
        /// - key   : Swift.UInt8? 
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible. 
        /// ## (grayscale-color-formats)
        
        /// case PNG.Format.v16(fill:key:)
        ///     A 16-bit grayscale color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).v16`].
        /// - fill  : Swift.UInt16? 
        ///     An optional background color. Most PNG viewers ignore this field.
        /// - key   : Swift.UInt16? 
        ///     An optional chroma key. If present, pixels matching it
        ///     will be displayed as transparent, if possible. 
        /// ## (grayscale-color-formats)
        
        /// case PNG.Format.bgr8(palette:fill:key:)
        ///     An 8-bit BGR color format. 
        /// 
        ///     This color format is an iphone-optimized format. 
        ///     It has a [`pixel`] format of [`(Pixel).rgb8`].
        /// - palette   : [(b:Swift.UInt8, g:Swift.UInt8, r:Swift.UInt8)]
        ///     An palette of suggested posterization values. Most PNG viewers 
        ///     ignore this field. 
        /// 
        ///     This field is unrelated to, and should not be confused with a 
        ///     [`SuggestedPalette`].
        /// - fill      : (b:Swift.UInt8, g:Swift.UInt8, r:Swift.UInt8)?
        ///     An optional background color. Most PNG viewers ignore this field.
        /// - key       : (b:Swift.UInt8, g:Swift.UInt8, r:Swift.UInt8)?
        ///     An optional chroma key. If present, pixels matching it 
        ///     will be displayed as transparent, if possible. 
        /// ## (ios-color-formats)
        
        /// case PNG.Format.rgb8(palette:fill:key:)
        ///     An 8-bit RGB color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).rgb8`].
        /// - palette   : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8)]
        ///     An palette of suggested posterization values. Most PNG viewers 
        ///     ignore this field. 
        /// 
        ///     This field is unrelated to, and should not be confused with a 
        ///     [`SuggestedPalette`].
        /// - fill      : (r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8)?
        ///     An optional background color. Most PNG viewers ignore this field.
        /// - key       : (r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8)?
        ///     An optional chroma key. If present, pixels matching it 
        ///     will be displayed as transparent, if possible. 
        /// ## (rgb-color-formats)
        
        /// case PNG.Format.rgb16(palette:fill:key:)
        ///     A 16-bit RGB color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).rgb16`].
        /// - palette   : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8)]
        ///     An palette of suggested posterization values. Most PNG viewers 
        ///     ignore this field. Although the image color depth is `16`, the 
        ///     palette atom type is [`Swift.UInt8`], not [`Swift.UInt16`].
        /// 
        ///     This field is unrelated to, and should not be confused with a 
        ///     [`SuggestedPalette`].
        /// - fill      : (r:Swift.UInt16, g:Swift.UInt16, b:Swift.UInt16)?
        ///     An optional background color. Most PNG viewers ignore this field.
        /// - key       : (r:Swift.UInt16, g:Swift.UInt16, b:Swift.UInt16)?
        ///     An optional chroma key. If present, pixels matching it 
        ///     will be displayed as transparent, if possible. 
        /// ## (rgb-color-formats)
        
        /// case PNG.Format.indexed1(palette:fill:)
        ///     A 1-bit indexed color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).indexed1`].
        /// - palette   : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8, a:Swift.UInt8)]
        ///     The palette values referenced by an image with this color format. 
        ///     This palette must be non-empty, and can have at most `2` entries.
        /// - fill      : Swift.Int?
        ///     A palette index specifying an optional background color. This index 
        ///     must be within the index range of the `palette` array.
        /// 
        ///     Most PNG viewers ignore this field.
        /// ## (indexed-color-formats)
        
        /// case PNG.Format.indexed2(palette:fill:)
        ///     A 2-bit indexed color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).indexed2`].
        /// - palette   : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8, a:Swift.UInt8)]
        ///     The palette values referenced by an image with this color format. 
        ///     This palette must be non-empty, and can have at most `4` entries.
        /// - fill      : Swift.Int?
        ///     A palette index specifying an optional background color. This index 
        ///     must be within the index range of the `palette` array.
        /// 
        ///     Most PNG viewers ignore this field.
        /// ## (indexed-color-formats)
        
        /// case PNG.Format.indexed4(palette:fill:)
        ///     A 4-bit indexed color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).indexed4`].
        /// - palette   : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8, a:Swift.UInt8)]
        ///     The palette values referenced by an image with this color format. 
        ///     This palette must be non-empty, and can have at most `16` entries.
        /// - fill      : Swift.Int?
        ///     A palette index specifying an optional background color. This index 
        ///     must be within the index range of the `palette` array.
        /// 
        ///     Most PNG viewers ignore this field.
        /// ## (indexed-color-formats)
        
        /// case PNG.Format.indexed8(palette:fill:)
        ///     An 8-bit indexed color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).indexed8`].
        /// - palette   : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8, a:Swift.UInt8)]
        ///     The palette values referenced by an image with this color format. 
        ///     This palette must be non-empty, and can have at most `256` entries.
        /// - fill      : Swift.Int?
        ///     A palette index specifying an optional background color. This index 
        ///     must be within the index range of the `palette` array.
        /// 
        ///     Most PNG viewers ignore this field.
        /// ## (indexed-color-formats)
        
        /// case PNG.Format.va8(fill:)
        ///     An 8-bit grayscale-alpha color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).va8`].
        /// - fill      : Swift.UInt8?
        ///     An optional background color. Most PNG viewers ignore this field.
        /// ## (grayscale-alpha-color-formats)
        
        /// case PNG.Format.va16(fill:)
        ///     A 16-bit grayscale-alpha color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).va16`].
        /// - fill      : Swift.UInt16?
        ///     An optional background color. Most PNG viewers ignore this field.
        /// ## (grayscale-alpha-color-formats)
        
        /// case PNG.Format.bgra8(palette:fill:)
        ///     An 8-bit BGRA color format. 
        /// 
        ///     This color format is an iphone-optimized format. 
        ///     It has a [`pixel`] format of [`(Pixel).rgba8`].
        /// - palette   : [(b:Swift.UInt8, g:Swift.UInt8, r:Swift.UInt8)]
        ///     An palette of suggested posterization values. Most PNG viewers 
        ///     ignore this field. 
        /// 
        ///     This field is unrelated to, and should not be confused with a 
        ///     [`SuggestedPalette`].
        /// - fill      : (b:Swift.UInt8, g:Swift.UInt8, r:Swift.UInt8)?
        ///     An optional background color. Most PNG viewers ignore this field.
        /// ## (ios-color-formats)
        
        /// case PNG.Format.rgba8(palette:fill:)
        ///     An 8-bit RGBA color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).rgba8`].
        /// - palette   : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8)]
        ///     An palette of suggested posterization values. Most PNG viewers 
        ///     ignore this field. 
        /// 
        ///     This field is unrelated to, and should not be confused with a 
        ///     [`SuggestedPalette`].
        /// - fill      : (r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8)?
        ///     An optional background color. Most PNG viewers ignore this field.
        /// ## (rgba-color-formats)
        
        /// case PNG.Format.rgba16(palette:fill:)
        ///     A 16-bit RGBA color format. 
        /// 
        ///     This color format has a [`pixel`] format of [`(Pixel).rgba16`].
        /// - palette   : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8)]
        ///     An palette of suggested posterization values. Most PNG viewers 
        ///     ignore this field. Although the image color depth is `16`, the 
        ///     palette atom type is [`Swift.UInt8`], not [`Swift.UInt16`].
        /// 
        ///     This field is unrelated to, and should not be confused with a 
        ///     [`SuggestedPalette`].
        /// - fill      : (r:Swift.UInt16, g:Swift.UInt16, b:Swift.UInt16)?
        ///     An optional background color. Most PNG viewers ignore this field.
        /// ## (rgba-color-formats)
        case v1      (                                                fill:   UInt8?,                       key:   UInt8?                      )
        case v2      (                                                fill:   UInt8?,                       key:   UInt8?                      )
        case v4      (                                                fill:   UInt8?,                       key:   UInt8?                      )
        case v8      (                                                fill:   UInt8?,                       key:   UInt8?                      )
        case v16     (                                                fill:   UInt16?,                      key:   UInt16?                     )
        
        case bgr8    (palette:[(b:UInt8, g:UInt8, r:UInt8         )], fill:(b:UInt8,  g:UInt8,  r:UInt8 )?, key:(b:UInt8,  g:UInt8,  r:UInt8 )?)
        
        case rgb8    (palette:[(r:UInt8, g:UInt8, b:UInt8         )], fill:(r:UInt8,  g:UInt8,  b:UInt8 )?, key:(r:UInt8,  g:UInt8,  b:UInt8 )?)
        case rgb16   (palette:[(r:UInt8, g:UInt8, b:UInt8         )], fill:(r:UInt16, g:UInt16, b:UInt16)?, key:(r:UInt16, g:UInt16, b:UInt16)?)
        
        case indexed1(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:    Int?                                                            )
        case indexed2(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:    Int?                                                            )
        case indexed4(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:    Int?                                                            )
        case indexed8(palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)], fill:    Int?                                                            )
        
        case va8     (                                                fill:   UInt8?                                                           )
        case va16    (                                                fill:   UInt16?                                                          )
        
        case bgra8   (palette:[(b:UInt8, g:UInt8, r:UInt8         )], fill:(b:UInt8,  g:UInt8,  r:UInt8 )?                                     )
        
        case rgba8   (palette:[(r:UInt8, g:UInt8, b:UInt8         )], fill:(r:UInt8,  g:UInt8,  b:UInt8 )?                                     )
        case rgba16  (palette:[(r:UInt8, g:UInt8, b:UInt8         )], fill:(r:UInt16, g:UInt16, b:UInt16)?                                     )
    }
}
extension PNG.Format.Pixel 
{
    /// var PNG.Format.Pixel.hasColor   : Swift.Bool { get }
    /// @   inlinable 
    ///     Indicates whether an image with this pixel format contains more than one 
    ///     non-alpha color component.
    /// 
    ///     This property is `true` for all RGB, RGBA, and indexed pixel formats, 
    ///     and `false` otherwise.
    @inlinable
    public
    var hasColor:Bool
    {
        switch self 
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
            return false 
        case .rgb8, .rgb16, .indexed1, .indexed2, .indexed4, .indexed8, .rgba8, .rgba16:
            return true 
        }
    }
    /// var PNG.Format.Pixel.hasAlpha   : Swift.Bool { get }
    /// @   inlinable 
    ///     Indicates whether an image with this pixel format contains an alpha 
    ///     component.
    /// 
    ///     This property is `true` for all grayscale-alpha and RGBA pixel formats, 
    ///     and `false` otherwise. Note that indexed pixel formats are not 
    ///     considered transparent pixel formats, even though images using them 
    ///     can contain per-pixel alpha information.
    @inlinable
    public
    var hasAlpha:Bool
    {
        switch self 
        {
        case .v1, .v2, .v4, .v8, .v16, .rgb8, .rgb16, 
            .indexed1, .indexed2, .indexed4, .indexed8:
            return false 
        case .va8, .va16, .rgba8, .rgba16:
            return true 
        }
    }
    
    @inlinable
    var volume:Int
    {
        self.depth * self.channels
    }
    
    /// var PNG.Format.Pixel.channels   : Swift.Int { get }
    /// @   inlinable 
    ///     The number of channels encoded per-pixel in the internal representation 
    ///     of an image with this pixel format. 
    /// 
    ///     This number is *not* the number of components in the encoded image; 
    ///     it indicates the dimensionality of the stored image data. Notably, 
    ///     indexed images are defined as having one channel, even though each 
    ///     scalar index represents a four-component color value.
    /// 
    ///     This property returns `1` for all grayscale and indexed pixel formats. 
    /// 
    ///     This property returns `2` for all grayscale-alpha pixel formats. 
    /// 
    ///     This property returns `3` for all RGB pixel formats. 
    /// 
    ///     This property returns `4` for all RGBA pixel formats. 
    @inlinable
    public
    var channels:Int
    {
        switch self
        {
        case .v1, .v2, .v4, .v8, .v16,
            .indexed1, .indexed2, .indexed4, .indexed8:     return 1
        case .va8,   .va16:                                 return 2
        case .rgb8,  .rgb16:                                return 3
        case .rgba8, .rgba16:                               return 4
        }
    }
    /// var PNG.Format.Pixel.depth      : Swift.Int { get }
    /// @   inlinable 
    ///     The bit depth of an image with this pixel format. 
    /// 
    ///     This number is *not* the color depth the encoded image; 
    ///     it indicates the bit depth of the stored image data. Notably, 
    ///     indexed images always have a color depth of `8`, even though they may 
    ///     have a bit depth less than `8`.
    /// 
    ///     This property returns `1` for the [`v1`] and [`indexed1`] pixel formats. 
    /// 
    ///     This property returns `2` for the [`v2`] and [`indexed2`] pixel formats. 
    /// 
    ///     This property returns `4` for the [`v4`] and [`indexed4`] pixel formats. 
    /// 
    ///     This property returns `8` for the [`v8`], [`va8`], [`indexed8`], 
    ///     [`rgb8`], and [`rgba8`] pixel formats. 
    /// 
    ///     This property returns `16` for the [`v16`], [`va16`], 
    ///     [`rgb16`], and [`rgba16`] pixel formats. 
    @inlinable
    public
    var depth:Int 
    {
        switch self 
        {
        case    .v1,          .indexed1:                    return  1
        case    .v2,          .indexed2:                    return  2
        case    .v4,          .indexed4:                    return  4
        case    .v8,  .rgb8,  .indexed8, .va8,  .rgba8:     return  8
        case    .v16, .rgb16,            .va16, .rgba16:    return 16
        }
    }
    
    var code:(depth:UInt8, type:UInt8) 
    {
        switch self 
        {
        case .v1:        return ( 1, 0)
        case .v2:        return ( 2, 0)
        case .v4:        return ( 4, 0)
        case .v8:        return ( 8, 0)
        case .v16:       return (16, 0)
        
        case .rgb8:      return ( 8, 2)
        case .rgb16:     return (16, 2)
        
        case .indexed1:  return ( 1, 3)
        case .indexed2:  return ( 2, 3)
        case .indexed4:  return ( 4, 3)
        case .indexed8:  return ( 8, 3) 
        
        case .va8:       return ( 8, 4) 
        case .va16:      return (16, 4) 
        
        case .rgba8:     return ( 8, 6)
        case .rgba16:    return (16, 6) 
        }
    }
    
    static 
    func recognize(code:(depth:UInt8, type:UInt8)) -> Self?
    {
        switch code
        {
        case ( 1, 0):   return .v1
        case ( 2, 0):   return .v2
        case ( 4, 0):   return .v4
        case ( 8, 0):   return .v8
        case (16, 0):   return .v16
        
        case ( 8, 2):   return .rgb8
        case (16, 2):   return .rgb16
        
        case ( 1, 3):   return .indexed1
        case ( 2, 3):   return .indexed2
        case ( 4, 3):   return .indexed4
        case ( 8, 3):   return .indexed8
        
        case ( 8, 4):   return .va8
        case (16, 4):   return .va16
        
        case ( 8, 6):   return .rgba8
        case (16, 6):   return .rgba16
        
        default:        return nil
        }
    }
}
extension PNG.Format 
{
    // can’t use these in the enum cases because they are `internal` only
    typealias RGB<T>  = (r:T, g:T, b:T)
    typealias RGBA<T> = (r:T, g:T, b:T, a:T)
    
    /// var PNG.Format.pixel    : Pixel { get }
    /// @   inlinable 
    ///     The pixel format used by an image with this color format.
    @inlinable
    public
    var pixel:Pixel
    {
        switch self
        {
        case .v1:       return .v1
        case .v2:       return .v2
        case .v4:       return .v4
        case .v8:       return .v8
        case .v16:      return .v16
        case .bgr8:     return .rgb8
        case .rgb8:     return .rgb8
        case .rgb16:    return .rgb16
        case .indexed1: return .indexed1
        case .indexed2: return .indexed2
        case .indexed4: return .indexed4
        case .indexed8: return .indexed8
        case .va8:      return .va8
        case .va16:     return .va16
        case .bgra8:    return .rgba8
        case .rgba8:    return .rgba8
        case .rgba16:   return .rgba16
        }
    }
    
    // enum case constructors can’t perform validation, so we need to check 
    // the range of the sample values with this function. 
    func validate() -> Self 
    {
        let max:(sample:UInt16, count:Int, index:Int)
        max.sample  = .max >> (UInt16.bitWidth - self.pixel.depth)
        max.count   = 1    <<                min(self.pixel.depth, 8)
        // palette cannot contain more entries than bit depth allows 
        switch self 
        {
        case    .bgr8    (palette: let palette, fill: _, key: _),
                .bgra8   (palette: let palette, fill: _):
            max.index = palette.count - 1
        case 
                .rgb8    (palette: let palette, fill: _, key: _),
                .rgb16   (palette: let palette, fill: _, key: _),
                .rgba8   (palette: let palette, fill: _),
                .rgba16  (palette: let palette, fill: _):
            max.index = palette.count - 1
        case    .indexed1(palette: let palette, fill: _),
                .indexed2(palette: let palette, fill: _),
                .indexed4(palette: let palette, fill: _),
                .indexed8(palette: let palette, fill: _):
            guard !palette.isEmpty 
            else 
            {
                PNG.ParsingError.invalidPaletteCount(0, max: max.count).fatal
            }
            max.index = palette.count - 1
        default:
            max.index =                -1
        }
        
        guard max.index < max.count 
        else 
        {
            PNG.ParsingError.invalidPaletteCount(max.index + 1, max: max.count).fatal 
        }
        
        switch self 
        {
        case    .v1(fill: let fill?, key: _),
                .v2(fill: let fill?, key: _),
                .v4(fill: let fill?, key: _):
            let fill:UInt16 = .init(fill)
            guard fill <= max.sample 
            else 
            {
                PNG.ParsingError.invalidBackgroundSample(fill, max: max.sample).fatal 
            }
        case    .indexed1(palette: _, fill: let i?),
                .indexed2(palette: _, fill: let i?),
                .indexed4(palette: _, fill: let i?),
                .indexed8(palette: _, fill: let i?):
            guard i <= max.index 
            else 
            {
                PNG.ParsingError.invalidBackgroundIndex(i, max: max.index).fatal 
            }
        default:
            break 
        }
        
        switch self 
        {
        case    .v1(fill: _?, key: let key?),
                .v2(fill: _?, key: let key?),
                .v4(fill: _?, key: let key?):
            let key:UInt16 = .init(key)
            guard key <= max.sample 
            else 
            {
                PNG.ParsingError.invalidTransparencySample(key, max: max.sample).fatal 
            }
        default:
            break
        }
        
        return self
    }
    
    // this function assumes all inputs have been validated for consistency, 
    // except for the presence of the palette argument itself.
    static 
    func recognize(standard:PNG.Standard, pixel:PNG.Format.Pixel, 
        palette:PNG.Palette?, background:PNG.Background?, transparency:PNG.Transparency?) 
        -> Self?
    {
        let format:Self 
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16:
            guard palette == nil 
            else 
            {
                PNG.ParsingError.unexpectedPalette(pixel: pixel).fatal
            }
            let f:UInt16?, 
                k:UInt16?
            switch background?.case 
            {
            case .v(let v)?:    f = v
            case nil:           f = nil 
            default: 
                fatalError("expected background of case `v` for pixel format `\(pixel)`")
            }
            switch transparency?.case 
            {
            case .v(let v)?:    k = v
            case nil:           k = nil 
            default:
                fatalError("expected transparency of case `v` for pixel format `\(pixel)`")
            }
            
            switch pixel 
            {
            case .v1:
                format = .v1(fill: f.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v2:
                format = .v2(fill: f.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v4:
                format = .v4(fill: f.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v8:
                format = .v8(fill: f.map(UInt8.init(_:)), key: k.map(UInt8.init(_:)))
            case .v16:
                format = .v16(fill: f,                    key: k)
            default:
                fatalError("unreachable")
            }
        
        case .rgb8, .rgb16:
            let palette:[RGB<UInt8>] = palette?.entries ?? []
            let f:RGB<UInt16>?, 
                k:RGB<UInt16>?
            switch background?.case 
            {
            case .rgb(let c)?:  f = c
            case nil:           f = nil 
            default: 
                fatalError("expected background of case `rgb` for pixel format `\(pixel)`")
            }
            switch transparency?.case 
            {
            case .rgb(let c)?:  k = c
            case nil:           k = nil 
            default: 
                fatalError("expected transparency of case `rgb` for pixel format `\(pixel)`")
            }
            
            switch (standard, pixel) 
            {
            case (.common,  .rgb8):
                format = .rgb8(palette: palette, 
                    fill: f.map{ (.init($0.r), .init($0.g), .init($0.b)) }, 
                    key:  k.map{ (.init($0.r), .init($0.g), .init($0.b)) })
            case (.ios,     .rgb8):
                format = .bgr8(palette: palette.map{ ($0.b, $0.g, $0.r) }, 
                    fill: f.map{ (.init($0.b), .init($0.g), .init($0.r)) }, 
                    key:  k.map{ (.init($0.b), .init($0.g), .init($0.r)) })
            case (_,        .rgb16):
                format = .rgb16(palette: palette, fill: f, key: k)
            default:
                fatalError("unreachable")
            }
        
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let solid:PNG.Palette = palette
            else 
            {
                return nil 
            }
            let f:Int? 
            switch background?.case 
            {
            case .palette(let i):   f = i
            case nil:               f = nil 
            default: 
                fatalError("expected background of case `palette` for pixel format `\(pixel)`")
            }
            
            let palette:[RGBA<UInt8>]
            switch transparency?.case 
            {
            case nil:
                palette =          solid.entries.map        { (  $0.r,   $0.g,   $0.b, .max) }
            case .palette(let alpha):
                guard alpha.count <= solid.entries.count 
                else 
                {
                    PNG.ParsingError.invalidTransparencyCount(alpha.count, 
                        max: solid.entries.count).fatal
                }
                
                palette =      zip(solid.entries, alpha).map{ ($0.0.r, $0.0.g, $0.0.b, $0.1) } + 
                    solid.entries.dropFirst(alpha.count).map{ (  $0.r,   $0.g,   $0.b, .max) }
            default: 
                fatalError("expected transparency of case `palette` for pixel format `\(pixel)`")
            }
            
            switch pixel  
            {
            case .indexed1: 
                format = .indexed1(palette: palette, fill: f)
            case .indexed2: 
                format = .indexed2(palette: palette, fill: f)
            case .indexed4: 
                format = .indexed4(palette: palette, fill: f)
            case .indexed8: 
                format = .indexed8(palette: palette, fill: f)
            default:
                fatalError("unreachable")
            }
        
        case .va8, .va16:
            guard palette == nil
            else
            {
                PNG.ParsingError.unexpectedPalette(pixel: pixel).fatal
            }
            guard transparency == nil 
            else 
            {
                PNG.ParsingError.unexpectedTransparency(pixel: pixel).fatal
            }
            
            let f:UInt16?
            switch background?.case 
            {
            case .v(let v)?:    f = v
            case nil:           f = nil 
            default:
                fatalError("expected background of case `v` for pixel format `\(pixel)`")
            }
            
            switch pixel 
            {
            case .va8:
                format = .va8( fill: f.map(UInt8.init(_:)))
            case .va16:
                format = .va16(fill: f)
            default:
                fatalError("unreachable")
            }
        
        case .rgba8, .rgba16:
            guard transparency == nil 
            else 
            {
                PNG.ParsingError.unexpectedTransparency(pixel: pixel).fatal
            }
            
            let palette:[RGB<UInt8>] = palette?.entries ?? []
            let f:RGB<UInt16>?
            switch background?.case 
            {
            case .rgb(let c)?:  f = c
            case nil:           f = nil 
            default: 
                fatalError("expected background of case `rgb` for pixel format `\(pixel)`")
            }
            
            switch (standard, pixel) 
            {
            case (.common,  .rgba8):
                format = .rgba8(palette: palette, 
                    fill: f.map{ (.init($0.r), .init($0.g), .init($0.b)) })
            case (.ios,     .rgba8):
                format = .bgra8(palette: palette.map{ ($0.b, $0.g, $0.r) }, 
                    fill: f.map{ (.init($0.b), .init($0.g), .init($0.r)) })
            case (_,        .rgba16):
                format = .rgba16(palette: palette, fill: f)
            default:
                fatalError("unreachable")
            }
        }
        // do not call `.validate()` on `format` because this will be done when 
        // the `PNG.Layout` struct is initialized
        return format
    }
}
