import Glibc
@testable import MaxPNG

let bold = "\u{001B}[1m"
let green = "\u{001B}[0;32m"
let green_bold = "\u{001B}[1;32m"

let light_green = "\u{001B}[92m"
let light_green_bold = "\u{001B}[1;92m"

let light_cyan = "\u{001B}[96m"
let light_cyan_bold = "\u{001B}[1;96m"

let red = "\u{001B}[0;31m"
let red_bold = "\u{001B}[1;31m"

let color_off = "\u{001B}[0m"

let TERM_WIDTH:Int = 72

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

func test_against_rgba64(png_data:[UInt8], properties:PNGProperties, path_rgba:String, log:inout [String]) -> Bool
{
    guard let rgba_data_png:[RGBA<UInt16>] = properties.rgba64(raw_data: png_data)
    else
    {
        return false
    }

    let rgba_data_rgba:[RGBA<UInt16>] = load_rgba_data(path: path_rgba,
                                                       n_pixels: properties.width * properties.height)

    var pass:Bool = false,
        mismatch_index:Int = 0

    if rgba_data_png.count == rgba_data_rgba.count
    {
        pass = true
        for i:Int in rgba_data_png.indices
        {
            if rgba_data_png[i] != rgba_data_rgba[i]
            {
                mismatch_index = i
                pass = false
                break
            }
        }
    }

    if !pass
    {
        log.append("RGBA[\(rgba_data_rgba.count)](\(mismatch_index)): \(rgba_data_rgba[mismatch_index ..< mismatch_index + 8])")
        log.append("PNG [\(rgba_data_png.count )](\(mismatch_index)): \(rgba_data_png [mismatch_index ..< mismatch_index + 8])")
    }

    return pass
}

func print_centered(_ str:String, color:String?, width:Int = TERM_WIDTH)
{
    print(String(repeating: " ", count: max(0, (width - str.characters.count)) >> 1) + (color ?? "") + str + color_off)
}

func print_progress(percent:Double, text:[(String, String?)], erase:Bool = false, width:Int = TERM_WIDTH)
{
    let bar_width:Int = width - 8
    let percent_label:String = "\(Int(percent * 100))%"
    let percent_padding:String = String(repeating: " ", count: 5 - percent_label.characters.count)

    if erase
    {
        let erasers:String = String(repeating: "\u{001B}[1A\u{001B}[K", count: text.count + 1)
        print(erasers, terminator: "")
    }

    for (str, color):(String, String?) in text
    {
        print_centered(str, color: color, width: width)
    }

    print("\(percent_padding)\(percent_label) \(light_green)[\(light_green_bold)", terminator: "")
    let bar_segments:Int = Int(percent * Double(bar_width))
    print(String(repeating: "=", count: bar_segments) + String(repeating: "-", count: bar_width - bar_segments), terminator: "")
    print("\(color_off)\(light_green)]\(color_off)")
    fflush(stdout)
}
