import Glibc
import MaxPNG

public
func test_images_identical(_ img_path1:RelativePath, _ img_path2:RelativePath) throws -> Bool
{
    let path1:Unixpath = unix_path(img_path1)
    let path2:Unixpath = unix_path(img_path2)

    let png_decode1 = try PNGDecoder(path: path1)
    let png_decode2 = try PNGDecoder(path: path2)

    while let scanline1 = try png_decode1.next_scanline()
    {
        guard let scanline2 = try png_decode2.next_scanline()
        else
        {
            return false
        }

        if scanline1 != scanline2
        {
            return false
        }
    }
    return true
}
