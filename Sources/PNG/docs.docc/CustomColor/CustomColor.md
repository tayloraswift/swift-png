# Custom color

Learn how to define a custom color target, understand and use the library’s convolution and deconvolution helper functions, implement pixel packing and unpacking for a custom HSVA color target, and apply chroma keys from applicable color formats.


## Key terms

-   term *pixel kernel*:
    A function that converts groups of image data samples into instances of a color target, and vice-versa.

-   term *convolution*:
    A function that converts groups of image data samples into instances of a color target.

-   term *deconvolution*:
    A function that converts instances of a color target into groups of image data samples.

-   term *atom type*:
    The type of the unscaled samples in the image data storage buffer.

-   term *intensity type*:
    The type of the scaled samples in the image data storage buffer.


## Worked example

As we have already seen, *Swift PNG*’s pixel packing and unpacking interfaces are generic over the library protocol ``PNG.Color``. The built-in color targets [`PNG.VA<T>`](PNG/VA) and [`PNG.RGBA<T>`](PNG/RGBA) both conform to it. In this tutorial, we will implement a custom color target, `HSVA`, which uses the [hue-saturation-value color model](https://en.wikipedia.org/wiki/HSL_and_HSV).

At this point, it is important to reiterate the difference between color formats and color targets. A color format is the internal representation that pixels are stored as in a PNG file. A color target is an interpretation of those pixels that we obtain by unpacking pixels from an image data instance.

If you have used [*Swift JPEG*](https://github.com/tayloraswift/jpeg), that library has the concept of a *color format type*, which can also be customized. This is because JPEG is an *open standard*, meaning that users can encode images with a user-defined internal representation. Thus, JPEG is actually a family of file formats, rather than a single standard. PNG is a *closed standard*, so *Swift PNG* does not allow you to customize the color format.

>   Note:
>   Strictly speaking, PNG is also a family of file formats, with two color format types — the standard set of color formats, and the iphone-optimized color formats. however, the png specification provides no means of defining custom color formats within its headers (thus, the need for the ``PNG/Chunk/CgBI`` chunk), so for ease-of-use, the library merges both png color format types into a single library-defined color format type.


@Image(source: "CustomColor.png") {
    The example image.

    Source: [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Alice-in-Wonderland_by-David-Revoy_2010-07-21.jpg)
}

We begin by defining the `HSVA` type. For simplicity, we won’t make it generic like [`PNG.VA<T>`](PNG/VA) or [`PNG.RGBA<T>`](PNG/RGBA). It will have a fixed width of 64 bits, with 32 bits for the hue component, 16 bits for the saturation component, and 8 bits each for the value and alpha components. We define the range of the hue component to be `0 ... 393222`, and the range of the other components to be the entire range of their integer storage types. (This means only nineteen of the 32 hue bits will be inhabited.)

@Snippet(id: "CustomColor", slice: "HSVA_TYPE")

We define the following conversion function, which initializes an HSVA color from RGBA samples. The conversion formula is unimportant, so it’s fine if you don’t understand exactly how it works.

@Snippet(id: "CustomColor", slice: "HSVA_CONVERT_FROM_RGBA")

We also define the HSVA-to-RGBA conversion, using [`PNG.RGBA<UInt8>`](PNG/RGBA) as the return type. Again, the details of the conversion formula are unimportant.

@Snippet(id: "CustomColor", slice: "HSVA_CONVERT_TO_RGBA")

Now that we have a working HSVA implementation, we need to conform it to the ``PNG.Color`` protocol so we can use it as a color target. To do this, we need to fulfill the following requirements:

```swift
protocol PNG.Color
{
    associatedtype Aggregate

    static
    func unpack(_ interleaved:[UInt8],
        of format:PNG.Format,
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> Aggregate) -> [Self]
    static
    func pack(_ pixels:[Self],
        as format:PNG.Format,
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Aggregate) -> Int) -> [UInt8]

    static
    func unpack(_ interleaved:[UInt8], of format:PNG.Format) -> [Self]
    static
    func pack(_ pixels:[Self], as format:PNG.Format) -> [UInt8]
}
```

For certain associated ``PNG.Color/Aggregate`` types, the library provides default implementations for ``PNG.Color/unpack(_:of:) [requirement]`` and ``PNG.Color/pack(_:as:) [requirement]``, which have behaviors detailed in the <doc:Indexing> tutorial. In such cases, we only need to implement ``PNG.Color/unpack(_:of:deindexer:)`` and ``PNG.Color/pack(_:as:indexer:)``. The specific `Aggregate` types are

- `(UInt8, UInt8)`, and
- `(UInt8, UInt8, UInt8, UInt8)`.

In the [indexed color tutorial](doc:Indexing), we saw how they were used by the [`PNG.VA<T>`](PNG/VA) and [`PNG.RGBA<T>`](PNG/RGBA) color targets. (The scalar color targets also use their own `Aggregate` type, ``UInt8``, though this does not go through the ``PNG.Color`` protocol.)

The core idea of a color target is the **pixel kernel**. Pixel kernels convert groups of image data samples into instances of a color target, and vice-versa. In *Swift PNG*, the application of a pixel kernel to an image data buffer is called a **convolution**, and the inverse operation is called a **deconvolution**. The simplest deconvolution is to flatten an array of RGBA pixels to an array of [*r*, *g*, *b*, *a*, *r*, *g*, *b*, *a*, …] samples, and the simplest convolution is to group the elements of such an array into an array of RGBA pixels. Conceptually, this is a Swift ``Sequence/flatMap(_:) ((Self.Element) -> SegmentOfResult)``, and whatever you would call the opposite of a flatmap, respectively. We are allowed to do arbitrary computations in the pixel kernels, which is why we call it a (de)convolution, and not just a flatmap.

Let’s tackle the unpacking operation first. *Swift PNG* provides a set of helper functions to reduce the amount of boilerplate you have to write.

```swift
extension PNG
{
    static
    func convolve<A, T, C>(_ buffer:[UInt8], dereference:(Int) -> A,
        kernel:(T) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func convolve<A, T, C>(_ buffer:[UInt8], dereference:(Int) -> (A, A),
        kernel:((T, T)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func convolve<A, T, C>(_ buffer:[UInt8], dereference:(Int) -> (A, A, A),
        kernel:((T, T, T)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func convolve<A, T, C>(_ buffer:[UInt8], dereference:(Int) -> (A, A, A, A),
        kernel:((T, T, T, T)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func convolve<A, T, C>(_ buffer:[UInt8], of _:A.Type, depth:Int,
        kernel:(T, A) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func convolve<A, T, C>(_ buffer:[UInt8], of _:A.Type, depth:Int,
        kernel:((T, T)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func convolve<A, T, C>(_ buffer:[UInt8], of _:A.Type, depth:Int,
        kernel:((T, T, T), (A, A, A)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func convolve<A, T, C>(_ buffer:[UInt8], of _:A.Type, depth:Int,
        kernel:((T, T, T, T)) -> C)
        -> [C]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
}
```

The first four convolution functions are meant to be used with indexed color formats, and the remaining four are meant to be used with non-indexed color formats. To understand how they work, let’s first go over what the generic parameters `A`, `T`, and `C` mean.

-   The `A` type is the **atom type**. (The `A` stands for ***a***tom.) Atom types are closely related to color formats. For images with a color depth of 16, the appropriate atom type is ``UInt16``. Otherwise, it is ``UInt8``. In the image data storage buffer, which has a type of `[UInt8]`, `UInt16` atoms are stored in big-endian order.

    Atoms are unscaled samples. For example, in a ``PNG/Format/v4(fill:key:)`` image, which has a color depth of 4, the ``UInt8`` atoms can take on values in the range `0 ... 15`, with the remaining states unused.

-   The `T` type is the **intensity type**. (The `T` stands for in***t***ensity, or ***t***arget, whatever floats your boat.) Intensity types are closely related to color targets. Oftentimes, the intensity type is simply the component type of the color target. For example, for the built-in [`PNG.RGBA<T>`](PNG/RGBA) color target, its generic parameter and the intensity type are the same `T`. Of course, this isn’t always the case, notably, with our custom `HSVA` type, which has heterogenous components.

    As the name suggests, intensity values are scaled samples. The entire range of an intensity type is always inhabited. For example, in a ``PNG/Format/v4(fill:key:)`` image, an atom with the value `15` would become a ``UInt8`` intensity with the value `255`. If the intensity type was ``UInt32`` instead, the same atom would generate an intensity value of `4294967295` (``UInt32.max``).

    The use of intensity types in *Swift PNG* means that you don’t have to worry about normalizing samples when implementing custom color targets.

-   Finally, the `C` type is the color target type. (Guess what the `C` stands for.) If you want to unpack a ``PNG/Format/va16(fill:)`` image to an array of [`PNG.RGBA<UInt8>`](PNG/RGBA) pixels, the atom type would be ``UInt16``, the intensity type would be ``UInt8``, and the color target type would of course be [`PNG.RGBA<UInt8>`](PNG/RGBA). Indeed, this is exactly what the built-in [`PNG.RGBA<T>`](PNG/RGBA) color target does.

The four non-indexed convolution functions perform the following operations:

1. Load (big-endian) atoms from the given data buffer.
2. Convert the atoms to the intensity type, and scale them to fill the range of the intensity type, according to the given color depth.
3. Feed the intensities, and in certain cases, the original atoms as well, to the given pixel kernel, and get pixel instances in return.

The reason why some of the pixel kernels receive the original atoms in addition to the intensity values is because their associated color formats (namely, the grayscale, RGB, and BGR formats) require us to do chroma key comparisons, which must be performed in the original atom type.

The four indexed convolution functions do basically the same thing, except they obtain the atoms from the given `dereference` function, which in turn gets its ``Int`` index argument from the given data buffer. Generally, you would expect it to get the atoms from the image palette. They are meant to be used with the ``PNG.Color/Aggregate`` types `A`, `(A, A)`, `(A, A, A)`, or `(A, A, A, A)`, respectively. The indexed convolution functions assume the image color depth is the same as the bit width of the atom type, which is why they don’t ask you to supply a color depth argument. None of them pass the original atoms to their pixel kernels, since indexed color formats don’t use chroma keys.

Now, let’s write the implementation for the unpacking function.

First, we set the associated ``PNG.Color/Aggregate`` type to `(UInt8, UInt8, UInt8, UInt8)`. This means that we expect the deindexing function to return four atoms, since we want to use all four components of the RGBA palette entries to compute the HSVA outputs. (This also means that the library will give us a default `deindexer` implementation for free.)

@Snippet(id: "CustomColor", slice: "HSVA_CONFORMANCE_SIGNATURES")

We can handle all of the indexed color formats in one `switch` case. We assume that the `dereference` function returns RGBA samples in the `(UInt8, UInt8, UInt8, UInt8)` aggregate, and we forward them to `HSVA.init(r:g:b:a:)`. (If you don’t understand how to get the `dereference` function from `deindexer`, read the <doc:Indexing> tutorial.)

@Snippet(id: "CustomColor", slice: "HSVA_CONFORMANCE_INDEXED")

For grayscale color formats without a chroma key, we assign the grayscale sample to the value channel of the HSVA output, set the hue and saturation to zero, and the alpha to full opacity. We need a separate case for the ``PNG/Format/v16(fill:key:)`` color format, since its atom type is ``UInt16`` and not ``UInt8``.

@Snippet(id: "CustomColor", slice: "HSVA_CONFORMANCE_V")

For the grayscale formats with a chroma key, we do the same thing, except we clear the alpha if the original grayscale atom matches the chroma key.

@Snippet(id: "CustomColor", slice: "HSVA_CONFORMANCE_V_KEYED")

The rest of the cases are quite boilerplatey, and therefore should be incredibly straightforward.

@Snippet(id: "CustomColor", slice: "HSVA_CONFORMANCE_REST")

If you understood how we implemented the unpacking function, then the packing function should be easy to write too. Mirroring the convolution functions, *Swift PNG* provides eight deconvolution helper functions. The generic parameters have the exact same meanings as they did before.

```swift
extension PNG
{
    static
    func deconvolve<A, T, C>(_ pixels:[C],
        reference:(A) -> Int,
        kernel:(C) -> T) -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func deconvolve<A, T, C>(_ pixels:[C],
        reference:((A, A)) -> Int,
        kernel:(C) -> (T, T)) -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func deconvolve<A, T, C>(_ pixels:[C],
        reference:((A, A, A)) -> Int,
        kernel:(C) -> (T, T, T)) -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func deconvolve<A, T, C>(_ pixels:[C],
        reference:((A, A, A, A)) -> Int,
        kernel:(C) -> (T, T, T, T)) -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func deconvolve<A, T, C>(_ pixels:[C],
        as _:A.Type,
        depth:Int,
        kernel:(C) -> T) -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func deconvolve<A, T, C>(_ pixels:[C],
        as _:A.Type,
        depth:Int,
        kernel:(C) -> (T, T)) -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func deconvolve<A, T, C>(_ pixels:[C],
        as _:A.Type,
        depth:Int,
        kernel:(C) -> (T, T, T)) -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger

    static
    func deconvolve<A, T, C>(_ pixels:[C],
        as _:A.Type,
        depth:Int,
        kernel:(C) -> (T, T, T, T)) -> [UInt8]
        where A:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
}
```

The four non-indexed deconvolution functions perform the following operations:

1. Feed the pixel instances from the given pixel array to the given pixel kernel, and get intensity tuples (or a scalar) in return.
2. Convert the intensities to the atom type, and scale them to the range specified by the given color depth.
3. Store the atoms in the returned data buffer (as big-endian integers).

The main difference is that none of the deconvolution kernels interact with the generated atoms, since chroma keys aren’t relevant to pixel packing. This is because any chroma key-based transparency would have already been baked into the pixel array when it was first unpacked from the image data instance.

The four indexed deconvolution functions have essentially the same relationship to the non-indexed deconvolution functions as the indexed convolution functions do to the non-indexed convolution functions.

The implementation of the packing function is straightforward. When necessary, we have used the `rgba` property we defined on the `HSVA` type to perform the HSVA-to-RGBA conversion. Note that we have explicitly written the return types in the pixel kernels since, at the time of writing, the Swift compiler seems to have some issues with type inferencing across module boundaries.

@Snippet(id: "CustomColor", slice: "HSVA_CONFORMANCE_PACK")

Now, we can put our custom `HSVA` color target to work.

@Snippet(id: "CustomColor", slice: "LOAD_EXAMPLE")

We can visualize the hue, saturation, and value channels as follows:

@Snippet(id: "CustomColor", slice: "SAVE_HUE")

@Image(source: "CustomColor-hue.png") {
    A visualization of the example image hue.
}

@Snippet(id: "CustomColor", slice: "SAVE_SATURATION")

@Image(source: "CustomColor-saturation.png") {
    A visualization of the example image saturation.
}

@Snippet(id: "CustomColor", slice: "SAVE_VALUE")

@Image(source: "CustomColor-value.png") {
    A visualization of the example image value.
}

We can test our pixel packing implementation by re-encoding the HSVA image.

@Snippet(id: "CustomColor", slice: "SAVE_EXAMPLE")

@Image(source: "CustomColor.png.png") {
    The example image, re-encoded from the previously-obtained HSVA representation.
}
