//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/. 
    
extension PNG 
{
    /// struct PNG.Percentmille 
    /// :   Swift.AdditiveArithmetic
    /// :   Swift.ExpressibleByIntegerLiteral 
    ///     A rational percentmille value. 
    /// ## (currency-types)
    public 
    struct Percentmille:AdditiveArithmetic, ExpressibleByIntegerLiteral
    {
        /// var PNG.Percentmille.points : Swift.Int 
        ///     The numerator of this percentmille value. 
        /// 
        ///     The numerical value of this percentmille instance is this integer 
        ///     divided by `100000`.
        public 
        var points:Int 
        
        /// static let PNG.Percentmille.zero : Self 
        /// ?:  Swift.AdditiveArithmetic
        ///     A percentmille value of zero. 
        public static 
        let zero:Self = 0
        
        /// init PNG.Percentmille.init<T>(_:) 
        /// where T:Swift.BinaryInteger 
        ///     Creates a percentmille value with the given numerator. 
        /// 
        ///     The numerical value of this percentmille value will be the given 
        ///     numerator divided by `100000`.
        /// - points : T 
        ///     The numerator. 
        public 
        init<T>(_ points:T) where T:BinaryInteger
        {
            self.points = .init(points)
        }
        
        /// init PNG.Percentmille.init(integerLiteral:) 
        /// ?:  Swift.ExpressibleByIntegerLiteral 
        ///     Creates a percentmille value using the given integer literal as 
        ///     the numerator.
        /// 
        ///     The provided integer literal is *not* the numerical value of the 
        ///     created percentmille value. It will be interpreted as the numerator 
        ///     of a rational value.
        /// - integerLiteral : Swift.Int
        ///     The integer literal. 
        public 
        init(integerLiteral:Int)
        {
            self.init(integerLiteral)
        }
        
