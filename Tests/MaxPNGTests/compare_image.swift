import Glibc
import MaxPNG

public
func test_images_identical(_ img_path1:RelativePath, _ img_path2:RelativePath) throws -> Bool
{
    let path1:Unixpath = unix_path(img_path1)
    let path2:Unixpath = unix_path(img_path2)

    let png_decode1 = try PNGDecoder(path: path1)
    let png_decode2 = try PNGDecoder(path: path2)
    var png_data1:[[UInt8]] = [],
        png_data2:[[UInt8]] = []
    while let scanline = try png_decode1.next_scanline()
    {
        png_data1.append(scanline)
    }
    while let scanline = try png_decode2.next_scanline()
    {
        png_data2.append(scanline)
    }
    if png_decode1.header.interlace
    {
        png_data1 = try deinterlace(scanlines: png_data1, header: png_decode1.header)
    }
    if png_decode2.header.interlace
    {
        png_data2 = try deinterlace(scanlines: png_data2, header: png_decode2.header)
    }

    guard png_data1.count == png_data2.count
    else
    {
        return false
    }
    for (l1, l2):([UInt8], [UInt8]) in zip(png_data1, png_data2)
    {
        if l1 != l2
        {
            return false
        }
    }
    return true
}
