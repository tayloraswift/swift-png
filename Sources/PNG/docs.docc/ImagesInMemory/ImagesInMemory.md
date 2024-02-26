# In-memory images

Learn how to decode an image from a memory blob, encode an image into a memory blob, and implement a custom data source or destination.

## Key terms

-   term *bytestream protocol*:
    A protocol that a custom data stream type can conform to. The library has two bytestream protocols: ``PNG.BytestreamSource`` and ``PNG.BytestreamDestination``.

## Worked example

Up to this point we have been using the built-in file system API that the library provides on Linux and MacOS platforms. These APIs are built atop of the library’s core data stream APIs, which are available on all Swift platforms. The core library is universally portable because it is written in pure Swift, with no dependencies, even ``/Foundation``. In this tutorial, we will use this lower-level interface to implement reading and writing PNG files in memory.

If you have used *Swift PNG*’s companion library [*Swift JPEG*](https://github.com/tayloraswift/jpeg), the interface here is exactly the same. In fact, you can copy-and-paste large swaths of the code from the corresponding [JPEG tutorial](https://github.com/tayloraswift/jpeg/tree/master/examples#using-in-memory-images), and it will just work.

@Snippet(id: "ImagesInMemory", slice: "BLOB_TYPE")

We can conform to ``PNG.BytestreamSource`` and ``PNG.BytestreamDestination`` with the following implementations:

@Snippet(id: "ImagesInMemory", slice: "BLOB_CONFORMANCE")

For the sake of tutorial brevity, we are not going to bother bootstrapping the task of obtaining the PNG memory blob in the first place, so we will just use the built-in file system API for this. But we could have gotten the data any other way.

@Snippet(id: "ImagesInMemory", slice: "BLOB_BOOTSTRAP")

@Image(source: "ImagesInMemory.png", alt: "input png") {
    The example image.

    Source: [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Agence_Rol,_24.4.21,_concours_de_machines_-_BnF.jpg)
}

To decode from our `System.Blob` type, we use the ``PNG/Image/decompress(stream:)`` function, which is part of the core library, and does essentially the same thing as the file system-aware ``PNG/Image/decompress(path:)`` function. We can then unpack pixels from the returned image data structure as we would in any other situation.

@Snippet(id: "ImagesInMemory", slice: "READ")

Just as with the decompression interfaces, the ``PNG/Image/compress(path:level:hint:)`` function has a generic ``PNG/Image/compress(stream:level:hint:)`` counterpart. Here, we have cleared the blob storage, and written the example image we decoded earlier to it:

@Snippet(id: "ImagesInMemory", slice: "WRITE")

We can save the blob to disk, to verify that the memory blob does indeed contain a valid PNG file.

@Snippet(id: "ImagesInMemory", slice: "SAVE")

@Image(source: "ImagesInMemory.png.png", alt: "output png") {
    The example image, re-encoded to a memory blob, and saved to disk.
}
