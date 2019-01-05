# *PNG* tutorials

## Convert color images to grayscale using natural luminance

<img src="../../examples/example-luminance-input.png" alt="luminance example input" style="width: 512px;"/>

*Example input: *Spiral staircase of the Exhibition Hall of the German Historical Museum*, by [Ansgar Koreng / CC BY-SA 3.0 (DE)](https://commons.wikimedia.org/wiki/File:Treppenturm,_Deutsches_Historisches_Museum,_Berlin,_150118,_ako.jpg)*

We will write the following function, `luminance(input:output:)`, which will load a PNG image from the given path, convert it to grayscale using a natural luminance formula, and save it at the given destination.

```swift 
func luminance(input inputPath:String, output outputPath:String) 
```

The easiest way to load a PNG file with *PNG* is to use the `rgba(path:of:)` function defined at the root of the `enum PNG` namespace. This function takes two arguments: a file path, and a component type. (As is typical with Swift APIs, *PNG* makes you supply the metatype object `UInt8.self` explicitly.) It returns a tuple containing a row-major array of the image’s pixel values, and its size, in pixels. The product of the size dimensions is guaranteed to equal the `count` of the array.

```swift
    guard let (rgba, (x, y)):([PNG.RGBA<UInt8>], (x:Int, y:Int)) = 
        try? PNG.rgba(path: inputPath, of: UInt8.self) 
```

The type argument specifies what component type you want the output `RGBA<T>` pixel values to have. Any type that conforms to both [`FixedWidthInteger`](https://developer.apple.com/documentation/swift/fixedwidthinteger) and [`UnsignedInteger`](https://developer.apple.com/documentation/swift/unsignedinteger) is a valid argument for this parameter, but only `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt` have specializations in the library. (Specializations remove generic abstraction overhead from the API.)

The `rgba(path:of:)` function can throw errors. The most common will probably be (`PNG.`)`File.Error.couldNotOpen`, which usually means you gave a wrong file path, though other errors can occur in the case of a corrupted PNG image. In this example, we’ll just gather up all errors with a `try?` and `guard` statement.

```swift 
    else 
    {
        print("failed to decode '\(inputPath)'")
        return 
    }
```

The pixel array can be transformed like any other Swift array. Here we apply a standard luminance formula, `l = 1742/8192 R + 5859/8192 G + 591/8192 B`.

```swift 
    let v:[UInt8] = rgba.map 
    {
        (c:PNG.RGBA<UInt8>) in 
        
        // widen components to avoid overflow
        let r:UInt = .init(c.r), 
            g:UInt = .init(c.g), 
            b:UInt = .init(c.b)
        
        // use the luminance formula:
        // l = 1742/8192 R + 5859/8192 G + 591/8192 B
        return .init((r * 1742 + g * 5859 + b * 591) >> 13)
    }
```

The easiest way to save the output is to use the `encode(v:size:as:chromaKey:path:level:)` function. The first argument is an array of scalar pixel values, which is generic over all [`FixedWidthInteger`](https://developer.apple.com/documentation/swift/fixedwidthinteger) and [`UnsignedInteger`](https://developer.apple.com/documentation/swift/unsignedinteger) types. Like `rgba(path:of:)`, it has specializations for all the default unsigned Swift integer types. This function also has three variants, `encode(va:size:as:chromaKey:path:level:)`, `encode(rgba:size:as:chromaKey:path:level:)`, and `encode(indices:palette:size:as:chromaKey:path:level:)`, which take `VA<T>` grayscale–alpha pairs, `RGBA<T>` color quadruples, and indexed palette colors, respectively.

The second argument specifies the size of the output image, which in this example, remains unchanged. Supplying a `size` that disagrees with the pixel array `count` will result in a `PNG.ConversionError.pixelCount` error.

The third argument specifies the format of the output image. The `.v8` argument means we are creating an 8-bit PNG with one (grayscale) color channel.

The fourth argument is optional, and allows us to supply a chroma key for the output image. A PNG chroma key indicates to viewers to display all pixels that match it as transparent, though not all viewers support it. However, if a PNG file contains a valid chroma key, *PNG* functions like `rgba(path:of:)` will honor it. Chroma keys are only meaningful for PNGs with a color format that lacks transparency, for example, RGB, as opposed to RGBA.

The fifth argument specifies the file path where the encoded PNG file will be written to. The sixth argument is optional, and allows us to specify a compression level in the range `0 ... 9`. By default, its value is `9`, which is the most aggressive level of compression. Giving a value outside the valid range will result in a precondition failure.

```swift 
    guard let _:Void = 
        try? PNG.encode(v: v, size: (x, y), as: .v8, path: outputPath)
    else 
    {
        print("failed to encode '\(outputPath)'")
        return 
    }
```

Here, we chose `.v8` for the format argument because our pixel data was an array of `UInt8` scalars. However, other bit depths such as `.v4` and `.v16` are available. Using a bit depth that is smaller than the bit width of the given pixel data will result in a smaller output file, at the expense of some data loss. Other color types like `.va8` (8-bit grayscale–alpha) and `.rgb16` (16-bit RGB color) are also available, and will result in visually identical output images, but in this case are a waste of space as the library will simply fill the extra channels with empty data. The following table lists the available color formats, excluding indexed formats.

### `encode(v: :::::)`

| Format | (V) → *Encoding* | Bit depth
| --- | --- | --- |
| `.v1` | `V` | 1 
| `.v2` | `V` | 2 
| `.v4` | `V` | 4 
| `.v8` | `V` | 8 
| `.v16` | `V` | 16 
| `.va8` | `(V, UInt8.max)` | 8 
| `.va16` | `(V, UInt16.max)` | 16 
| `.rgb8` | `(V, V, V)` | 8 
| `.rgb16` | `(V, V, V)` | 16 
| `.rgba8` | `(V, V, V, UInt8.max)` | 8 
| `.rgba16` | `(V, V, V, UInt16.max)` | 16 

Its variant functions operate on similar principles, though in some cases, pixel data is discarded, for example, when narrowing RGBA data to a grayscale target format.

### `encode(va: :::::)`

| Format | (V, A) → *Encoding* | Bit depth
| --- | --- | --- |
| `.v1` | `V` | 1 
| `.v2` | `V` | 2 
| `.v4` | `V` | 4 
| `.v8` | `V` | 8 
| `.v16` | `V` | 16 
| `.va8` | `(V, A)` | 8 
| `.va16` | `(V, A)` | 16 
| `.rgb8` | `(V, V, V)` | 8 
| `.rgb16` | `(V, V, V)` | 16 
| `.rgba8` | `(V, V, V, A)` | 8 
| `.rgba16` | `(V, V, V, A)` | 16 

### `encode(rgba: :::::)`

| Format | (R, G, B, A) → *Encoding* | Bit depth
| --- | --- | --- |
| `.v1` | `R` | 1 
| `.v2` | `R` | 2 
| `.v4` | `R` | 4 
| `.v8` | `R` | 8 
| `.v16` | `R` | 16 
| `.va8` | `(R, A)` | 8 
| `.va16` | `(R, A)` | 16 
| `.rgb8` | `(R, G, B)` | 8 
| `.rgb16` | `(R, G, B)` | 16 
| `.rgba8` | `(R, G, B, A)` | 8 
| `.rgba16` | `(R, G, B, A)` | 16 

<img src="../../examples/example-luminance-output.png" alt="luminance example output" style="width: 512px;"/>

*Example output*

The full code for this example can be found at [`examples/luminance.swift`](examples/luminance.swift).

## Apply a color ramp to a grayscale image

<img src="../../examples/example-sepia-input.png" alt="sepia example input" style="width: 512px;"/>

*Example input: *Walter Johnson and Calvin Coolidge shake hands*, [National Photo Company / PD](https://commons.wikimedia.org/wiki/File:Walter_Johnson_and_Calvin_Coolidge_shake_hands_FINAL.jpg)*

In this example, we will write the following function, `sepia(input:output:)`, which will apply a “sepia” color ramp to a grayscale input image. 

```swift 
func sepia(input inputPath:String, output outputPath:String)
```

Here, we are using a slightly lower-level *PNG* API to decode the input file in multiple steps. The first stage is failable and decompresses the image into a `Data.Uncompressed` structure, which contains the decoded image pixels, though not necessarily arranged in a rectangular row-major pixel matrix. The second step performs any necessary [deinterlacing](https://en.wikipedia.org/wiki/Adam7_algorithm) to rearrange the pixels in the `Uncompressed` image into a rectangular pixel array represented by the `Data.Rectangular` type.

```swift
    guard let input:PNG.Data.Uncompressed = try? .decompress(path: inputPath) 
    else 
    {
        print("failed to decode '\(inputPath)'")
        return 
    }

    let rectangular:PNG.Data.Rectangular = input.deinterlaced()
```

Interlaced images these days are rare, and are usually produced when someone accidentally selects the “interlace” option in an image editor, so the second step is almost always a no-op. The two calls can be replaced with a single call to `decompress(path:)` directly on the `Data.Rectangular` type, so the following code is equivalent to the above code.

```swift
    guard let input:PNG.Data.Rectangular = try? .decompress(path: inputPath) 
    else 
    {
        ...
    }
```

The `Data.Rectangular` structure has an instance method `rgba(of:)` which returns an array of `RGBA<T>` quadruples and is analogous to the namespace-level `rgba(path:of)` function in the previous example. Both functions have variants `va(of:)`/`va(path:of:)` and `v(of:)`/`v(path:of:)` which return `VA<T>` pairs and `T` scalars, respectively. They work on all PNG files, regardless of color format, in essentially the same way as the `encode()` functions in the previous example, so calling `rgba(of:)` on an opaque grayscale image will return `RGBA<T>` pixels with the same value in all three color components, and `T.max` in the alpha component. However, since we only require grayscale samples, we will use the `v(of:)` instance method.

```swift 
    // define the black- and white-stops of the color ramp
    let black:PNG.RGBA<UInt16> = .init(12000, 5000, 6000, .max), 
        white:PNG.RGBA<UInt16> = .init(.max, .max, .max, .max)

    let sepia:[PNG.RGBA<UInt16>] = rectangular.v(of: UInt16.self).map 
    {
        (value:UInt16) in 
        
        let r:UInt16 = lerp(black.r, white.r, by: value), 
            g:UInt16 = lerp(black.g, white.g, by: value), 
            b:UInt16 = lerp(black.b, white.b, by: value)
        return .init(r, g, b)
    }
```

The `lerp(_:_:by:)` function is a standard linear interpolation implementation. 

```swift 
func lerp(_ a:UInt16, _ b:UInt16, by t:UInt16) -> UInt16
{
    let a32:UInt32 = .init(a), 
        b32:UInt32 = .init(b)
    
    let f1:UInt32  = .init(UInt16.max - t) + 1, 
        f2:UInt32  = .init(             t)
    return .init((a32 * f1 + b32 * f2) >> UInt16.bitWidth)
}
```

You might notice we are using 16-bit color with `UInt16.self` as the argument to the `v(of:)` function’s metatype parameter. We are doing this to increase the precision in the linear interpolation, so that distinct pixel values in the input image will get distinct pixel values in the output image. (Though no one could probably tell the difference.) The input PNG file is actually an 8-bit image, so pixels with the value `255` (pure white, `UInt8.max`) will be seen as `65535` (`UInt16.max`) by our program. We could also have chosen `UInt32.self` or `UInt64.self` if we wanted even more precision.

While using `Data.Uncompressed` and `Data.Rectangular` is more verbose than using the single-stage `v`/`va`/`rgba(path:of:)` APIs, the image data types give us access to the image metadata through the `properties` member. This structure has type (`PNG.`)`Properties`, and contains information like the size, interlacing algorithm, palette, chroma key, and color format of the image. We can, for example, assert that our input image has a grayscale color format (including grayscale–alpha), since it wouldn’t make sense to apply a color ramp to a multi-color image.

```swift 
    let format:PNG.Properties.Format = rectangular.properties.format
    guard !format.code.hasColor
    else 
    {
        print("input image is not grayscale (color format '\(format.code)')")
        return 
    }
```

> Warning: An image can be visually monochrome, and still be encoded in an RGB or RGBA color format, simply by having the same component values in all three color channels. In that case, the above guard statement will reject the image.

We can then use the `convert(rgba:size:to:)` static method to pack the output pixels back into a `Data.Uncompressed` byte buffer, and the `compress(path:chunkSize:level:)` instance method to encode it and save it to disk. 

The `chunkSize:` argument is optional and by default is set to 2<sup>16</sup> bytes. It specifies the size of the internal data blocks in the compressed PNG file, and there is rarely a good reason to change it. At the default, the library will emit 20–30 chunks for a “normal” size image (“1K” resolution).

The `level:` argument is also optional, and by default it’s set to 9 (just like the `encode` functions), but here we’ve set it to 8, for no reason other than to show that compression levels other than 9 work.

```swift 
    guard let output:PNG.Data.Uncompressed = 
        try? .convert(rgba: sepia, size: rectangular.properties.size, to: .rgb16)
    else 
    {
        print("failed to convert '\(inputPath)'")
        return 
    }

    guard let _:Void = try? output.compress(path: outputPath, level: 8)
    else 
    {
        print("failed to encode '\(outputPath)'")
        return 
    }
```

The above code is, of course, equivalent to a single call to `PNG.encode(rgba: sepia, size: rectangular.properties.size, as: .rgb16, path: outputPath, level: 8)`.

You might wonder why the `Data.Uncompressed` API even exists, if the namespace-level APIs are so much more convenient. The answer is that the `Data.Uncompressed` API is much more flexible. The `compress(path:chunkSize:level:)` and `decompress(path:)` methods have generic variants `compress<Destination>(to:chunkSize:level:)` and `decompress<Source>(from:)` which take source and destination arguments which conform to the protocols `DataSource` and `DataDestination`, respectively.

```swift 
protocol DataSource
{
    mutating
    func read(count:Int) -> [UInt8]?
}

protocol DataDestination
{
    mutating
    func write(_ buffer:[UInt8]) -> Void?
}
```

These protocols can be used, for example, to implement reading and writing PNG files to memory instead of to disk. (This is out of the scope of this tutorial, but not difficult. Just wrap an ordinary Swift `Array` and implement `read(count:)` and `write(_:)`.)

<img src="../../examples/example-sepia-output.png" alt="sepia example output" style="width: 512px;"/>

*Example output*

The full code for this example can be found at [`examples/sepia.swift`](examples/sepia.swift).
