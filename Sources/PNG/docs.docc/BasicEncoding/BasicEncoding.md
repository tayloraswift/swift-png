# Basic encoding

Learn how to define an image layout, understand the relationship between color formats and color targets, create a rectangular image data instance from a pixel array, and compress images at different compression levels.

## Key terms

-   term *image layout*:
    Specifies everything about a PNG image that is not strictly “metadata” or content.

-   term *interlacing*:
    An alternative way of storing the image data within the PNG file’s internal representation. See [ADAM7](https://en.wikipedia.org/wiki/Adam7_algorithm).

-   term *color format*:
    A color format is the internal representation that a PNG file uses to store image data. You can encode any color target to any color format, though some combinations can result in information loss. For example, the alpha channel of a [`PNG.RGBA<UInt8>`](PNG/RGBA) pixel array will be lost when encoding in the 8-bit RGB format.

-   term *color depth*:
    The bit width of the color channels in each pixel.

-   term *bit depth*:
    The bit width of the samples in each pixel. The bit depth is different from the color depth for the indexed color formats, because the pixel samples are indices referencing 8-bit palette colors.

-   term *chroma key*:
    A special color value that some PNG viewers use to display transparency. Such viewers will display pixels as transparent if they match the chroma key.

-   term *compression level*:
    A number in the range `0 ... 13`, where `13` is the most aggressive setting.


## Worked example

This tutorial will assume you have the image you want to encode stored as an array of pixels.

@Snippet(id: "BasicEncoding", slice: "LOAD_RGBA")

The first step to encoding a PNG file is to define an [*image layout*](#st:image-layout). Here, we have defined an 8-bit RGB layout, as well as an 8-bit grayscale layout which we will use later.

@Snippet(id: "BasicEncoding", slice: "LAYOUT")

The signature of the ``PNG.Layout`` initializer is given below:

```swift
init(format:PNG.Format, interlaced:Bool = false)
```

The `format` parameter specifies the [*color format*](#st:color-format) of the layout.

We can enable [*interlacing*](#st:interlacing) by setting the `interlaced` parameter to `true`. This parameter is `false` by default. There is rarely a good reason to enable it, and it usually hurts the compression ratio, so we have omitted it in this example. We will explore a possible use case for it in the <doc:OnlineDecoding> tutorial.

The library supports all fifteen standard PNG color formats, plus two formats from Apple’s PNG extensions.

|          enumeration case                 |    color model    | bit depth | color depth | standard  |
| -------------------------------------     | ----------------- | --------- | ----------- | --------- |
| ``PNG.Format/v1(fill:key:)``              | grayscale         | 1         | 1           | core      |
| ``PNG.Format/v2(fill:key:)``              | grayscale         | 2         | 2           | core      |
| ``PNG.Format/v4(fill:key:)``              | grayscale         | 4         | 4           | core      |
| ``PNG.Format/v8(fill:key:)``              | grayscale         | 8         | 8           | core      |
| ``PNG.Format/v16(fill:key:)``             | grayscale         | 16        | 16          | core      |
||||||
| ``PNG.Format/va8(fill:)``                 | grayscale-alpha   | 8         | 8           | core      |
| ``PNG.Format/va16(fill:)``                | grayscale-alpha   | 16        | 16          | core      |
||||||
| ``PNG.Format/indexed1(palette:fill:)``    | indexed           | 1         | 8           | core      |
| ``PNG.Format/indexed2(palette:fill:)``    | indexed           | 2         | 8           | core      |
| ``PNG.Format/indexed4(palette:fill:)``    | indexed           | 4         | 8           | core      |
| ``PNG.Format/indexed8(palette:fill:)``    | indexed           | 8         | 8           | core      |
||||||
| ``PNG.Format/bgr8(palette:fill:key:)``    | BGR               | 8         | 8           | apple     |
| ``PNG.Format/rgb8(palette:fill:key:)``    | RGB               | 8         | 8           | core      |
| ``PNG.Format/rgb16(palette:fill:key:)``   | RGB               | 16        | 16          | core      |
||||||
| ``PNG.Format/bgra8(palette:fill:)``       | BGRA              | 8         | 8           | apple     |
| ``PNG.Format/rgba8(palette:fill:)``       | RGBA              | 8         | 8           | core      |
| ``PNG.Format/rgba16(palette:fill:)``      | RGBA              | 16        | 16          | core      |

The `fill` field specifies a solid background color which some PNG viewers use to display the image. Formats that lack a full alpha channel also have a `key` field, which specifies a [*chroma key*](#st:chroma-key). The type of the `fill` and `key` fields varies depending on the color format. For example, they are `(r:UInt8, g:UInt8, b:UInt8)` tuples in the ``PNG/Format/rgb8(palette:fill:key:)`` format, and ``Int`` indices in the ``PNG/Format/indexed8(palette:fill:)`` format. Indexed images do not support chroma keys, because they contain a full alpha channel.

Most PNG viewers ignore the `fill` field, and a few ignore the `key` field as well. It is common to leave both fields as nil to disable this functionality.

The non-grayscale color formats include a `palette` field. Setting it to the empty array is analogous to setting `fill` or `key` to nil. For the indexed color formats, a non-empty `palette` is mandatory. For the other formats, it is optional (meaning it can be set to `[]`), and furthermore, ignored by almost all PNG clients, since it only specifies a suggested [posterization](https://en.wikipedia.org/wiki/Posterization) for the image.

To create a rectangular image data instance, use the ``PNG/Image/init(packing:size:layout:metadata:) ([Color], _, _, _)`` initializer. This initializer is the inverse of the ``PNG/Image/unpack(as:) -> [Color]`` method we used in the <doc:BasicDecoding> tutorial. Needless to say, the length of the pixel array must equal `size.x * size.y`. The `metadata` argument has a default value, which is an empty metadata record.

@Snippet(id: "BasicEncoding", slice: "PACK_RGB")

On platforms with built-in file system support, we can compress it to a file using the ``PNG/Image/compress(path:level:hint:)`` method. The `hint` argument provides a size hint for the emitted image data chunks. Its default value is `32768`, which is fine for almost all use cases. We will explore the `hint` parameter in more detail in the <doc:OnlineDecoding> tutorial.

The `level` argument specifies the [*compression level*](#st:compression-level). Its default value is `9`. Setting `level` to a value less than `0` is the same as setting it to `0`. Likewise, setting it to a value greater than `13` is the same as setting it to `13`.

Compression level `9` is roughly equivalent to *libpng*’s maximum compression setting in terms of compression ratio and encoding speed. The higher levels (`10` through `13`) are very computationally expensive, so you should only use them if you really need to optimize for file size.

@Snippet(id: "BasicEncoding", slice: "COMPRESS_RGB")

@Image(source: "BasicEncoding-color-rgb.png", alt: "output png") {
    The example image, encoded by *swift png* in the 8-bit rgb color format.

    Source: [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Photo_of_a_venetian_mask_in_a_studio_photo_session.jpg)
}


We can compress the same image to different files, and at different compression levels, without having to repack the pixel data.

@Snippet(id: "BasicEncoding", slice: "COMPRESS_RGB_LEVELS")

If we inspect the emitted PNG files, we can verify that the higher compression settings result in smaller images.

| level | file size     |
| ----- | ------------- |
| 0     | 379,075 bytes |
| 4     | 372,543 bytes |
| 8     | 358,592 bytes |
| 9     | 355,856 bytes |
| 13    | 353,347 bytes |

We can also encode the same pixel data using the grayscale layout we defined earlier.

@Snippet(id: "BasicEncoding", slice: "SAVE_V")

The built-in [`PNG.RGBA<T>`](PNG/RGBA) color target will discard the green, blue, and alpha channels when encoding to a grayscale format.

@Image(source: "BasicEncoding-color-v.png", alt: "output png") {
    The example image, encoded by *swift png* in the 8-bit grayscale color format.
}

Like the ``PNG/Image/unpack(as:) -> [Color]`` method, the ``PNG/Image/init(packing:size:layout:metadata:) ([Color], _, _, _)`` initializer is generic and can take an array of any color target. It also has an overload (``PNG/Image/init(packing:size:layout:metadata:) ([T], _, _, _)``) which takes an array of scalars. To demonstrate this use case, we will compute the luminance of our example image (using a standard formula), and store it as a `[UInt8]` array.

@Snippet(id: "BasicEncoding", slice: "COMPUTE_LUMINANCE")

We can encode it to a file just as we did with the array of [`PNG.RGBA<UInt8>`](PNG/RGBA) colors:

@Snippet(id: "BasicEncoding", slice: "SAVE_V_LUMINANCE")

@Image(source: "BasicEncoding-luminance-v.png", alt: "output png") {
    The computed luminance of the example image, encoded by in the 8-bit grayscale color format. The output image is 123,810 bytes in size.

    Observe that it looks different from the previous output, since we used information from all three color channels to compute the grayscale values.
}

We could also have encoded it using an RGB color format, which produces a visually identical image.

@Snippet(id: "BasicEncoding", slice: "SAVE_RGB_LUMINANCE")

@Image(source: "BasicEncoding-luminance-rgb.png", alt: "output png") {
    The computed luminance of the example image, encoded in the 8-bit rgb color format. The output image is 226,563 bytes in size.
}

The resulting file is much larger than the one encoded in the grayscale format, since it contains two redundant color channels. So there’s rarely a good reason to save a grayscale image in an non-grayscale color format.
