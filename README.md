<div align="center">

📷 &nbsp; **swift-png** &nbsp; 📸

a portable, Foundation-free library for decoding, inspecting, editing, and encoding PNG images

[documentation](https://swiftinit.org/docs/swift-png) ·
[license](LICENSE)

</div>


## Requirements

The swift-png library requires Swift 5.10 or later.

| Platform | Status |
| -------- | ------ |
| 💬 Documentation | [![Documentation](https://github.com/tayloraswift/swift-png/actions/workflows/Documentation.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/Documentation.yml) |
| 🐧 Linux | [![Tests](https://github.com/tayloraswift/swift-png/actions/workflows/Tests.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/Tests.yml) |
| 🍏 Darwin | [![Tests](https://github.com/tayloraswift/swift-png/actions/workflows/Tests.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/Tests.yml) |
| 🍏 Darwin (iOS) | [![iOS](https://github.com/tayloraswift/swift-png/actions/workflows/iOS.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/iOS.yml) |
| 🍏 Darwin (tvOS) | [![tvOS](https://github.com/tayloraswift/swift-png/actions/workflows/tvOS.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/tvOS.yml) |
| 🍏 Darwin (visionOS) | [![visionOS](https://github.com/tayloraswift/swift-png/actions/workflows/visionOS.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/visionOS.yml) |
| 🍏 Darwin (watchOS) | [![watchOS](https://github.com/tayloraswift/swift-png/actions/workflows/watchOS.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/watchOS.yml) |
| 🤖 Android | [![watchOS](https://github.com/tayloraswift/swift-png/actions/workflows/Android.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/Android.yml) |


[Check deployment minimums](https://swiftinit.org/docs/swift-png#ss:platform-requirements)


## Getting started

To use swift-png in a project, add this descriptor to the `dependencies` list in your `Package.swift` file:

```swift
.package(url: "https://github.com/tayloraswift/swift-png", from: "4.5.0")
```

The library is powered by a native Swift *DEFLATE* implementation, which can be used as a [standalone module](https://swiftinit.org/docs/swift-png/lz77).

## Basic usage

Decode an image:

```swift
import PNG
func decode(png path: String) throws {
    guard
    let image: PNG.Image = try .decompress(path: path) else {
        // failed to access file from file system
    }

    let rgba: [PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self),
        size: (x:Int, y:Int) = image.size
    // ...
}
```

Encode an image:

```swift
func encode(png path: String, size: (x:Int, y:Int), pixels: [PNG.RGBA<UInt8>]) throws {
    let image: PNG.Image = .init(
        packing: pixels,
        size: size,
        layout: .init(format: .rgba8(palette: [], fill: nil))
    )
    try image.compress(path: path, level: 9)
}
```

## Features

- ***Powerful interfaces.*** swift-png’s expressive, strongly-typed APIs make working with PNG images easy for beginners and advanced users alike. If your code compiles, you’re already most of the way there. Power users can take advantage of [custom indexing](https://swiftinit.org/docs/swift-png/png/indexing), [manual decoding workflows](https://swiftinit.org/docs/swift-png/png/onlinedecoding), and [user-defined color targets](https://swiftinit.org/docs/swift-png/png/customcolor).

- ***Superior compression***. swift-png supports minimum cost path-based [*DEFLATE*](https://tools.ietf.org/html/rfc1951) optimization, which is why it offers four additional compression levels beyond what [*libpng*](http://www.libpng.org/pub/png/libpng.html) supports.

- ***Competitive performance.*** swift-png offers competitive performance compared to *libpng*. On appropriate CPU architectures, the swift-png encoder makes use of [hardware-accelerated hash tables](https://engineering.fb.com/2019/04/25/developer-tools/f14/) for even greater performance.

- ***Pure Swift, all the way down.*** swift-png is powered by its own, native Swift *DEFLATE* implementation. It depends only on other Foundation-less, pure-Swift libraries, and therefore does not need to link Foundation. This also means the core components of swift-png work on any platform that Swift itself works on, and that swift-png’s performance improves as the Swift compiler matures.

- ***Batteries included.*** swift-png comes with [built-in color targets](https://swiftinit.org/ptcl/swift-png/png/_pngcolor) with support for [premultiplied alpha](https://swiftinit.org/docs/swift-png/png/png/rgba.premultiplied). [Convolution](https://swiftinit.org/docs/swift-png/png/png.convolve(_:dereference:kernel:)?hash=O92V) and [deconvolution](https://swiftinit.org/docs/swift-png/png/png.deconvolve(_:as:depth:kernel:)?hash=2SQA0) helper functions make [implementing custom color targets](https://swiftinit.org/docs/swift-png/png/customcolor) a breeze.

- ***First-class iPhone optimization support.*** swift-png requires no custom setup or third-party plugins to handle [iPhone-optimized](https://swiftinit.org/docs/swift-png/png/iphoneoptimized) PNG images. iPhone-optimized images just work, on all platforms. Reproduce [`pngcrush`](https://developer.apple.com/library/archive/qa/qa1681/_index.html)’s output with [bit width-aware alpha premultiplication](https://swiftinit.org/docs/swift-png/png/png/rgba.premultiplied(as:)), for seamless integration anywhere in your application stack.

- ***Comprehensive metadata support.*** swift-png can parse and validate all public PNG chunks, which are accessible as [strongly-typed metadata records](https://swiftinit.org/docs/swift-png/png/png/metadata).

- ***Modern error handling.*** swift-png has a fully stateless and Swift-native [error-handling system](https://swiftinit.org/docs/swift-png/png/png/error).

## See also

* [swift-jpeg](https://github.com/tayloraswift/jpeg)
