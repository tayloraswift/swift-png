# Using iPhone-optimized images

Learn how to read and create iPhone-optimized PNG files, premultiply and straighten alpha, and access packed image data.

## Key terms

-   term *iPhone-optimized image*:
    A PNG file that uses the BGR/BGRA color formats, and omits the modular redundancy check from the compressed image data stream. iPhone-optimized images are designed to be computationally efficient for iPhone hardware, and are sometimes (rarely) more space-efficient than standard PNG images.

-   term *modular redundancy check*:
    A checksum algorithm used to detect errors in data transmission. The modular redundancy check is omitted from iPhone-optimized images. See [Adler-32](https://en.wikipedia.org/wiki/Adler-32).

-   term *BGR/BGRA color format*:
    The native color format of an iPhone. It is used to blit image data to the iPhone’s graphics hardware without having to do as much post-processing on it.

-   term *premultiplied alpha*:
    A pixel encoding where the color samples are scaled by the alpha sample. This improves compression by zeroing-out all color channels in fully-transparent pixels.

-   term *straight alpha*:
    A pixel encoding where the color samples are not scaled by the alpha sample. This is the normal PNG pixel encoding.

## Worked example

As of version 4.0, this library has first-class support for **iPhone-optimized images**. iPhone-optimized images are a proprietary Apple extension to the PNG standard. Sometimes people refer to them as *CgBI images*. This name comes from the ``PNG/Chunk/CgBI`` application chunk present at the beginning of such files, whose name in turn comes from the [`CGBitmapInfo`](https://developer.apple.com/documentation/coregraphics/cgbitmapinfo) option set in the Apple Core Graphics framework.

iPhone-optimized images are occasionally more space-efficient than standard PNG images, because the color model they use (discussed shortly) quantizes away color information that the user will never see. It is a common misconception that iPhone-optimized images are optimized for file size. They are mainly optimized for computational efficiency, by omitting the **modular redundancy check** from the compressed image data stream. ([Some authors](https://iphonedevwiki.net/index.php/CgBI_file_format) erroneously refer to it as the *cyclic redundancy check*, which is a distinct concept, and completely unaffected by iPhone optimizations.) iPhone-optimized images also use the **BGR/BGRA color formats**, the latter of which is the native color format of an iphone. This makes it possible to blit image data to an idevice’s graphics hardware without having to do as much post-processing on it.

First-class support means that the library supports iPhone-optimized images out of the box. Most PNG libraries such as *libpng* require third-party plugins to handle them, since there is some debate in the open source community over whether such images should be considered real PNG files. *Swift PNG* is, of course, a Swift library, so it supports them anyway, on all platforms, including non-Apple platforms. A possible use case is to have a Linux server serve iPhone-optimized images to an iOS client, thus reducing battery consumption on users’ devices.

In this tutorial, we will convert the following iphone-optimized image to a standard PNG file, and then convert it back into an iphone-optimized image.

@Image(source: "iPhoneOptimized.png", alt: "iphone-optimized example") {
    An iPhone-optimized example image. Unless you are using Safari, your browser most likely cannot display this image. If you are on an Apple platform, you can download this file and view it normally.

    Source: [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Soviet_Union-1963-stamp-Valentina_Vladimirovna_Tereshkova.jpg)
}

You don’t need any special settings to handle iPhone-optimized images. You can decode them as you would any other PNG file.

@Snippet(id: "iPhoneOptimized", slice: "LOAD_EXAMPLE")

We can check if a file is an iphone-optimized image by inspecting its color format.

@Snippet(id: "iPhoneOptimized", slice: "INSPECT_FORMAT")

```
bgra8(palette: [], fill: nil)
```

The ``PNG/Format/bgra8(palette:fill:)`` format is one of two iPhone-optimized color formats. It is analogous to the ``PNG/Format/rgba8(palette:fill:)`` format. Another possibility is ``PNG/Format/bgr8(palette:fill:key:)``, which lacks an alpha channel, and is analogous to ``PNG/Format/rgb8(palette:fill:key:)``.

We can unpack iPhone-optimized images to any color target. iPhone-optimized images use [*premultiplied alpha*](#st:premultiplied-alpha). We can convert the pixels back to **straight alpha** using the ``PNG/RGBA.straightened`` or ``PNG/VA.straightened`` computed properties.

@Snippet(id: "iPhoneOptimized", slice: "STRAIGHTEN")

It is often convenient to work in the premultiplied color space, so the library does not straighten the alpha automatically. Of course, it’s also unnecessary to straighten the alpha if you know the image has no transparency.

>   Note:
>   Unpacking BGRA images to a scalar target discards the alpha channel, making it impossible to straighten the grayscale pixels. If you trying to unpack grayscale values from an iPhone-optimized image with transparency, unpack it to the [`PNG.VA<T>`](PNG/VA) color target, and take the gray channel *after* straightening the grayscale-alpha pixels.

Depending on your use case, you may not be getting the most out of iPhone-optimized images by unpacking them to a color target. As mentioned previously, the iPhone-optimized format is designed such that the raw, packed image data can be uploaded directly to the graphics hardware. You can access the packed data buffer through the ``PNG/Image.storage`` property.

@Snippet(id: "iPhoneOptimized", slice: "INSPECT_STORAGE")

```swift
[25, 0, 1, 255, 16, 8, 8, 255, 8, 0, 16, 255, 32, 13, 0, 255]
```

We can convert the iPhone-optimized example image to a standard PNG file by re-encoding it as any of the standard color formats.

@Snippet(id: "iPhoneOptimized", slice: "REENCODE_RGB")

@Image(source: "iPhoneOptimized-rgb8.png", alt: "output png") {
    The iPhone-optimized example image, re-encoded as a standard PNG file.
}

We can convert it back into an iPhone-optimized image by specifying one of the iphone-optimized color formats. The ``PNG/RGBA.premultiplied`` property converts the pixels to the premultiplied color space. Again, this step is unnecessary if you know the image contains no transparency.

@Snippet(id: "iPhoneOptimized", slice: "REENCODE_BGR")

@Image(source: "iPhoneOptimized-bgr8.png", alt: "output png") {
    The previous output, re-encoded as an iPhone-optimized file. Unless you are using Safari, your browser most likely cannot display this image. Some versions of Safari have a bug which reverses the color channels. If you are on an Apple platform, you can download this file and view it normally.
}

The ``PNG/RGBA.premultiplied`` and ``PNG/RGBA.straightened`` properties satisfy the condition that `x.premultiplied == x.premultiplied.straightened.premultiplied` for all `x`.

>   Warning:
>   Alpha premultiplication is a destructive operation. It is **not** the case that `x == x.premultiplied.straightened` for all `x`!
