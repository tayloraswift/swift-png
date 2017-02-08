import Glibc
import MaxPNG

public
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

public
func skip_png(_ rpath:RelativePath) throws
{
    let path = unix_path(rpath)
    let _ = try PNGDecoder(path: path, look_for: [])
}

public
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

public
func process_png(_ rpath:RelativePath, output:RelativePath) throws
{
    let path = unix_path(rpath)
    let out = unix_path(output)
    let png_decode = try PNGDecoder(path: path)
    let png_encode = try PNGEncoder(path: out, header: png_decode.header)
    try png_encode.initialize()
    let total_scanlines = png_decode.header.height
    var l = 0
    print("0 %")
    while let scanline = try png_decode.next_scanline()
    {
        l += 1
        try png_encode.add_scanline(scanline)
        if (l % 64) == 0
        {
            print("\(Double(l)/Double(total_scanlines) * 100) %")
        }
    }
    try png_encode.finish()
    print("100 %")
}
