import Glibc
@testable import MaxPNG

struct RGBA<Pixel:UnsignedInteger>:CustomStringConvertible
{
    let r:Pixel,
        g:Pixel,
        b:Pixel,
        a:Pixel

    var description:String
    {
        return "(\(self.r), \(self.g), \(self.b), \(self.a))"
    }
}

func load_rgb_data<Pixel:UnsignedInteger>(absolute_path:String, npixels:Int) -> [RGBA<Pixel>]
{
    guard let stream:FilePointer = fopen(absolute_path, "rb")
    else
    {
        fatalError("Failed to read rgba file '\(absolute_path)'\n")
    }
    defer { fclose(stream) }

    var pixel_data = [RGBA<Pixel>](repeating: RGBA(r: 0, g: 0, b: 0, a: 0), count: npixels)
    guard fread(&pixel_data, MemoryLayout<RGBA<Pixel>>.stride, npixels, stream) == npixels
    else
    {
        fatalError("Failed to read rgba file '\(absolute_path)'\n")
    }

    return pixel_data
}
