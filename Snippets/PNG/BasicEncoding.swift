//  In this example code, we have loaded pixel data from a raw `.rgba` data file using the
//  library’s [file system APIs](/PNG/System/File). As previously mentioned, these APIs are only
//  available on MacOS and Linux.

//  snippet.LOAD_RGBA
import PNG

let path:String = "Sources/PNG/docs.docc/BasicEncoding/BasicEncoding"
let size:(x:Int, y:Int) = (638, 425)

guard
let rgba:[PNG.RGBA<UInt8>] = (System.File.Source.open(path: "\(path).rgba")
{
    guard
    let data:[UInt8] = $0.read(count: 4 * size.x * size.y)
    else
    {
        fatalError("failed to read from file '\(path).rgba'")
    }

    return (0 ..< size.x * size.y).map
    {
        (i:Int) -> PNG.RGBA<UInt8> in
        .init(data[4 * i], data[4 * i + 1], data[4 * i + 2], data[4 * i + 3])
    }
})
else
{
    fatalError("failed to open file '\(path).rgba'")
}

//  snippet.LAYOUT

let layout:(rgb:PNG.Layout, v:PNG.Layout) =
(
    rgb:    .init(format: .rgb8(palette: [], fill: nil, key: nil)),
    v:      .init(format:   .v8(             fill: nil, key: nil))
)

//  snippet.end

do
{
    //  snippet.PACK_RGB
    let image:PNG.Image  = .init(packing: rgba, size: size, layout: layout.rgb)
    //  snippet.COMPRESS_RGB
    try image.compress(path: "\(path)-color-rgb.png", level: 9)
    //  snippet.COMPRESS_RGB_LEVELS
    for level:Int in [0, 4, 8, 13]
    {
        try image.compress(path: "\(path)-color-rgb@\(level).png", level: level)
    }
    //  snippet.end
}
do
{
    //  snippet.SAVE_V
    let image:PNG.Image  = .init(packing: rgba, size: size, layout: layout.v)
    try image.compress(path: "\(path)-color-v.png", level: 9)
    //  snippet.end
}

//  snippet.COMPUTE_LUMINANCE
let luminance:[UInt8] = rgba.map
{
    let r:Double = .init($0.r),
        g:Double = .init($0.g),
        b:Double = .init($0.b)
    let l:Double = (0.299 * r * r + 0.587 * g * g + 0.114 * b * b).squareRoot()
    return .init(max(0, min(l.rounded(), 255)))
}
do
{
    //  snippet.SAVE_V_LUMINANCE
    let image:PNG.Image  = .init(packing: luminance, size: size, layout: layout.v)
    try image.compress(path: "\(path)-luminance-v.png", level: 9)
    //  snippet.end
}
do
{
    //  snippet.SAVE_RGB_LUMINANCE
    let image:PNG.Image  = .init(packing: luminance, size: size, layout: layout.rgb)
    try image.compress(path: "\(path)-luminance-rgb.png", level: 9)
    //  snippet.end
}
