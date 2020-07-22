# improving deflate compression ratios

Version 4 of Swift *PNG* features a native Swift implementation of the *DEFLATE* and *INFLATE* algorithms, as described in the [rfc-1951](https://tools.ietf.org/html/rfc1951). *DEFLATE* implementations can vary widely in quality, with some implementations producing far better-optimized (higher compression ratio) output streams than others. So, just as it is important to ensure Swift *PNG*’s *INFLATE* procedure [is as fast as that of the *zlib* C library](../low-level-swift-optimization.md), it is also important to ensure Swift *PNG*’s *DEFLATE* output is as optimal as *zlib*’s. This readme documents some comparisons between Swift *PNG* and *libpng*/*zlib*, as well as choices of compression parameters in the framework at the time of writing.

## i. methodology 

### i.i. test images 

All of Swift *PNG*’s compression benchmarks run on the following 28 test images. I chose them depicting essentially the same subject, in photographic and non-photographic forms, and in different PNG color formats to be representative of how PNGs are used in the real world. Because casual PNG users do stupid things (from the perspective of 𝒸𝑜𝓂𝓅𝓇𝑒𝓈𝓈𝒾𝑜𝓃 𝑒𝓃𝑔𝒾𝓃𝑒𝑒𝓇𝓈, who \~never\~ do stupid things) such as save a monochrome image in RGB(A) format, the test suite includes representation for those use cases as well. None of the images have transparent alpha, as PNG images with varying alpha are rare. (Most transparent PNGs such as logos, test overlays, etc., have alpha that comes in regions of either full or zero opacity, which has the same compression characteristics as fully opaque alpha.)

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

I based this implementation on the recommendations of the original PNG and *DEFLATE* specifications. For filter selection, it uses a heuristic that minimizes the **sum of absolute values** of the filtered scanline. It performs non-greedy LZ77 compression with a backtracking limit of 1 byte. (LZ77 dictionaries have the [*suffix property*](https://scholar.acadiau.ca/islandora/object/theses:625), so you only need to backtrack once to get optimal output.) For entropic partitioning, it emits *DEFLATE* blocks at fixed intervals of 32K *DEFLATE* terms each.

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

Most of the test images compress slightly worse than the baseline. (It would be very weird if a naïve implementation produced *better* output than the baseline.) A few of them — namely the indexed images and some of the monochrome images that were saved in an RGB or RGBA format — compress significantly better than the baseline. We’ll see later why that happened.

## iii. improvement: better filter heuristics 

The filter selection heuristic is the only part of the compression pipeline that is under the control of the PNG codec if it does not also implement its own *DEFLATE*. So it’s a common starting point for improving PNG compression. 

### iii.i. minimum intervals

Versions 2 through 3.02 of Swift *PNG* used a heuristic called the **minimum intervals** selector. It minimizes the number of byte changes in the filtered scanline, so it prefers data that looks like `[5, 5, 5, 5, 5, 5, 6, 6, 6, 6]`, whereas the absolute values selector would prefer data that looks like `[0, 1, 0, 1, 0, 1, 1, 0, 1, 0]`. It’s not really an improvement over the absolute values selector, but for reference, the benchmark results for this filter selector are given below (in the collapsible section):

<details>
<summary><em>Click to expand</em></summary>
  
| Filter selection | LZ77 algorithm | LZ77 matches | Entropic partitioning |
| --------- | -------------- | ------- | ----- |
| Intervals | Non-greedy | All allowed | Fixed-length blocks |

| Image                                 | Baseline      | Swift *PNG*   | Ratio      |
| ------------------------------------- | ------------- | ------------- | ---------- |
| `v8-monochrome-photographic`          | 58.3428 KB    | 74.3691 KB    | **1.2747** |
| `v8-monochrome-nonphotographic`       | 47.0615 KB    | 63.5762 KB    | **1.3509** |
| `v16-monochrome-photographic`         | 172.1055 KB   | 172.8584 KB   | **1.0044** |
| `v16-monochrome-nonphotographic`      | 120.4795 KB   | 121.7344 KB   | **1.0104** |
|   |   |   |   |
| `va8-monochrome-photographic`         | 74.4922 KB    | 76.9248 KB    | **1.0327** |
| `va8-monochrome-nonphotographic`      | 59.0605 KB    | 61.3496 KB    | **1.0388** |
| `va16-monochrome-photographic`        | 204.9824 KB   | 223.3369 KB   | **1.0895** |
| `va16-monochrome-nonphotographic`     | 140.5615 KB   | 147.2939 KB   | **1.0479** |
|   |   |   |   |
| `indexed8-monochrome-photographic`    | 80.0918 KB    | 75.0986 KB    | **0.9377** |
| `indexed8-color-photographic`         | 63.9521 KB    | 66.5498 KB    | **1.0406** |
| `indexed8-monochrome-nonphotographic` | 61.4141 KB    | 62.6807 KB    | **1.0206** |
| `indexed8-color-nonphotographic`      | 42.4766 KB    | 45.5898 KB    | **1.0733** |
|   |   |   |   |
| `rgb8-monochrome-photographic`        | 89.8662 KB    | 119.0811 KB   | **1.3251** |
| `rgb8-color-photographic`             | 170.2129 KB   | 185.5430 KB   | **1.0901** |
| `rgb8-monochrome-nonphotographic`     | 74.8398 KB    | 96.4775 KB    | **1.2891** |
| `rgb8-color-nonphotographic`          | 127.5342 KB   | 145.6641 KB   | **1.1422** |
| `rgb16-monochrome-photographic`       | 370.2275 KB   | 228.5674 KB   | **0.6174** |
| `rgb16-color-photographic`            | 466.5859 KB   | 451.0078 KB   | **0.9666** |
| `rgb16-monochrome-nonphotographic`    | 238.3564 KB   | 160.9482 KB   | **0.6752** |
| `rgb16-color-nonphotographic`         | 356.6924 KB   | 360.0156 KB   | **1.0093** |
|   |   |   |   |
| `rgba8-monochrome-photographic`       | 99.1416 KB    | 87.2051 KB    | **0.8796** |
| `rgba8-color-photographic`            | 191.9307 KB   | 209.5791 KB   | **1.0920** |
| `rgba8-monochrome-nonphotographic`    | 82.1270 KB    | 70.7471 KB    | **0.8614** |
| `rgba8-color-nonphotographic`         | 143.5771 KB   | 160.1768 KB   | **1.1156** |
| `rgba16-monochrome-photographic`      | 404.8105 KB   | 318.9385 KB   | **0.7879** |
| `rgba16-color-photographic`           | 506.2188 KB   | 506.1338 KB   | **0.9998** |
| `rgba16-monochrome-nonphotographic`   | 140.5615 KB   | 147.2939 KB   | **1.0479** |
| `rgba16-color-nonphotographic`        | 385.2471 KB   | 399.4443 KB   | **1.0369** |

</details>

### iii.ii. squared frequencies

One alternative filter heuristic does seem to be an improvement over the absolute values selector: the **squared frequencies** selector. The squared frequencies selector maximizes the sum of the squared frequencies of each byte value (256 in total) in the filtered data. So it prefers data that looks like `[5, 6, 5, 5, 6, 5, 6, 6, 5, 6]` over data that looks like `[0, 0, 0, 1, 1, 1, 2, 2, 2, 2]`. (Which the previous two heuristics would prefer.)

The squared frequencies selector works by reducing the entropy of the filtered data, making its huffman encoding more efficient. For most input images, it has little to no impact, but it noticably improves the worst-case compression compared to the absolute values selector.

| Filter selection | LZ77 algorithm | LZ77 matches | Entropic partitioning |
| --------- | -------------- | ------- | ----- |
| Squared frequencies | Non-greedy | All allowed | Fixed-length blocks |

| Image                                 | Baseline      | Swift *PNG*   | Ratio      |
| ------------------------------------- | ------------- | ------------- | ---------- |
| `v8-monochrome-photographic`          | 58.3428 KB    | 67.9697 KB    | **1.1650** |
| `v8-monochrome-nonphotographic`       | 47.0615 KB    | 55.0615 KB    | **1.1700** |
| `v16-monochrome-photographic`         | 172.1055 KB   | 173.8086 KB   | **1.0099** |
| `v16-monochrome-nonphotographic`      | 120.4795 KB   | 123.3574 KB   | **1.0239** |
|   |   |   |   |
| `va8-monochrome-photographic`         | 74.4922 KB    | 76.7412 KB    | **1.0302** |
| `va8-monochrome-nonphotographic`      | 59.0605 KB    | 61.2178 KB    | **1.0365** |
| `va16-monochrome-photographic`        | 204.9824 KB   | 224.8350 KB   | **1.0968** |
| `va16-monochrome-nonphotographic`     | 140.5615 KB   | 150.3066 KB   | **1.0693** |
|   |   |   |   |
| `indexed8-monochrome-photographic`    | 80.0918 KB    | 68.7061 KB    | **0.8578** |
| `indexed8-color-photographic`         | 63.9521 KB    | 67.9199 KB    | **1.0620** |
| `indexed8-monochrome-nonphotographic` | 61.4141 KB    | 53.4941 KB    | **0.8710** |
| `indexed8-color-nonphotographic`      | 42.4766 KB    | 49.1191 KB    | **1.1564** |
|   |   |   |   |
| `rgb8-monochrome-photographic`        | 89.8662 KB    | 112.1992 KB   | **1.2485** |
| `rgb8-color-photographic`             | 170.2129 KB   | 188.2383 KB   | **1.1059** |
| `rgb8-monochrome-nonphotographic`     | 74.8398 KB    | 85.9590 KB    | **1.1486** |
| `rgb8-color-nonphotographic`          | 127.5342 KB   | 144.8555 KB   | **1.1358** |
| `rgb16-monochrome-photographic`       | 370.2275 KB   | 231.5352 KB   | **0.6254** |
| `rgb16-color-photographic`            | 466.5859 KB   | 463.0098 KB   | **0.9923** |
| `rgb16-monochrome-nonphotographic`    | 238.3564 KB   | 166.0303 KB   | **0.6966** |
| `rgb16-color-nonphotographic`         | 356.6924 KB   | 362.9736 KB   | **1.0176** |
|   |   |   |   |
| `rgba8-monochrome-photographic`       | 99.1416 KB    | 86.8799 KB    | **0.8763** |
| `rgba8-color-photographic`            | 191.9307 KB   | 212.1475 KB   | **1.1053** |
| `rgba8-monochrome-nonphotographic`    | 82.1270 KB    | 70.4961 KB    | **0.8584** |
| `rgba8-color-nonphotographic`         | 143.5771 KB   | 159.9473 KB   | **1.1140** |
| `rgba16-monochrome-photographic`      | 404.8105 KB   | 322.1221 KB   | **0.7957** |
| `rgba16-color-photographic`           | 506.2188 KB   | 517.6357 KB   | **1.0226** |
| `rgba16-monochrome-nonphotographic`   | 140.5615 KB   | 150.3066 KB   | **1.0693** |
| `rgba16-color-nonphotographic`        | 385.2471 KB   | 403.0332 KB   | **1.0462** |

## iv. improvement: better LZ77 matching 

### iv.i. match thresholds 

Many of the test images are still compressing 5 to 15 percent worse than the baseline. When examining the symbol histograms of the original and recompressed images, we can see that the string matches Swift *PNG* is emitting are very different from the matches that *zlib* is emitting.

In the screenshot below, the upper histogram is from one of the original test images (`rgb8-color-nonphotographic`), and the lower histogram is from the recompressed version.

<p align="center">
<img src="../tests/compression/baseline/rgb8-color-nonphotographic.png"/>
</p>

![Comparison of string match frequencies for the original and recompressed versions of one of the test images](histogram-iv-1.png)

> Symbol histogram for the test image `rgb8-color-nonphotographic.png` when compressed with *libpng*/*zlib* (top) and Swift *PNG* (bottom).

We can see that Swift *PNG* is finding many more matches than *zlib* is, but most of these matches are short matches located at distant offsets. These matches are relatively expensive to encode, and are raising the overall entropy of the *DEFLATE* stream, so they are not really helping to compress the image.

*zlib* on the other hand is discarding all matches of length less than 6. (Decade 3 corresponds to a length of 6, so all the previous columns are empty.) This is because *libpng* has *zlib* configured to use the [`Z_FILTERED`](http://www.zlib.net/manual.html) search strategy, which only accepts matches of length 6.

Getting Swift *PNG* to impose this condition improves the compression for almost all the test images to the point where they compress about as well as they do under *libpng*/*zlib*.

| Filter selection | LZ77 algorithm | LZ77 matches | Entropic partitioning |
| --------- | -------------- | ------- | ----- |
| Squared frequencies | Non-greedy | Fixed threshold | Fixed-length blocks |

| Image                                 | Baseline      | Swift *PNG*   | Ratio      |
| ------------------------------------- | ------------- | ------------- | ---------- |
| `v8-monochrome-photographic`          | 58.3428 KB    | 59.7842 KB    | **1.0247** |
| `v8-monochrome-nonphotographic`       | 47.0615 KB    | 48.2822 KB    | **1.0259** |
| `v16-monochrome-photographic`         | 172.1055 KB   | 171.0078 KB   | **0.9936** |
| `v16-monochrome-nonphotographic`      | 120.4795 KB   | 120.5137 KB   | **1.0003** |
|   |   |   |   |
| `va8-monochrome-photographic`         | 74.4922 KB    | 75.8877 KB    | **1.0187** |
| `va8-monochrome-nonphotographic`      | 59.0605 KB    | 59.7227 KB    | **1.0112** |
| `va16-monochrome-photographic`        | 204.9824 KB   | 205.2910 KB   | **1.0015** |
| `va16-monochrome-nonphotographic`     | 140.5615 KB   | 140.8359 KB   | **1.0020** |
|   |   |   |   |
| `indexed8-monochrome-photographic`    | 80.0918 KB    | 60.5088 KB    | **0.7555** |
| `indexed8-color-photographic`         | 63.9521 KB    | 61.3555 KB    | **0.9594** |
| `indexed8-monochrome-nonphotographic` | 61.4141 KB    | 47.1191 KB    | **0.7672** |
| `indexed8-color-nonphotographic`      | 42.4766 KB    | 45.3438 KB    | **1.0675** |
|   |   |   |   |
| `rgb8-monochrome-photographic`        | 89.8662 KB    | 101.9668 KB   | **1.1347** |
| `rgb8-color-photographic`             | 170.2129 KB   | 175.3096 KB   | **1.0299** |
| `rgb8-monochrome-nonphotographic`     | 74.8398 KB    | 84.8887 KB    | **1.1343** |
| `rgb8-color-nonphotographic`          | 127.5342 KB   | 132.3105 KB   | **1.0375** |
| `rgb16-monochrome-photographic`       | 370.2275 KB   | 350.9502 KB   | **0.9479** |
| `rgb16-color-photographic`            | 466.5859 KB   | 465.6855 KB   | **0.9981** |
| `rgb16-monochrome-nonphotographic`    | 238.3564 KB   | 234.2822 KB   | **0.9829** |
| `rgb16-color-nonphotographic`         | 356.6924 KB   | 357.7402 KB   | **1.0029** |
|   |   |   |   |
| `rgba8-monochrome-photographic`       | 99.1416 KB    | 101.3145 KB   | **1.0219** |
| `rgba8-color-photographic`            | 191.9307 KB   | 200.4219 KB   | **1.0442** |
| `rgba8-monochrome-nonphotographic`    | 82.1270 KB    | 81.9160 KB    | **0.9974** |
| `rgba8-color-nonphotographic`         | 143.5771 KB   | 149.3398 KB   | **1.0401** |
| `rgba16-monochrome-photographic`      | 404.8105 KB   | 399.9043 KB   | **0.9879** |
| `rgba16-color-photographic`           | 506.2188 KB   | 504.9336 KB   | **0.9975** |
| `rgba16-monochrome-nonphotographic`   | 140.5615 KB   | 140.8359 KB   | **1.0020** |
| `rgba16-color-nonphotographic`        | 385.2471 KB   | 387.3760 KB   | **1.0055** |

### iv.ii. internal matches

While most of the worst-case inputs have converged towards a ratio of 1.0, so have some of the best-case inputs. Notably, the monochrome RGB and RGBA images (some of which were previously outperforming the baseline by over 38 percent!) are now compressing about the same as the baseline. This is because certain monochrome RGB and RGBA byte patterns tend to produce lots of highly-efficient matches that get discarded by the match threshold. Many of these are **internal matches** (matches with a distance less than 3), which are very efficient to encode.

| Color format | Compression pattern |
| ------------ | ------------------- |
| RGB16  | `(A B) (A B) (A B)       → (A) (B) match(offset: -2, count: 4)` |
| RGBA16 | `(A B) (A B) (A B) (C C) → (A) (B) match(offset: -2, count: 4) (C) (C)` |

If we look at the histograms for the monochrome RGB16 images, we can see that there are a vast number of matches of length 4 and distance 2, especially compared to the adjacent cells. Because these matches are all concentrated in a single bin, they are cheap to encode, but the match threshold condition, not knowing any better, is discarding them all.

![Comparison of string match frequencies for the original and recompressed versions a monochrome RGB16 image](histogram-iv-2.png)

> Symbol histograms for the test image `rgb16-monochrome-photographic.png`, compressed using *libpng*/*zlib* (top), and Swift *PNG* with the match length threshold turned off (bottom). The bin for decade (1, 1) in the second histogram has overflowed, so it is displaying “9999”. The second compressed image is less than two-thirds the size of the first image!
>
> A similar effect happens in the monochrome RGBA16 images, but it is far less pronounced.

### iv.iii. harmonic matches 

A similar but unrelated phenomenon called **harmonic matching** takes place when compressing RGB and RGBA images, as well as some VA images. While internal matches are references to a sequence within the same logical pixel, harmonic matches are references to entire, preceeding pixels.

Harmonic matches occur because PNG filters have a set [delay](http://www.libpng.org/pub/png/spec/1.2/PNG-Filters.html) determined by the logical stride of the image pixels. For an 8-bit RGB image, this delay is three bytes long. For a 16-bit RGBA image, the filter delay is eight bytes long, and so forth. This filter delay tends to create repetitions in the filtered data at integer multiples of the delay length. We can think of this length as the natural wavelength of the PNG image, which creates clusters of matches at certain lengths and offsets. 

| Color format  | Wavelength    | Length decades        | Distance decades  |
| ------------- | ------------- | --------------------- | ----------------- |
| V16           | 2 B           | —                     | 1, 3, 4, 5, …     |
| VA8           | 2 B           | —                     | 1, 3, 4, 5, …     |
| VA16          | 4 B           | 1, 5, 8, 10, 12, …    | 3, 5, 6, 7, 8<sup>†</sup>, … |
| RGB8          | 3 B           | 0, 3, 6, 8, 10, …     | 2, 4, 6<sup>†</sup>, 8<sup>†</sup>, … |
| RGB16         | 6 B           | 3, 8, 11, 13, 14, …   | 4, 6, 8, 10<sup>†</sup>, … |
| RGBA8         | 4 B           | 1, 5, 8, 10, 12, …    | 3, 5, 6, 7, 8<sup>†</sup>, … |
| RGBA16        | 8 B           | 5, 10, 13, 15, …      | 5, 7, 8, 9, 10<sup>†</sup>, … |

> † Additional decades from signal aliasing.

We can observe these spectral patterns in the symbol histograms. For example, we can see in the histograms from the last subsection that the column for length decade 3 contains many more matches than either of the adjacent columns. It is no coincidence that length decade 3 corresponds to a match length of 6 bytes, which is the natural wavelength of a 16-bit RGB image. In fact, we can observe secondary peaks in the columns for length decades 8, 11, and 13. These decades contain matches of length 12, 18, and 24, respectively, all of which are integer multiples of 6. Harmonic banding also happens along the vertical (match offset) axis — we can observe a disproportionately high match density in rows 4, 6, and 8, which correspond to offsets of 6, 12, and 18 and 24 (both in decade 8). [Signal aliasing](https://en.wikipedia.org/wiki/Aliasing) creates additional striations in distance decades 10, 12, 14, 16, and so forth.

The following symbol histogram contains an very pronounced example of harmonic banding. It was created from an 8-bit RGBA image, which has a natural wavelength of four bytes. The striations gradually blend together in the higher length decades (horizontal axis) because they encode increasingly larger ranges of length values. The same effect happens in the higher distance decades (vertical axis), but here, the 1-byte staggering from the filter code at the beginning of each scanline also contributes to spectral broadening.

![Symbol histogram containing highly visible harmonic bands](histogram-iv-3.png)

> A symbol histogram from the test image `rgba8-monochrome-nonphotographic.png`, compressed by Swift *PNG*, with match thresholding turned off. The histogram from the same image compressed with *libpng*/*zlib* does not contain the same striations, which is why the Swift *PNG* version is so much smaller (ratio = 0.8584).

Harmonic matches are easiest to see in monochrome RGB/RGBA images, but they also occur in full-color images. Match lengths generally don’t fall on integer multiples of the image wavelength, since full-color images lack the repeated samples that monochrome images have, but match offsets still tend towards those frequencies, since PNG scanline filtering is still reducing the entropy in those frequencies.

![Symbol histogram containing less-visible harmonic bands](histogram-iv-4.png)

> A symbol histogram from the test image `rgb8-color-nonphotographic.png`, compressed by Swift *PNG*, with match thresholding turned off. It has visible harmonic banding in the vertical (distance) direction, but not the horizontal (length) direction.

## *further reading* 

1. [PNG tech](http://optipng.sourceforge.net/pngtech/)
2. [The Effect of Non-Greedy Parsingin Ziv-Lempel Compression Methods](https://webhome.cs.uvic.ca/~nigelh/Publications/LZ-non-greedy.pdf)
3. [Non-greedy Lempel-Ziv Data Compression](https://scholar.acadiau.ca/islandora/object/theses:625)
4. [Understanding *zlib*](https://www.euccas.me/zlib/)
5. [Data Compression Explained](http://mattmahoney.net/dc/dce.html)
6. [*zlib* Compressed Data Format Specification version 3.3](https://tools.ietf.org/html/rfc1950)
6. [*DEFLATE* Compressed Data Format Specification version 1.3](https://tools.ietf.org/html/rfc1951)
