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

func read_png(_ rpath:RelativePath) throws
{
    let path = unix_path(rpath)
    let png = try PNGDataIterator(path: path)

    let total_samples = png.header.height*png.header.width*png.header.channels
    var o = 0
    var l = 0
    while let b = try png.next(png.header.width*3 + 1)
    {
        o += b.count
        l += 1
        if (l % 16) == 0
        {
            print("\(Double(o)/Double(total_samples) * 100) %")
        }
    }
    print("100 %")
}
