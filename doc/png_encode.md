###### Function

# `png_encode(path:raw_data:properties:chunk_size:) throws`

Compress, encode, validate, and write the contents of a raw pixel buffer to a PNG file.

------

## Declaration

````swift
png_encode(path:String, raw_data:[UInt8], properties:PNGProperties, chunk_size:Int = 65536) throws
````

## Discussion

Encode `raw_data` as a PNG file `path`. The encoder will emit [`IDAT`](pngchunk.md#case-idat) chunks that are of size `chunk_size` each. If the `properties` are set to [`interlaced`](pngproperties.md#let-interlacedbool), the encoder will write interlaced scanlines with the appropriate byte-alignment, but it assumes the pixels are *already in ADAM7 order*. The length of the `raw_data` buffer must be the correct data size computed by the PNG `properties`. If appropriate, the encoder will write the [`PLTE`](pngchunk.md#case-plte) and [`tRNS`](pngchunk.md#case-trns) chunks, but *does not validate the palette*. You must ensure that none of the indexed samples in the pixel data reference non-existent palette entries. All file and compression streams are closed when this function returns.
