# ``/LZ77``

This module contains a pure-Swift implementation of the LZ77 algorithm. It supports the bare
`deflate` (`zlib`) archive format, as well as the more-popular `gzip` format.

## Topics

### Gzip compression

The simplest way to compress data is to use the ``Gzip.archive(bytes:level:hint:)`` convenience
method.

@Snippet(id: "BasicGzip", slice: "ARCHIVE")

You can extract data from a gzip archive with the ``Gzip.extract(from:)`` convenience method.

@Snippet(id: "BasicGzip", slice: "EXTRACT")

-   ``Gzip``
-   ``Gzip.archive(bytes:level:hint:)``
-   ``Gzip.extract(from:)``

### Gzip streaming

High-volume use cases may require streaming data in and out of an archive. You can use the
``Gzip.Inflator`` and ``Gzip.Deflator`` types to do this.

You inflate gzip streams by pushing buffers to ``Gzip.Inflator.push(_:)`` while calling
``Gzip.Inflator.pull(_:)`` repeatedly to extract the decompressed data. This method returns nil
if the requested amount of data is not yet available.

It is also possible to wait until you have pushed all the buffers and then call
``Gzip.Inflator.pull()`` once to obtain all of the decompressed data, although in this situation
it would make more sense to use ``Gzip.extract(from:)`` instead.

@Snippet(id: "StreamingGzip", slice: "INFLATE")

#### Inflator methods

-   ``Gzip.Inflator``
-   ``Gzip.Inflator.push(_:)``
-   ``Gzip.Inflator.pull(_:)``
-   ``Gzip.Inflator.pull()``

Compressing data to a stream follows a similar pattern, except you need to tell
``Gzip.Deflator.push(_:last:)`` which input buffer is the final buffer in the stream.

@Snippet(id: "StreamingGzip", slice: "DEFLATE")

The compressed data comes out of ``Gzip.Deflator.pull()`` in blocks. Depending on how you are
synchronizing the input and output streams, it may also be more performant to call
``Gzip.Deflator.pop()`` instead, which avoids buffer flushes but is more complicated to
synchronize.

@Snippet(id: "StreamingGzip", slice: "WRITE")

#### Deflator methods

-   ``Gzip.Deflator``
-   ``Gzip.Deflator.push(_:last:)``
-   ``Gzip.Deflator.pull()``
-   ``Gzip.Deflator.pop()``


### Zlib compression

DEFLATE, or “zlib” compression is a nearly-identical form of compression to gzip, which uses the
same algorithm but with a different header format. It has slightly less overhead than gzip, but
is also less widely supported.

-   ``LZ77``
