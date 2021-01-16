## library build flags

*Swift PNG* is designed to work out-of-the-box, and should not require any build customization. All build flags listed here are for debugging and performance evaluation purposes only, and may change without warning.

Pass build flags by appending an `Xswiftc` argument to your SPM build invocation. Each flag requires its own `Xswiftc` prefix. 



### `NO_INTRINSICS`

```bash 
swift build -Xswiftc -DNO_INTRINSICS
```

Disables the use of all hardware-specific CPU intrinsics. All vector operations will fall back to platform-independent implementations which use Swift’s standard library `SIMD` APIs.

Building with this flag will make *Swift PNG* encoding slower on `x86_64` platforms. It should not affect decoding, or any non-`x86_64` builds. 

Passing this flag is **not necessary** to compile *Swift PNG* on non-intel platforms. It only prevents the compiler from making intel-specific SIMD optimizations if it already knows that it is building for an `x86_64` target.

### `WARN_COPY_ON_WRITE`

```bash 
swift build -Xswiftc -DWARN_COPY_ON_WRITE
```

Makes *Swift PNG* emit a warning each time one of its internal buffers is copied to preserve the value-semantics of its encoding and decoding structures. This compilation mode is useful for debugging ownership issues in the client application which may be harming *Swift PNG* performance.

### `INTERNAL_BENCHMARKS`

```bash 
swift build -Xswiftc -DINTERNAL_BENCHMARKS
```

Builds *Swift PNG* with a copy of the library benchmark functions inside the `PNG` module, which is useful for measuring module boundary overhead. This flag only has an effect when building on MacOS and Linux.


### `DUMP_FILTERED_SCANLINES`

```bash 
swift build -Xswiftc -DDUMP_FILTERED_SCANLINES
```

Makes the decoder print out each image scanline before defiltering.

### `DUMP_LZ77_TERMS`

```bash 
swift build -Xswiftc -DDUMP_LZ77_TERMS
```

Makes the decoder print out each *DEFLATE* term (either a literal value or a string reference) as it decompresses the *DEFLATE* stream within a PNG file.

### `DUMP_LZ77_BLOCKS`

```bash 
swift build -Xswiftc -DDUMP_LZ77_BLOCKS
```

Makes the decoder print out information about each *DEFLATE* block, and aggregate statistics for the entire *DEFLATE* stream, including: 

* the average entropy-coding efficiency of the literal terms in the stream,
* a histogram of composite lengths of the string reference terms in the stream, and 
* a two-dimensional histogram of the run length decades and distance decades of the string reference terms in the stream.

The histogram may not be readable if your terminal does not support advanced terminal colors.

### `DUMP_LZ77_SYMBOL_HISTOGRAM`

```bash 
swift build -Xswiftc -DDUMP_LZ77_SYMBOL_HISTOGRAM
```

The same as `DUMP_LZ77_BLOCKS`, except it only prints out the two-dimensional symbol histogram. The histograms look like this:

![example histogram](notes/sample-histogram.png)

The *x*-axis is binned by **run-length decade**. Decade zero corresponds to a match length of 3 bytes. Decade 28 corresponds to a match length of 258 bytes. 

The *y*-axis is binned by **distance decade**. Decade zero corresponds to an offset of 1 byte. Decade 29 corresponds to an offset of anywhere from 24,577 to 32,768 bytes, refined by extra bits. You can find the full table of run-length and distance decades on page 12 of the [rfc-1951](https://tools.ietf.org/html/rfc1951).

The symbol histograms are a useful visual indicator for how a particular LZ77 implementation behaves, how well it is modeling its input, and how efficiently the phrases it emits will be compressed by the huffman coder.
