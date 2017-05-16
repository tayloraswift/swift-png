@testable import MaxPNG

func decode_png_progressive(absolute_path:String) throws -> ([[UInt8]], PNGHeader)
{
    let png_decode = try PNGDecoder(path: absolute_path)
    var png_data:[[UInt8]] = []
    png_data.reserveCapacity(png_decode.header.height)
    while let scanline = try png_decode.next_scanline()
    {
        png_data.append(scanline)
    }

    if png_decode.header.interlace
    {
        png_data = try deinterlace(scanlines: png_data, header: png_decode.header)
    }

    return (png_data, png_decode.header)
}

public
func decode_png_progressive(relative_path:String) throws -> ([[UInt8]], PNGHeader)
{
    return try decode_png_progressive(absolute_path: absolute_unix_path(relative_path))
}
