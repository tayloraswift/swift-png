import Glibc
@testable import MaxPNG

func load_rgba_data<Pixel:UnsignedInteger>(absolute_path:String, n_pixels:Int) -> [RGBA<Pixel>]
{
    guard let stream:FilePointer = fopen(absolute_path, "rb")
    else
    {
        fatalError("Failed to read rgba file '\(absolute_path)'\n")
    }
    defer { fclose(stream) }

    var pixel_data = [RGBA<Pixel>](repeating: RGBA(0, 0, 0, 0), count: n_pixels)
    guard fread(&pixel_data, MemoryLayout<RGBA<Pixel>>.stride, n_pixels, stream) == n_pixels
    else
    {
        fatalError("Failed to read rgba file '\(absolute_path)'\n")
    }

    return pixel_data
}

func test_decoded_identical(relative_path_png:String, relative_path_rgba:String) throws -> Bool
{
    let (png_data, png_header):([UInt8], PNGHeader) = try decode_png_contiguous(relative_path: relative_path_png)
    let rgba_data_png:[RGBA<UInt16>] = rgba32(raw_data: png_data, header: png_header)!.map
    {
        let r:UInt16 = UInt16($0.r),
            g:UInt16 = UInt16($0.g),
            b:UInt16 = UInt16($0.b),
            a:UInt16 = UInt16($0.a)
        return RGBA(r << 8 | r, g << 8 | g, b << 8 | b, a << 8 | a)
    }
    let rgba_data_rgba:[RGBA<UInt16>] = load_rgba_data(absolute_path: absolute_unix_path(relative_path_rgba),
                                                       n_pixels: png_header.width * png_header.height)

    return rgba_data_rgba == rgba_data_png
}
