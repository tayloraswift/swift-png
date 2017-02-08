import Glibc
@testable import MaxPNG

typealias RelativePath = String
typealias Unixpath = String

func unix_path(_ path:RelativePath) -> Unixpath
{
    guard path.characters.count > 1
    else {
        return path
    }
    let path_i0 = path.startIndex
    let path_i2 = path.index(path_i0, offsetBy: 2)
    var expanded_path:Unixpath = path
    if path[path.startIndex..<path_i2] == "~/" {
        expanded_path = String(cString: getenv("HOME")) +
                        path[path.index(path_i0, offsetBy: 1)..<path.endIndex]
    }
    return expanded_path
}

func skip_png(_ rpath:RelativePath) throws
{
    let path = unix_path(rpath)
    let _ = try PNGDecoder(path: path, look_for: [])
}

func read_png(_ rpath:RelativePath) throws
{
    let path = unix_path(rpath)
    let png = try PNGDecoder(path: path)

    let total_samples = png.header.height*png.header.width*png.header.channels
    var o = 0
    var l = 0
    while let b = try png.next_scanline()
    {
        o += b.count
        l += 1
        if (l % 64) == 0
        {
            print("\(Double(o)/Double(total_samples) * 100) %")
        }
    }
    print("100 %")
}

func read_png_into_buffer(_ rpath:RelativePath) throws -> (PNGImageHeader, [[UInt8]])
{
    let path = unix_path(rpath)
    let png = try PNGDecoder(path: path)

    let total_samples = png.header.height*png.header.width*png.header.channels
    var o = 0
    var l = 0
    var scanlines:[[UInt8]] = []
    while let b = try png.next_scanline()
    {
        o += b.count
        l += 1
        if (l % 64) == 0
        {
            print("\(Double(o)/Double(total_samples) * 100) %")
        }
        scanlines.append(b)
    }
    print("100 %")
    return (png.header, scanlines)
}

func write_png(_ rpath:RelativePath, _ scanlines:[[UInt8]], header:PNGImageHeader) throws
{
    let path = unix_path(rpath)
    let png = try PNGEncoder(path: path, header: header)
    try png.initialize()
    for scanline in scanlines
    {
        try png.add_scanline(scanline)
    }
    try png.finish()
}
