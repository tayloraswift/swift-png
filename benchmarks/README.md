# *swift png* benchmarks 

> generated on **October 28, 2020** for commit **[`a8493d0`](https://github.com/kelvin13/png/commit/a8493d06bbee474ab04397222ea3f12a49661cee)** using **[`utils/decompression-benchmark`](../utils/utils/decompression-benchmark)**

## running benchmarks 

*Swift PNG*’s benchmarks live in the `benchmarks` directory. They are divided into compression benchmarks (`benchmarks/compression`) and decompression benchmarks (`benchmarks/decompression`). Each benchmark compares a *Swift PNG* test application to an equivalent *libpng*-based implementation. All performance benchmarks are *cold-start* measurements, meaning that the code sleeps for a fraction of a second before each trial run.

All benchmarks run on a test suite of **28** images. 

<details>
<summary><em>Click to show test image table</em></summary>

| Test image | Size |
| ---------- | ---- |
| `indexed8-color-nonphotographic.png` <br/> <img src="../tests/compression/baseline/indexed8-color-nonphotographic.png"/> | 43,496 B |
| `indexed8-color-photographic.png` <br/> <img src="../tests/compression/baseline/indexed8-color-photographic.png"/> | 65,487 B |
| `indexed8-monochrome-nonphotographic.png` <br/> <img src="../tests/compression/baseline/indexed8-monochrome-nonphotographic.png"/> | 62,888 B |
| `indexed8-monochrome-photographic.png` <br/> <img src="../tests/compression/baseline/indexed8-monochrome-photographic.png"/> | 82,014 B |
| `rgb16-color-nonphotographic.png` <br/> <img src="../tests/compression/baseline/rgb16-color-nonphotographic.png"/> | 365,253 B |
| `rgb16-color-photographic.png` <br/> <img src="../tests/compression/baseline/rgb16-color-photographic.png"/> | 477,784 B |
| `rgb16-monochrome-nonphotographic.png` <br/> <img src="../tests/compression/baseline/rgb16-monochrome-nonphotographic.png"/> | 244,077 B |
| `rgb16-monochrome-photographic.png` <br/> <img src="../tests/compression/baseline/rgb16-monochrome-photographic.png"/> | 379,113 B |
| `rgb8-color-nonphotographic.png` <br/> <img src="../tests/compression/baseline/rgb8-color-nonphotographic.png"/> | 130,595 B |
| `rgb8-color-photographic.png` <br/> <img src="../tests/compression/baseline/rgb8-color-photographic.png"/> | 174,298 B |
| `rgb8-monochrome-nonphotographic.png` <br/> <img src="../tests/compression/baseline/rgb8-monochrome-nonphotographic.png"/> | 76,636 B |
| `rgb8-monochrome-photographic.png` <br/> <img src="../tests/compression/baseline/rgb8-monochrome-photographic.png"/> | 92,023 B |
| `rgba16-color-nonphotographic.png` <br/> <img src="../tests/compression/baseline/rgba16-color-nonphotographic.png"/> | 394,493 B |
| `rgba16-color-photographic.png` <br/> <img src="../tests/compression/baseline/rgba16-color-photographic.png"/> | 518,368 B |
| `rgba16-monochrome-nonphotographic.png` <br/> <img src="../tests/compression/baseline/rgba16-monochrome-nonphotographic.png"/> | 143,935 B |
| `rgba16-monochrome-photographic.png` <br/> <img src="../tests/compression/baseline/rgba16-monochrome-photographic.png"/> | 414,526 B |
| `rgba8-color-nonphotographic.png` <br/> <img src="../tests/compression/baseline/rgba8-color-nonphotographic.png"/> | 147,023 B |
| `rgba8-color-photographic.png` <br/> <img src="../tests/compression/baseline/rgba8-color-photographic.png"/> | 196,537 B |
| `rgba8-monochrome-nonphotographic.png` <br/> <img src="../tests/compression/baseline/rgba8-monochrome-nonphotographic.png"/> | 84,098 B |
| `rgba8-monochrome-photographic.png` <br/> <img src="../tests/compression/baseline/rgba8-monochrome-photographic.png"/> | 101,521 B |
| `v16-monochrome-nonphotographic.png` <br/> <img src="../tests/compression/baseline/v16-monochrome-nonphotographic.png"/> | 123,371 B |
| `v16-monochrome-photographic.png` <br/> <img src="../tests/compression/baseline/v16-monochrome-photographic.png"/> | 176,236 B |
| `v8-monochrome-nonphotographic.png` <br/> <img src="../tests/compression/baseline/v8-monochrome-nonphotographic.png"/> | 48,191 B |
| `v8-monochrome-photographic.png` <br/> <img src="../tests/compression/baseline/v8-monochrome-photographic.png"/> | 59,743 B |
| `va16-monochrome-nonphotographic.png` <br/> <img src="../tests/compression/baseline/va16-monochrome-nonphotographic.png"/> | 143,935 B |
| `va16-monochrome-photographic.png` <br/> <img src="../tests/compression/baseline/va16-monochrome-photographic.png"/> | 209,902 B |
| `va8-monochrome-nonphotographic.png` <br/> <img src="../tests/compression/baseline/va8-monochrome-nonphotographic.png"/> | 60,478 B |
| `va8-monochrome-photographic.png` <br/> <img src="../tests/compression/baseline/va8-monochrome-photographic.png"/> | 76,280 B |

</details>

## results

### decoding 

The decompression benchmarks compare the performance of *Swift PNG* to that of *libpng* while decoding the **28** images in the library test suite. Run times are normalized according to the *median* runtime of the baseline (*libpng*) implementation *for each test image*. 

In the density plot below, the labeled curves represent the *aggregate distribution* of run times across all **28** test images. The unlabeled curves are the distributions for each individual test image.

![decompression performance](densityplot-decompression.svg)

As of commit **[`a8493d0`](https://github.com/kelvin13/png/commit/a8493d06bbee474ab04397222ea3f12a49661cee)**, the median decoding run time of *Swift PNG* was **139.48 percent** that of *libpng*.
