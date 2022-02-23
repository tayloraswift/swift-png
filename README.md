<p align="center">
  <a href="https://swift.org"><img alt="platforms: all" src="https://img.shields.io/badge/platforms-all-lightgrey.svg"/></a>
  <a href="https://github.com/kelvin13/swift-png/releases"><img alt="releases" src="https://img.shields.io/github/v/release/kelvin13/swift-png"/></a>
  <a href="https://github.com/kelvin13/swift-png/actions?query=workflow%3Abuild"><img alt="build status" src="https://img.shields.io/github/workflow/status/kelvin13/swift-png/documentation/master?label=build"/></a>
  <a href="https://github.com/kelvin13/swift-png/actions?query=workflow%3Adocumentation"><img alt="documentation status" src="https://img.shields.io/github/workflow/status/kelvin13/swift-png/documentation/master?label=build%20docs"/></a>
  <a href="https://github.com/kelvin13/swift-png/issues?state=open"><img alt="issues" src="https://img.shields.io/github/issues/kelvin13/swift-png"/></a>
  <a href="https://swift.org"><img alt="language" src="https://img.shields.io/badge/version-swift_5.5-ffa020.svg"/></a>
  <a href="https://github.com/kelvin13/swift-png/blob/master/LICENSE"><img alt="license: mpl2" src="https://img.shields.io/badge/license-MPL2-ff3079.svg"/></a>
</p>

<p align="center">
  <em><code>png</code></em><br/><code>4.0.2</code>
</p>

*Swift PNG* is a pure, cross-platform Swift framework for decoding, inspecting, editing, and encoding PNG images. The framework does not depend on *Foundation* or any other packages, and will compile and provide consistent behavior on all Swift platforms. *Swift PNG* also comes with built-in file system support on Linux and MacOS.

