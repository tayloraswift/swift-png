###### Structure

# `PNGProperties`

The non-pixel image data associated with a PNG file, as specified in the PNG standard.

------

## Nested types

#### `enum` [`PNGProperties.ColorFormat`](pngproperties_colorformat.md)

## Symbols

### Initializers

#### `init?(width:Int, height:Int, bit_depth:Int, color:ColorType, interlaced:Bool)`

> Initialize and validate an instance with the given value, producing `nil` if the values are invalid (for example, a mismatched `color` format and `bit_depth` value). The following are valid `color` and `bit_depth` format values.

>| Color format  | Allowed bit depths |
>| ------------- | ------------- |
>| [`grayscale`](pngproperties_colorformat.md#case-grayscale--0)  | `1`, `2`, `4`, `8`, `16` |
>| [`rgb`](pngproperties_colorformat.md#case-rgb--2)  | `8`, `16` |
>| [`indexed`](pngproperties_colorformat.md#case-indexed--3)  | `1`, `2`, `4`, `8` |
>| [`grayscale_a`](pngproperties_colorformat.md#case-grayscale_a--4)  | `8`, `16` |
>| [`rgba`](pngproperties_colorformat.md#case-rgba--6)  | `8`, `16` |

### Instance properties

#### `var width:Int { get }`

> The width, in pixels, of the image.

#### `var height:Int { get }`

> The height, in pixels, of the image.

#### `let bit_depth:Int`

> The number of bits per *sample* in the image.

#### `let color:`[`PNGProperties.ColorFormat`](pngproperties_colorformat.md)

> The format of the pixels in the image (grayscale, grayscale with alpha, rgb color, rgba transparent color, indexed color).

#### `let interlaced:Bool`

> Whether or not the image is [interlaced](http://www.libpng.org/pub/png/spec/1.2/PNG-DataRep.html#DR.Interlaced-data-order) in ADAM7 order.

#### `var palette:[`[`RGBA`](rgba.md)`<UInt8>]? { get }`

> The color palette, if any, of the image. A color palette is forbidden in any images with a grayscale [`color`](#let-colorpngpropertiescolorformat) format.

#### `var chroma_key:`[`RGBA`](rgba.md)`<UInt16>? { get }`

> The chroma key, if any, of the image. A chroma key is forbidden in any images with a transparent [`color`](#let-colorpngpropertiescolorformat) format. The chroma key’s samples are normalized to the range `0 ... 65535`, even if the image itself is of a lower [`bit_depth`](#let-bit_depthint).

#### `let sub_dimensions:[(width:Int, height:Int)]`

> The pixel dimensions of the seven subimages that would exist in an interlaced image of the same [`width`](#var-widthint--get-) and [`height`](#var-heightint--get-). The eighth tuple in the array stores the [`width`](#var-widthint--get-) and [`height`](#var-heightint--get-) of the image.

#### `var deinterlaced_properties:`[`PNGProperties`](pngproperties.md)` { get }`

> Produces a copy of the instance, with the [`interlaced`](#let-interlacedbool) property set to `false`.

#### `var quantum8:UInt8 { get }`

> The size of the quantized levels of the image samples, if normalized to the range `0 ... 255`. Multiplying a raw sample value by the 8 bit quantum size will normalize it to the full range of a `UInt8`.

#### `var quantum16:UInt16 { get }`

> The size of the quantized levels of the image samples, if normalized to the range `0 ... 65535`. Multiplying a raw sample value by the 16 bit quantum size will normalize it to the full range of a `UInt16`.

#### `var description:String { get }`

> A textual description of the image properties.

### Instance methods

#### `mutating func set_palette(_ palette:[`[`RGBA`](rgba.md)`<UInt8>])`

> Transfers up to 256 entries in the given palette vector to the image’s color [`palette`](#var-palettergbauint8--get-). If the image bit depth is less than 8, only the first 2<sup>bit depth</sup> entries will be used by the encoder. If a color palette is forbidden by the image [`color`](#let-colorpngpropertiescolorformat) format, the palette will still be assigned to the instance property, but it will be ignored by the encoder and all other utility functions.

#### `mutating func set_chroma_key(_ key:`[`RGBA`](rgba.md)`<UInt16>)`

> Sets the image [`chroma_key`](#var-chroma_keyrgbauint16--get-) to the given value. The alpha sample is ignored and set to `UInt16.max`. If the image is not of an opaque [`color`](#let-colorpngpropertiescolorformat) format, the chroma key will still be set, but it will be ignored by the encoder and all other utility functions.

#### `func make_interlaced_buffer(initialized_to repeated_value:UInt8) -> [UInt8]`

> *[Since: 2.1]* Creates an empty buffer with the right size to fit an interlaced image of width [`width`](#var-widthint--get-) and height [`height`](#var-heightint--get-). All entries are initialized to `repeated_value`.

#### `func make_interlaced_buffer() -> [UInt8]`

> *[Since: 2.1]* Creates an empty buffer with the right size to fit an interlaced image of width [`width`](#var-widthint--get-) and height [`height`](#var-heightint--get-). All entries are initialized to 0.

#### `func make_noninterlaced_buffer(initialized_to repeated_value:UInt8) -> [UInt8]`

> *[Since: 2.1]* Creates an empty buffer with the right size to fit a non-interlaced image of width [`width`](#var-widthint--get-) and height [`height`](#var-heightint--get-). All entries are initialized to `repeated_value`.

#### `func make_noninterlaced_buffer() -> [UInt8]`

> *[Since: 2.1]* Creates an empty buffer with the right size to fit an non-interlaced image of width [`width`](#var-widthint--get-) and height [`height`](#var-heightint--get-). All entries are initialized to 0.

#### `func decompose(raw_data:[UInt8]) -> [([UInt8], `[`PNGProperties`](pngproperties.md)`)]?`

> Takes the given `raw_data` and extracts the seven ADAM7 subimage buffers from it, along with appropriate [`PNGProperties`](pngproperties.md) structures for each subimage. If the length of the input buffer is not the correct ADAM7 length, this function returns `nil`.

#### `func deinterlace(raw_data:[UInt8]) -> [UInt8]?`

> Takes the given `raw_data` and deinterlaces the pixel contents as if they were stored in ADAM7 order. If the length of the input buffer is not the correct ADAM7 length, this function returns `nil`.

#### `func rgba32(raw_data:[UInt8]) -> [`[`RGBA`](rgba.md)`<UInt8>]?`

> Takes the given `raw_data` and assembles it into an array of 32 bit [`RGBA`](rgba.md) structures. The samples are normalized to the range `0 ... 255`. The input data must be deinterlaced if it was originally interlaced, or this function will produce incorrect output. This function will return `nil` if the length of the input buffer does not match the expected data size of the image, or if the image has a [`bit_depth`](#let-bit_depthint) greater than 8. If the image was of an [`indexed`](pngproperties_colorformat.md#case-indexed--3) [`color`](#let-colorpngpropertiescolorformat) format, this function will look up the appropriate entry in the image [`palette`](#var-palettergbauint8--get-). If the palette entry, or the palette itself does not exist, this function returns `nil`.

#### `func rgba64(raw_data:[UInt8]) -> [`[`RGBA`](rgba.md)`<UInt16>]?`

> Takes the given `raw_data` and assembles it into an array of 64 bit [`RGBA`](rgba.md) structures. The samples are normalized to the range `0 ... 65535`. The input data must be deinterlaced if it was originally interlaced, or this function will produce incorrect output. This function will return `nil` if the length of the input buffer does not match the expected data size of the image. If the image was of an [`indexed`](pngproperties_colorformat.md#case-indexed--3) color format, this function will look up the appropriate entry in the image [`palette`](#var-palettergbauint8--get-). If the palette entry, or the palette itself does not exist, this function returns `nil`.

#### `func argb32_premultiplied(raw_data:[UInt8]) -> [UInt32]?`

> Takes the given `raw_data` and assembles it into an array of 32 bit unsigned integers. The alpha sample lives in the 8 most significant bits, followed by the red sample, the green sample, and then the blue sample. The red, green, and blue samples are premultiplied with the alpha according to this formula:

>     premultiplied_sample = (sample * (alpha + 1)) >> 8

> The samples are normalized to the range `0 ... 255`. This buffer is [compatible](https://www.cairographics.org/manual/cairo-Image-Surfaces.html#cairo-format-t) with the Cairo graphics library, independent of endianess. The input data must be deinterlaced if it was originally interlaced, or this function will produce incorrect output. This function will return `nil` if the length of the input buffer does not match the expected data size of the image. If the image was of an [`indexed`](pngproperties_colorformat.md#case-indexed--3) color format, this function will look up the appropriate entry in the image [`palette`](#var-palettergbauint8--get-). If the palette entry, or the palette itself does not exist, this function returns `nil`. Unlike the [`rgba32(raw_data:)`](#func-rgba32raw_datauint8---rgbauint8) function, this function will succeed even if the image [`bit_depth`](#let-bit_depthint) is greater than 8; the sample is divided by 256 and the 8 least significant bits of information are lost.

## Relationships

### Conforms to

#### [`CustomStringConvertible`](https://developer.apple.com/reference/swift/customstringconvertible)
