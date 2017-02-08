# maxpng

`maxpng` is written in pure swift with the exception of one dependency on the `zlib` C library. You almost certainly have it on your computer already. `maxpng` contains no calls to this “`Foundation`” of which you speak; its just plain, standard swift.

`maxpng` is simple to use:

````swift
import MaxPNG

let png = try PNGDataIterator(path: "/absolute/path/to/my/png/file.png")

while let scanline = try png.next_scanline()
{
    _do_whatever_you_want(scanline)
}
````

While it works great with PNG files of all sizes, `maxpng` was designed for *big* PNG files. Thats why the default API reads the PNGs scanline by scanline. Feel free to throw giant [NASA space textures](http://visibleearth.nasa.gov/view.php?id=74218) at it. `maxpng` won’t break a sweat; in fact in my tests with NASA’s >400 MB Blue Marble PNGs, `maxpng`’s memory usage never rose above 1.2 MB (yes, that’s MB, as in one megabyte).

One more thing: `maxpng` returns arrays of `UInt8` bytes; it does not split the output into RGB(A) tuples. That’s partly because this is the format most useful for loading the pixel data as textures in OpenGL, Cairo, etc, and partly because you don’t know the layout of the PNG until after you decode its first chunk. Maybe someday `maxpng` can package the pixel colors for us. For now, all the info you need is in the `.header` member of the `PNGDataIterator` object:

````swift
public
struct PNGImageHeader
{
    public
    enum ColorType:Int
    {
        case grayscale      = 0,
             rgb            = 2,
             indexed        = 3,
             grayscale_a    = 4,
             rgba           = 6
    }

    public
    let width:Int,
        height:Int,
        bit_depth:Int,
        color_type:ColorType,
        interlace:Bool

    public
    let channels:Int
}
````

At the moment, indexed-color and interlaced PNGs are unsupported. Tragic. Hmu on the issues page if you need them.

## FAQ

> Why not use a C PNG decoder like [`libpng`](http://www.libpng.org/pub/png/libpng.html)?

Cause it either a) doesn’t work in Swift, or b) it actually does work but the API is [so](https://bobobobo.wordpress.com/2009/03/02/how-to-use-libpng/) [bad](http://latentcontent.net/2007/12/05/libpng-worst-api-ever/) that I don’t know how to get it to work, which, if you think about it, is just as bad. Either way, `libpng` is written in C. `maxpng` is written in Swift. Yay!

> Why does it depend on `zlib` then?

`zlib` is cute, nice, and friendly, and it’s also pretty much everywhere. I’ve never had a problem with `zlib`. The only other Swift PNG decoder library in existence at the time of writing, [SwiftGL Image](https://github.com/SwiftGL/Image), actually implements its own, pure swift, `INFLATE` algorithm. (Be warned though, it doesn’t compile on Swift ≥3.1.) For me, using `zlib` sounded like a lot less work so I went with that.

> Why does `maxpng` decode my pictures line-by-line?

Some PNGs are so large that loading them into your RAM will make you very sad. These PNGs are not meant to be viewed, rather processed as data for other purposes. (Think satellite scan data.) Reading them line by line avoids this problem by letting you stream the picture in and out of your program while you do your thing (such as downsampling them to something small enough that you *can* view on your screen). At any rate, if you really want the entire image, you can just dump the scanline buffers into one big buffer if you have the memory. There’s no extra overhead to that — every PNG decoder works like that internally.

> Why did it “skip” `nUGZ`??? That’s my favorite chunk!!!

Right now, `maxpng` only recognizes the chunks `IHDR`, `IDAT`, and `IEND`. `PLTE` is ignored but it would probably take about an afternoon or two to implement; I’m just lazy because I have seen maybe 5 indexed PNGs in my entire life. Most of the ancillary PNG chunks are actually trivial to implement and add to `maxpng` (they just involve casting bytes to integers and binding them to structs), I just haven’t gotten around to it.

> Wait, `maxpng` lets you skip `IDAT`??? Why would you ever want to do that?

By default, `maxpng` will decode the image pixel data, but if you pass `PNGDataIterator.init()` an empty array in its `look_for:[PNGChunkType]` field, it will ignore the pixel data chunks. Sometimes you want to do this if, for example, you just want to get the dimensions of the PNG file. Decoding the pixel data we don’t care about would just be a waste of time.

> Does `maxpng` do gamma correction?

No. Gamma is meant to be applied at the image *display* stage. `maxpng` only gives you the raw, integer color data in the file. Gamma is also easy to apply to raw color data but computationally expensive to remove. Some PNGs include gamma data in a chunk called `gAMA`, but most don’t, and viewers will just apply a `γ = 2.2` regardless. `maxpng` doesn’t read `gAMA` right now.
