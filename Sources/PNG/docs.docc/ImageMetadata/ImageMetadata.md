# Image metadata

Learn how to inspect and edit image metadata.

## Key terms

-   term *metadata chunk*:
    A piece of metadata in a PNG file.

## Worked example

In this tutorial, we will inspect and edit metadata in the following example image.

@Image(source: "ImageMetadata.png", alt: "input png") {
    Source: [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Coat_of_arms_of_Siam.svg)
}

On appropriate platforms, we can decompress the image using the ``PNG/Image/decompress(path:)`` static method.

@Snippet(id: "ImageMetadata", slice: "LOAD_EXAMPLE")

The image metadata lives in a ``PNG.Metadata`` structure, which is stored in the ``PNG/Image/metadata`` property of the image data structure. The metadata structure has the following properties:

```swift
var time:PNG.TimeModified?
var chromaticity:PNG.Chromaticity?
var colorProfile:PNG.ColorProfile?
var colorRendering:PNG.ColorRendering?
var gamma:PNG.Gamma?
var histogram:PNG.Histogram?
var physicalDimensions:PNG.PhysicalDimensions?
var significantBits:PNG.SignificantBits?

var suggestedPalettes:[PNG.SuggestedPalette]
var text:[PNG.Text]
var application:[(type:PNG.Chunk, data:[UInt8])]
```

The individual metadata elements are called **metadata chunks**. Each field of the metadata struct is nil or empty (`[]`) if the corresponding metadata chunk is not present in the PNG file. Some metadata chunks — suggested palette chunks, text chunks, and private application data chunks — can appear more than once, which is why those properties are ``Array``s instead of ``Optional``s.

The example image has a ``PNG/Chunk/tIME`` chunk, a ``PNG/Chunk/gAMA`` chunk, and a ``PNG/Chunk/pHYs`` chunk, and we can pretty-print them using the Swift ``print(_:separator:terminator:)`` function.

@Snippet(id: "ImageMetadata", slice: "INSPECT_CHUNKS")

```
PNG.TimeModified (tIME)
{
    year        : 2024
    month       : 1
    day         : 30
    hour        : 22
    minute      : 1
    second      : 56
}
PNG.Gamma (gAMA)
{
    value       : 45455 / 100000
}
PNG.PhysicalDimensions (pHYs)
{
    density     : (x: 2835, y: 2835) / meter
}
```

Accordingly, we can see that the example image was last saved on January 30th, 2024, at 10:01:56 PM, that it has a gamma of 0.45455, and a physical resolution of 2,835 pixels per meter (72 dpi).

The example image also has several text chunks which contain machine-readable data that [GIMP](https://www.gimp.org/) added to the image when it was first saved. We can pretty-print *all* of the metadata in the image by printing the entire metadata structure. For the sake of brevity, we won’t show the output here.

@Snippet(id: "ImageMetadata", slice: "PRINT_CHUNKS")

The ``PNG/Image/metadata`` property is mutable, so we can overwrite metadata fields without having to repack the image pixels.

@Snippet(id: "ImageMetadata", slice: "MODIFY_CHUNKS")

We can save it and read it back to show that the new image now has a different value for its ``PNG/Chunk/tIME`` chunk.

@Snippet(id: "ImageMetadata", slice: "SAVE_EXAMPLE")

```
PNG.TimeModified (tIME)
{
    year        : 1992
    month       : 8
    day         : 3
    hour        : 0
    minute      : 0
    second      : 0
}
```

>   Note:
>   Many png viewers ignore the ``PNG/Chunk/tIME`` chunk and display the image modification time stored in the image’s [EXIF data](https://en.wikipedia.org/wiki/Exif), which we did not modify. The PNG file format does not have a metadata chunk for EXIF data, so this information is usually encoded as a base-64 string in a text chunk. Parsing and editing this string is beyond the scope of this tutorial, so we won’t go over it.
