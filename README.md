# maxpng

`maxpng` is written in pure swift with the exception of one dependency on the `zlib` C library. You almost certainly have it on your computer already. `maxpng` contains no calls to this “`Foundation`” of which you speak; its just plain, standard swift.

`maxpng` is simple to use:

````swift
import MaxPNG

let png = try PNGDataIterator(path: "/absolute/path/to/my/png/file.png")

while let scanline = try png.next()
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

At the moment, indexed-color PNGs are unsupported. Tragic. Hmu on the issues page if you need them.
