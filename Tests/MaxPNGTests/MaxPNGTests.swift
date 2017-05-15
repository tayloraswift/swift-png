import Glibc
@testable import MaxPNG

let bold = "\u{001B}[1m"
let green = "\u{001B}[0;32m"
let green_bold = "\u{001B}[1;32m"

let light_green = "\u{001B}[92m"
let light_green_bold = "\u{001B}[1;92m"

let red = "\u{001B}[0;31m"
let red_bold = "\u{001B}[1;31m"

let color_off = "\u{001B}[0m"

let TERM_WIDTH:Int = 64

func print_progress(percent:Double, width:Int, eraser:String = "\r")
{
    let bar_width:Int = width - 6
    let percent_label:String = "\(Int(percent * 100))%"
    print(eraser, terminator: "")
    for _ in 0...(4 - percent_label.characters.count)
    {
        fputc(0x20, stdout)
    }
    print("\(percent_label) \(green)[\(light_green_bold)", terminator: "")
    let bar_segments:Int = Int(percent * Double(bar_width))
    for _ in 0..<bar_segments
    {
        fputc(Int32(UnicodeScalar("=")!.value), stdout)
    }
    for _ in bar_segments..<bar_width
    {
        fputc(Int32(UnicodeScalar("-")!.value), stdout)
    }
    print("\(color_off)\(green)]\(color_off)", terminator: "")
    fflush(stdout)
}

public
func skip_png(_ rpath:String) throws
{
    let path = absolute_unix_path(rpath)
    let _ = try PNGDecoder(path: path, look_for: [])
}

public
func write_png(_ rpath:String, _ scanlines:[[UInt8]], header:PNGHeader) throws
{
    let path = absolute_unix_path(rpath)
    let png = try PNGEncoder(path: path, header: header)
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
    print(png_decode.header)

    var i:Int = 0
    print_progress(percent: 0, width: TERM_WIDTH, eraser: "")
    while let scanline = try png_decode.next_scanline()
    {
        i += 1
        try png_encode.add_scanline(scanline)
        print_progress(percent: Double(i) / Double(png_decode.header.height), width: TERM_WIDTH)
    }
    try png_encode.finish()
    print("")
}

public
func decompose_png(_ rpath:String, output:String) throws
{
    let png_decode = try PNGDecoder(path: absolute_unix_path(rpath))
    print(png_decode.header)
    var scanlines:[[UInt8]] = []
    scanlines.reserveCapacity(png_decode.header.height)
    var i:Int = 0
    let interlace_scanlines:Double = Double(png_decode.header.sub_dimensions.dropLast().map{ $0.height }.reduce(0, +))
    print_progress(percent: 0, width: TERM_WIDTH, eraser: "")
    while let scanline = try png_decode.next_scanline()
    {
        i += 1
        scanlines.append(scanline)
        print_progress(percent: Double(i) / interlace_scanlines, width: TERM_WIDTH)
    }
    print("")

    let out = absolute_unix_path(output)
    var l:Int = 0
    for (offset: i, element: (width: h, height: k)) in png_decode.header.sub_dimensions.dropLast().enumerated()
    {
        let frag_header = try PNGHeader(width: h, height: k,
                                        bit_depth: png_decode.header.bit_depth,
                                        color_type: png_decode.header.color_type,
                                        interlace: false)
        let png_encode = try PNGEncoder(path: "\(out)_subimage_\(i).png", header: frag_header)
        for scanline in scanlines[l..<(l + k)]
        {
            try png_encode.add_scanline(scanline)
        }
        try png_encode.finish()
        l += k
    }

    let deinterlaced_header = try PNGHeader(width: png_decode.header.width, height: png_decode.header.height,
                                            bit_depth: png_decode.header.bit_depth,
                                            color_type: png_decode.header.color_type,
                                            interlace: false)
    let deinterlaced_encode = try PNGEncoder(path: out, header: deinterlaced_header)
    for scanline in try deinterlace(scanlines: scanlines, header: png_decode.header)
    {
        try deinterlaced_encode.add_scanline(scanline)
    }
    try deinterlaced_encode.finish()
}
