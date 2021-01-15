# *swift png* benchmarks 

> generated on **{date}** for commit **{commit}** using **{tool}**

## running benchmarks 

*Swift PNG*’s benchmarks live in the `benchmarks` directory. They are divided into compression benchmarks ([`benchmarks/compression`](compression)) and decompression benchmarks ([`benchmarks/decompression`](decompression)). Each benchmark compares a *Swift PNG* test application to an equivalent *libpng*-based implementation. All performance benchmarks are *cold-start* measurements, meaning that the code sleeps for a fraction of a second before each trial run.

All benchmarks run on a test suite of **{images}** images. 

<details>
<summary><em>Click to show test image table</em></summary>

{image_table}

</details>

## results

### decoding 

The decompression benchmarks compare the performance of *Swift PNG* to that of *libpng* while decoding the **{images}** images in the library test suite. Run times are normalized according to the *median* runtime of the baseline (*libpng*) implementation *for each test image*. 

In the density plot below, the labeled curves represent the *aggregate distribution* of run times across all **{images}** test images. The unlabeled curves are the distributions for each individual test image. The dashed curve indicates the distribution for one of the 8-bit RGB test images (`rgb8-color-photographic`), one of the most common PNG image types.

![decompression performance](../{densityplot_decompression})

As of commit **{commit}**, *Swift PNG*’s median decoding time was **{median_ratio_decompression}** that of *libpng*.

### encoding 

The compression benchmarks are similar to the decompression benchmarks except we measure ten of the library’s thirteen compression levels separately. (The three highest compression levels have no *libpng* equivalent.)

Note that *Swift PNG* and *libpng* compression levels generally don’t correspond to one another. In particular, *Swift PNG*’s speed-vs-compression curve is “flatter” than *libpng*’s. This means *Swift PNG* performs more compression (using more resources) than *libpng* for the first few compression levels, and some of the higher compression levels as well. This is by design, because *libpng* has the undesirable property in that for many input images, its speed does not decrease monotonically as the compression parameter increases.

In the density plots below, the labeled curves represent the *aggregate distribution* of run times across all **{images}** test images. The unlabeled curves are the distributions for each individual test image. The dashed curve indicates the distribution for one of the 8-bit RGB test images (`rgb8-color-photographic`), one of the most common PNG image types.


#### compression level 0

![compression performance](../{densityplot_compression_speed@0})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 0th compression level was **{median_ratio_compression@0}** that of *libpng*. *Swift PNG*’s encoding time for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_speed@0}** that of *libpng*.

![compression performance](../{densityplot_compression_size@0})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_size@0}** that of *libpng*.


#### compression level 1

![compression performance](../{densityplot_compression_speed@1})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 1st compression level was **{median_ratio_compression@1}** that of *libpng*. *Swift PNG*’s encoding time for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_speed@1}** that of *libpng*.

![compression performance](../{densityplot_compression_size@1})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_size@1}** that of *libpng*.


#### compression level 2

![compression performance](../{densityplot_compression_speed@2})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 2nd compression level was **{median_ratio_compression@2}** that of *libpng*. *Swift PNG*’s encoding time for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_speed@2}** that of *libpng*.

![compression performance](../{densityplot_compression_size@2})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_size@2}** that of *libpng*.


#### compression level 3

![compression performance](../{densityplot_compression_speed@3})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 3rd compression level was **{median_ratio_compression@3}** that of *libpng*. *Swift PNG*’s encoding time for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_speed@3}** that of *libpng*.

![compression performance](../{densityplot_compression_size@3})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_size@3}** that of *libpng*.


#### compression level 4

![compression performance](../{densityplot_compression_speed@4})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 4th compression level was **{median_ratio_compression@4}** that of *libpng*. *Swift PNG*’s encoding time for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_speed@4}** that of *libpng*.

![compression performance](../{densityplot_compression_size@4})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_size@4}** that of *libpng*.


#### compression level 5

![compression performance](../{densityplot_compression_speed@5})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 5th compression level was **{median_ratio_compression@5}** that of *libpng*. *Swift PNG*’s encoding time for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_speed@5}** that of *libpng*.

![compression performance](../{densityplot_compression_size@5})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_size@5}** that of *libpng*.


#### compression level 6

![compression performance](../{densityplot_compression_speed@6})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 6th compression level was **{median_ratio_compression@6}** that of *libpng*. *Swift PNG*’s encoding time for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_speed@6}** that of *libpng*.

![compression performance](../{densityplot_compression_size@6})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_size@6}** that of *libpng*.


#### compression level 7

![compression performance](../{densityplot_compression_speed@7})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 7th compression level was **{median_ratio_compression@7}** that of *libpng*. *Swift PNG*’s encoding time for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_speed@7}** that of *libpng*.

![compression performance](../{densityplot_compression_size@7})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_size@7}** that of *libpng*.


#### compression level 8

![compression performance](../{densityplot_compression_speed@8})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 8th compression level was **{median_ratio_compression@8}** that of *libpng*. *Swift PNG*’s encoding time for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_speed@8}** that of *libpng*.

![compression performance](../{densityplot_compression_size@8})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_size@8}** that of *libpng*.


#### compression level 9

![compression performance](../{densityplot_compression_speed@9})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 9th compression level was **{median_ratio_compression@9}** that of *libpng*. *Swift PNG*’s encoding time for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_speed@9}** that of *libpng*.

![compression performance](../{densityplot_compression_size@9})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_ratio_compression_size@9}** that of *libpng*.

### performance by toolchain 

*Swift PNG* is a pure Swift library, so its performance is ultimately constrained by the efficiency of the machine code generated by the Swift compiler. Experimentally, we can observe that the library is getting slightly faster with newer toolchains. The following plots compare the performance of the same version of *Swift PNG* on the `rgb8-color-photographic` test image when compiled with the following nightly toolchains: 

{historical_toolchains}

![historical encoder performance](../{densityplot_historical})

![historical encoder performance, detail](../{densityplot_historical_detail})
