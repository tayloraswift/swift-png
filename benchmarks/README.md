# *swift png* benchmarks 

> generated on **January 15, 2021** for commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)** using **[`utils/benchmark`](../utils/benchmark)**

## running benchmarks 

*Swift PNG*’s benchmarks live in the `benchmarks` directory. They are divided into compression benchmarks ([`benchmarks/compression`](compression)) and decompression benchmarks ([`benchmarks/decompression`](decompression)). Each benchmark compares a *Swift PNG* test application to an equivalent *libpng*-based implementation. All performance benchmarks are *cold-start* measurements, meaning that the code sleeps for a fraction of a second before each trial run.

All benchmarks run on a test suite of **28** images. 

<details>
<summary><em>Click to show test image table</em></summary>

| Test image | Size |
| ---------- | ---- |
| `indexed8-color-nonphotographic` <br/> <img src="../tests/compression/baseline/indexed8-color-nonphotographic.png"/> | 43,496 B |
| `indexed8-color-photographic` <br/> <img src="../tests/compression/baseline/indexed8-color-photographic.png"/> | 65,487 B |
| `indexed8-monochrome-nonphotographic` <br/> <img src="../tests/compression/baseline/indexed8-monochrome-nonphotographic.png"/> | 62,888 B |
| `indexed8-monochrome-photographic` <br/> <img src="../tests/compression/baseline/indexed8-monochrome-photographic.png"/> | 82,014 B |
| `rgb16-color-nonphotographic` <br/> <img src="../tests/compression/baseline/rgb16-color-nonphotographic.png"/> | 365,253 B |
| `rgb16-color-photographic` <br/> <img src="../tests/compression/baseline/rgb16-color-photographic.png"/> | 477,784 B |
| `rgb16-monochrome-nonphotographic` <br/> <img src="../tests/compression/baseline/rgb16-monochrome-nonphotographic.png"/> | 244,077 B |
| `rgb16-monochrome-photographic` <br/> <img src="../tests/compression/baseline/rgb16-monochrome-photographic.png"/> | 379,113 B |
| `rgb8-color-nonphotographic` <br/> <img src="../tests/compression/baseline/rgb8-color-nonphotographic.png"/> | 130,595 B |
| `rgb8-color-photographic` <br/> <img src="../tests/compression/baseline/rgb8-color-photographic.png"/> | 174,298 B |
| `rgb8-monochrome-nonphotographic` <br/> <img src="../tests/compression/baseline/rgb8-monochrome-nonphotographic.png"/> | 76,636 B |
| `rgb8-monochrome-photographic` <br/> <img src="../tests/compression/baseline/rgb8-monochrome-photographic.png"/> | 92,023 B |
| `rgba16-color-nonphotographic` <br/> <img src="../tests/compression/baseline/rgba16-color-nonphotographic.png"/> | 394,493 B |
| `rgba16-color-photographic` <br/> <img src="../tests/compression/baseline/rgba16-color-photographic.png"/> | 518,368 B |
| `rgba16-monochrome-nonphotographic` <br/> <img src="../tests/compression/baseline/rgba16-monochrome-nonphotographic.png"/> | 143,935 B |
| `rgba16-monochrome-photographic` <br/> <img src="../tests/compression/baseline/rgba16-monochrome-photographic.png"/> | 414,526 B |
| `rgba8-color-nonphotographic` <br/> <img src="../tests/compression/baseline/rgba8-color-nonphotographic.png"/> | 147,023 B |
| `rgba8-color-photographic` <br/> <img src="../tests/compression/baseline/rgba8-color-photographic.png"/> | 196,537 B |
| `rgba8-monochrome-nonphotographic` <br/> <img src="../tests/compression/baseline/rgba8-monochrome-nonphotographic.png"/> | 84,098 B |
| `rgba8-monochrome-photographic` <br/> <img src="../tests/compression/baseline/rgba8-monochrome-photographic.png"/> | 101,521 B |
| `v16-monochrome-nonphotographic` <br/> <img src="../tests/compression/baseline/v16-monochrome-nonphotographic.png"/> | 123,371 B |
| `v16-monochrome-photographic` <br/> <img src="../tests/compression/baseline/v16-monochrome-photographic.png"/> | 176,236 B |
| `v8-monochrome-nonphotographic` <br/> <img src="../tests/compression/baseline/v8-monochrome-nonphotographic.png"/> | 48,191 B |
| `v8-monochrome-photographic` <br/> <img src="../tests/compression/baseline/v8-monochrome-photographic.png"/> | 59,743 B |
| `va16-monochrome-nonphotographic` <br/> <img src="../tests/compression/baseline/va16-monochrome-nonphotographic.png"/> | 143,935 B |
| `va16-monochrome-photographic` <br/> <img src="../tests/compression/baseline/va16-monochrome-photographic.png"/> | 209,902 B |
| `va8-monochrome-nonphotographic` <br/> <img src="../tests/compression/baseline/va8-monochrome-nonphotographic.png"/> | 60,478 B |
| `va8-monochrome-photographic` <br/> <img src="../tests/compression/baseline/va8-monochrome-photographic.png"/> | 76,280 B |

