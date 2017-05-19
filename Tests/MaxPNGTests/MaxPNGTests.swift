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

let pink_bold = "\u{001B}[1m\u{001B}[38;5;204m"

let color_off = "\u{001B}[0m"

let TERM_WIDTH:Int = 72

func normalize_and_compare(path_png:String, path_rgba:String, log:inout [String]) -> Bool
{
    guard let (deinterlaced, properties):([UInt8], PNGProperties) = normalize_deinterlace(path: path_png, log: &log)
    else
    {
        return false
    }
    return test_against_rgba64(png_data: deinterlaced, properties: properties, path_rgba: path_rgba, log: &log)
}

func normalize_deinterlace(path:String, log:inout [String]) -> ([UInt8], PNGProperties)?
{
    let (png_raw_data, properties):([UInt8], PNGProperties)
    do
    {
        (png_raw_data, properties) = try png_decode(path: path, recognizing: [.IDAT, .tRNS])
    }
    catch
    {
        log.append(String(describing: error))
        return nil
    }

    if properties.interlaced
    {
        guard let deinterlaced:[UInt8] = properties.deinterlace(raw_data: png_raw_data)
        else
        {
            log.append("InterlaceDimensionError")
            return nil
        }
        return (deinterlaced, properties)
    }
    else
    {
        return (png_raw_data, properties)
    }
}

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
        log.append("RGBA[\(rgba_data_rgba.count)](\(mismatch_index)): \(rgba_data_rgba[mismatch_index ..< min(mismatch_index + 8, rgba_data_rgba.count)])")
        log.append("PNG [\(rgba_data_png.count )](\(mismatch_index)): \(rgba_data_png [mismatch_index ..< min(mismatch_index + 8, rgba_data_png.count )])")
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

public
typealias TestFunc = (String, inout [String]) -> Bool

public
func run_tests(_ tests:[(String, [String], TestFunc)], verbose:Bool, only_run test_subset:Set<String>?) -> Int32
{
    typealias TestRecord = (index: Int, number:String, name:String)

    let test_count:Int      = tests.map{ $0.1.count }.reduce(0, +)
    var test_counter:String = "—— Testing: 0 of \(test_count) tests ——"
    var fail_vector:[TestRecord]   = []
    var pass_vector:[TestRecord]   = []
    var log:[[String]]      = []
    var i:Int               = 0
    if !verbose
    {
        print_progress(percent: 0, text: [(test_counter, light_cyan_bold), ("", nil)], erase: false)
    }
    for (test_group, test_cases, test_func):(String, [String], TestFunc) in tests
    {
        for (j, test_case) in test_cases.enumerated()
        {
            if let test_subset = test_subset, !test_subset.contains(test_case)
            {
                continue
            }
            let record:TestRecord  = (index: i, number: "\(test_group):\(j)", name: test_case)
            let output:(String, String?)
            var log_entry:[String] = []
            if test_func(record.name, &log_entry)
            {
                output = ("(\(record.number)) test '\(record.name)' passed", green_bold)
                pass_vector.append(record)
            }
            else
            {
                output = ("(\(record.number)) test '\(record.name)' failed", red_bold)
                fail_vector.append(record)
            }

            log.append(log_entry)

            if verbose
            {
                print((output.1 ?? "") + output.0 + color_off)
                print(log[i].joined(separator: "\n"))
            }
            else
            {
                test_counter = "—— Testing: \(i + 1) of \(test_count) tests ——"
                print_progress(percent: Double(i)/Double(test_count), text: [(test_counter, light_cyan_bold), output], erase: true)
            }

            i += 1
        }
    }

    let summary:String = "\(pass_vector.count) passed, \(fail_vector.count) failed"
    print_progress(percent: 1, text: [(test_counter, light_cyan_bold), (summary, light_cyan_bold)], erase: true && !verbose)
    print()

    if !verbose
    {
        for (index: i, number: number, name: name) in fail_vector
        {
            print(red_bold + "[\(i)] (\(number)) test '\(name)' failed" + color_off)
            print(log[i].joined(separator: "\n"))
            print()
        }
    }

    if fail_vector.count == 0 && pass_vector.count > 0
    {
        print_centered("<13", color: pink_bold)
    }

    return Int32(fail_vector.count)
}

public
let tests:[(String, [String], TestFunc)] =
[
    ("argb32", decode_test_cases, argb32_premultiplied_64_test),
    ("rgba32", decode_test_cases, rgba32_64_test),
    ("decode-unit", decode_test_cases, decode_test),
    ("reencode-unit", decode_test_cases, test_reencode_unit_png),
    ("decompose", ["decompose1"], test_decompose(test_name:log:)),
    ("reencode", ["becky palatte", "taylor", "if red got the grammy", "wildest dreams adam7"], test_reencode_wild_png),
    ("progressive", ["becky palatte", "taylor", "wildest dreams adam7", "if red got the grammy"], test_progressive)
]
