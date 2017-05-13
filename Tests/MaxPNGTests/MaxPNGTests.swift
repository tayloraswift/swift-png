import Glibc
@testable import MaxPNG

public
func skip_png(_ rpath:String) throws
{
    let path = absolute_unix_path(rpath)
    let _ = try PNGDecoder(path: path, look_for: [])
}

public
func write_png(_ rpath:String, _ scanlines:[[UInt8]], header:PNGImageHeader) throws
{
    let path = absolute_unix_path(rpath)
    let png = try PNGEncoder(path: path, header: header)
    try png.initialize()
    for scanline in scanlines
    {
        try png.add_scanline(scanline)
    }
    try png.finish()
}

public
func reencode_png_stream(_ rpath:String, output:String) throws
{
    let path = absolute_unix_path(rpath)
    let out = absolute_unix_path(output)
    let png_decode = try PNGDecoder(path: path)
    let png_encode = try PNGEncoder(path: out, header: png_decode.header)
    try png_encode.initialize()
    print(png_decode.header)
    print("0 %")
    while let scanline = try png_decode.next_scanline()
    {
        try png_encode.add_scanline(scanline)
    }
    try png_encode.finish()
    print("100 %")
}

public
func decompose_png(_ rpath:String, output:String) throws
{
    let png_decode = try PNGDecoder(path: absolute_unix_path(rpath))
    print(png_decode.header)
    print("0 %")
    var scanlines:[[UInt8]] = []
    scanlines.reserveCapacity(png_decode.header.height)
    while let scanline = try png_decode.next_scanline()
    {
        scanlines.append(scanline)
    }
    print("100 %")

    let out = absolute_unix_path(output)
    var l:Int = 0
    for (offset: i, element: (width: h, height: k)) in png_decode.header.sub_dimensions.dropLast().enumerated()
    {
        let frag_header = try PNGImageHeader(width: h, height: k,
                                            bit_depth: png_decode.header.bit_depth,
                                            color_type: png_decode.header.color_type,
                                            interlace: false)
        let png_encode = try PNGEncoder(path: "\(out)_subimage_\(i).png", header: frag_header)
        try png_encode.initialize()
        for scanline in scanlines[l..<(l + k)]
        {
            try png_encode.add_scanline(scanline)
        }
        try png_encode.finish()
        l += k
    }

    let deinterlaced_header = try PNGImageHeader(width: png_decode.header.width, height: png_decode.header.height,
                                        bit_depth: png_decode.header.bit_depth,
                                        color_type: png_decode.header.color_type,
                                        interlace: false)
    let deinterlaced_encode = try PNGEncoder(path: out, header: deinterlaced_header)
    try deinterlaced_encode.initialize()
    for scanline in try deinterlace(scanlines: scanlines, header: png_decode.header)
    {
        try deinterlaced_encode.add_scanline(scanline)
    }
    try deinterlaced_encode.finish()
}
