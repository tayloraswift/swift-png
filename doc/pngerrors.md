###### Enumeration

# `PNGReadError:Error`

Errors that may occur when reading and decoding a PNG file from disk.

------

## Symbols

### Enumeration Cases

#### `case FileError(String)`
> MaxPNG was unable to open the PNG file. The associated value contains the path to the unreadable file.

#### `case FiletypeError`
> The file is not a PNG file.

#### `case IncompleteChunkError`
> MaxPNG was unable to read from the file the number of bytes the chunk declared itself as having.

#### `case UnexpectedCriticalChunkError(String)`
> MaxPNG encountered an unrecognized [critical chunk](http://www.libpng.org/pub/png/spec/1.2/PNG-Structure.html#Chunk-naming-conventions). The associated value contains the name of the chunk.

#### `case PNGSyntaxError(String)`
> MaxPNG encountered a malformed, but recognized, PNG chunk. The associated value contains the error message.

#### `case DataCorruptionError(PNGChunk)`
> The CRC32 value of at least one chunk did not match the computed [CRC32 checksum](www.libpng.org/pub/png/spec/1.2/PNG-Structure.html#CRC-algorithm) of the chunk data. The associated value contains the type of the corrupted chunk.

#### `case IllegalChunkError(PNGChunk)`
> MaxPNG encountered at least one chunk forbidden by the color format of the image, or the presence of another previously read chunk. The associated value contains the type of the offending chunk.

#### `case DuplicateChunkError(PNGChunk)`
> MaxPNG encountered a second occurrence of a PNG chunk that is [only allowed to occur once](http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.Summary-of-standard-chunks) per PNG file. The associated value contains the type of the repeated chunk.

#### `case ChunkOrderingError(PNGChunk)`
> MaxPNG encountered a PNG chunk that violates the [ordering rules](http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.Summary-of-standard-chunks) of the PNG standard. The associated value contains the type of the offending chunk.

#### `case MissingHeaderError`
> The PNG file is missing its [image header](http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.IHDR) chunk.

#### `case MissingPalatteError`
> The PNG file is of `indexed` [color format](pngproperties_colorformat.md) and is missing its [palette](http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.PLTE) chunk.

#### `case PrematureEOSError`
> MaxPNG encountered the end of the `DEFLATE` stream before reading the expected amount of data.

#### `case PrematureIENDError`
> MaxPNG encountered the [`IEND`](pngchunk.md#case-IEND) chunk before it encountered any [`IDAT`](pngchunk.md#case-IDAT) chunks.
