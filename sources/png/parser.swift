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
    /// # [See also](color-spaces)
    /// ## (0:color-spaces)
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
        /// # [See also](color-spaces)
        /// ## (0:color-spaces)
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
    /// var PNG.Format.Pixel.hasColor   : Swift.Bool 
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
    /// var PNG.Format.Pixel.hasAlpha   : Swift.Bool 
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
    
    /// var PNG.Format.Pixel.channels   : Swift.Int
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
    /// var PNG.Format.Pixel.depth      : Swift.Int
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
    
    /// var PNG.Format.pixel    : Pixel 
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
                palette =          solid.map        { (  $0.r,   $0.g,   $0.b, .max) }
            case .palette(let alpha):
                guard alpha.count <= solid.count 
                else 
                {
                    PNG.ParsingError.invalidTransparencyCount(alpha.count, 
                        max: solid.count).fatal
                }
                
                palette =      zip(solid, alpha).map{ ($0.0.r, $0.0.g, $0.0.b, $0.1) } + 
                    solid.dropFirst(alpha.count).map{ (  $0.r,   $0.g,   $0.b, .max) }
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
    public 
    struct Header
    {
        public
        let size:(x:Int, y:Int), 
            pixel:PNG.Format.Pixel, 
            interlaced:Bool
        
        public 
        init(size:(x:Int, y:Int), pixel:PNG.Format.Pixel, interlaced:Bool) 
        {
            guard size.x > 0, size.y > 0 
            else 
            {
                PNG.ParsingError.invalidHeaderSize(size).fatal
            }
            self.size       = size 
            self.pixel      = pixel 
            self.interlaced = interlaced
        }
    }
}
extension PNG.Header 
{
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
            throw PNG.ParsingError.invalidHeaderCompressionCode(data[10])
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
    public 
    struct Palette 
    {
        let entries:[(r:UInt8, g:UInt8, b:UInt8)]
    }
}
extension PNG.Palette 
{
    public 
    init(_ entries:[(r:UInt8, g:UInt8, b:UInt8)], pixel:PNG.Format.Pixel) 
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
extension PNG.Palette:RandomAccessCollection 
{
    public 
    var startIndex:Int 
    {
        self.entries.startIndex
    }
    public 
    var endIndex:Int 
    {
        self.entries.endIndex
    }
    public 
    subscript(index:Int) -> (r:UInt8, g:UInt8, b:UInt8) 
    {
        self.entries[index]
    }
}

extension PNG 
{
    public 
    struct Transparency 
    {
        public 
        enum Case 
        {
            case palette(alpha:[UInt8])
            case rgb(key:(r:UInt16, g:UInt16, b:UInt16))
            case v(key:UInt16)
        }
        
        public 
        let `case`:Case
    }
}
extension PNG.Transparency 
{
    public 
    init(case:Case, pixel:PNG.Format.Pixel, palette:PNG.Palette?) 
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16: 
            guard palette == nil 
            else 
            {
                PNG.ParsingError.unexpectedPalette(pixel: pixel).fatal
            }
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
                fallthrough 
            }
            guard case .palette(alpha: let alpha) = `case` 
            else 
            {
                fatalError("expected transparency of case `palette` for pixel format `\(pixel)`")
            }
            guard alpha.count <= palette.count  
            else 
            {
                PNG.ParsingError.invalidTransparencyCount(alpha.count, max: palette.count).fatal
            }
            
        case .va8, .va16, .rgba8, .rgba16:
            PNG.ParsingError.unexpectedTransparency(pixel: pixel).fatal
        }
        
        self.case = `case`
    }
    
    public 
    init(parsing data:[UInt8], pixel:PNG.Format.Pixel, palette:PNG.Palette?) throws 
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16:
            guard palette == nil 
            else 
            {
                throw PNG.ParsingError.unexpectedPalette(pixel: pixel)
            }
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
                fallthrough
            }
            guard data.count <= palette.count  
            else 
            {
                throw PNG.ParsingError.invalidTransparencyCount(data.count, max: palette.count)
            }
            self.case =  .palette(alpha: data)
        
        case .va8, .va16, .rgba8, .rgba16:
            throw PNG.ParsingError.unexpectedTransparency(pixel: pixel)
        }
    }
    
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
    public 
    struct Background 
    {
        public 
        enum Case 
        {
            case palette(index:Int)
            case rgb((r:UInt16, g:UInt16, b:UInt16))
            case v(UInt16)
        }
        
        public 
        let `case`:Case
    }
}
extension PNG.Background 
{
    public 
    init(case:Case, pixel:PNG.Format.Pixel, palette:PNG.Palette?) 
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
            guard palette == nil 
            else 
            {
                PNG.ParsingError.unexpectedPalette(pixel: pixel).fatal
            }
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
                PNG.ParsingError.unexpectedBackground(pixel: pixel).fatal
            }
            guard case .palette(index: let index) = `case` 
            else 
            {
                fatalError("expected background of case `palette` for pixel format `\(pixel)`")
            }
            guard index < palette.count
            else 
            {
                PNG.ParsingError.invalidBackgroundIndex(index, max: palette.count - 1).fatal
            }
        }
        
        self.case = `case`
    }
    public 
    init(parsing data:[UInt8], pixel:PNG.Format.Pixel, palette:PNG.Palette?) throws
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
            guard palette == nil 
            else 
            {
                throw PNG.ParsingError.unexpectedPalette(pixel: pixel)
            }
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
                throw PNG.ParsingError.unexpectedBackground(pixel: pixel)
            }
            guard data.count == 1
            else 
            {
                throw PNG.ParsingError.invalidBackgroundChunkLength(data.count, expected: 1)
            }
            let index:Int = .init(data[0])
            guard index < palette.count
            else 
            {
                throw PNG.ParsingError.invalidBackgroundIndex(index, max: palette.count - 1)
            }
            self.case = .palette(index: index)
        }
    }
    
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
    public 
    struct Histogram 
    {
        public 
        let frequencies:[UInt16]
    }
}
extension PNG.Histogram 
{
    public 
    init(frequencies:[UInt16], pixel:PNG.Format.Pixel, palette:PNG.Palette)
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16, .rgb8, .rgb16, .rgba8, .rgba16:
            PNG.ParsingError.unexpectedHistogram(pixel: pixel).fatal
        
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard frequencies.count == palette.count
            else 
            {
                fatalError("number of histogram entries (\(frequencies.count)) must match number of palette entries (\(palette.count))")
            }
            
