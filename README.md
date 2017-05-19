# maxpng

[![Build](https://travis-ci.org/kelvin13/maxpng.svg?branch=master)](https://travis-ci.org/kelvin13/maxpng)
[![Issues](https://img.shields.io/github/issues/kelvin13/maxpng.svg)](https://github.com/kelvin13/maxpng/issues?state=open)
[![Language](https://img.shields.io/badge/version-swift_3-ffa020.svg)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-GPL3-ff3079.svg)](https://github.com/kelvin13/maxpng/blob/master/LICENSE.gpl3)
[![Queen](https://img.shields.io/badge/taylor-swift-e030ff.svg)](https://www.google.com/search?q=where+is+ts6&oq=where+is+ts6)

An efficient, powerful, safe, and free PNG library, written in pure Swift. MaxPNG is 

### *…modern*

MaxPNG is written in pure Swift, and it has a dependency on just a single C library — [zlib](http://www.zlib.net/). MaxPNG makes no reference to slow, legacy Objective C frameworks, in fact, it doesn’t even import Foundation. You get the benefit of a comfortable Swift API, without the overhead of aging Apple frameworks. MaxPNG is actively maintained, and builds on the latest Swift 3.1.

### *…easy to use*

Decode or encode a PNG file in just one function call.

````swift
import MaxPNG

let (png_raw_data, png_properties):([UInt8], PNGProperties) = try png_decode(path: "my_png_file.png")
````

````swift
let my_png_settings = PNGProperties(width: 3, height: 3, bit_depth: 8, color: .rgb, interlaced: false)
let my_png_data:[UInt8] = [0  ,0  ,0  ,    255,255,255,    255,0  ,255,
                           255,255,255,    0  ,0  ,0  ,    0  ,255,0  ,
                           120,120,255,    150,120,255,    180,120,255]
try png_encode(path: "my_output_png.png", raw_data: my_png_data, properties: my_png_settings)
````
MaxPNG’s entire public API is [documented](doc/maxpng.md).

MaxPNG is batteries-included, providing several utility [functions](doc/pngproperties.md#instance-methods) that will deinterlace and normalize image data, turning any PNG file into an array of RGBA samples. In most cases, MaxPNG’s default output can even be sent directly to a graphics API such as OpenGL.

### *…powerful*

MaxPNG includes a progressive API that reads and writes PNGs scanline by scanline, allowing you to process enormous PNG files. The progressive decoder and encoder objects also clean up after themselves, so you never have to worry about closing file streams or managing zlib internal state.

````swift
let png = try PNGDecoder(path: "my_png_file.png")
let out = try PNGEncoder(path: "my_resaved_png.png", properties: png.properties)

while let scanline = try png.next_scanline()
{
    try out.add_scanline(scanline)
}
try out.finish()
````
### *…safe*

MaxPNG is written in pure Swift, and so it should behave like a Swift library. Its decoder is fully standards-compliant, passing all 161 official PNG [unit tests](http://www.schaik.com/pngsuite/pngsuite.html#basic), among others. It supports interlacing, indexed color, and even chroma key transparency. MaxPNG also throws [errors](doc/pngerrors.md) like a Swift library should, minimizing the chance that you’ll end up with a corrupt PNG.

### *…free*

MaxPNG was built on Linux, and developed on github from the start. It has nothing to do with Apple, or any Apple framework, even Foundation. I created it because there was [no existing, maintained](#swift-png-parser) open source Swift PNG library.

## FAQ

### Usage

> What’s the difference between bit depth and color type?

Color type refers to the channels present in a PNG. A grayscale PNG has only one color channel, while an RGB PNG has three (red, green, and blue). An RGBA PNG has four — three color channels, plus one alpha channel. Similarly, a grayscale–alpha PNG has two — one grayscale “color” channel and one alpha channel. An indexed-color PNG (unsupported) has one encoded channel in the image data, but the colors the indices represent are always RGB triples. The vast majority of PNGs in the world are either of color type RGB or RGBA.

Bit depth goes one level lower; it represents the size of each *channel*. A PNG with a bit depth of `8` has `8` bits per channel. Hence, one pixel of an RGBA PNG is `4 * 8 = 32` bits long, or `4` bytes.

> What does interlacing mean?

[Interlacing](https://en.wikipedia.org/wiki/Interlacing_(bitmaps)) is a way of progressivly ordering the image data in a PNG so it can be displayed at lower resolution even when partially downloaded. Interlacing is common in images downloaded from social media such as Instagram or Twitter, but rare elsewhere. Interlacing hurts compression, and so it usually significantly increases the size of a PNG file, sometimes as much as thirty percent.

MaxPNG will read interlaced images as a series of subimage scanlines. To recover a rectangular pixel array, you should pass the interlaced scanlines into the provided `PNGProperties` member function `.deinterlace(raw_data:)` function.

> How do I deinterlace an interlaced PNG?

Use `PNGProperties`’s member function `.deinterlace(raw_data:)`.

````swift
PNGProperties › func deinterlace(raw_data:[UInt8]) -> [UInt8]?
````
The scanlines passed in the scanline array must be in [ADAM7 order](https://en.wikipedia.org/wiki/Adam7_algorithm), and their sizes must agree with the bit depth and color format parameters passed through the `PNGProperties` struct.

### General

> Why not use a C PNG decoder like [`libpng`](http://www.libpng.org/pub/png/libpng.html)?

Cause it either a) doesn’t work in Swift, or b) it actually does work but the API is [so](https://bobobobo.wordpress.com/2009/03/02/how-to-use-libpng/) [bad](http://latentcontent.net/2007/12/05/libpng-worst-api-ever/) that I don’t know how to get it to work, which, if you think about it, is just as bad. Either way, `libpng` is written in C. MaxPNG is written in Swift. Yay!

> Why does it depend on `zlib` then?

ZLib is a standard compression/decompression library that is installed by default on most Linux systems. The only other Swift PNG decoder library in existence at the time of writing, [SwiftGL Image](https://github.com/SwiftGL/Image), actually implements its own, pure Swift, `INFLATE` algorithm. (Be warned though, it doesn’t compile on Swift ≥3.1.) For me, using ZLib sounded like a lot less work so I went with that.

> What is the progressive API good for?

Some PNGs are so large that loading them into your RAM will make you very sad. These PNGs are not meant to be viewed, rather processed as data for other purposes. (Think satellite scan data.) Reading them line by line avoids this problem by letting you stream the picture in and out of your program while you do your thing (such as downsampling them to something small enough that you *can* view on your screen).

> Why did it “skip” `nUGZ`??? That’s my favorite chunk!!!

Right now, MaxPNG only recognizes the chunks `IHDR`, `IDAT`, `IEND`, `PLTE`, and `.tRNS`. The other ancillary chunks are currently unrecognized, but still validated for chunk ordering.

> Wait, MaxPNG lets you skip `IDAT`??? Why would you ever want to do that?

By default, MaxPNG will decode the image pixel data, but if you pass `PNGDecoder.init(path:recognizing:)` an empty array in its `recognizing:[PNGChunkType]` field, it will ignore the pixel data chunks. Sometimes you want to do this if, for example, you just want to get the dimensions of the PNG file. Decoding the pixel data we don’t care about would just be a waste of time.

> Does MaxPNG do gamma correction?

No. Gamma is meant to be applied at the image *display* stage. MaxPNG only gives you the raw, integer color data in the file. Gamma is also easy to apply to raw color data but computationally expensive to remove. Some PNGs include gamma data in a chunk called `gAMA`, but most don’t, and viewers will just apply a `γ = 2.2` regardless. MaxPNG doesn’t read `gAMA` right now.

> Can I add extra chunks to my PNG output?

At the moment, no. MaxPNG currently only writes the basic `IHDR`, `IDAT`, `IEND` chunks, and the `PLTE` and `tRNS` chunks if applicable.

> I hate maxpng isnt there any other png encoder/decoder out there i stg

It’s okay, I only wrote MaxPNG because I couldn’t find any good existing free Swift PNG library. Here’s a rundown of some of the alternatives I stumbled across from a simple search of `'swift png'` in the magical github search bar:

> #### [Swift-PNG-Parser](https://github.com/dixielandtech/Swift-PNG-Parser)

Not a library, just a wrapper around the Cocoa framework.

> #### [SimplePNG](https://github.com/rfdickerson/SimplePNG)

Not a library, just a wrapper around `libpng`. Also has no support for decoding PNG files.

> #### [swift-png](https://github.com/llaimiaomiao/swift-png)

This repository was empty. I did however enjoy the github youtube channel

> #### [pinge](https://github.com/Vel0x/Pinge)

Actually one of the most complete Swift PNG libraries I’ve seen. Has no support for encoding PNG files though, and I don’t believe it lets you read by scanline. Also depends on Apple Foundation.

> #### [CompressPicture](https://github.com/chenmo230/CompressPicture)

I have no idea what this repository does.

## Building
Build MaxPNG with the swift package manager, `swift build`. Make sure you have the `zlib` headers on your computer (`sudo apt-get install libz-dev`).
