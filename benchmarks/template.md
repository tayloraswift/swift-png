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

![decompression performance](../{plot_decompression_speed})

As of commit **{commit}**, *Swift PNG*’s median decoding time was **{median_decompression_speed}** that of *libpng*. *Swift PNG*’s median decoding time for the `rgb8-color-photographic` test image was **{rgb8_decompression_speed}** that of *libpng*.

### encoding (levels `0 ... 9`)

The compression benchmarks are similar to the decompression benchmarks except we measure ten of the library’s fourteen compression levels separately. The four highest *Swift PNG* compression levels have no *libpng* equivalent; size comparisons between their output and *libpng*’s output at its highest compression level can be found in the [next section](#encoding-levels-10--13).

Note that *Swift PNG* and *libpng* compression levels generally don’t correspond to one another. In particular, *Swift PNG*’s speed-vs-compression curve is “flatter” than *libpng*’s. This means *Swift PNG* performs more compression (using more resources) than *libpng* for the first few compression levels, and some of the higher compression levels as well. This is by design, because *libpng* has the undesirable property in that for many input images, its speed does not decrease monotonically as the compression parameter increases.

In the density plots below, the labeled curves represent the *aggregate distribution* of run times across all **{images}** test images. The unlabeled curves are the distributions for each individual test image. The dashed curve indicates the distribution for one of the 8-bit RGB test images (`rgb8-color-photographic`), one of the most common PNG image types.


#### compression level 0

![compression performance](../{plot_compression_speed@0})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 0th compression level was **{median_compression_speed@0}** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **{rgb8_compression_speed@0}** that of *libpng*.

![compression ratios](../{plot_compression_ratio@0})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@0}** that of *libpng*.


#### compression level 1

![compression performance](../{plot_compression_speed@1})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 1st compression level was **{median_compression_speed@1}** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **{rgb8_compression_speed@1}** that of *libpng*.

![compression ratios](../{plot_compression_ratio@1})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@1}** that of *libpng*.


#### compression level 2

![compression performance](../{plot_compression_speed@2})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 2nd compression level was **{median_compression_speed@2}** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **{rgb8_compression_speed@2}** that of *libpng*.

![compression ratios](../{plot_compression_ratio@2})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@2}** that of *libpng*.


#### compression level 3

![compression performance](../{plot_compression_speed@3})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 3rd compression level was **{median_compression_speed@3}** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **{rgb8_compression_speed@3}** that of *libpng*.

![compression ratios](../{plot_compression_ratio@3})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@3}** that of *libpng*.


#### compression level 4

![compression performance](../{plot_compression_speed@4})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 4th compression level was **{median_compression_speed@4}** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **{rgb8_compression_speed@4}** that of *libpng*.

![compression ratios](../{plot_compression_ratio@4})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@4}** that of *libpng*.


#### compression level 5

![compression performance](../{plot_compression_speed@5})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 5th compression level was **{median_compression_speed@5}** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **{rgb8_compression_speed@5}** that of *libpng*.

![compression ratios](../{plot_compression_ratio@5})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@5}** that of *libpng*.


#### compression level 6

![compression performance](../{plot_compression_speed@6})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 6th compression level was **{median_compression_speed@6}** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **{rgb8_compression_speed@6}** that of *libpng*.

![compression ratios](../{plot_compression_ratio@6})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@6}** that of *libpng*.


#### compression level 7

![compression performance](../{plot_compression_speed@7})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 7th compression level was **{median_compression_speed@7}** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **{rgb8_compression_speed@7}** that of *libpng*.

![compression ratios](../{plot_compression_ratio@7})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@7}** that of *libpng*.


#### compression level 8

![compression performance](../{plot_compression_speed@8})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 8th compression level was **{median_compression_speed@8}** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **{rgb8_compression_speed@8}** that of *libpng*.

![compression ratios](../{plot_compression_ratio@8})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@8}** that of *libpng*.


#### compression level 9

![compression performance](../{plot_compression_speed@9})

As of commit **{commit}**, *Swift PNG*’s median encoding time at its 9th compression level was **{median_compression_speed@9}** that of *libpng*. *Swift PNG*’s median encoding time for the `rgb8-color-photographic` test image was **{rgb8_compression_speed@9}** that of *libpng*.

![compression ratios](../{plot_compression_ratio@9})

*Swift PNG*’s generated file size for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@9}** that of *libpng*.

### encoding (levels `10 ... 13`)

The following file size plots compare the output of *Swift PNG* at its four highest compression levels with the output of *libpng* at its highest compression level (level `9`).

#### compression level 10

![compression ratios](../{plot_compression_ratio@10})

As of commit **{commit}**, *Swift PNG*’s generated file size its 10th compression level for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@10}** that of *libpng* at its highest compression level.


#### compression level 11

![compression ratios](../{plot_compression_ratio@11})

As of commit **{commit}**, *Swift PNG*’s generated file size its 11th compression level for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@11}** that of *libpng* at its highest compression level.


#### compression level 12

![compression ratios](../{plot_compression_ratio@12})

As of commit **{commit}**, *Swift PNG*’s generated file size its 12th compression level for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@12}** that of *libpng* at its highest compression level.


#### compression level 13

![compression ratios](../{plot_compression_ratio@13})

As of commit **{commit}**, *Swift PNG*’s generated file size its 13th compression level for the `rgb8-color-photographic` test image was **{rgb8_compression_ratio@13}** that of *libpng* at its highest compression level.


### performance by toolchain 

*Swift PNG* is a pure Swift library, so its performance is ultimately constrained by the efficiency of the machine code generated by the Swift compiler. Experimentally, we can observe that the library is getting slightly faster with newer toolchains. The following plots compare the performance of the same version of *Swift PNG* on the `rgb8-color-photographic` test image when compiled with the following nightly toolchains: 

{historical_toolchains}

![historical encoder performance](../{plot_historical})

![historical encoder performance, detail](../{plot_historical_detail})
