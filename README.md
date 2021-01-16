<p align="center">
  <img alt="platforms: all" src="https://img.shields.io/badge/platforms-all-lightgrey.svg" href="https://swift.org"/>
  <img alt="releases" src="https://img.shields.io/github/v/release/kelvin13/png" href="https://github.com/kelvin13/png/releases"/>
  <img alt="build status" src="https://img.shields.io/github/workflow/status/kelvin13/png/documentation/master?label=build" href="https://github.com/kelvin13/png/actions?query=workflow%3Abuild"/>
  <img alt="documentation status" src="https://img.shields.io/github/workflow/status/kelvin13/png/documentation/master?label=build%20docs" href="https://github.com/kelvin13/png/actions?query=workflow%3Adocumentation"/>
  <img alt="issues" src="https://img.shields.io/github/issues/kelvin13/png" href="https://github.com/kelvin13/png/issues?state=open"/>
  <img alt="language" src="https://img.shields.io/badge/version-swift_5.2-ffa020.svg" href="https://swift.org"/>
  <img alt="license: mpl2" src="https://img.shields.io/badge/license-MPL2-ff3079.svg" href="https://github.com/kelvin13/png/blob/master/LICENSE"/>
</p>

<p align="center">
  <img align="center" width="256px" src="logo.svg.png">
</p>

*Swift PNG* is a pure, cross-platform Swift framework for decoding, inspecting, editing, and encoding PNG images. The framework does not depend on *Foundation* or any other packages, and will compile and provide consistent behavior on all Swift platforms. *Swift PNG* supports additional features, such as file system support, on Linux and MacOS.

Swift *PNG* is available under the [Mozilla Public License 2.0](https://www.mozilla.org/en-US/MPL/2.0/). The [example programs](examples/) are public domain and can be adapted freely.

## [tutorials and example programs](examples/)

1. [basic decoding](examples/#basic-decoding) ([sources](examples/decode-basic/))
2. [basic encoding](examples/#basic-encoding) ([sources](examples/encode-basic/))
3. [using indexed images](examples/#using-indexed-images) ([sources](examples/indexed/))
4. [using iphone-optimized images](examples/#using-iphone-optimized-images) ([sources](examples/iphone-optimized/))
5. [working with metadata](examples/#working-with-metadata) ([sources](examples/metadata/))
6. [using in-memory images](examples/#using-in-memory-images) ([sources](examples/in-memory/))
7. [online decoding](examples/#online-decoding) ([sources](examples/decode-online/))
8. [custom color targets](examples/#custom-color-targets) ([sources](examples/custom-color/))

## [api reference](https://kelvin13.github.io/png)

* [**`PNG.PNG`**](https://kelvin13.github.io/png/PNG)
* [**`PNG.LZ77`**](https://kelvin13.github.io/png/LZ77)
* [**`PNG.System`**](https://kelvin13.github.io/png/System)

## getting started 

To use *Swift PNG* in a project, add this descriptor to the `dependencies` list in your `Package.swift` file:

```swift
.package(url: "https://github.com/kelvin13/png", .exact("4.0.0")) 
```

## basic usage 

Decode an image:

```swift 
import PNG 
func decode(png path:String) throws 
{
    guard let image:PNG.Data.Rectangular = try .decompress(path: path)
    else 
    {
        // failed to access file from file system
    }

    let rgba:[PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self), 
        size:(x:Int, y:Int)    = image.size
    // ...
}
```

Encode an image:

```swift 
func encode(png path:String, size:(x:Int, y:Int), pixels:[PNG.RGBA<UInt8>]) throws
{
    let image:PNG.Data.Rectangular = .init(packing: pixels, size: size, 
        layout: .init(format: .rgba8(palette: [], fill: nil)))
    try image.compress(path: path, level: 9)
}
```

## see also 

* [Swift *JPEG*](https://github.com/kelvin13/jpeg)