        /// static func PNG.Percentmille.(+)(_:_:)
        /// ?:  Swift.AdditiveArithmetic
        ///     Adds two percentmille values and produces their sum.
        /// - lhs   : Self 
        ///     The first value to add. 
        /// - rhs   : Self 
        ///     The second value to add.
        /// - ->    : Self 
        ///     The sum of the two given percentmille values.
        public static 
        func + (lhs:Self, rhs:Self) -> Self 
        {
            .init(lhs.points + rhs.points)
        }
        /// static func PNG.Percentmille.(+=)(_:_:)
        /// ?:  Swift.AdditiveArithmetic
        ///     Adds two percentmille values and stores the result in the 
        ///     left-hand-side variable.
        /// - lhs   : inout Self 
        ///     The first value to add. 
        /// - rhs   : Self 
        ///     The second value to add.
        public static 
        func += (lhs:inout Self, rhs:Self) 
        {
            lhs.points += rhs.points
        }
        /// static func PNG.Percentmille.(-)(_:_:)
        /// ?:  Swift.AdditiveArithmetic
        ///     Subtracts one percentmille value from another and produces their 
        ///     difference.
        /// - lhs   : Self 
        ///     A percentmille value. 
        /// - rhs   : Self 
        ///     The value to subtract from `lhs`.
        /// - ->    : Self 
        ///     The difference of the two given percentmille values.
        public static 
        func - (lhs:Self, rhs:Self) -> Self 
        {
            .init(lhs.points - rhs.points)
        }
        /// static func PNG.Percentmille.(-=)(_:_:)
        /// ?:  Swift.AdditiveArithmetic
        ///     Subtracts one percentmille value from another and stores the 
        ///     result in the left-hand-side variable.
        /// - lhs   : inout Self 
        ///     A percentmille value. 
        /// - rhs   : Self 
        ///     The value to subtract from `lhs`.
        public static 
        func -= (lhs:inout Self, rhs:Self) 
        {
            lhs.points -= rhs.points
        }
    }
    
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

extension PNG 
{
    /// struct PNG.Palette 
    ///     An image palette.
    /// 
    ///     This type models the information stored in a [`(Chunk).PLTE`] chunk. 
    ///     This information is used to populate the non-alpha components of the 
    ///     `palette` field in an image color [`Format`], when appropriate.
    /// # [Parsing and serialization](palette-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct Palette 
    {
        /// let PNG.Palette.entries : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8)]
        ///     The entries in this palette.
        public 
        let entries:[(r:UInt8, g:UInt8, b:UInt8)]
    }
}
extension PNG.Palette 
{
    /// init PNG.Palette.init(entries:pixel:)
    ///     Creates an image palette.
    /// 
    ///     This initializer validates the palette information against the given 
    ///     `pixel` format.
    /// - entries   : [(r:Swift.UInt8, g:Swift.UInt8, b:Swift.UInt8)]
    ///     An array of palette entries. This array must be non-empty, and can 
    ///     contain at most `256`, or `1 << pixel.`[`(Format.Pixel).depth`] elements, 
    ///     whichever is lower.
    /// - pixel     : Format.Pixel 
    ///     The pixel format of the image this palette is to be used for. 
    ///     If this parameter is a grayscale or grayscale-alpha format, this 
    ///     initializer will suffer a precondition failure.
    public 
    init(entries:[(r:UInt8, g:UInt8, b:UInt8)], pixel:PNG.Format.Pixel) 
    {
        guard pixel.hasColor
        else
        {
            PNG.ParsingError.unexpectedPalette(pixel: pixel).fatal 
        }
        let max:Int = 1 << Swift.min(pixel.depth, 8)
        guard 1 ... max ~= entries.count 
        else
        {
            PNG.ParsingError.invalidPaletteCount(entries.count, max: max).fatal
        }
        
        self.entries = entries 
    }
    /// init PNG.Palette.init(parsing:pixel:) 
    /// throws 
    ///     Creates an image palette by parsing the given chunk data, interpreting 
    ///     and validating it according to the given `pixel` format.
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).PLTE`] chunk to parse. 
    /// - pixel     : Format.Pixel 
    ///     The pixel format specifying how the chunk data is to be interpreted.
    /// ## (palette-parsing-and-serialization)
    public 
    init(parsing data:[UInt8], pixel:PNG.Format.Pixel) throws
    {
        guard pixel.hasColor
        else
        {
            throw PNG.ParsingError.unexpectedPalette(pixel: pixel)
        }
        
        let (count, remainder):(Int, Int) = data.count.quotientAndRemainder(dividingBy: 3)
        guard remainder == 0
        else
        {
            throw PNG.ParsingError.invalidPaletteChunkLength(data.count)
        }
        
        // check number of palette entries
        let max:Int = 1 << Swift.min(pixel.depth, 8)
        guard 1 ... max ~= count 
        else
        {
            throw PNG.ParsingError.invalidPaletteCount(count, max: max)
        }

        self.entries = stride(from: data.startIndex, to: data.endIndex, by: 3).map
        {
            (base:Int) in (r: data[base], g: data[base + 1], b: data[base + 2])
        }
    }
    /// var PNG.Palette.serialized   : [Swift.UInt8] { get }
    ///     Encodes this image palette as the contents of a [`(Chunk).PLTE`] chunk.
    /// ## (palette-parsing-and-serialization)
    public 
    var serialized:[UInt8] 
    {
        .init(unsafeUninitializedCapacity: 3 * self.entries.count)
        {
            for (i, c):(Int, (r:UInt8, g:UInt8, b:UInt8)) in 
                zip(stride(from: $0.startIndex, to: $0.endIndex, by: 3), self.entries) 
            {
                $0[i    ] = c.r
                $0[i + 1] = c.g
                $0[i + 2] = c.b
            }
            $1 = $0.count
        }
    }
}

extension PNG 
{
    /// struct PNG.Transparency 
    ///     A transparency descriptor.
    /// 
    ///     This type models the information stored in a [`(Chunk).tRNS`] chunk.
    ///     This information either used to populate the `key` field in 
    ///     an image color [`Format`], or augment its `palette` field, when appropriate.
    /// 
    ///     The value of this descriptor is stored in the [`(PNG.Transparency).case`] 
    ///     property, after validation.
    /// # [Parsing and serialization](transparency-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct Transparency 
    {
        /// enum PNG.Transparency.Case 
        ///     A transparency case.
        public 
        enum Case 
        {
            /// case PNG.Transparency.Case.palette(alpha:)
            ///     A transparency descriptor for an indexed image.
            /// - alpha     : [Swift.UInt8]
            ///     An array of alpha samples, where each sample augments an 
            ///     RGB triple in an image [`Palette`]. This array can contain no 
            ///     more elements than entries in the image palette, but it can 
            ///     contain fewer. 
            /// 
            ///     It is acceptable (though pointless) for the `alpha` array to be 
            ///     empty.
            case palette(alpha:[UInt8])
            /// case PNG.Transparency.Case.rgb(key:)
            ///     A transparency descriptor for an RGB or BGR image.
            /// - key     : (r:Swift.UInt16, g:Swift.UInt16, b:Swift.UInt16)
            ///     A chroma key used to display transparency. Pixels 
            ///     matching this key will be displayed as transparent, if possible.
            /// 
            ///     Note that the chroma key components are unscaled samples. If 
            ///     the image color depth is less than `16`, only the least-significant 
            ///     bits of each sample are inhabited.
            case rgb(key:(r:UInt16, g:UInt16, b:UInt16))
            /// case PNG.Transparency.Case.v(key:)
            ///     A transparency descriptor for a grayscale image.
            /// - key     : Swift.UInt16
            ///     A chroma key used to display transparency. Pixels 
            ///     matching this key will be displayed as transparent, if possible.
            /// 
            ///     Note that the chroma key is an unscaled sample. If 
            ///     the image color depth is less than `16`, only the least-significant 
            ///     bits are inhabited.
            case v(key:UInt16)
        }
        
        /// let PNG.Transparency.case : Case 
        ///     The value of this transparency descriptor.
        public 
        let `case`:Case
    }
}
extension PNG.Transparency 
{
    /// init PNG.Transparency.init(case:pixel:palette:)
    ///     Creates a transparency descriptor.
    /// 
    ///     This initializer validates the transparency information against the 
    ///     given pixel format and image palette. Some `pixel` formats imply 
    ///     that `palette` must be `nil`. This initializer does not check this 
    ///     assumption, as it is expected to have been verified by 
    ///     [`Palette.init(entries:pixel:)`].
    /// - case      : Case 
    ///     A transparency descriptor value.
    /// 
    ///     If this parameter is a [`(Case).v(key:)`] or [`(Case).rgb(key:)`] case, 
    ///     the samples in its chroma key payload must fall within the 
    ///     range determined by the image color depth. Passing an enumeration 
    ///     case with an invalid chroma key sample will result in a precondition 
    ///     failure.
    /// - pixel     : Format.Pixel 
    ///     The pixel format of the image this transparency descriptor is to be 
    ///     used for. Passing a mismatched enumeration `case` will result in a 
    ///     precondition failure. 
    /// 
    ///     Transparency descriptors are not allowed for grayscale-alpha or RGBA 
    ///     images, so setting `pixel` to one of those pixel formats will always 
    ///     result in a precondition failure.
    /// - palette   : PNG.Palette? 
    ///     The palette of the image this transparency descriptor is to be 
    ///     used for. 
    /// 
    ///     If `case` is a [`(Case).palette(alpha:)`] case, this palette must 
    ///     not be `nil`, and must contain at least as many entries as the  
    ///     number of alpha samples in the [`(Case).palette(alpha:)`] payload. 
    ///     Otherwise, this initializer will suffer a precondition failure. 
    /// 
    ///     If `case` is a [`(Case).v(key:)`] or [`(Case).rgb(key:)`] case, 
    ///     this parameter is ignored.
    public 
    init(case:Case, pixel:PNG.Format.Pixel, palette:PNG.Palette?) 
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16: 
            guard case .v(key: let v) = `case` 
            else 
            {
                fatalError("expected transparency of case `v` for pixel format `\(pixel)`")
            }

            let max:UInt16 = .max >> (UInt16.bitWidth - pixel.depth)
            guard v <= max 
            else 
            {
                PNG.ParsingError.invalidTransparencySample(v, max: max).fatal
            }
        
        case .rgb8, .rgb16: 
            guard case .rgb(key: let (r, g, b)) = `case` 
            else 
            {
                fatalError("expected transparency of case `rgb` for pixel format `\(pixel)`")
            }
            let max:UInt16 = .max >> (UInt16.bitWidth - pixel.depth)
            guard r <= max, g <= max, b <= max 
            else 
            {
                PNG.ParsingError.invalidTransparencySample(Swift.max(r, g, b), max: max).fatal
            }
            
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let palette:PNG.Palette = palette 
            else 
            {
                PNG.DecodingError.required(chunk: .PLTE, before: .tRNS).fatal 
            }
            guard case .palette(alpha: let alpha) = `case` 
            else 
            {
                fatalError("expected transparency of case `palette` for pixel format `\(pixel)`")
            }
            guard alpha.count <= palette.entries.count  
            else 
            {
                PNG.ParsingError.invalidTransparencyCount(alpha.count, max: palette.entries.count).fatal
            }
            
        case .va8, .va16, .rgba8, .rgba16:
            PNG.ParsingError.unexpectedTransparency(pixel: pixel).fatal
        }
        
        self.case = `case`
    }
    /// init PNG.Transparency.init(parsing:pixel:palette:) 
    /// throws 
    ///     Creates a transparency descriptor by parsing the given chunk data, 
    ///     interpreting and validating it according to the given `pixel` format and 
    ///     image `palette`. 
    /// 
    ///     Some `pixel` formats imply that `palette` must be `nil`. 
    ///     This initializer does not check this assumption, as it is expected 
    ///     to have been verified by [`Palette.init(parsing:pixel:)`].
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).tRNS`] chunk to parse. 
    /// - pixel     : Format.Pixel 
    ///     The pixel format specifying how the chunk data is to be interpreted 
    ///     and validated against.
    /// - palette   : Palette?
    ///     The image palette the chunk data is to be validated against, if 
    ///     applicable. 
    /// ## (transparency-parsing-and-serialization)
    public 
    init(parsing data:[UInt8], pixel:PNG.Format.Pixel, palette:PNG.Palette?) throws 
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16:
            guard data.count == 2 
            else 
            {
                throw PNG.ParsingError.invalidTransparencyChunkLength(data.count, expected: 2)
            }
            
            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            let v:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0)
            guard v <= max 
            else 
            {
                throw PNG.ParsingError.invalidTransparencySample(v, max: max)
            }
            self.case =  .v(key: v)
        
        case .rgb8, .rgb16:
            guard data.count == 6 
            else 
            {
                throw PNG.ParsingError.invalidTransparencyChunkLength(data.count, expected: 6)
            }
            
            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            let r:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0),
                g:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 2),
                b:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 4)
            guard r <= max, g <= max, b <= max 
            else 
            {
                throw PNG.ParsingError.invalidTransparencySample(Swift.max(r, g, b), max: max)
            }
            self.case =  .rgb(key: (r, g, b))
        
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let palette:PNG.Palette = palette 
            else 
            {
                throw PNG.DecodingError.required(chunk: .PLTE, before: .tRNS)
            }
            guard data.count <= palette.entries.count  
            else 
            {
                throw PNG.ParsingError.invalidTransparencyCount(data.count, max: palette.entries.count)
            }
            self.case =  .palette(alpha: data)
        
        case .va8, .va16, .rgba8, .rgba16:
            throw PNG.ParsingError.unexpectedTransparency(pixel: pixel)
        }
    }
    /// var PNG.Transparency.serialized : [Swift.UInt8] { get }
    ///     Encodes this transparency descriptor as the contents of a 
    ///     [`(Chunk).tRNS`] chunk.
    /// ## (transparency-parsing-and-serialization)
    public 
    var serialized:[UInt8] 
    {
        switch self.case 
        {
        case .palette(alpha: let alpha):
            return .init(unsafeUninitializedCapacity: alpha.count)
            {
                $0.baseAddress?.assign(from: alpha, count: $0.count)
                $1 = $0.count
            }
        case .rgb(key: let c):
            return .init(unsafeUninitializedCapacity: 6)
            {
                $0.store(c.r, asBigEndian: UInt16.self, at: 0)
                $0.store(c.g, asBigEndian: UInt16.self, at: 2)
                $0.store(c.b, asBigEndian: UInt16.self, at: 4)
                $1 = $0.count
            }
        case .v(key: let v):
            return .init(unsafeUninitializedCapacity: 2)
            {
                $0.store(v, asBigEndian: UInt16.self, at: 0)
                $1 = $0.count
            }
        }
    }
}

