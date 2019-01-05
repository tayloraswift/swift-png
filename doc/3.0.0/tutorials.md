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
