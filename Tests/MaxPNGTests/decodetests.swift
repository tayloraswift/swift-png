import Glibc
@testable import MaxPNG

func load_rgb_data<Pixel:UnsignedInteger>(absolute_path:String, n_pixels:Int) -> [RGBA<Pixel>]
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
