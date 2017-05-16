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

func load_rgba_data<Pixel:UnsignedInteger>(path:String, n_pixels:Int) -> [RGBA<Pixel>]
{
    guard let stream:FilePointer = fopen(posix_path(path), "rb")
    else
    {
        fatalError("Failed to read rgba file '\(posix_path(path))'")
    }
    defer { fclose(stream) }

    var pixel_data = [RGBA<Pixel>](repeating: RGBA(0, 0, 0, 0), count: n_pixels)
    guard fread(&pixel_data, MemoryLayout<RGBA<Pixel>>.stride, n_pixels, stream) == n_pixels
    else
    {
        fatalError("Failed to read rgba file '\(posix_path)'")
    }

    return pixel_data
}

func test_against_rgba64(png_data:[UInt8], header:PNGHeader, path_rgba:String) -> Bool
{
    guard let rgba_data_png:[RGBA<UInt16>] = header.rgba64(raw_data: png_data)
    else
    {
        return false
    }

    let rgba_data_rgba:[RGBA<UInt16>] = load_rgba_data(path: path_rgba,
                                                       n_pixels: header.width * header.height)

    if rgba_data_rgba != rgba_data_png
    {
        print("RGBA(\(rgba_data_rgba.count)) : \(rgba_data_rgba[0...7])")
        print("PNG (\(rgba_data_png.count )) : \(rgba_data_png[0...7])")
    }

    return rgba_data_rgba == rgba_data_png
}

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
func reencode_png(_ path:String, output:String) throws
{
    let (png_data, png_header):([UInt8], PNGHeader) = try decode_png(path: path)
    print(png_header)

    print_progress(percent: 0, width: TERM_WIDTH, eraser: "")
    try encode_png(path: output, raw_data: png_data, header: png_header)
    print_progress(percent: 1, width: TERM_WIDTH)
    print()
}