extension PNG 
{
    /// struct PNG.Background 
    ///     A background descriptor.
    /// 
    ///     This type models the information stored in a [`(Chunk).bKGD`] chunk.
    ///     This information is used to populate the `fill` field in 
    ///     an image color [`Format`].
    /// 
    ///     The value of this descriptor is stored in the [`(PNG.Background).case`] 
    ///     property, after validation.
    /// # [Parsing and serialization](background-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct Background 
    {
        /// enum PNG.Background.Case 
        ///     A background case.
        public 
        enum Case 
        {
            /// case PNG.Background.Case.palette(index:)
            ///     A background descriptor for an indexed image.
            /// - index    : Swift.Int
            ///     The index of the palette entry to be used as a background color.
            /// 
            ///     This index must be within the index range of the image palette.
            case palette(index:Int)
            /// case PNG.Background.Case.rgb(_:)
            ///     A background descriptor for an RGB, BGR, RGBA, or BGRA image.
            /// - _     : (r:Swift.UInt16, g:Swift.UInt16, b:Swift.UInt16)
            ///     A background color.
            /// 
            ///     Note that the background components are unscaled samples. If 
            ///     the image color depth is less than `16`, only the least-significant 
            ///     bits of each sample are inhabited.
            case rgb((r:UInt16, g:UInt16, b:UInt16))
            /// case PNG.Background.Case.v(_:)
            ///     A background descriptor for a grayscale or grayscale-alpha image.
            /// - _       : Swift.UInt16
            ///     A background color.
            /// 
            ///     Note that the background value is an unscaled sample. If 
            ///     the image color depth is less than `16`, only the least-significant 
            ///     bits are inhabited.
            case v(UInt16)
        }
        /// let PNG.Background.case : Case 
        ///     The value of this background descriptor.
        public 
        let `case`:Case
    }
}
extension PNG.Background 
{
    /// init PNG.Background.init(case:pixel:palette:)
    ///     Creates a background descriptor.
    /// 
    ///     This initializer validates the background information against the 
    ///     given pixel format and image palette. Some `pixel` formats imply 
    ///     that `palette` must be `nil`. This initializer does not check this 
    ///     assumption, as it is expected to have been verified by 
    ///     [`Palette.init(entries:pixel:)`].
    /// - case      : Case 
    ///     A background descriptor value.
    /// 
    ///     If this parameter is a [`(Case).v(_:)`] or [`(Case).rgb(_:)`] case, 
    ///     the samples in its background color payload must fall within the 
    ///     range determined by the image color depth. Passing an enumeration 
    ///     case with an invalid background sample will result in a precondition 
    ///     failure.
    /// - pixel     : Format.Pixel 
    ///     The pixel format of the image this background descriptor is to be 
    ///     used for. Passing a mismatched enumeration `case` will result in a 
    ///     precondition failure.
    /// - palette   : PNG.Palette? 
    ///     The palette of the image this background descriptor is to be 
    ///     used for. 
    /// 
    ///     If `case` is a [`(Case).palette(index:)`] case, this palette must 
    ///     not be `nil`, and the number of entries in it must be at least `1` 
    ///     greater than the value of the [`(Case).palette(index:)`] payload. 
    ///     If the index payload is out of range, this function will suffer a 
    ///     precondition failure.
    /// 
    ///     If `case` is a [`(Case).v(_:)`] or [`(Case).rgb(_:)`] case, 
    ///     this parameter is ignored. 
    public 
    init(case:Case, pixel:PNG.Format.Pixel, palette:PNG.Palette?) 
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
            guard case .v(let v) = `case` 
            else 
            {
                fatalError("expected background of case `v` for pixel format `\(pixel)`")
            }
            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            guard v <= max 
            else 
            {
                PNG.ParsingError.invalidBackgroundSample(v, max: max).fatal
            }
        
