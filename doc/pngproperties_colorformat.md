###### Enumeration

# `PNGProperties.ColorFormat:Int`

The five PNG color formats, as defined in the [PNG standard](http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.IHDR).

------

## Symbols

### Enumeration Cases

#### `case grayscale = 0`
> Each pixel is a grayscale sample.

#### `case rgb = 2`
> Each pixel is a red, green, and blue triple.

#### `case indexed = 3`
> Each pixel is a palette index and a [`PLTE`](pngchunk.md#case-PLTE) chunk must appear.

#### `case grayscale_a = 4`
> Each pixel is a grayscale sample, followed by an alpha sample.

#### `case rgba = 6`
> Each pixel is a red, green, and blue triple, followed by an alpha sample.
