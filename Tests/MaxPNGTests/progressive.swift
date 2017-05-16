@testable import MaxPNG

func decode_png_progressive(posix_path:String) throws -> ([[UInt8]], PNGHeader)
{
    let progressive = try PNGDecoder(path: posix_path)
    var png_data:[[UInt8]] = []
    png_data.reserveCapacity(progressive.header.height)
    while let scanline = try progressive.next_scanline()
    {
        png_data.append(scanline)
    }

    return (png_data, progressive.header)
}

public
func decode_png_progressive(relative_path:String) throws -> ([[UInt8]], PNGHeader)
{
    return try decode_png_progressive(posix_path: posix_path(relative_path))
}