        case .rgb8, .rgb16, .rgba8, .rgba16:
            guard case .rgb(let (r, g, b)) = `case` 
            else 
            {
                fatalError("expected background of case `v` for pixel format `\(pixel)`")
            }
            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            guard r <= max, g <= max, b <= max 
            else 
            {
                PNG.ParsingError.invalidBackgroundSample(Swift.max(r, g, b), max: max).fatal
            }
        
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let palette:PNG.Palette = palette 
            else 
            {
                PNG.DecodingError.required(chunk: .PLTE, before: .bKGD).fatal
            }
            guard case .palette(index: let index) = `case` 
            else 
            {
                fatalError("expected background of case `palette` for pixel format `\(pixel)`")
            }
            guard index < palette.entries.count
            else 
            {
                PNG.ParsingError.invalidBackgroundIndex(index, max: palette.entries.count - 1).fatal
            }
        }
        
        self.case = `case`
    }
    /// init PNG.Background.init(parsing:pixel:palette:) 
    /// throws 
    ///     Creates a background descriptor by parsing the given chunk data, 
    ///     interpreting and validating it according to the given `pixel` format and 
    ///     image `palette`. 
    /// 
    ///     Some `pixel` formats imply that `palette` must be `nil`. This 
    ///     initializer does not check this assumption, as it is expected to have 
    ///     been verified by [`Palette.init(parsing:pixel:)`].
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).bKGD`] chunk to parse. 
    /// - pixel     : Format.Pixel 
    ///     The pixel format specifying how the chunk data is to be interpreted 
    ///     and validated against.
    /// - palette   : Palette?
    ///     The image palette the chunk data is to be validated against, if 
    ///     applicable. 
    /// ## (background-parsing-and-serialization)
    public 
    init(parsing data:[UInt8], pixel:PNG.Format.Pixel, palette:PNG.Palette?) throws
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
            guard data.count == 2 
            else 
            {
                throw PNG.ParsingError.invalidBackgroundChunkLength(data.count, expected: 2)
            }
            
            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            let v:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0)
            guard v <= max 
            else 
            {
                throw PNG.ParsingError.invalidBackgroundSample(v, max: max)
            }
            self.case = .v(v)
        
        case .rgb8, .rgb16, .rgba8, .rgba16:
            guard data.count == 6 
            else 
            {
                throw PNG.ParsingError.invalidBackgroundChunkLength(data.count, expected: 6)
            }
            
            let max:UInt16  = .max >> (UInt16.bitWidth - pixel.depth)
            let r:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0),
                g:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 2),
                b:UInt16    = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 4)
            guard r <= max, g <= max, b <= max 
            else 
            {
                throw PNG.ParsingError.invalidBackgroundSample(Swift.max(r, g, b), max: max)
            }
            self.case = .rgb((r, g, b))
        
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard let palette:PNG.Palette = palette 
            else 
            {
                throw PNG.DecodingError.required(chunk: .PLTE, before: .bKGD)
            }
            guard data.count == 1
            else 
            {
                throw PNG.ParsingError.invalidBackgroundChunkLength(data.count, expected: 1)
            }
            let index:Int = .init(data[0])
            guard index < palette.entries.count
            else 
            {
                throw PNG.ParsingError.invalidBackgroundIndex(index, max: palette.entries.count - 1)
            }
            self.case = .palette(index: index)
        }
    }
    /// var PNG.Background.serialized : [Swift.UInt8] { get }
    ///     Encodes this background descriptor as the contents of a 
    ///     [`(Chunk).bKGD`] chunk.
    /// ## (background-parsing-and-serialization)
    public 
    var serialized:[UInt8] 
    {
        switch self.case 
        {
        case .palette(index: let i):
            return [.init(i)]
        case .rgb(let c):
            return .init(unsafeUninitializedCapacity: 6)
            {
                $0.store(c.r, asBigEndian: UInt16.self, at: 0)
                $0.store(c.g, asBigEndian: UInt16.self, at: 2)
                $0.store(c.b, asBigEndian: UInt16.self, at: 4)
                $1 = $0.count
            }
        case .v(let v):
            return .init(unsafeUninitializedCapacity: 2)
            {
                $0.store(v, asBigEndian: UInt16.self, at: 0)
                $1 = $0.count
            }
        }
    }
}

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

extension PNG 
{
    /// struct PNG.Chromaticity 
    ///     A chromaticity descriptor.
    /// 
    ///     This type models the information stored in a [`(Chunk).cHRM`] chunk.
    /// # [Parsing and serialization](chromaticity-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct Chromaticity  
    {
        /// let PNG.Chromaticity.w : (x:Percentmille, y:Percentmille) 
        ///     The white point of an image, expressed as a pair of fractions.
        /// ## ()
        
        /// let PNG.Chromaticity.r : (x:Percentmille, y:Percentmille) 
        ///     The chromaticity of the red component of an image, 
        ///     expressed as a pair of fractions.
        /// ## ()
        
        /// let PNG.Chromaticity.g : (x:Percentmille, y:Percentmille) 
        ///     The chromaticity of the green component of an image, 
        ///     expressed as a pair of fractions.
        /// ## ()
        
        /// let PNG.Chromaticity.b : (x:Percentmille, y:Percentmille) 
        ///     The chromaticity of the blue component of an image, 
        ///     expressed as a pair of fractions.
        /// ## ()
        public 
        let w:(x:Percentmille, y:Percentmille), 
            r:(x:Percentmille, y:Percentmille), 
            g:(x:Percentmille, y:Percentmille), 
            b:(x:Percentmille, y:Percentmille)
        
        /// init PNG.Chromaticity.init(w:r:g:b:)
        ///     Creates a chromaticity descriptor with the given values.
        /// - w : (x:Percentmille, y:Percentmille) 
        ///     The white point, expressed as a pair of fractions.
        /// - r : (x:Percentmille, y:Percentmille) 
        ///     The red chromaticity, expressed as a pair of fractions.
        /// - g : (x:Percentmille, y:Percentmille) 
        ///     The green chromaticity, expressed as a pair of fractions.
        /// - b : (x:Percentmille, y:Percentmille) 
        ///     The blue chromaticity, expressed as a pair of fractions.
        public 
        init(
            w:(x:Percentmille, y:Percentmille), 
            r:(x:Percentmille, y:Percentmille), 
            g:(x:Percentmille, y:Percentmille), 
            b:(x:Percentmille, y:Percentmille))
        {
            self.w = w 
            self.r = r 
            self.g = g 
            self.b = b
        }
    }
}
extension PNG.Chromaticity 
{
    /// init PNG.Chromaticity.init(parsing:) 
    /// throws 
    ///     Creates a chromaticity descriptor by parsing the given chunk data.
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).cHRM`] chunk to parse. 
    /// ## (chromaticity-parsing-and-serialization)
    public 
    init(parsing data:[UInt8]) throws 
    {
        guard data.count == 32
        else 
        {
            throw PNG.ParsingError.invalidChromaticityChunkLength(data.count)
        }
        
        self.w.x = .init(data.load(bigEndian: UInt32.self, as: Int.self, at:  0))
        self.w.y = .init(data.load(bigEndian: UInt32.self, as: Int.self, at:  4))
        self.r.x = .init(data.load(bigEndian: UInt32.self, as: Int.self, at:  8))
        self.r.y = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 12))
        self.g.x = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 16))
        self.g.y = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 20))
        self.b.x = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 24))
        self.b.y = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 28))
    }
    /// var PNG.Chromaticity.serialized : [Swift.UInt8] { get }
    ///     Encodes this chromaticity descriptor as the contents of a 
    ///     [`(Chunk).cHRM`] chunk.
    /// ## (chromaticity-parsing-and-serialization)
    public 
    var serialized:[UInt8]
    {
        .init(unsafeUninitializedCapacity: 32) 
        {
            $0.store(self.w.x.points, asBigEndian: UInt32.self, at:  0)
            $0.store(self.w.y.points, asBigEndian: UInt32.self, at:  4)
            
            $0.store(self.r.x.points, asBigEndian: UInt32.self, at:  8)
            $0.store(self.r.y.points, asBigEndian: UInt32.self, at: 12)
            
            $0.store(self.g.x.points, asBigEndian: UInt32.self, at: 16)
            $0.store(self.g.y.points, asBigEndian: UInt32.self, at: 20)
            
            $0.store(self.b.x.points, asBigEndian: UInt32.self, at: 24)
            $0.store(self.b.y.points, asBigEndian: UInt32.self, at: 28)
            $1 = $0.count
        }
    }
}

extension PNG 
{
    /// enum PNG.ColorRendering 
    ///     A color rendering mode.
    /// 
    ///     This type models the information stored in an [`(Chunk).sRGB`] chunk.
    ///     It is not recommended for the same image to include both a `ColorRendering`
    ///     mode and a [`ColorProfile`].
    /// # [Parsing and serialization](colorrendering-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    enum ColorRendering
    {
        /// case PNG.ColorRendering.perceptual 
        ///     The perceptual rendering mode.
        /// ## ()
        case perceptual 
        /// case PNG.ColorRendering.relative 
        ///     The relative colorimetric rendering mode.
        /// ## ()
        case relative 
        /// case PNG.ColorRendering.saturation 
        ///     The saturation rendering mode.
        /// ## ()
        case saturation 
        /// case PNG.ColorRendering.absolute 
        ///     The absolute colorimetric rendering mode.
        /// ## ()
        case absolute 
    }
}
extension PNG.ColorRendering 
{
    /// init PNG.ColorRendering.init(parsing:) 
    /// throws 
    ///     Creates a color rendering mode by parsing the given chunk data.
    /// - data      : [Swift.UInt8]
    ///     The contents of an [`(Chunk).sRGB`] chunk to parse. 
    /// ## (colorrendering-parsing-and-serialization)
    public 
    init(parsing data:[UInt8]) throws 
    {
        guard data.count == 1
        else 
        {
            throw PNG.ParsingError.invalidColorRenderingChunkLength(data.count)
        }
        
        switch data[0] 
        {
        case 0:     self = .perceptual 
        case 1:     self = .relative 
        case 2:     self = .saturation 
        case 3:     self = .absolute 
        case let code:    
            throw PNG.ParsingError.invalidColorRenderingCode(code)
        }
    }
    /// var PNG.ColorRendering.serialized : [Swift.UInt8] { get }
    ///     Encodes this color rendering mode as the contents of an 
    ///     [`(Chunk).sRGB`] chunk.
    /// ## (colorrendering-parsing-and-serialization)
    public 
    var serialized:[UInt8]
    {
        switch self 
        {
        case .perceptual:   return [0]
        case .relative:     return [1]
        case .saturation:   return [2]
        case .absolute:     return [3]
        }
    }
}

