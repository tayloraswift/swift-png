# Basic decoding

Learn how to decompress a png file to its rectangular image representation, and unpack rectangular image data to the built-in rgba, grayscale-alpha, and scalar color targets.

## Key terms

-   Term **color target**:
    A color format combined with a fixed precision, such as `RGBA<UInt16>`.

## Worked example

@Snippet(id: "BasicDecoding", slice: "RGBA")

@Image(source: "BasicDecoding.png", alt: "output png") {
    The example image, decoded to an rgba data file, and re-encoded as a png (for display purposes).

    Source: [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Ada_Lovelace_portrait.jpg)
}

The element type of the output array, [`PNG.RGBA<UInt8>`](PNG/RGBA), is called a **color target**. The pixels in the array are arranged in row-major order. The pixel in the top-left corner of the image is the first element of the array.

We could also have unpacked the image pixels to the [`PNG.VA<UInt8>`](PNG/VA) built-in color target, which produces an identically-shaped array of grayscale-alpha pixels.

@Snippet(id: "BasicDecoding", slice: "VA")

@Image(source: "BasicDecoding.va.png", alt: "output png") {
    The example image, decoded to an grayscale-alpha data file, and re-encoded as a png.
}

The ``PNG/Image/unpack(as:) [7GIAM]`` method is non-mutating, so you can unpack the same image to multiple color targets without having to re-decode the file each time.

The ``PNG/Image/unpack(as:) [69N73]`` method also has an overload which allows you to unpack an image into scalar grayscale samples.

```swift
let v:[UInt8] = image.unpack(as: UInt8.self)
```

@Image(source: "BasicDecoding.v.png", alt: "output png") {
    The example image, decoded to an grayscale data file, and re-encoded as a PNG. it looks the same as the grayscale-alpha output because the original image has no transparent pixels.
}

The two `unpack(as:)` methods support all Swift integer types that conform to ``FixedWidthInteger`` `&` ``UnsignedInteger``. They have generic specializations for ``UInt8``, ``UInt16``, ``UInt32``, ``UInt64``, and ``UInt``.

If you unpack an image to an integer type `T` with a bit width different from the color depth of the original image, the samples will be scaled to fill the range `T.min ... T.max`. The scaling is done arithmetically, so if you unpack an 8-bit image to a ``UInt16``-based color target, then samples with the value `255` will become `65535`, not `65280`.

> warning: the built-in grayscale color targets do not compute luminance for rgb- and rgba-type images. they simply use the red component as the gray value, and discard the green and blue components. to perform more sophisticated pixel unpacking, [define a custom pixel kernel](CustomColor).
