# improving *deflate* compression speed

*see also:* [*low level swift optimization techniques*](low-level-swift-optimization.md)

*see also:* [*improving *deflate* compression ratio*](improving-deflate-compression-ratio.md)

As documented in the [last article](improving-deflate-compression-ratio.md), version 4 of Swift *PNG* features a pure-Swift *DEFLATE* encoder capable of achieving the same compression ratio as *libpng*/*zlib* can. However, encoder speed is also an important aspect of a PNG codec. This readme documents some comparisons between Swift *PNG* and *libpng*/*zlib*, and some techniques I used to close the performance gap between the two.

## i. methodology

### i.i test images 

All speed benchmarks run on the same set of 28 test images as the compression benchmarks do. You can read more about the test suite in the [methodology section](improving-deflate-compression-ratio.md#i-methodology) of the last article.

### i.ii benchmarks 

To benchmark compression, it was enough to compare Swift *PNG* outputs to previously saved PNG files created with a third-party application like [GIMP](https://www.gimp.org/). Benchmarking speed this way would not be fair to *libpng*/*zlib*, because external measurements would include overhead from the client application itself. To avoid this, the speed benchmarks contain a basic C program which invokes *libpng* directly. This C program lives in [`benchmarks/encode/baseline/`](../benchmarks/encode/baseline). A script, [`utils/benchmark-compression`](../utils/benchmark-compression), builds it using `clang` with the following invocation:

```bash 
clang -lpng ${prefix}/main.c -o ${binary}
```

The same script also builds an equivalent Swift program in [`benchmarks/encode/swift/`](../benchmarks/encode/swift) using the Swift Package Manager. The Swift program, of course, invokes Swift *PNG* instead of *libpng*.

Disk latency contributes a noticeable (but not overwhelming) proportion of the time needed to encode a PNG file, especially at low compression levels. To avoid this problem, the C and Swift benchmarks both have their respective backends configured to write output images to memory instead of the file system. For *libpng*, you can do this by creating a custom buffer context and passing a callback function to `png_set_write_fn(_:_:_:_:)`. For Swift *PNG*, you can do this statically by conforming a buffer type of your choice to the `PNG.Bytestream.Destination` protocol.

The memory target for the baseline C program is a `malloc`-based vector which uses the following reallocation rule:

&emsp; capacity(*n*) = 3 *n* / 2 + 16 .

The memory target for the Swift program is a normal `[UInt8]` Swift array, which uses whatever reallocation rule the current version of the standard library has defined.
