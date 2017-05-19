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
> Each pixel is a palette index and a [`PLTE`](pngchunk.md#case-plte) chunk must appear.

#### `case grayscale_a = 4`
> Each pixel is a grayscale sample, followed by an alpha sample.

#### `case rgba = 6`
> Each pixel is a red, green, and blue triple, followed by an alpha sample.

### Instance properties

#### `var channels:Int { get }`

> The number of samples per pixel for this color format.

>| Color format  | Number of channels |
>| ------------- | ------------- |
>| [`grayscale`](pngproperties_colorformat.md#case-grayscale--0)  | `1` |
>| [`rgb`](pngproperties_colorformat.md#case-rgb--2)  | `3` |
>| [`indexed`](pngproperties_colorformat.md#case-indexed--3)  | `1` |
>| [`grayscale_a`](pngproperties_colorformat.md#case-grayscale_a--4)  | `2` |
>| [`rgba`](pngproperties_colorformat.md#case-rgba--6)  | `4` |
