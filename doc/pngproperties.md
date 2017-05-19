###### Structure

# `PNGProperties`

The non-pixel image data associated with a PNG file, as specified in the PNG standard. 

------

## Nested types

#### `enum` [`PNGProperties.ColorFormat`](pngproperties_colorformat.md)

## Symbols 

### Initializers

#### `init?(width:Int, height:Int, bit_depth:Int, color:ColorType, interlaced:Bool)`

> Initialize and validate an instance with the given value, producing `nil` if the values are invalid (for example, a mismatched `color` type and `bit_depth` value).

### Instance properties 

#### `let width:Int`

> The width, in pixels, of the image.

#### `let height:Int`

> The height, in pixels, of the image.

#### `let bit_depth:Int`

> The number of bits per *sample* in the image.

#### `let color:PNGProperties.ColorFormat`

> The format of the pixels in the image (grayscale, grayscale with alpha, rgb color, rgba transparent color, indexed color).

#### `let channels:Int`

> The number of samples per pixel in the image.

#### `var palatte:[`[`RGBA`](rgba.md)`<UInt8>]? { get }`

> The color palatte, if any, of the image. A color palatte is forbidden in any images with a grayscale `color` format.

#### `var chroma_key:`[`RGBA`](rgba.md)`<UInt16>? { get }`

> The chroma key, if any, of the image. A chroma key is forbidden in any images with a transparent `color` format. The chroma key’s samples are normalized to the range `0 ... 65535`, even if the image itself is of a lower `bit_depth`.

#### `let sub_dimensions:[(width:Int, height:Int)]`

> The pixel dimensions of the seven subimages that would exist in an interlaced image of the same `width` and `height`. The eighth tuple in the array is equal to the `width` and `height` of the image.

#### `var deinterlaced_properties:`[`PNGProperties`](pngproperties.md)` { get }`

> Produces a copy of the instance, with the `interlace` property set to `false`.

#### `var quantum8:UInt8 { get }`

> The size of the quantized levels of the image samples, if normalized to the range `0 ... 255`

#### `var quantum16:UInt16 { get }`

> The size of the quantized levels of the image samples, if normalized to the range `0 ... 65535`

#### `var description:String { get }`

> A textual description of the image properties.

### Instance methods

#### `mutating func set_palatte(_ palatte:[`[`RGBA`](rgba.md)`<UInt8>])`

> Transfers up to 256 entries in the given palatte vector to the image’s color `palatte`. If the image bit depth is less than `8`, only the first 2<sup>bit depth</sup> entries will be used by the encoder.

#### `mutating func set_chroma_key(_ key:`[`RGBA`](rgba.md)`<UInt16>)`

> Sets the image `chroma_key` to the given value. The alpha sample is ignored and set to `UInt16.max`. If the image is not of an opaque `color` format, the chroma key will be ignored by the encoder.

#### `func decompose(raw_data:[UInt8]) -> [([UInt8], [`PNGProperties`](pngproperties.md)`)]?`

> Takes the given `raw_data` and extracts the seven ADAM7 subimage buffers from it, along with appropriate [`PNGProperties`](pngproperties.md) structures for each subimage. If the length of the input buffer is not the correct ADAM7 length, this function returns `nil`.

#### `func deinterlace(raw_data:[UInt8]) -> [UInt8]?`

> Takes the given `raw_data` and deinterlaces the pixel contents as if they were stored in ADAM7 order. If the length of the input buffer is not the correct ADAM7 length, this function returns `nil`.

#### `func rgba32(raw_data:[UInt8]) -> [`[`RGBA`](rgba.md)`<UInt8>]?`

> Takes the given `raw_data` and assembles it into an array of 32 bit [`RGBA`](rgba.md) structures. The samples are normalized to the range `0 ... 255`. The input data must be deinterlaced if it was originally interlaced, or this function will produce incorrect output. This function will return `nil` if the length of the input buffer does not match the expected data size of the image, or if the image has a `bit_depth` greater than 8. If the image was of an `indexed` color format, this function will look up the appropriate entry in the image `palatte`. If the palatte entry, or the palatte itself does not exist, this function returns `nil`.

#### `func rgba64(raw_data:[UInt8]) -> [`[`RGBA`](rgba.md)`<UInt16>]?`

> Takes the given `raw_data` and assembles it into an array of 64 bit [`RGBA`](rgba.md) structures. The samples are normalized to the range `0 ... 65535`. The input data must be deinterlaced if it was originally interlaced, or this function will produce incorrect output. This function will return `nil` if the length of the input buffer does not match the expected data size of the image. If the image was of an `indexed` color format, this function will look up the appropriate entry in the image `palatte`. If the palatte entry, or the palatte itself does not exist, this function returns `nil`.

## Relationships

### Conforms to 

#### [`CustomStringConvertible`](https://developer.apple.com/reference/swift/customstringconvertible)