extension PNG 
{
    /// struct PNG.SignificantBits 
    ///     A color precision descriptor.
    /// 
    ///     This type models the information stored in an [`(Chunk).sBIT`] chunk.
    /// # [Parsing and serialization](significantbits-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct SignificantBits 
    {
        /// enum PNG.SignificantBits.Case 
        ///     A color precision case.
        public 
        enum Case  
        {
            /// case PNG.SignificantBits.Case.v(_:)
            ///     A color precision descriptor for a grayscale image.
            /// - _ : Swift.Int 
            ///     The number of significant bits in each grayscale sample. 
            /// 
            ///     This value must be greater than zero, and can be no greater 
            ///     than the color depth of the image color format.
            /// ## ()
            case v(Int)
            /// case PNG.SignificantBits.Case.va(_:)
            ///     A color precision descriptor for a grayscale-alpha image.
            /// - _ : (v:Swift.Int, a:Swift.Int) 
            ///     The number of significant bits in each grayscale and alpha 
            ///     sample, respectively. 
            /// 
            ///     Both precision values must be greater than zero, and neither 
            ///     can be greater than the color depth of the image color format.
            /// ## ()
            case va((v:Int, a:Int))
            /// case PNG.SignificantBits.Case.rgb(_:)
            ///     A color precision descriptor for an RGB, BGR, or indexed image.
            /// - _ : (r:Swift.Int, g:Swift.Int, b:Swift.Int) 
            ///     The number of significant bits in each red, green, and blue 
            ///     sample, respectively. If the image uses an indexed color format, 
            ///     the precision values refer to the precision of the palette 
            ///     entries, not the indices. The [`(Chunk).sBIT`] chunk type is 
            ///     not capable of specifying the precision of the alpha component 
            ///     of the palette entries. If the image palette was augmented with 
            ///     alpha samples from a [`Transparency`] descriptor, the precision  
            ///     of those samples is left undefined.
            /// 
            ///     The meaning of a color precision descriptor is 
            ///     poorly-defined for BGR images. It is strongly recommended that 
            ///     iphone-optimized images use [`(PNG).SignificantBits`] only if all 
            ///     samples have the same precision.
            /// 
            ///     Each precision value must be greater than zero, and none of them 
            ///     can be greater than the color depth of the image color format.
            /// ## ()
            case rgb((r:Int, g:Int, b:Int))
            /// case PNG.SignificantBits.Case.rgba(_:)
            ///     A color precision descriptor for an RGBA or BGRA image.
            /// - _ : (r:Swift.Int, g:Swift.Int, b:Swift.Int, a:Swift.Int) 
            ///     The number of significant bits in each red, green, blue, and alpha 
            ///     sample, respectively. 
            ///
            ///     The meaning of a color precision descriptor is 
            ///     poorly-defined for BGRA images. It is strongly recommended that 
            ///     iphone-optimized images use [`(PNG).SignificantBits`] only if all 
            ///     samples have the same precision.
            /// 
            ///     Each precision value must be greater than zero, and none of them 
            ///     can be greater than the color depth of the image color format.
            /// ## ()
            case rgba((r:Int, g:Int, b:Int, a:Int))
        }
        /// let PNG.SignificantBits.case : Case 
        ///     The value of this color precision descriptor.
        let `case`:Case
    }
}
extension PNG.SignificantBits 
{
    /// init PNG.SignificantBits.init(case:pixel:)
    ///     Creates a color precision descriptor.
    /// 
    ///     This initializer validates the precision information against the 
    ///     given pixel format.
    /// - case      : Case 
    ///     A color precision case. Each precision value in the enumeration 
    ///     payload must be greater than zero, and none of them 
    ///     can be greater than the color depth of the image color format.
    /// - pixel     : Format.Pixel 
    ///     The pixel format of the image this color precision descriptor is to be 
    ///     used for. Passing a mismatched enumeration `case` will result in a 
    ///     precondition failure.
    public 
    init(case:Case, pixel:PNG.Format.Pixel) 
    {
        let precision:[Int] 
        switch `case` 
        {
        case .v   (let  v          ):   precision = [v]
        case .va  (let (v,       a)):   precision = [v, a]
        case .rgb (let (r, g, b   )):   precision = [r, g, b]
        case .rgba(let (r, g, b, a)):   precision = [r, g, b, a]
        }
        
        let max:Int
        switch pixel  
        {
        case .indexed1, .indexed2, .indexed4, .indexed8:    max = 8
        default:                                            max = pixel.depth 
        }
        for v:Int in precision where !(1 ... max ~= v)
        {
            PNG.ParsingError.invalidSignificantBitsPrecision(v, max: max).fatal
        }
        
        self.case = `case`
    }
    /// init PNG.SignificantBits.init(parsing:pixel:) 
    /// throws 
    ///     Creates a color precision descriptor by parsing the given chunk data, 
    ///     interpreting and validating it according to the given `pixel` format.
    /// - data      : [Swift.UInt8]
    ///     The contents of an [`(Chunk).sBIT`] chunk to parse. 
    /// - pixel     : Format.Pixel 
    ///     The pixel format specifying how the chunk data is to be interpreted 
    ///     and validated against.
    /// ## (significantbits-parsing-and-serialization)
    public 
    init(parsing data:[UInt8], pixel:PNG.Format.Pixel) throws
    {
        let arity:Int = (pixel.hasColor ? 3 : 1) + (pixel.hasAlpha ? 1 : 0)
        guard data.count == arity 
        else 
        {
            throw PNG.ParsingError.invalidSignificantBitsChunkLength(data.count, 
                expected: arity)
        }
        
        let precision:[Int]
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16:
            let v:Int = .init(data[0])
            self.case = .v(v)
            precision = [v]
        
        case .rgb8, .rgb16, .indexed1, .indexed2, .indexed4, .indexed8:
            let r:Int = .init(data[0]), 
                g:Int = .init(data[1]), 
                b:Int = .init(data[2])
            self.case = .rgb((r, g, b))
            precision = [r, g, b]
        
        case .va8, .va16:
            let v:Int = .init(data[0]), 
                a:Int = .init(data[1])
            self.case = .va((v, a))
            precision = [v, a]
        
        case .rgba8, .rgba16:
            let r:Int = .init(data[0]), 
                g:Int = .init(data[1]), 
                b:Int = .init(data[2]),
                a:Int = .init(data[3])
            self.case = .rgba((r, g, b, a))
            precision = [r, g, b, a]
        }
        
        let max:Int
        switch pixel  
        {
        case .indexed1, .indexed2, .indexed4, .indexed8:    max = 8
        default:                                            max = pixel.depth 
        }
        for v:Int in precision where !(1 ... max ~= v)
        {
            throw PNG.ParsingError.invalidSignificantBitsPrecision(v, max: max)
        }
    }
    /// var PNG.SignificantBits.serialized : [Swift.UInt8] { get }
    ///     Encodes this color precision descriptor as the contents of an 
    ///     [`(Chunk).sBIT`] chunk.
    /// ## (significantbits-parsing-and-serialization)
    public 
    var serialized:[UInt8]
    {
        switch self.case 
        {
        case .v(   let c):  return [c].map(UInt8.init(_:))
        case .va(  let c):  return [c.v, c.a].map(UInt8.init(_:))
        case .rgb( let c):  return [c.r, c.g, c.b].map(UInt8.init(_:))
        case .rgba(let c):  return [c.r, c.g, c.b, c.a].map(UInt8.init(_:))
        }
    }
}

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

extension PNG 
{
    /// struct PNG.SuggestedPalette 
    ///     A suggested image palette.
    /// 
    ///     This type models the information stored in an [`(Chunk).sPLT`] chunk. 
    ///     It should not be confused with the suggested palette stored in the 
    ///     color [`Format`] of an RGB, BGR, RGBA, or BGRA image.
    /// # [Parsing and serialization](suggestedpalette-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types)
    public 
    struct SuggestedPalette 
    {
        /// enum PNG.SuggestedPalette.Entries 
        ///     A variant array of palette colors and frequencies.
        public 
        enum Entries 
        {
            /// case PNG.SuggestedPalette.Entries.rgba8(_:)
            ///     A suggested palette with an 8-bit color depth.
            /// - _ : [(color:(r:Swift.UInt8,  g:Swift.UInt8,  b:Swift.UInt8,  a:Swift.UInt8),  frequency:Swift.UInt16)] 
            ///     An array of 8-bit palette colors and frequencies.
            /// ## ()
            case rgba8( [(color:(r:UInt8,  g:UInt8,  b:UInt8,  a:UInt8),  frequency:UInt16)])
            /// case PNG.SuggestedPalette.Entries.rgba16(_:)
            ///     A suggested palette with a 16-bit color depth.
            /// - _ : [(color:(r:Swift.UInt16,  g:Swift.UInt16,  b:Swift.UInt16,  a:Swift.UInt16),  frequency:Swift.UInt16)] 
            ///     An array of 16-bit palette colors and frequencies.
            /// ## ()
            case rgba16([(color:(r:UInt16, g:UInt16, b:UInt16, a:UInt16), frequency:UInt16)])
        }
        /// let PNG.SuggestedPalette.name : Swift.String 
        ///     The name of this suggested palette. 
        public 
        let name:String 
        /// let PNG.SuggestedPalette.entries : Entries 
        ///     The colors in this suggested palette, and their frequencies.
        public 
        var entries:Entries 
        
