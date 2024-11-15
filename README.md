<div align="center">

***`png`***

[![Tests](https://github.com/tayloraswift/swift-png/actions/workflows/Tests.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/Tests.yml)
[![Documentation](https://github.com/tayloraswift/swift-png/actions/workflows/Documentation.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/Documentation.yml)

</div>

*Swift PNG* is a Foundation-less, cross-platform framework for decoding, inspecting, editing, and encoding PNG images. The framework is written in pure Swift, and will compile and provide consistent behavior on all Swift platforms. The library also comes with built-in file system support on linux, macOS, and Windows.

The library is powered by a native Swift *DEFLATE* implementation, which can be used as a [standalone module](https://swiftinit.org/docs/swift-png/lz77).

Swift *PNG* is [available](LICENSE) under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0). The [example programs](Snippets/) are public domain and can be adapted freely.

Swift *PNG*’s [documentation](https://swiftinit.org/docs/swift-png/png) is available on Swiftinit!


## Requirements

The swift-png library requires Swift 5.10 or later.

| Platform | Status |
| -------- | ------ |
| 🐧 Linux | [![Tests](https://github.com/tayloraswift/swift-png/actions/workflows/Tests.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/Tests.yml) |
| 🍏 Darwin | [![Tests](https://github.com/tayloraswift/swift-png/actions/workflows/Tests.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/Tests.yml) |
| 🍏 Darwin (iOS) | [![iOS](https://github.com/tayloraswift/swift-png/actions/workflows/iOS.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/iOS.yml) |
| 🍏 Darwin (tvOS) | [![tvOS](https://github.com/tayloraswift/swift-png/actions/workflows/tvOS.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/tvOS.yml) |
| 🍏 Darwin (visionOS) | [![visionOS](https://github.com/tayloraswift/swift-png/actions/workflows/visionOS.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/visionOS.yml) |
| 🍏 Darwin (watchOS) | [![watchOS](https://github.com/tayloraswift/swift-png/actions/workflows/watchOS.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/watchOS.yml) |


[Check deployment minimums](https://swiftinit.org/docs/swift-png#ss:platform-requirements)


## Getting started

To use *Swift PNG* in a project, add this descriptor to the `dependencies` list in your `Package.swift` file:

```swift
.package(url: "https://github.com/tayloraswift/swift-png", .from("4.4.0"))
```

## Basic usage

Decode an image:

```swift
import PNG
func decode(png path:String) throws
{
    guard
    let image:PNG.Image = try .decompress(path: path)
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
    let image:PNG.Image = .init(packing: pixels, size: size,
        layout: .init(format: .rgba8(palette: [], fill: nil)))
    try image.compress(path: path, level: 9)
}
```

## Features

- ***Powerful interfaces.*** *Swift PNG*’s expressive, strongly-typed APIs make working with PNG images easy for beginners and advanced users alike. If your code compiles, you’re already most of the way there. Power users can take advantage of [custom indexing](https://swiftinit.org/docs/swift-png/png/indexing), [manual decoding workflows](https://swiftinit.org/docs/swift-png/png/onlinedecoding), and [user-defined color targets](https://swiftinit.org/docs/swift-png/png/customcolor).

- ***Superior compression***. *Swift PNG* supports minimum cost path-based [*DEFLATE*](https://tools.ietf.org/html/rfc1951) optimization, which is why it offers four additional compression levels beyond what [*libpng*](http://www.libpng.org/pub/png/libpng.html) supports.

- ***Competitive performance.*** *Swift PNG* offers competitive performance compared to *libpng*. On appropriate CPU architectures, the *Swift PNG* encoder makes use of [hardware-accelerated hash tables](https://engineering.fb.com/2019/04/25/developer-tools/f14/) for even greater performance.

- ***Pure Swift, all the way down.*** *Swift PNG* is powered by its own, native Swift *DEFLATE* implementation. It depends only on other Foundation-less, pure-Swift libraries, and therefore does not need to link Foundation. This also means the core components of *Swift PNG* work on any platform that Swift itself works on, and that *Swift PNG*’s performance improves as the Swift compiler matures.

- ***Batteries included.*** *Swift PNG* comes with [built-in color targets](https://swiftinit.org/ptcl/swift-png/png/_pngcolor) with support for [premultiplied alpha](https://swiftinit.org/docs/swift-png/png/png/rgba.premultiplied). [Convolution](https://swiftinit.org/docs/swift-png/png/png.convolve(_:dereference:kernel:)?hash=O92V) and [deconvolution](https://swiftinit.org/docs/swift-png/png/png.deconvolve(_:as:depth:kernel:)?hash=2SQA0) helper functions make [implementing custom color targets](https://swiftinit.org/docs/swift-png/png/customcolor) a breeze.

- ***First-class iPhone optimization support.*** *Swift PNG* requires no custom setup or third-party plugins to handle [iPhone-optimized](https://swiftinit.org/docs/swift-png/png/iphoneoptimized) PNG images. iPhone-optimized images just work, on all platforms. Reproduce [`pngcrush`](https://developer.apple.com/library/archive/qa/qa1681/_index.html)’s output with [bit width-aware alpha premultiplication](https://swiftinit.org/docs/swift-png/png/png/rgba.premultiplied(as:)), for seamless integration anywhere in your application stack.

- ***Comprehensive metadata support.*** *Swift PNG* can parse and validate all public PNG chunks, which are accessible as [strongly-typed metadata records](https://swiftinit.org/docs/swift-png/png/png/metadata).

- ***Modern error handling.*** *Swift PNG* has a fully stateless and Swift-native [error-handling system](https://swiftinit.org/docs/swift-png/png/png/error).

## See also

* [Swift *JPEG*](https://github.com/tayloraswift/jpeg)
