# improving deflate compression ratios

Version 4 of Swift *PNG* features a native Swift implementation of the *DEFLATE* and *INFLATE* algorithms, as described in the [rfc-1951](https://tools.ietf.org/html/rfc1951). *DEFLATE* implementations can vary widely in quality, with some implementations producing far better-optimized (higher compression ratio) output streams than others. So, just as it is important to ensure Swift *PNG*’s *INFLATE* procedure [is as fast as that of the *zlib* C library](../low-level-swift-optimization.md), it is also important to ensure Swift *PNG*’s *DEFLATE* output is as optimal as *zlib*’s. This readme documents some comparisons between Swift *PNG* and *libpng*/*zlib*, as well as choices of compression parameters in the framework at the time of writing.

## i. methodology 

### i.i. test images 

All of Swift *PNG*’s compression benchmarks run on the following 28 test images. I chose them depicting essentially the same subject, in photographic and non-photographic forms, and in different PNG color formats to be representative of how PNGs are used in the real world. Because casual PNG users do stupid things (from the perspective of 𝒸𝑜𝓂𝓅𝓇𝑒𝓈𝓈𝒾𝑜𝓃 𝑒𝓃𝑔𝒾𝓃𝑒𝑒𝓇𝓈, who ~never~ do stupid things) such as save a monochrome image in RGB(A) format, the test suite includes representation for those use cases as well. None of the images have transparent alpha, as PNG images with varying alpha are rare. (Most transparent PNGs such as logos, test overlays, etc., have alpha that comes in regions of either full or zero opacity, which has the same compression characteristics as fully opaque alpha.)

All baseline images were saved in [GIMP 2.10](https://www.gimp.org/) at the maximum compression setting (*zlib* mode 9), with no interlacing and no ancillary chunks.

| Test image | Color format | Size |
| ---------- | ------------ | ---- |
| `v8-monochrome-photographic.png`          <br/> <img src="../tests/compression/baseline/v8-monochrome-photographic.png"/>             | `v8`       |  59,743 B | 
| `v8-monochrome-nonphotographic.png`       <br/> <img src="../tests/compression/baseline/v8-monochrome-nonphotographic.png"/>          | `v8`       |  48,191 B | 
| `v16-monochrome-photographic.png`         <br/> <img src="../tests/compression/baseline/v16-monochrome-photographic.png"/>            | `v16`      | 176,236 B | 
| `v16-monochrome-nonphotographic.png`      <br/> <img src="../tests/compression/baseline/v16-monochrome-nonphotographic.png"/>         | `v16`      | 123,371 B | 
|   |   |   |
| `va8-monochrome-photographic.png`         <br/> <img src="../tests/compression/baseline/va8-monochrome-photographic.png"/>            | `va8`      |  76,280 B | 
| `va8-monochrome-nonphotographic.png`      <br/> <img src="../tests/compression/baseline/va8-monochrome-nonphotographic.png"/>         | `va8`      |  60,478 B | 
| `va16-monochrome-photographic.png`        <br/> <img src="../tests/compression/baseline/va16-monochrome-photographic.png"/>           | `va16`     | 209,902 B | 
| `va16-monochrome-nonphotographic.png`     <br/> <img src="../tests/compression/baseline/va16-monochrome-nonphotographic.png"/>        | `va16`     | 143,935 B | 
|   |   |   |
| `indexed8-monochrome-photographic.png`    <br/> <img src="../tests/compression/baseline/indexed8-monochrome-photographic.png"/>       | `indexed8` |  82,014 B | 
| `indexed8-color-photographic.png`         <br/> <img src="../tests/compression/baseline/indexed8-color-photographic.png"/>            | `indexed8` |  65,487 B | 
| `indexed8-monochrome-nonphotographic.png` <br/> <img src="../tests/compression/baseline/indexed8-monochrome-nonphotographic.png"/>    | `indexed8` |  62,888 B | 
| `indexed8-color-nonphotographic.png`      <br/> <img src="../tests/compression/baseline/indexed8-color-nonphotographic.png"/>         | `indexed8` |  43,496 B | 
|   |   |   |
| `rgb8-monochrome-photographic.png`        <br/> <img src="../tests/compression/baseline/rgb8-monochrome-photographic.png"/>           | `rgb8`     |  92,023 B | 
| `rgb8-color-photographic.png`             <br/> <img src="../tests/compression/baseline/rgb8-color-photographic.png"/>                | `rgb8`     | 174,298 B | 
| `rgb8-monochrome-nonphotographic.png`     <br/> <img src="../tests/compression/baseline/rgb8-monochrome-nonphotographic.png"/>        | `rgb8`     |  76,636 B | 
| `rgb8-color-nonphotographic.png`          <br/> <img src="../tests/compression/baseline/rgb8-color-nonphotographic.png"/>             | `rgb8`     | 130,595 B | 
| `rgb16-monochrome-photographic.png`       <br/> <img src="../tests/compression/baseline/rgb16-monochrome-photographic.png"/>          | `rgb16`    | 379,113 B | 
| `rgb16-color-photographic.png`            <br/> <img src="../tests/compression/baseline/rgb16-color-photographic.png"/>               | `rgb16`    | 477,784 B | 
| `rgb16-monochrome-nonphotographic.png`    <br/> <img src="../tests/compression/baseline/rgb16-monochrome-nonphotographic.png"/>       | `rgb16`    | 244,077 B | 
| `rgb16-color-nonphotographic.png`         <br/> <img src="../tests/compression/baseline/rgb16-color-nonphotographic.png"/>            | `rgb16`    | 365,253 B | 
|   |   |   |
| `rgba8-monochrome-photographic.png`       <br/> <img src="../tests/compression/baseline/rgba8-monochrome-photographic.png"/>          | `rgba8`    | 101,521 B | 
| `rgba8-color-photographic.png`            <br/> <img src="../tests/compression/baseline/rgba8-color-photographic.png"/>               | `rgba8`    | 196,537 B | 
| `rgba8-monochrome-nonphotographic.png`    <br/> <img src="../tests/compression/baseline/rgba8-monochrome-nonphotographic.png"/>       | `rgba8`    |  84,098 B | 
| `rgba8-color-nonphotographic.png`         <br/> <img src="../tests/compression/baseline/rgba8-color-nonphotographic.png"/>            | `rgba8`    | 147,023 B | 
| `rgba16-monochrome-photographic.png`      <br/> <img src="../tests/compression/baseline/rgba16-monochrome-photographic.png"/>         | `rgba16`   | 414,526 B | 
| `rgba16-color-photographic.png`           <br/> <img src="../tests/compression/baseline/rgba16-color-photographic.png"/>              | `rgba16`   | 518,368 B | 
| `rgba16-monochrome-nonphotographic.png`   <br/> <img src="../tests/compression/baseline/rgba16-monochrome-nonphotographic.png"/>      | `rgba16`   | 143,935 B | 
| `rgba16-color-nonphotographic.png`        <br/> <img src="../tests/compression/baseline/rgba16-color-nonphotographic.png"/>           | `rgba16`   | 394,493 B | 

### i.ii. benchmarks

The compression benchmarks come in their own package target, `compression-test`. The repository’s [CI](https://github.com/kelvin13/png/actions?query=workflow%3Abuild) builds and runs them, though it doesn’t really care about the output. 

The `compression-test` product is most useful when Swift *PNG* is built with one of several inspection features enabled. To enable inspection, pass one of the following compiler build flags:

1. `DUMP_FILTERED_SCANLINES`
2. `DUMP_LZ77_TERMS`
3. `DUMP_LZ77_BLOCKS`
4. `DUMP_LZ77_SYMBOL_HISTOGRAM`

> To pass a build flag with the Swift Package Manager, use `-Xswiftc -D`. For example, to build with scanline dumping enabled, pass `-Xswiftc -DDUMP_FILTERED_SCANLINES` to the Swift compiler. 

#### `DUMP_FILTERED_SCANLINES`

Makes the decoder print out each image scanline before defiltering.

#### `DUMP_LZ77_TERMS`

Makes the decoder print out each *DEFLATE* term (either a literal value or a string reference) as it decompresses the *DEFLATE* stream.

#### `DUMP_LZ77_BLOCKS`

Makes the decoder print out information about each *DEFLATE* block, and aggregate statistics for the entire *DEFLATE* stream, including: 

* the average entropy-coding efficiency of the literal terms in the stream,
* a histogram of composite lengths of the string reference terms in the stream, and 
* a two-dimensional histogram of the run length decades and distance decades of the string reference terms in the stream.

It also makes the encoder print out its decision-making process when determining optimal *DEFLATE* block boundaries.

#### `DUMP_LZ77_SYMBOL_HISTOGRAM`

The same as `DUMP_LZ77_BLOCKS`, except it only prints out the two-dimensional symbol histogram. The histograms look like this:

![example histogram](sample-histogram.png)

The *x*-axis is binned by **run-length decade**. Decade zero corresponds to a match length of 3 bytes. Decade 28 corresponds to a match length of 258 bytes. 

The *y*-axis is binned by **distance decade**. Decade zero corresponds to an offset of 1 byte. Decade 29 corresponds to an offset of anywhere from 24,577 to 32,768 bytes, refined by extra bits.

> You can find the full table of run-length and distance decades on page 12 of the [rfc-1951](https://tools.ietf.org/html/rfc1951).

The symbol histograms are a useful visual indicator for how a particular LZ77 implementation behaves, how well it is modeling its input, and how efficiently the phrases it emits will be compressed by the huffman coder.

In general:

* More red/orange is better than less, because that means the run-length coder is collapsing many phrases. (As opposed to emitting literals.)

* The upper-right corner is good, because these correspond to long matches that take few bits to encode.

* The lower-left corner is bad, because these correspond to short matches that take many bits to encode.

* A few high-frequency bins are better than many low-frequency bins, because this reduces the entropy of the emitted terms, making the subsequent huffman coding more effective.

## ii. naïve implementation

I based this implementation on the recommendations of the original PNG and *DEFLATE* specifications. For filter selection, it uses a heuristic that minimizes the sum of absolute values of the filtered scanline. It performs non-greedy LZ77 compression with a backtracking limit of 1 byte. (LZ77 dictionaries have the [*suffix property*](https://scholar.acadiau.ca/islandora/object/theses:625), so you only need to backtrack once to get optimal output.) For entropic partitioning, it emits *DEFLATE* blocks at fixed intervals of 32K *DEFLATE* terms each.

To summarize:

| Filter selection | LZ77 algorithm | LZ77 matches | Entropic partitioning |
| --------- | -------------- | ------- | ----- |
| Absolute value | Non-greedy | All allowed | Fixed-length blocks |

The sizes of the Swift *PNG* output images under this implementation are given below, along with comparisons with the baseline *libpng*/*zlib* output. A ratio smaller than 1.0 means Swift *PNG* performed better than *libpng*/*zlib*, a ratio greater than 1.0 means Swift *PNG* performed worse.

| Image                                 | Baseline      | Swift *PNG*   | Ratio      |
| ------------------------------------- | ------------- | ------------- | ---------- |
| `v8-monochrome-photographic`          | 58.3428 KB    | 68.2217 KB    | **1.1693** |
| `v8-monochrome-nonphotographic`       | 47.0615 KB    | 60.6436 KB    | **1.2886** |
| `v16-monochrome-photographic`         | 172.1055 KB   | 175.9600 KB   | **1.0224** |
| `v16-monochrome-nonphotographic`      | 120.4795 KB   | 123.3584 KB   | **1.0239** |
|   |   |   |   |
| `va8-monochrome-photographic`         | 74.4922 KB    | 76.9102 KB    | **1.0325** |
| `va8-monochrome-nonphotographic`      | 59.0605 KB    | 62.2832 KB    | **1.0546** |
| `va16-monochrome-photographic`        | 204.9824 KB   | 228.5391 KB   | **1.1149** |
| `va16-monochrome-nonphotographic`     | 140.5615 KB   | 149.7783 KB   | **1.0656** |
|   |   |   |   |
| `indexed8-monochrome-photographic`    | 80.0918 KB    | 68.9570 KB    | **0.8610** |
| `indexed8-color-photographic`         | 63.9521 KB    | 68.6729 KB    | **1.0738** |
| `indexed8-monochrome-nonphotographic` | 61.4141 KB    | 59.5332 KB    | **0.9694** |
| `indexed8-color-nonphotographic`      | 42.4766 KB    | 49.7051 KB    | **1.1702** |
|   |   |   |   |
| `rgb8-monochrome-photographic`        | 89.8662 KB    | 112.9160 KB   | **1.2565** |
| `rgb8-color-photographic`             | 170.2129 KB   | 186.3906 KB   | **1.0950** |
| `rgb8-monochrome-nonphotographic`     | 74.8398 KB    | 93.4502 KB    | **1.2487** |
| `rgb8-color-nonphotographic`          | 127.5342 KB   | 178.3242 KB   | **1.3982** |
| `rgb16-monochrome-photographic`       | 370.2275 KB   | 233.2422 KB   | **0.6300** |
| `rgb16-color-photographic`            | 466.5859 KB   | 463.9150 KB   | **0.9943** |
| `rgb16-monochrome-nonphotographic`    | 238.3564 KB   | 164.1875 KB   | **0.6888** |
| `rgb16-color-nonphotographic`         | 356.6924 KB   | 359.4639 KB   | **1.0078** |
|   |   |   |   |
| `rgba8-monochrome-photographic`       | 99.1416 KB    | 87.1504 KB    | **0.8790** |
| `rgba8-color-photographic`            | 191.9307 KB   | 208.4258 KB   | **1.0859** |
| `rgba8-monochrome-nonphotographic`    | 82.1270 KB    | 72.5537 KB    | **0.8834** |
| `rgba8-color-nonphotographic`         | 143.5771 KB   | 162.5908 KB   | **1.1324** |
| `rgba16-monochrome-photographic`      | 404.8105 KB   | 329.2549 KB   | **0.8134** |
| `rgba16-color-photographic`           | 506.2188 KB   | 519.5957 KB   | **1.0264** |
| `rgba16-monochrome-nonphotographic`   | 140.5615 KB   | 149.7783 KB   | **1.0656** |
| `rgba16-color-nonphotographic`        | 385.2471 KB   | 401.6504 KB   | **1.0426** |

## *further reading* 

1. [PNG tech](http://optipng.sourceforge.net/pngtech/)
2. [The Effect of Non-Greedy Parsingin Ziv-Lempel Compression Methods](https://webhome.cs.uvic.ca/~nigelh/Publications/LZ-non-greedy.pdf)
3. [Non-greedy Lempel-Ziv Data Compression](https://scholar.acadiau.ca/islandora/object/theses:625)
4. [Understanding *zlib*](https://www.euccas.me/zlib/)
5. [Data Compression Explained](http://mattmahoney.net/dc/dce.html)
6. [*zlib* Compressed Data Format Specification version 3.3](https://tools.ietf.org/html/rfc1950)
6. [*DEFLATE* Compressed Data Format Specification version 1.3](https://tools.ietf.org/html/rfc1951)
