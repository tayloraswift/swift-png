# swift png tutorials 

*jump to:*

1. [basic decoding](#basic-decoding) ([sources](decode-basic/))

## basic decoding 

[`sources`](decode-basic/)

> ***by the end of this tutorial, you should be able to:***
> - *decompress a png file to its rectangular image representation*
> - *unpack rectangular image data to the built-in rgba, grayscale-alpha, and scalar color targets*

On platforms with built-in file system support (MacOS, Linux), decoding a PNG file to a pixel array takes just two function calls.

```swift 
import PNG 

let path:String = "examples/decode-basic/ada-lovelace-1840.png"

guard let image:PNG.Data.Rectangular = try .decompress(path: path)
else 
{
    fatalError("failed to open file '\(path)'")
}

let rgba:[PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self)
```

<img src="decode-basic/ada-lovelace-1840.png.rgba.png" alt="output (as png)" width=300/>

> example image, decoded to an rgba data file, and re-encoded as a png (for display purposes).
> *source: [wikimedia commons](https://commons.wikimedia.org/wiki/File:Ada_Lovelace_portrait.jpg)*

The pixels in the output array are arranged in row-major order. The pixel in the top-left corner of the image is the first element of the array.

We could also have unpacked the image pixels to the `PNG.VA<UInt8>` built-in color target, which produces an identically-shaped array of grayscale-alpha pixels.

```swift 
let va:[PNG.VA<UInt8>] = image.unpack(as: PNG.VA<UInt8>.self)
```

<img src="decode-basic/ada-lovelace-1840.png.va.png" alt="output (as png)" width=300/>

> the same example image, decoded to an grayscale-alpha data file, and re-encoded as a png.

The `unpack(as:)` method is [non-mutating](https://docs.swift.org/swift-book/LanguageGuide/Methods.html#ID239), so you can unpack the same image to multiple color targets without having to re-decode the file each time.

The `unpack(as:)` method also has an overload which allows you to unpack an image into scalar grayscale samples.

```swift 
let v:[UInt8] = image.unpack(as: UInt8.self)
```

<img src="decode-basic/ada-lovelace-1840.png.v.png" alt="output (as png)" width=300/>

> the same example image, decoded to an grayscale data file, and re-encoded as a png. it looks the same as the grayscale-alpha output because the original image has no transparent pixels.

The two `unpack(as:)` methods support all Swift integer types that conform to [`FixedWidthInteger`](https://developer.apple.com/documentation/swift/fixedwidthinteger)`&`[`UnsignedInteger`](https://developer.apple.com/documentation/swift/unsignedinteger). They have generic specializations for [`UInt8`](https://developer.apple.com/documentation/swift/uint8), [`UInt16`](https://developer.apple.com/documentation/swift/uint16), [`UInt32`](https://developer.apple.com/documentation/swift/uint32), [`UInt64`](https://developer.apple.com/documentation/swift/uint64), and [`UInt`](https://developer.apple.com/documentation/swift/uint). 

If you unpack an image to an integer type `T` with a bit width different from the bit depth of the original image, the samples will be scaled to fill the range `T.min ... T.max`. The scaling is done arithmetically, so if you unpack an 8-bit image to a [`UInt16`](https://developer.apple.com/documentation/swift/uint16)-based color target, then samples with the value `255` will become `65535`, not `65280`.

> **warning:** the built-in grayscale color targets do not compute luminance for rgb- and rgba-type images. they simply use the red component as the gray value, and discard the green and blue components. to perform more sophisticated pixel unpacking, [define a custom pixel kernel](#custom-color-targets).
