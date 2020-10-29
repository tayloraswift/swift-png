# *swift png* benchmarks 

> generated on **{date}** for commit **{commit}** using **{tool}**

## running benchmarks 

*Swift PNG*’s benchmarks live in the `benchmarks` directory. They are divided into compression benchmarks (`benchmarks/compression`) and decompression benchmarks (`benchmarks/decompression`). Each benchmark compares a *Swift PNG* test application to an equivalent *libpng*-based implementation. All performance benchmarks are *cold-start* measurements, meaning that the code sleeps for a fraction of a second before each trial run.

All benchmarks run on a test suite of **{images}** images. 

<details>
<summary><em>Click to show test image table</em></summary>

{image_table}

</details>

## results

### decoding 

The decompression benchmarks compare the performance of *Swift PNG* to that of *libpng* while decoding the **{images}** images in the library test suite. Run times are normalized according to the *median* runtime of the baseline (*libpng*) implementation *for each test image*. 

In the density plot below, the labeled curves represent the *aggregate distribution* of run times across all **{images}** test images. The unlabeled curves are the distributions for each individual test image.

![decompression performance](densityplot-decompression.svg)

As of commit **{commit}**, the median decoding run time of *Swift PNG* was **{median_ratio}** that of *libpng*.