            self.frequencies = frequencies
        }
    }
    
    public 
    init(parsing data:[UInt8], pixel:PNG.Format.Pixel, palette:PNG.Palette) throws
    {
        switch pixel 
        {
        case .v1, .v2, .v4, .v8, .v16, .va8, .va16, .rgb8, .rgb16, .rgba8, .rgba16:
            throw PNG.ParsingError.unexpectedHistogram(pixel: pixel)
        
        case .indexed1, .indexed2, .indexed4, .indexed8:
            guard data.count == 2 * palette.count
            else 
            {
                throw PNG.ParsingError.invalidHistogramChunkLength(data.count, 
                    expected: 2 * palette.count)
            }
            self.frequencies = (0 ..< data.count >> 1).map 
            {
                data.load(bigEndian: UInt16.self, as: UInt16.self, at: $0 << 1)
            }
        }
    }
    
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
    public 
    struct Gamma 
    {
        public 
        let pcm:Percentmille 
        
        public 
        init(pcm:Percentmille) 
        {
            self.pcm = pcm
        }
    }
}
extension PNG.Gamma 
{
    public 
    init(parsing data:[UInt8]) throws 
    {
        guard data.count == 4
        else 
        {
            throw PNG.ParsingError.invalidGammaChunkLength(data.count)
        }
        
        self.pcm = .init(data.load(bigEndian: UInt32.self, as: Int.self, at: 0))
    }
    
    public 
    var serialized:[UInt8] 
    {
        .init(unsafeUninitializedCapacity: MemoryLayout<UInt32>.size) 
        {
            $0.store(self.pcm.points, asBigEndian: UInt32.self, at: 0)
            $1 = $0.count
        }
    }
}

extension PNG 
{
    public 
    struct Chromaticity  
    {
        public 
        let w:(x:Percentmille, y:Percentmille), 
            r:(x:Percentmille, y:Percentmille), 
            g:(x:Percentmille, y:Percentmille), 
            b:(x:Percentmille, y:Percentmille)
        
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
    public 
    enum ColorRendering
    {
        case perceptual 
        case relative 
        case saturation 
        case absolute 
    }
}
extension PNG.ColorRendering 
{
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
    public 
    struct SignificantBits 
    {
        public 
        enum Case  
        {
            case v(Int)
            case va((v:Int, a:Int))
            case rgb((r:Int, g:Int, b:Int))
            case rgba((r:Int, g:Int, b:Int, a:Int))
        }
        
        let `case`:Case
    }
}
extension PNG.SignificantBits 
{
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
    public 
    struct ColorProfile
    {
        public 
        let name:String 
        public 
        let profile:[UInt8]
        
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
            throw PNG.ParsingError.incompleteColorProfileCompressedBytestream
        }
        
        self.profile = inflator.pull()
    }
    
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
    public 
    struct PhysicalDimensions
    {
        public 
        enum Unit 
        {
            case meter
        }
        
        public 
        let density:(x:Int, y:Int, unit:Unit?)
        
        public 
        init(density:(x:Int, y:Int, unit:Unit?)) 
        {
            self.density = density 
        }
    }
}
extension PNG.PhysicalDimensions 
{
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
    public 
    struct SuggestedPalette 
    {
        public 
        enum Entries 
        {
            case rgba8( [(color:(r:UInt8,  g:UInt8,  b:UInt8,  a:UInt8),  frequency:UInt16)])
            case rgba16([(color:(r:UInt16, g:UInt16, b:UInt16, a:UInt16), frequency:UInt16)])
        }
        
        public 
        let name:String 
        public 
        var entries:Entries 
        
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
    public 
    struct TimeModified 
    {
        public 
        let year:Int, 
            month:Int, 
            day:Int, 
            hour:Int, 
            minute:Int, 
            second:Int
        
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
    public 
    struct Text 
    {
        public 
        let compressed:Bool 
        public 
        let keyword:(english:String, localized:String), 
            language:[String]
        public 
        let content:String
        
        init(compressed:Bool, keyword:(english:String, localized:String), 
            language:[String], content:String)
        {
            guard Self.validate(name: keyword.english.unicodeScalars)
            else 
            {
                PNG.ParsingError.invalidTextEnglishKeyword(keyword.english).fatal 
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
                    throw PNG.ParsingError.incompleteTextCompressedBytestream
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
                    throw PNG.ParsingError.incompleteTextCompressedBytestream
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
    static 
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