Swift *PNG* is [available](LICENSE) under the [Mozilla Public License 2.0](https://www.mozilla.org/en-US/MPL/2.0/). The [example programs](examples/) are public domain and can be adapted freely.

## [tutorials and example programs](examples/)

1. [basic decoding](examples/#basic-decoding) ([sources](examples/decode-basic/))
2. [basic encoding](examples/#basic-encoding) ([sources](examples/encode-basic/))
3. [using indexed images](examples/#using-indexed-images) ([sources](examples/indexed/))
4. [using iphone-optimized images](examples/#using-iphone-optimized-images) ([sources](examples/iphone-optimized/))
5. [working with metadata](examples/#working-with-metadata) ([sources](examples/metadata/))
6. [using in-memory images](examples/#using-in-memory-images) ([sources](examples/in-memory/))
7. [online decoding](examples/#online-decoding) ([sources](examples/decode-online/))
8. [custom color targets](examples/#custom-color-targets) ([sources](examples/custom-color/))

## [api reference](https://kelvin13.github.io/swift-png)

* [**`PNG.PNG`**](https://kelvin13.github.io/swift-png/PNG)
* [**`PNG.LZ77`**](https://kelvin13.github.io/swift-png/LZ77)
* [**`PNG.System`**](https://kelvin13.github.io/swift-png/System)

## getting started 

To use *Swift PNG* in a project, add this descriptor to the `dependencies` list in your `Package.swift` file:

```swift
.package(url: "https://github.com/kelvin13/swift-png", .exact("4.0.2")) 
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

## features 

- ***Powerful interfaces.*** *Swift PNG*’s expressive, strongly-typed APIs make working with PNG images easy for beginners and advanced users alike. If your code compiles, you’re already most of the way there. Power users can take advantage of [custom indexing](examples/#using-indexed-images), [manual decoding workflows](examples/#online-decoding), and [user-defined color targets](examples/#custom-color-targets).

- ***Superior compression***. *Swift PNG* supports minimum cost path-based [*DEFLATE*](https://tools.ietf.org/html/rfc1951) optimization, which is why it offers four additional compression levels beyond what [*libpng*](http://www.libpng.org/pub/png/libpng.html) supports. *Swift PNG* outperforms *libpng* at its highest compression setting by [significant margins](benchmarks#compression-level-13) for almost all types of input images. 

- ***Competitive performance.*** *Swift PNG* offers [competitive performance](benchmarks/) compared to *libpng*. On appropriate CPU architectures, the *Swift PNG* encoder makes use of [hardware-accelerated hash tables](https://engineering.fb.com/2019/04/25/developer-tools/f14/) for even greater performance.

- ***Pure Swift, all the way down.*** Aside from having no external dependencies, *Swift PNG* is powered by its own, native Swift *DEFLATE* implementation. This means *Swift PNG* works on any platform that Swift itself works on. It also means that *Swift PNG*’s performance [improves as the Swift compiler matures](benchmarks#performance-by-toolchain).

- ***Batteries included.*** *Swift PNG* comes with [built-in color targets](https://kelvin13.github.io/swift-png/PNG/Color/) with support for [premultiplied alpha](https://kelvin13.github.io/swift-png/PNG/RGBA/premultiplied/). [Convolution](https://kelvin13.github.io/swift-png/PNG/convolve(_:dereference:kernel:)/) and [deconvolution](https://kelvin13.github.io/swift-png/PNG/deconvolve(_:reference:kernel:)/) helper functions make [implementing custom color targets](examples/#custom-color-targets) a breeze.
  
    On MacOS and Linux, *Swift PNG* has built-in file system support, allowing you to [compress](https://kelvin13.github.io/swift-png/PNG/Data/Rectangular/compress(path:level:hint:)/) or [decompress](https://kelvin13.github.io/swift-png/PNG/Data/Rectangular/decompress(path:)/) an image, given a filepath, in a single function call. Other platforms can take advantage of *Swift PNG*’s [protocol-oriented IO](https://kelvin13.github.io/swift-png/PNG/Bytestream/) to implement their own data loading.

- ***First-class iPhone optimization support.*** *Swift PNG* requires no custom setup or third-party plugins to handle [iPhone-optimized](examples/#using-iphone-optimized-images) PNG images. iPhone-optimized images just work, on all platforms. Reproduce [`pngcrush`](https://developer.apple.com/library/archive/qa/qa1681/_index.html)’s output with [bit width-aware alpha premultiplication](https://kelvin13.github.io/swift-png/PNG/RGBA/premultiplied(as:)/), for seamless integration anywhere in your application stack.

- ***Comprehensive metadata support.*** *Swift PNG* can parse and validate all public PNG chunks, which are accessible as [strongly-typed metadata records](https://kelvin13.github.io/swift-png/PNG/Metadata/).

- ***Modern error handling.*** *Swift PNG* has a fully stateless and Swift-native [error-handling system](https://kelvin13.github.io/swift-png/PNG/Error/).

## infrastructure 

A list of build flags can be found [here](build.md). Project automation scripts live in the [`utils/`](utils/) directory, and are invoked as follows:

- [**`utils/examples`**](utils/examples) `[-c/--configuration debug | release]`

    Builds and runs the example programs in the [`examples/`](examples/) directory. The `--configuration` argument specifies the Swift build mode to use.

- [**`utils/benchmark`**](utils/benchmark) `[-t/--trials n0 n1 n2]` `[-s/--save]` `[-l/--load]`

    Runs library performance and compression benchmarks, and generates a [performance report](benchmarks/).
    
    The `--trials` argument specifies the number of trials to run, for decompression, compression, and historical toolchain benchmarks, respectively. The `--save` argument makes this script store benchmark measurements in cache files; the `--load` argument makes this script use cached measurements instead of re-running the benchmarks.

- [**`utils/generate-documentation`**](utils/generate-documentation) `[-l/--local]`

    Generates documentation pages for the library using [*Entrapta*](https://github.com/kelvin13/entrapta). A [Github action](.github/workflows/docs.yml) invokes this script and deploys the output to the [*Swift PNG* API reference website](https://kelvin13.github.io/swift-png) on every commit.

The CI [runs](.github/workflows/ci.yml) *Swift PNG*’s test suites with the following invocations:

```bash 
swift run            unit-test 
swift run -c release integration-test --compact
swift run -c release compression-test 
```

The `integration-test` product accepts a `-c/--compact` option, which specifies the output verbosity, and an `-e/--print-expected-failures` option, which makes it print the error messages for expected failures.

## see also 

* [Swift *JPEG*](https://github.com/kelvin13/jpeg)
