import Glibc
@testable import MaxPNG

public
func test_images_identical(_ path1:String, _ path2:String) throws -> Bool
{
    let (png_data1, _):([[UInt8]], PNGHeader) = try decode_png(relative_path: path1),
        (png_data2, _):([[UInt8]], PNGHeader) = try decode_png(relative_path: path2)

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
