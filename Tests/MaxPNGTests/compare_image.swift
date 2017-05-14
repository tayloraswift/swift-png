import Glibc
@testable import MaxPNG

public
func test_images_identical(_ path1:String, _ path2:String) throws -> Bool
{
    let (png_data1, _):([UInt8], PNGHeader) = try decode_png_contiguous(relative_path: path1),
        (png_data2, _):([UInt8], PNGHeader) = try decode_png_contiguous(relative_path: path2)
    return png_data1 == png_data2
}
