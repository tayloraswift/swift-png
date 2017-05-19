###### Class

# `PNGDecoder`

A progressive PNG reader object that provides pixel data lazily, scanline by scanline, and closes all file and decompression streams when it goes out of scope.

------

## Symbols

### Initializers

#### `init(path:String, recognizing recognized:Set<`[`PNGChunk`](pngchunk.md)`> = [.IDAT]) throws`

> Initialize an instance of [`PNGDecoder`](pngdecoder.md), and read the non-data chunks of the PNG at the path given. The decoder will ignore (but still validate the ordering of) any non-critical chunks that are not included in `recognized`.

### Instance properties

#### `var properties:`[`PNGProperties`](pngproperties.md)` { get }`

> The non-pixel data of the decoded image.

### Instance methods

#### `func next_scanline() throws -> [UInt8]?`

> Returns the next scanline in the image, or `nil` if the decoder is finished decoding. If the image is [`interlaced`](pngproperties.md#let-interlaced:Bool), the scanlines may not all be the same size.
