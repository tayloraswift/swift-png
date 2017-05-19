###### Class

# `PNGEncoder`

A progressive PNG writer object that encodes pixel data lazily, scanline by scanline, and closes all file and compression streams when it goes out of scope

------

## Symbols

### Initializers

#### `init(path:String, properties:`[`PNGProperties`](pngproperties.md)`, chunk_size:Int = 65536) throws`

> Initialize an instance of [`PNGEncoder`](pngencoder.md), and write the non-data chunks of the PNG to the path given. The encoder is set to emit [`IDAT`](pngchunk.md#case-IDAT) chunks that are of size `chunk_size` each.

### Instance methods

#### `func add_scanline(_ src:[UInt8]) throws`

> Attempts to write another scanline `src`’s worth of data to the PNG target. If the image is [`interlaced`](pngproperties.md#let-interlaced:Bool), the input scanline must be of the correct ADAM7 length.

#### `func finish() throws`

> Writes the [`IEND`](pngchunk.md#case-IEND) chunk to the PNG target and flushes the compression stream. This function *must* be called after the last scanline has been appended. This function *does not close the PNG file stream*, the file stream is closed when the [`PNGEncoder`](pngencoder.md) object goes out of scope and is deallocated by Swift.