        /// init PNG.SuggestedPalette.init(name:entries:)
        ///     Creates a suggested palette. 
        /// - name : Swift.String
        ///     The palette name. 
        /// 
        ///     This string must contain only unicode scalars 
        ///     in the ranges `"\u{20}" ... "\u{7d}"` or `"\u{a1}" ... "\u{ff}"`. 
        ///     Leading, trailing, and consecutive spaces are not allowed. 
        ///     Passing an invalid string will result in a precondition failure.
        /// - entries : Entries 
        ///     A variant array of palette colors and frequencies.
        public 
        init(name:String, entries:Entries) 
        {
            guard PNG.Text.validate(name: name.unicodeScalars) 
            else 
            {
                PNG.ParsingError.invalidSuggestedPaletteName(name).fatal 
            }
            
            self.name       = name 
            self.entries    = entries
            
            guard self.descendingFrequency 
            else 
            {
                PNG.ParsingError.invalidSuggestedPaletteFrequency.fatal
            }
        }
    }
}
extension PNG.SuggestedPalette 
{
    /// init PNG.SuggestedPalette.init(parsing:) 
    /// throws 
    ///     Creates a suggested palette by parsing the given chunk data.
    /// - data      : [Swift.UInt8]
    ///     The contents of an [`(Chunk).sPLT`] chunk to parse. 
    /// ## (suggestedpalette-parsing-and-serialization)
    public 
    init(parsing data:[UInt8]) throws 
    {
        let k:Int 
        
        (self.name, k) = try PNG.Text.name(parsing: data[...])
        {
            PNG.ParsingError.invalidSuggestedPaletteName($0)
        }
        
        guard k + 1 < data.count 
        else 
        {
            throw PNG.ParsingError.invalidSuggestedPaletteChunkLength(data.count, min: k + 2)
        }
        
        let bytes:Int = data.count - k - 2
        switch data[k + 1] 
        {
        case 8:
            guard bytes % 6 == 0 
            else 
            {
                throw PNG.ParsingError.invalidSuggestedPaletteDataLength(bytes, stride: 6)
            }
            
            self.entries = .rgba8(stride(from: k + 2, to: data.endIndex, by: 6).map 
            {
                (base:Int) -> (color:(r:UInt8, g:UInt8, b:UInt8, a:UInt8), frequency:UInt16) in
                (
                    (
                        data[base    ],
                        data[base + 1],
                        data[base + 2],
                        data[base + 3]
                    ), 
                    data.load(bigEndian: UInt16.self, as: UInt16.self, at: base + 4)
                )
            })
        
        case 16:
            guard bytes % 10 == 0 
            else 
            {
                throw PNG.ParsingError.invalidSuggestedPaletteDataLength(bytes, stride: 10)
            }
            
            self.entries = .rgba16(stride(from: k + 2, to: data.endIndex, by: 10).map 
            {
                (base:Int) -> (color:(r:UInt16, g:UInt16, b:UInt16, a:UInt16), frequency:UInt16) in
                (
                    (
                        data.load(bigEndian: UInt16.self, as: UInt16.self, at: base    ),
                        data.load(bigEndian: UInt16.self, as: UInt16.self, at: base + 2),
                        data.load(bigEndian: UInt16.self, as: UInt16.self, at: base + 4),
                        data.load(bigEndian: UInt16.self, as: UInt16.self, at: base + 6)
                    ), 
                    data.load(bigEndian: UInt16.self, as: UInt16.self, at: base + 8)
                )
            })
        
        case let code:
            throw PNG.ParsingError.invalidSuggestedPaletteDepthCode(code)
        }
        
        guard self.descendingFrequency 
        else 
        {
            throw PNG.ParsingError.invalidSuggestedPaletteFrequency
        }
    }
    
    private 
    var descendingFrequency:Bool 
    {
        var previous:UInt16 = .max
        switch self.entries 
        {
        case .rgba8(let entries):
            for current:UInt16 in entries.lazy.map(\.frequency)
            {
                guard current <= previous 
                else 
                {
                    return false 
                }
                
                previous = current 
            }
        case .rgba16(let entries):
            for current:UInt16 in entries.lazy.map(\.frequency)
            {
                guard current <= previous 
                else 
                {
                    return false 
                }
                
                previous = current 
            }
        }
        
        return true
    }
    /// var PNG.SuggestedPalette.serialized : [Swift.UInt8] { get }
    ///     Encodes this suggested palette as the contents of an 
    ///     [`(Chunk).sPLT`] chunk.
    /// ## (suggestedpalette-parsing-and-serialization)
    public 
    var serialized:[UInt8]
    {
        let head:Int = self.name.unicodeScalars.count
        let tail:Int 
        switch self.entries 
        {
        case .rgba8( let entries):  tail =  6 * entries.count 
        case .rgba16(let entries):  tail = 10 * entries.count 
        }
        
        return .init(unsafeUninitializedCapacity: head + 2 + tail) 
        {
            for (i, u):(Int, Unicode.Scalar) in 
                zip($0.indices, self.name.unicodeScalars)
            {
                $0[i] = .init(u.value)
            }
            $0[head] = 0
            
            switch self.entries 
            {
            case .rgba8( let entries):  
                $0[head + 1] = 8
                for (base, (color, frequency)):
                (
                    Int, 
                    ((r:UInt8,  g:UInt8,  b:UInt8,  a:UInt8), UInt16)
                ) 
                    in zip(stride(from: head + 2, to: $0.endIndex, by: 6), entries)
                {
                    $0[base    ]    = color.r
                    $0[base + 1]    = color.g
                    $0[base + 2]    = color.b
                    $0[base + 3]    = color.a
                    $0.store(frequency, asBigEndian: UInt16.self, at: base + 4)
                }
            case .rgba16(let entries): 
                $0[head + 1] = 16
                for (base, (color, frequency)):
                (
                    Int, 
                    ((r:UInt16, g:UInt16, b:UInt16, a:UInt16), UInt16)
                ) 
                    in zip(stride(from: head + 2, to: $0.endIndex, by: 10), entries)
                {
                    $0.store(color.r,   asBigEndian: UInt16.self, at: base    )
                    $0.store(color.g,   asBigEndian: UInt16.self, at: base + 2)
                    $0.store(color.b,   asBigEndian: UInt16.self, at: base + 4)
                    $0.store(color.a,   asBigEndian: UInt16.self, at: base + 6)
                    $0.store(frequency, asBigEndian: UInt16.self, at: base + 8)
                }
            }
            $1 = $0.count
        }
    }
}

extension PNG 
{
    /// struct PNG.TimeModified 
    ///     An image modification time. 
    /// 
    ///     This type models the information stored in a [`(Chunk).tIME`] chunk. 
    ///     This type is time-zone agnostic, and so all time values are assumed 
    ///     to be in universal time (UTC).
    /// # [Parsing and serialization](timemodified-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types) 
    public 
    struct TimeModified 
    {
        /// let PNG.TimeModified.year : Swift.Int 
        ///     The complete [gregorian](https://en.wikipedia.org/wiki/Gregorian_calendar) 
        ///     year.
        /// ## ()
        public 
        let year:Int, 
        /// let PNG.TimeModified.month : Swift.Int 
        ///     The calendar month, expressed as a 1-indexed integer.
        /// ## ()
            month:Int, 
        /// let PNG.TimeModified.day : Swift.Int 
        ///     The calendar day, expressed as a 1-indexed integer. 
        /// ## ()
            day:Int, 
        /// let PNG.TimeModified.hour : Swift.Int 
        ///     The hour, in 24-hour time, expressed as a 0-indexed integer.
        /// ## ()
            hour:Int, 
        /// let PNG.TimeModified.minute : Swift.Int 
        ///     The minute, expressed as a 0-indexed integer.
        /// ## ()
            minute:Int, 
        /// let PNG.TimeModified.second : Swift.Int 
        ///     The second, expressed as a 0-indexed integer.
        /// ## ()
            second:Int
        
