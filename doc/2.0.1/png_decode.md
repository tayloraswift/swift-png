###### Function

# `png_decode(path:recognizing:)`

Decompress, decode, and validate the raw pixel contents of a PNG file, without performing deinterlacing or deindexing.

------

## Declaration

````swift
func png_decode(path:String, recognizing recognized:Set<PNGChunk> = Set([.IDAT]))
     throws -> ([UInt8], PNGProperties)
````

## Discussion

Reads and decodes the PNG file at `path`, ignoring all chunks, except [`IHDR`](pngchunk.md#case-ihdr) and [`IEND`](pngchunk.md#case-iend), not in `recognized`. This function returns the raw pixel data in a buffer of `UInt8` bytes, and the other attributes of the PNG file in a [`PNGProperties`](pngproperties.md) struct. This `PNGProperties` struct must be used to further process the raw pixel data, for example, to deinterlace it, or normalize it to [`RGBA`](rgba.md) color space. Any *compatible* `PNGProperties` struct may be used to further process the raw image data, but may produce different output, for example, if the [`palette`](pngproperties.md#var-palettergbauint8--get-) differs. If the image [`bit_depth`](pngproperties.md#let-bit_depthint) is less than `8`, you should not assume that the pixels are packed contiguously in the bytes-array; there may be sub-byte gaps between scanlines. All file and decompression streams are closed when this function returns.
