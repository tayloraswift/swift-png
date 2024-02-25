# Indexing

Learn how to define a color palette, encode an image from an index array, decode an image to an index array, and use custom indexing and deindexing functions.

## Key terms

-   term *image palette*:
    A table of colors that an indexed image references. The palette is stored in the PNG file’s internal representation, and is used to map the indices in the image to colors.

-   term *palette aggregate*:
    A color tuple in the image palette.

-   term *indexing function*:
    A function that maps a color to a palette index.

-   term *deindexing function*:
    A function that maps a palette index to a color.

## Worked example

In this tutorial, we will use the library’s indexing APIs to colorize the following grayscale image:

@Image(source: "Indexing.png", alt: "input png") {
    The example image, which is an 8-bit grayscale png.

    Source: [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:20081206_Alexandros_Grigoropoulos_december_2008_riots_Sina_Street_Athens_Greece.jpg)
}

We already saw in the <doc:BasicDecoding> tutorial how to read grayscale samples from an input PNG.

@Snippet(id: "Indexing", slice: "LOAD_EXAMPLE")

What we want to do is map the grayscale ``UInt8`` values to some color gradient, where gray value `0` gets the color at the bottom of the gradient, and gray value `255` gets the color at the top of the gradient. We will do this by creating a new, indexed image where the gray values in the original image are the indices in the new image, and where each index references a gradient value stored in the **image palette**.

We define a simple, six-stop gradient function with the following code. It generates a gradient that is black at the bottom, red in the middle, and yellow at the top.

@Snippet(id: "Indexing", slice: "LERP")

Of course, we can’t encode a gradient function directly in a PNG file, since PNG viewers can’t execute Swift code. So we have to tabularize it as a 256-element array.

@Snippet(id: "Indexing", slice: "TABULARIZE")

We can visualize the gradient using the same APIs we used in the <doc:BasicEncoding> tutorial.

@Snippet(id: "Indexing", slice: "VISUALIZE")

@Image(source: "Indexing-gradient.png", alt: "gradient visualization") {
    A visualization of the generated gradient.
}

We can create an indexed image by defining an indexed layout, and passing the grayscale samples we obtained earlier to one of the pixel-packing APIs. The ``PNG/Image/init(packing:size:layout:metadata:) [8AEMD]`` initializer will treat the grayscale samples as pixel colors, not indices, and will try to match the pixel colors to entries in the given palette. This is not what we want, so we need to use a variant of that function, ``PNG/Image/init(packing:size:layout:metadata:indexer:) [7UEEA]``, and pass it a custom [*indexing function*](#st:indexing%20function).

@Snippet(id: "Indexing", slice: "PACK_EXAMPLE")

The best way to understand the indexing function is to compare it with the behavior of the ``PNG/Image/init(packing:size:layout:metadata:) [8AEMD]`` initializer. Calling that initializer is equivalent to calling ``PNG/Image/init(packing:size:layout:metadata:indexer:) [7UEEA]`` with the following indexing function.

```swift
{
    (palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (UInt8) -> Int in

    let lookup:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8): Int] = .init(
        uniqueKeysWithValues: zip(palette, palette.indices))
    return { (v:UInt8) -> Int in lookup[(v, v, v, .max), default: 0] }
}
```

>   Note:
>   At the time of writing, the above code does not compile due to a [bug in the compiler](https://github.com/apple/swift/pull/28833).

Its type is `([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (UInt8) -> Int`. This construct can be a little confusing, especially if you aren’t familiar with functional programming, so let’s walk through it.

The *outer function* is a [pure function](https://en.wikipedia.org/wiki/Pure_function) that takes a palette argument of type `[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]`. This palette comes from the `palette` field of the image’s color format, if the format is one of the indexed color formats. (If the image layout has a non-indexed color format, the indexing function never gets invoked in the first place.)

The default implementation of the outer function then constructs a dictionary mapping the palette entries to their array indices, using ``Dictionary/init(uniqueKeysWithValues:)``.

The return value of the outer function is an *inner function* of type `(UInt8) -> Int`. As its signature suggests, the inner function takes an argument of type ``UInt8``, and returns an ``Int`` index. The ``UInt8`` is a grayscale sample from the given pixel array. The inner function is not generic. If you pass a `[UInt16]` array to the packing initializer, the 16-bit grayscale samples will get rescaled to the range of a ``UInt8`` before getting passed to the inner function.

Its default implementation [encloses](https://en.wikipedia.org/wiki/Closure_%28computer_programming%29) the dictionary variable, and uses it to look up the palette index of the function’s grayscale sample argument, expanded to RGBA form. If there is no matching palette entry, it returns index `0`. As you might expect, this can be inefficient for some use cases (though not terribly so), so the custom indexing APIs are useful if you want to manipulate indices without re-indexing the entire image.

Depending on the color target, the inner function may take a tuple argument instead of a scalar. For the [`PNG.VA<T>`](/PNG/VA) color target, the inner function recieves `(UInt8, UInt8)` tuples. For the [`PNG.RGBA<T>`](/PNG/RGBA) color target, it receives `(UInt8, UInt8, UInt8, UInt8)` tuples. (The return type is always ``Int``.) In this library, the inner function argument is called a [*palette aggregate*](#st:palette%20aggregate).

Let’s go back to the custom indexing function:

```swift
{
    _ in Int.init(_:)
}
```

Since we just want to cast the grayscale samples directly to index values, we don’t need the palette parameter, so we discard it with the `_` binding. We then return the ``Int.init(_:) [4EKVL]`` initializer, which casts the grayscale samples to ``Int``s.

On appropriate platforms, we can encode the image to a file with the ``PNG/Image/compress(path:level:hint:)`` method.

@Snippet(id: "Indexing", slice: "COMPRESS_EXAMPLE")

@Image(source: "Indexing-indexed.png", alt: "output png") {
    The example image, colorized as an indexed png.
}

To read back the index values from the indexed image, we can use a custom **deindexing function**, which we pass to ``PNG/Image/unpack(as:deindexer:) [JEO1]``.

@Snippet(id: "Indexing", slice: "UNPACK_EXAMPLE")

For the scalar pixel packing API, deindexing functions have the type `([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> UInt8`. Its return type, `(Int) -> UInt8` is exactly the opposite of that of an indexing function. Its default behavior is equivalent to the following implementation, which should be self-explanatory.

```swift
{
    (palette:[(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> UInt8 in
    {
        (i:Int) -> UInt8 in palette[i].r
    }
}
```

>   Warning:
>   Do not unpack indices to a color target that is not ``UInt8``. If you unpack them to a target of a different bit width, such as ``UInt16``, the indices will get rescaled to fill the range of that integer type.

We can verify that the indices we read back with our custom deindexing function are identical to the grayscale samples we originally passed to the packing initializer.

@Snippet(id: "Indexing", slice: "CHECK_EXAMPLE")

```bash
true
```