        /// init PNG.TimeModified.init(year:month:day:hour:minute:second:)
        ///     Creates an image modification time. 
        /// 
        ///     The time is time-zone agnostic, and so all time parameters are 
        ///     assumed to be in universal time (UTC). Passing out-of-range 
        ///     time parameters will result in a precondition failure.
        /// - year : Swift.Int 
        ///     The complete [gregorian](https://en.wikipedia.org/wiki/Gregorian_calendar) 
        ///     year. It must be in the range `0 ..< 1 << 16`. It can be 
        ///     reasonably expected to have four decimal digits.
        /// - month : Swift.Int 
        ///     The calendar month, expressed as a 1-indexed integer. It must 
        ///     be in the range `1 ... 12`.
        /// - day : Swift.Int 
        ///     The calendar day, expressed as a 1-indexed integer.
        ///     It must be in the range `1 ... 31`.
        /// - hour : Swift.Int 
        ///     The hour, in 24-hour time, expressed as a 0-indexed integer.
        ///     It must be in the range `0 ... 23`.
        /// - minute : Swift.Int 
        ///     The minute, expressed as a 0-indexed integer.
        ///     It must be in the range `0 ... 59`.
        /// - second : Swift.Int 
        ///     The second, expressed as a 0-indexed integer. 
        ///     It must be in the range `0 ... 60`, where the value `60` is 
        ///     used to represent leap seconds.
        public 
        init(year:Int, month:Int, day:Int, hour:Int, minute:Int, second:Int) 
        {
            guard   0 ..< 1 << 16   ~= year, 
                    1 ... 12        ~= month, 
                    1 ... 31        ~= day, 
                    0 ... 23        ~= hour, 
                    0 ... 59        ~= minute, 
                    0 ... 60        ~= second 
            else 
            {
                PNG.ParsingError.invalidTimeModifiedTime(
                    year:   year, 
                    month:  month, 
                    day:    day, 
                    hour:   hour, 
                    minute: minute, 
                    second: second).fatal 
            }
            
            self.year   = year
            self.month  = month
            self.day    = day
            self.hour   = hour
            self.minute = minute
            self.second = second
        }
    }
}
extension PNG.TimeModified 
{
    /// init PNG.TimeModified.init(parsing:) 
    /// throws 
    ///     Creates an image modification time by parsing the given chunk data.
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).tIME`] chunk to parse. 
    /// ## (timemodified-parsing-and-serialization)
    public 
    init(parsing data:[UInt8]) throws 
    {
        guard data.count == 7 
        else 
        {
            throw PNG.ParsingError.invalidTimeModifiedChunkLength(data.count)
        }
        
        self.year   = data.load(bigEndian: UInt16.self, as: Int.self, at: 0) 
        self.month  = .init(data[2]) 
        self.day    = .init(data[3]) 
        self.hour   = .init(data[4]) 
        self.minute = .init(data[5]) 
        self.second = .init(data[6]) 
        
        guard   0 ..< 1 << 16   ~= self.year, 
                1 ... 12        ~= self.month, 
                1 ... 31        ~= self.day, 
                0 ... 23        ~= self.hour, 
                0 ... 59        ~= self.minute, 
                0 ... 60        ~= self.second 
        else 
        {
            throw PNG.ParsingError.invalidTimeModifiedTime(
                year:   self.year, 
                month:  self.month, 
                day:    self.day, 
                hour:   self.hour, 
                minute: self.minute, 
                second: self.second)
        }
    }
    /// var PNG.TimeModified.serialized : [Swift.UInt8] { get }
    ///     Encodes this image modification time as the contents of a 
    ///     [`(Chunk).tIME`] chunk.
    /// ## (timemodified-parsing-and-serialization)
    public 
    var serialized:[UInt8]
    {
        .init(unsafeUninitializedCapacity: 7) 
        {
            $0.store(self.year, asBigEndian: UInt16.self, at: 0)
            $0[2] = .init(self.month)
            $0[3] = .init(self.day)
            $0[4] = .init(self.hour)
            $0[5] = .init(self.minute)
            $0[6] = .init(self.second)
            $1 = $0.count
        }
    }
}

extension PNG 
{
    /// struct PNG.Text 
    ///     A text comment.
    /// 
    ///     This type models the information stored in a [`(Chunk).tEXt`], 
    ///     [`(Chunk).zTXt`], or [`(Chunk).iTXt`] chunk. 
    /// # [Parsing and serialization](text-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types) 
    public 
    struct Text 
    {
        /// let PNG.Text.compressed : Swift.Bool 
        ///     Indicates if the text is (or is to be) stored in compressed or 
        ///     uncompressed form within a PNG file.
        /// 
        ///     This flag is `true` if the original text chunk was a 
        ///     [`(Chunk).zTXt`] chunk, and `false` if it was a [`(Chunk).tEXt`] 
        ///     chunk. If the original chunk was an [`(Chunk).iTXt`] chunk, 
        ///     this flag can be either `true` or `false`.
        public 
        let compressed:Bool 
        /// let PNG.Text.keyword : (english:Swift.String, localized:Swift.String)
        ///     A keyword tag, in english, and possibly a non-english language. 
        /// 
        ///     If the text is in english, the `localized` keyword is the empty 
        ///     string `""`.
        public 
        let keyword:(english:String, localized:String), 
        /// let PNG.Text.language : [Swift.String]
        ///     An array representing an [rfc-1766](https://www.ietf.org/rfc/rfc1766.txt) 
        ///     language tag, where each element is a language subtag. 
        /// 
        ///     If this array is empty, then the language is unspecified.
            language:[String]
        /// let PNG.Text.content : Swift.String 
        ///     The text content.
        public 
        let content:String
        
        /// init PNG.Text.init(compressed:keyword:language:content:)
        ///     Creates a text comment.
        /// - compressed : Swift.Bool 
        ///     Indicates if the text is to be stored in compressed or 
        ///     uncompressed form within a PNG file.
        /// - keyword : (english:Swift.String, localized:Swift.String)
        ///     A keyword tag, in english, and possibly a non-english language. 
        /// 
        ///     The english keyword must contain only unicode scalars 
        ///     in the ranges `"\u{20}" ... "\u{7d}"` or `"\u{a1}" ... "\u{ff}"`. 
        ///     Leading, trailing, and consecutive spaces are not allowed. 
        ///     There are no restrictions on the `localized` keyword, other than 
        ///     that it must not contain any null characters.
        /// 
        ///     Passing invalid keyword strings will result in a precondition failure.
        /// 
        ///     If the text is in english, the `localized` keyword should be 
        ///     set to the empty string `""`.
        /// - language : [Swift.String]
        ///     An array representing an [rfc-1766](https://www.ietf.org/rfc/rfc1766.txt) 
        ///     language tag, where each element is a language subtag. 
        /// 
        ///     Each subtag must be a 1–8 character string containing alphabetical 
        ///     ASCII characters only. Passing an invalid language tag array 
        ///     will result in a precondition failure.
        /// 
        ///     If this array is empty, then the language is unspecified.
        /// - content : Swift.String 
        ///     The text content. There are no restrictions on it. It is allowed 
        ///     (but not recommended) to contain null characters.
        public 
        init(compressed:Bool, keyword:(english:String, localized:String), 
            language:[String], content:String)
        {
            guard Self.validate(name: keyword.english.unicodeScalars)
            else 
            {
                PNG.ParsingError.invalidTextEnglishKeyword(keyword.english).fatal 
            }
            guard (keyword.localized.unicodeScalars.allSatisfy{ $0 != "\u{0}" })
            else 
            {
                fatalError("localized keyword must not contain any null characters")
            }
            for tag:String in language
            {
                guard Self.validate(language: tag.unicodeScalars)
                else 
                {
                    PNG.ParsingError.invalidTextLanguageTag(tag).fatal 
                }
            }
            
            self.compressed = compressed 
            self.keyword    = keyword 
            self.language   = language 
            self.content    = content
        }
    }
}
extension PNG.Text 
{
    /// init PNG.Text.init(parsing:unicode:) 
    /// throws 
    ///     Creates a text comment by parsing the given chunk data, interpreting 
    ///     it either as a unicode text chunk, or a latin-1 text chunk.
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).tEXt`], [`(Chunk).zTXt`], or [`(Chunk).iTXt`] 
    ///     chunk to parse. 
    /// - unicode   : Swift.Bool 
    ///     Specifies if the given chunk `data` should be interpreted as a 
    ///     unicode chunk, or a latin-1 chunk. It should be set to `true` if the 
    ///     original text chunk was an [`(Chunk).iTXt`] chunk, and `false` 
    ///     otherwise. The default value is `true`.
    /// 
    ///     If this flag is set to `false`, the text is assumed to be in english, 
    ///     and the [`language`] tag will be set to `["en"]`.
    /// ## (text-parsing-and-serialization)
    public 
    init(parsing data:[UInt8], unicode:Bool = true) throws 
    {
        //  ┌ ╶ ╶ ╶ ╶ ╶ ╶┬───┬───┬───┬ ╶ ╶ ╶ ╶ ╶ ╶┬───┬ ╶ ╶ ╶ ╶ ╶ ╶┬───┬ ╶ ╶ ╶ ╶ ╶ ╶┐
        //  │   keyword  │ 0 │ C │ M │  language  │ 0 │   keyword  │ 0 │    text    │
        //  └ ╶ ╶ ╶ ╶ ╶ ╶┴───┴───┴───┴ ╶ ╶ ╶ ╶ ╶ ╶┴───┴ ╶ ╶ ╶ ╶ ╶ ╶┴───┴ ╶ ╶ ╶ ╶ ╶ ╶┘
        //               k  k+1 k+2 k+3           l  l+1           m  m+1
        let k:Int
        (self.keyword.english, k) = try Self.name(parsing: data[...]) 
        {
            PNG.ParsingError.invalidTextEnglishKeyword($0)
        }
        
        // parse iTXt chunk 
        if unicode 
        {
            // assert existence of compression flag and method bytes 
            guard k + 2 < data.endIndex 
            else 
            {
                throw PNG.ParsingError.invalidTextChunkLength(data.count, min: k + 3)
            }
            
            let l:Int 
            // language can be empty, in which case it is unknown 
            (self.language, l) = try Self.language(parsing: data[(k + 3)...]) 
            {
                PNG.ParsingError.invalidTextLanguageTag($0)
            }
            
            guard let m:Int = data[(l + 1)...].firstIndex(of: 0) 
            else 
            {
                throw PNG.ParsingError.invalidTextLocalizedKeyword
            }
            
            let localized:String    = .init(decoding: data[l + 1 ..< m], as: Unicode.UTF8.self)
            self.keyword.localized  = self.keyword.english == localized ? "" : localized
            
            let uncompressed:ArraySlice<UInt8>
            switch data[k + 1] 
            {
            case 0:
                uncompressed    = data[(m + 1)...]
                self.compressed = false
            case 1:
                guard data[k + 2] == 0 
                else 
                {
                    throw PNG.ParsingError.invalidTextCompressionMethodCode(data[k + 2])
                }
                var inflator:LZ77.Inflator = .init()
                guard try inflator.push(.init(data[(m + 1)...])) == nil 
                else 
                {
                    throw PNG.ParsingError.incompleteTextCompressedDatastream
                }
                uncompressed    = inflator.pull()[...]
                self.compressed = true
            case let code: 
                throw PNG.ParsingError.invalidTextCompressionCode(code)
            }
            
            self.content = .init(decoding: uncompressed, as: Unicode.UTF8.self)
        }
        // parse tEXt/zTXt chunk 
        else 
        {
            self.keyword.localized  = ""
            self.language           = ["en"]
            // if the next byte is also null, the chunk uses compression
            let uncompressed:ArraySlice<UInt8>
            if k + 1 < data.endIndex, data[k + 1] == 0
            {
                var inflator:LZ77.Inflator = .init()
                guard try inflator.push(.init(data[(k + 2)...])) == nil 
                else 
                {
                    throw PNG.ParsingError.incompleteTextCompressedDatastream
                }
                uncompressed    = inflator.pull()[...]
                self.compressed = true
            }
            else 
            {
                uncompressed    = data[(k + 1)...]
                self.compressed = false
            }
            
            self.content = .init(uncompressed.map{ Character.init(Unicode.Scalar.init($0)) })
        }
    }
    
    static 
    func name<E>(parsing data:ArraySlice<UInt8>, else error:(String?) -> E) throws 
        -> (name:String, offset:Int)
        where E:Swift.Error 
    {
        guard let offset:Int = data.firstIndex(of: 0)
        else 
        {
            throw error(nil)
        }
        
        let scalars:LazyMapSequence<ArraySlice<UInt8>, Unicode.Scalar> = 
            data[..<offset].lazy.map(Unicode.Scalar.init(_:))
            
        let name:String = .init(scalars.map(Character.init(_:)))
        guard Self.validate(name: scalars) 
        else 
        {
            throw error(name)
        }
        
        return (name, offset)
    }
    static 
    func validate<C>(name scalars:C) -> Bool 
        where C:Collection, C.Element == Unicode.Scalar 
    {
        // `count` in range `1 ... 80`
        guard var previous:Unicode.Scalar = scalars.first, scalars.count <= 80
        else 
        {
            return false
        }
        
        for scalar:Unicode.Scalar in scalars
        {
            guard   "\u{20}" ... "\u{7d}" ~= scalar || 
                    "\u{a1}" ... "\u{ff}" ~= scalar,
                    // no multiple spaces, also checks for no leading spaces 
                    (previous, scalar) != (" ", " ")
            else 
            {
                return false 
            }
            
            previous = scalar 
        }
        // no trailing spaces 
        return previous != " "
    }
    
    private static 
    func language<E>(parsing data:ArraySlice<UInt8>, else error:(String?) -> E) throws
        -> (language:[String], offset:Int)
        where E:Swift.Error 
    {
        guard let offset:Int = data.firstIndex(of: 0)
        else 
        {
            throw error(nil) 
        }
        
        // check for empty language tag 
        guard offset > data.startIndex 
        else 
        {
            return ([], offset)
        }
        
        // split on '-' 
        let language:[String] = 
            try data[..<offset].split(separator: 0x2d, omittingEmptySubsequences: false).map 
        {
            let scalars:LazyMapSequence<ArraySlice<UInt8>, Unicode.Scalar> = 
                $0.lazy.map(Unicode.Scalar.init(_:))
            let tag:String = .init(scalars.map(Character.init(_:)))
            guard Self.validate(language: scalars) 
            else 
            {
                throw error(tag)
            }
            
            // canonical lowercase 
            return tag.lowercased()
        }
        
        return (language, offset)
    }
    private static 
    func validate<C>(language scalars:C) -> Bool 
        where C:Collection, C.Element == Unicode.Scalar 
    {
        guard 1 ... 8 ~= scalars.count
        else 
        {
            return false 
        }
        
        return scalars.allSatisfy{ "a" ... "z" ~= $0 || "A" ... "Z" ~= $0 }
    }
    /// var PNG.Text.serialized : [Swift.UInt8] { get }
    ///     Encodes this text comment as the contents of a 
    ///     [`(Chunk).iTXt`] chunk. 
    /// 
    ///     This property *always* emits a unicode [`(Chunk).iTXt`] 
    ///     chunk, regardless of the type of the original chunk, if it was parsed 
    ///     from raw chunk data. It is the opinion of the library that the 
    ///     latin-1 chunk types [`(Chunk).tEXt`] and [`(Chunk).zTXt`] are 
    ///     deprecated.
    /// ## (text-parsing-and-serialization)
    public 
    var serialized:[UInt8]
    {
        let size:Int = 5 +
            self.keyword.english.count                      + 
            self.keyword.localized.count                    + 
            self.language.reduce(0){ $0 + $1.count + 1 }    + 
            self.content.utf8.count 
            
        var data:[UInt8] = []
        data.reserveCapacity(size)
        data.append(contentsOf: self.keyword.english.unicodeScalars.map{ .init($0.value) })
        data.append(0)
        data.append(self.compressed ? 1 : 0)
        data.append(0) // compression method
        data.append(contentsOf: self.language.map
        { 
            $0.unicodeScalars.map{ .init($0.value) }
        }.joined(separator: [0x2d]))
        data.append(0)
        if self.keyword.localized != self.keyword.english 
        {
            data.append(contentsOf: self.keyword.localized.utf8)
        }
        data.append(0)
        
        if self.compressed 
        {
            var deflator:LZ77.Deflator = .init(level: 13, exponent: 15, hint: 4096)
            deflator.push(.init(self.content.utf8), last: true)
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
        }
        else 
        {
            data.append(contentsOf: self.content.utf8)
        }
        
        return data
    }
}