</details>

## results

### decoding 

The decompression benchmarks compare the performance of *Swift PNG* to that of *libpng* while decoding the **28** images in the library test suite. Run times are normalized according to the *median* runtime of the baseline (*libpng*) implementation *for each test image*. 

In the density plot below, the labeled curves represent the *aggregate distribution* of run times across all **28** test images. The unlabeled curves are the distributions for each individual test image. The dashed curve indicates the distribution for one of the 8-bit RGB test images (`rgb8-color-photographic`), one of the most common PNG image types.

![decompression performance](../benchmarks/results/decompression-speed.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s median decoding time was **135.26 percent** that of *libpng*. *Swift PNG*’s median decoding time for the `rgb8-color-photographic` test image was **142.2 percent** that of *libpng*.

### encoding (levels `0 ... 9`)

The compression benchmarks are similar to the decompression benchmarks except we measure ten of the library’s fourteen compression levels separately. The four highest *Swift PNG* compression levels have no *libpng* equivalent; size comparisons between their output and *libpng*’s output at its highest compression level can be found in the [next section](#encoding-levels-10--13).

Note that *Swift PNG* and *libpng* compression levels generally don’t correspond to one another. In particular, *Swift PNG*’s speed-vs-compression curve is “flatter” than *libpng*’s. This means *Swift PNG* performs more compression (using more resources) than *libpng* for the first few compression levels, and some of the higher compression levels as well. This is by design, because *libpng* has the undesirable property in that for many input images, its speed does not decrease monotonically as the compression parameter increases.

In the density plots below, the labeled curves represent the *aggregate distribution* of run times across all **28** test images. The unlabeled curves are the distributions for each individual test image. The dashed curve indicates the distribution for one of the 8-bit RGB test images (`rgb8-color-photographic`), one of the most common PNG image types.


#### compression level 0

![compression performance](../benchmarks/results/compression-speed@0.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s median encoding time at its 0th compression level was **308.85 percent** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **268.18 percent** that of *libpng*.

![compression ratios](../benchmarks/results/compression-size@0.svg)

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **58.4 percent** that of *libpng*.


#### compression level 1

![compression performance](../benchmarks/results/compression-speed@1.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s median encoding time at its 1st compression level was **174.18 percent** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **131.52 percent** that of *libpng*.

![compression ratios](../benchmarks/results/compression-size@1.svg)

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **99.64 percent** that of *libpng*.


#### compression level 2

![compression performance](../benchmarks/results/compression-speed@2.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s median encoding time at its 2nd compression level was **169.1 percent** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **130.64 percent** that of *libpng*.

![compression ratios](../benchmarks/results/compression-size@2.svg)

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **99.78 percent** that of *libpng*.


#### compression level 3

![compression performance](../benchmarks/results/compression-speed@3.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s median encoding time at its 3rd compression level was **159.72 percent** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **119.35 percent** that of *libpng*.

![compression ratios](../benchmarks/results/compression-size@3.svg)

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **99.99 percent** that of *libpng*.


#### compression level 4

![compression performance](../benchmarks/results/compression-speed@4.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s median encoding time at its 4th compression level was **153.42 percent** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **107.0 percent** that of *libpng*.

![compression ratios](../benchmarks/results/compression-size@4.svg)

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **100.93 percent** that of *libpng*.


#### compression level 5

![compression performance](../benchmarks/results/compression-speed@5.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s median encoding time at its 5th compression level was **145.8 percent** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **112.61 percent** that of *libpng*.

![compression ratios](../benchmarks/results/compression-size@5.svg)

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **101.1 percent** that of *libpng*.


#### compression level 6

![compression performance](../benchmarks/results/compression-speed@6.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s median encoding time at its 6th compression level was **120.21 percent** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **116.43 percent** that of *libpng*.

![compression ratios](../benchmarks/results/compression-size@6.svg)

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **101.71 percent** that of *libpng*.


#### compression level 7

![compression performance](../benchmarks/results/compression-speed@7.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s median encoding time at its 7th compression level was **111.13 percent** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **107.94 percent** that of *libpng*.

![compression ratios](../benchmarks/results/compression-size@7.svg)

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **101.84 percent** that of *libpng*.


#### compression level 8

![compression performance](../benchmarks/results/compression-speed@8.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s median encoding time at its 8th compression level was **161.12 percent** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **168.84 percent** that of *libpng*.

![compression ratios](../benchmarks/results/compression-size@8.svg)

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **99.13 percent** that of *libpng*.


#### compression level 9

![compression performance](../benchmarks/results/compression-speed@9.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s median encoding time at its 9th compression level was **170.7 percent** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **220.06 percent** that of *libpng*.

![compression ratios](../benchmarks/results/compression-size@9.svg)

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **98.27 percent** that of *libpng*.

### encoding (levels `10 ... 13`)

The following file size plots compare the output of *Swift PNG* at its four highest compression levels with the output of *libpng* at its highest compression level (level `9`).

#### compression level 10

![compression ratios](../benchmarks/results/compression-size@10.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s generated file size its 10th compression level for the `rgb8-color-photographic` test image was **98.04 percent** that of *libpng* at its highest compression level.


#### compression level 11

![compression ratios](../benchmarks/results/compression-size@11.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s generated file size its 11th compression level for the `rgb8-color-photographic` test image was **97.89 percent** that of *libpng* at its highest compression level.


#### compression level 12

![compression ratios](../benchmarks/results/compression-size@12.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s generated file size its 12th compression level for the `rgb8-color-photographic` test image was **97.82 percent** that of *libpng* at its highest compression level.


#### compression level 13

![compression ratios](../benchmarks/results/compression-size@13.svg)

As of commit **[`89aa614`](https://github.com/kelvin13/swift-png/commit/89aa614cf3d0c88ec74f0048d2f10d603c8c1bb8)**, *Swift PNG*’s generated file size its 13th compression level for the `rgb8-color-photographic` test image was **97.74 percent** that of *libpng* at its highest compression level.


### performance by toolchain 

*Swift PNG* is a pure Swift library, so its performance is ultimately constrained by the efficiency of the machine code generated by the Swift compiler. Experimentally, we can observe that the library is getting slightly faster with newer toolchains. The following plots compare the performance of the same version of *Swift PNG* on the `rgb8-color-photographic` test image when compiled with the following nightly toolchains: 

- `DEVELOPMENT-SNAPSHOT-2020-05-03-a`
- `DEVELOPMENT-SNAPSHOT-2020-06-04-a`
- `DEVELOPMENT-SNAPSHOT-2020-07-11-a`
- `DEVELOPMENT-SNAPSHOT-2020-09-17-a`
- `DEVELOPMENT-SNAPSHOT-2020-11-05-a`
- `DEVELOPMENT-SNAPSHOT-2020-12-05-a`

![historical encoder performance](../benchmarks/results/plot-historical.svg)

![historical encoder performance, detail](../benchmarks/results/plot-historical-detail.svg)
