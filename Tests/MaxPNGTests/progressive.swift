@testable import MaxPNG

func decode_png_progressive(path:String) throws -> ([[UInt8]], PNGProperties)
{
    let progressive = try PNGDecoder(path: path)
    var png_data:[[UInt8]] = []
    png_data.reserveCapacity(progressive.properties.height)
    while let scanline = try progressive.next_scanline()
    {
        png_data.append(scanline)
    }

    return (png_data, progressive.properties)
}
