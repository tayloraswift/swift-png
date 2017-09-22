###### Enumeration

# `PNGChunk:String`

Public PNG chunks, as specified in the [PNG standard](http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html).

------

## Symbols

### Enumeration Cases

#### `case IHDR`
> Represents the header chunk of a PNG.

#### `case PLTE`
> Represents the palette chunk of a PNG.

#### `case IDAT`
> Represents a pixel data chunk of a PNG.

#### `case IEND`
> Represents the terminating chunk of a PNG.

#### `case cHRM`
> Represents the chromaticity chunk of a PNG.

#### `case gAMA`
> Represents the gamma value chunk of a PNG.

#### `case iCCP`
> Represents the color profile chunk of a PNG.

#### `case sBIT`
> Represents the significant bits value chunk of a PNG.

#### `case sRGB`
> Represents the sRGB chunk of a PNG.

#### `case bKGD`
> Represents the background color chunk of a PNG.

#### `case hIST`
> Represents the histogram chunk of a PNG.

#### `case tRNS`
> Represents the transparency chunk of a PNG.

#### `case pHYs`
> Represents the physical dimensions chunk of a PNG.

#### `case sPLT`
> Represents the suggested palette chunk of a PNG.

#### `case tIME`
> Represents the modification time chunk of a PNG.

#### `case iTXt`
> Represents a possibly compressed UTF-8 text chunk of a PNG.

#### `case tEXt`
> Represents an uncompressed Latin-1 text chunk of a PNG.

#### `case zTXt`
> Represents a compressed Latin-1 text chunk of a PNG.

#### `case PRIVATE`
> Represents a [private PNG chunk](http://www.libpng.org/pub/png/spec/1.2/PNG-Encoders.html#E.Use-of-private-chunks).

#### `case __INTERRUPTOR__`
> Represents an extraneous PNG chunk found between any two `IDAT` chunks. Used for [error messages](pngerrors.md).
