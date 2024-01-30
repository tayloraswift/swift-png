<div align="center">

***`png`***<br>`4.1`

[![ci status](https://github.com/tayloraswift/swift-png/actions/workflows/build.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/build.yml)
[![ci status](https://github.com/tayloraswift/swift-png/actions/workflows/build-devices.yml/badge.svg)](https://github.com/tayloraswift/swift-png/actions/workflows/build-devices.yml)


[![swift package index versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftayloraswift%2Fswift-png%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/tayloraswift/swift-png)
[![swift package index platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftayloraswift%2Fswift-png%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/tayloraswift/swift-png)

</div>

*Swift PNG* is a Foundation-less, cross-platform framework for decoding, inspecting, editing, and encoding PNG images. The framework is written in pure Swift, and will compile and provide consistent behavior on all Swift platforms. The library also comes with built-in file system support on linux, macOS, and Windows.

Swift *PNG* is [available](LICENSE) under the [Mozilla Public License 2.0](https://www.mozilla.org/en-US/MPL/2.0/). The [example programs](examples/) are public domain and can be adapted freely.

## [tutorials and example programs](examples/)

1. [basic decoding](Snippets/BasicDecoding.swift) ([sources](Snippets/BasicDecoding.swift))
2. [basic encoding](Snippets/BasicEncoding.swift) ([sources](Snippets/BasicEncoding.swift))
3. [using indexed images](Snippets/Indexing.swift) ([sources](Snippets/Indexing.swift))
4. [using iphone-optimized images](Snippets/iPhoneOptimized.swift) ([sources](Snippets/iPhoneOptimized.swift))
5. [working with metadata](Snippets/ImageMetadata.swift) ([sourcesSnippets/ImageMetadata.swift))
6. [using in-memory images](Snippets/ImagesInMemory.swift) ([sources](Snippets/ImagesInMemory.swift))
7. [online decoding](Snippets/OnlineDecoding.swift) ([sources](Snippets/OnlineDecoding.swift))
8. [custom color targets](Snippets/CustomColor.swift) ([sources](Snippets/CustomColor.swift))

## [api reference](https://tayloraswift.github.io/swift-png)

* [**`PNG.PNG`**](https://tayloraswift.github.io/swift-png/PNG)
* [**`PNG.LZ77`**](https://tayloraswift.github.io/swift-png/LZ77)
* [**`PNG.System`**](https://tayloraswift.github.io/swift-png/System)

## getting started

To use *Swift PNG* in a project, add this descriptor to the `dependencies` list in your `Package.swift` file:

```swift
.package(url: "https://github.com/tayloraswift/swift-png", .exact("4.0.3"))
```

## basic usage

Decode an image:

```swift
import PNG
func decode(png path:String) throws
{
    guard
    let image:PNG.Data.Rectangular = try .decompress(path: path)
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

## features

- ***Powerful interfaces.*** *Swift PNG*’s expressive, strongly-typed APIs make working with PNG images easy for beginners and advanced users alike. If your code compiles, you’re already most of the way there. Power users can take advantage of [custom indexing](examples/#using-indexed-images), [manual decoding workflows](examples/#online-decoding), and [user-defined color targets](examples/#custom-color-targets).

- ***Superior compression***. *Swift PNG* supports minimum cost path-based [*DEFLATE*](https://tools.ietf.org/html/rfc1951) optimization, which is why it offers four additional compression levels beyond what [*libpng*](http://www.libpng.org/pub/png/libpng.html) supports. *Swift PNG* outperforms *libpng* at its highest compression setting by [significant margins](benchmarks#compression-level-13) for almost all types of input images.

- ***Competitive performance.*** *Swift PNG* offers [competitive performance](benchmarks/) compared to *libpng*. On appropriate CPU architectures, the *Swift PNG* encoder makes use of [hardware-accelerated hash tables](https://engineering.fb.com/2019/04/25/developer-tools/f14/) for even greater performance.

- ***Pure Swift, all the way down.*** *Swift PNG* is powered by its own, native Swift *DEFLATE* implementation. It depends only on other Foundation-less, pure-Swift libraries, and therefore does not need to link Foundation. This also means the core components of *Swift PNG* work on any platform that Swift itself works on, and that *Swift PNG*’s performance [improves as the Swift compiler matures](benchmarks#performance-by-toolchain).

- ***Batteries included.*** *Swift PNG* comes with [built-in color targets](https://tayloraswift.github.io/swift-png/PNG/Color/) with support for [premultiplied alpha](https://tayloraswift.github.io/swift-png/PNG/RGBA/premultiplied/). [Convolution](https://tayloraswift.github.io/swift-png/PNG/convolve(_:dereference:kernel:)/) and [deconvolution](https://tayloraswift.github.io/swift-png/PNG/deconvolve(_:reference:kernel:)/) helper functions make [implementing custom color targets](examples/#custom-color-targets) a breeze.

    On MacOS and Linux, *Swift PNG* has built-in file system support, allowing you to [compress](https://tayloraswift.github.io/swift-png/PNG/Data/Rectangular/compress(path:level:hint:)/) or [decompress](https://tayloraswift.github.io/swift-png/PNG/Data/Rectangular/decompress(path:)/) an image, given a filepath, in a single function call. Other platforms can take advantage of *Swift PNG*’s [protocol-oriented IO](https://tayloraswift.github.io/swift-png/PNG/Bytestream/) to implement their own data loading.

- ***First-class iPhone optimization support.*** *Swift PNG* requires no custom setup or third-party plugins to handle [iPhone-optimized](examples/#using-iphone-optimized-images) PNG images. iPhone-optimized images just work, on all platforms. Reproduce [`pngcrush`](https://developer.apple.com/library/archive/qa/qa1681/_index.html)’s output with [bit width-aware alpha premultiplication](https://tayloraswift.github.io/swift-png/PNG/RGBA/premultiplied(as:)/), for seamless integration anywhere in your application stack.

- ***Comprehensive metadata support.*** *Swift PNG* can parse and validate all public PNG chunks, which are accessible as [strongly-typed metadata records](https://tayloraswift.github.io/swift-png/PNG/Metadata/).

- ***Modern error handling.*** *Swift PNG* has a fully stateless and Swift-native [error-handling system](https://tayloraswift.github.io/swift-png/PNG/Error/).

## infrastructure

A list of build flags can be found [here](build.md). Project automation scripts live in the [`utils/`](utils/) directory, and are invoked as follows:

- [**`utils/examples`**](utils/examples) `[-c/--configuration debug | release]`

    Builds and runs the example programs in the [`examples/`](examples/) directory. The `--configuration` argument specifies the Swift build mode to use.

- [**`utils/benchmark`**](utils/benchmark) `[-t/--trials n0 n1 n2]` `[-s/--save]` `[-l/--load]`

    Runs library performance and compression benchmarks, and generates a [performance report](benchmarks/).

    The `--trials` argument specifies the number of trials to run, for decompression, compression, and historical toolchain benchmarks, respectively. The `--save` argument makes this script store benchmark measurements in cache files; the `--load` argument makes this script use cached measurements instead of re-running the benchmarks.

- [**`utils/generate-documentation`**](utils/generate-documentation) `[-l/--local]`

    Generates documentation pages for the library using [*Entrapta*](https://github.com/tayloraswift/entrapta). A [Github action](.github/workflows/docs.yml) invokes this script and deploys the output to the [*Swift PNG* API reference website](https://tayloraswift.github.io/swift-png) on every commit.

The CI [runs](.github/workflows/build.yml) *Swift PNG*’s test suites with the following invocations:

```bash
swift run            PNGTests
swift run -c release PNGIntegrationTests
swift run -c release PNGCompressionTests
```

## see also

* [Swift *JPEG*](https://github.com/tayloraswift/jpeg)
