import MaxPNG

func normalize_and_compare(path_png:String, path_rgba:String, log:inout [String]) -> Bool
{
    let (png_raw_data, png_properties):([UInt8], PNGProperties)
    do
    {
        (png_raw_data, png_properties) = try decode_png(path: path_png, recognizing: [.IDAT, .tRNS])
    }
    catch
    {
        log.append(String(describing: error))
        return false
    }

    let png_data:[UInt8]
    if png_properties.interlaced
    {
        guard let deinterlaced:[UInt8] = png_properties.deinterlace(raw_data: png_raw_data)
        else
        {
            log.append(String(describing: PNGReadError.InterlaceDimensionError))
            return false
        }
        png_data = deinterlaced
    }
    else
    {
        png_data = png_raw_data
    }

    return test_against_rgba64(png_data: png_data, properties: png_properties, path_rgba: path_rgba, log: &log)
}

public
typealias TestFunc = (String, inout [String]) -> Bool

public
func run_tests(_ tests:[(String, [String], TestFunc)], verbose:Bool, only_run test_subset:Set<String>?)
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
}

func decode_test(test_name:String, log:inout [String]) -> Bool
{
    let path_png:String  = "Tests/MaxPNGTests/unit/png/\(test_name).png"
    let path_rgba:String = "Tests/MaxPNGTests/unit/rgba/\(test_name).png.rgba"
    return normalize_and_compare(path_png: path_png, path_rgba: path_rgba, log: &log)
}

let decode_test_cases:[String] =
[
"PngSuite",

"basn0g01",
"basn0g02",
"basn0g04",
"basn0g08",
"basn0g16",
"basn2c08",
"basn2c16",
"basn3p01",
"basn3p02",
"basn3p04",
"basn3p08",
"basn4a08",
"basn4a16",
"basn6a08",
"basn6a16",

"basi0g01",
"basi0g02",
"basi0g04",
"basi0g08",
"basi0g16",
"basi2c08",
"basi2c16",
"basi3p01",
"basi3p02",
"basi3p04",
"basi3p08",
"basi4a08",
"basi4a16",
"basi6a08",
"basi6a16",

"s01i3p01",
"s01n3p01",
"s02i3p01",
"s02n3p01",
"s03i3p01",
"s03n3p01",
"s04i3p01",
"s04n3p01",
"s05i3p02",
"s05n3p02",
"s06i3p02",
"s06n3p02",
"s07i3p02",
"s07n3p02",
"s08i3p02",
"s08n3p02",
"s09i3p02",
"s09n3p02",
"s32i3p04",
"s32n3p04",
"s33i3p04",
"s33n3p04",
"s34i3p04",
"s34n3p04",
"s35i3p04",
"s35n3p04",
"s36i3p04",
"s36n3p04",
"s37i3p04",
"s37n3p04",
"s38i3p04",
"s38n3p04",
"s39i3p04",
"s39n3p04",
"s40i3p04",
"s40n3p04",

"bgai4a08",
"bgai4a16",
"bgan6a08",
"bgan6a16",
"bgbn4a08",
"bggn4a16",
"bgwn6a08",
"bgyn6a16",

"tbbn0g04",
"tbbn2c16",
"tbbn3p08",
"tbgn2c16",
"tbgn3p08",
"tbrn2c08",
"tbwn0g16",
"tbwn3p08",
"tbyn3p08",
"tm3n3p02",
"tp0n0g08",
"tp0n2c08",
"tp0n3p08",
"tp1n3p08",

"g03n0g16",
"g03n2c08",
"g03n3p04",
"g04n0g16",
"g04n2c08",
"g04n3p04",
"g05n0g16",
"g05n2c08",
"g05n3p04",
"g07n0g16",
"g07n2c08",
"g07n3p04",
"g10n0g16",
"g10n2c08",
"g10n3p04",
"g25n0g16",
"g25n2c08",
"g25n3p04",

"f00n0g08",
"f00n2c08",
"f01n0g08",
"f01n2c08",
"f02n0g08",
"f02n2c08",
"f03n0g08",
"f03n2c08",
"f04n0g08",
"f04n2c08",
"f99n0g04",

"pp0n2c16",
"pp0n6a08",
"ps1n0g08",
"ps1n2c16",
"ps2n0g08",
"ps2n2c16",

"ccwn2c08",
"ccwn3p08",
"cdfn2c08",
"cdhn2c08",
"cdsn2c08",
"cdun2c08",
"ch1n3p04",
"ch2n3p08",
"cm0n0g04",
"cm7n0g04",
"cm9n0g04",
"cs3n2c16",
"cs3n3p08",
"cs5n2c08",
"cs5n3p08",
"cs8n2c08",
"cs8n3p08",
"ct0n0g04",
"ct1n0g04",
"cten0g04",
"ctfn0g04",
"ctgn0g04",
"cthn0g04",
"ctjn0g04",
"ctzn0g04",

"oi1n0g16",
"oi1n2c16",
"oi2n0g16",
"oi2n2c16",
"oi4n0g16",
"oi4n2c16",
"oi9n0g16",
"oi9n2c16",

"z00n2c08",
"z03n2c08",
"z06n2c08",
"z09n2c08"
]

func test_reencode_wild_png(test_name:String, log:inout [String]) -> Bool
{
    let dest_path:String = "Tests/" + test_name + "_rewritten.png"
    let ref_path:String  = "Tests/" + test_name + ".rgba"
    var encode_passed:Bool = true
    do
    {
        let (png_data, png_properties):([UInt8], PNGProperties) = try decode_png(path: "Tests/" + test_name + ".png")
        try encode_png(path: dest_path, raw_data: png_data, properties: png_properties)
    }
    catch
    {
        log.append(String(describing: error))
        encode_passed = false
    }

    return encode_passed && normalize_and_compare(path_png: dest_path, path_rgba: ref_path, log: &log)
}

public
let tests:[(String, [String], TestFunc)] =
[
    ("decode", decode_test_cases, decode_test),
    ("decompose", ["decompose1"], test_decompose(test_name:log:)),
    ("reencode", ["taylor", "wildest dreams adam7", "if red got the grammy", "becky palatte"], test_reencode_wild_png)
]
