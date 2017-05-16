import Glibc
@testable import MaxPNG

func load_rgba_data<Pixel:UnsignedInteger>(posix_path:String, n_pixels:Int) -> [RGBA<Pixel>]
{
    guard let stream:FilePointer = fopen(posix_path, "rb")
    else
    {
        fatalError("Failed to read rgba file '\(posix_path)'")
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

func test_decoded_identical(relative_path_png:String, relative_path_rgba:String) -> Bool
{
    let (png_data, png_header):([UInt8], PNGHeader)
    do
    {
        (png_data, png_header) = try decode_png_contiguous(relative_path: relative_path_png)
    }
    catch
    {
        print("Error: \(error)")
        return false
    }

    guard let rgba_data_png:[RGBA<UInt16>] = png_header.rgba64(raw_data: png_data)
    else
    {
        return false
    }
    /*
    let rgba_data_png:[RGBA<UInt16>] = rgba_data_png_32.map
    {
        let r:UInt16 = UInt16($0.r),
            g:UInt16 = UInt16($0.g),
            b:UInt16 = UInt16($0.b),
            a:UInt16 = UInt16($0.a)
        //return RGBA(r, g, b, a)
        return RGBA(r << 8 | r, g << 8 | g, b << 8 | b, a << 8 | a)
    }
    */
    let rgba_data_rgba:[RGBA<UInt16>] = load_rgba_data(posix_path: posix_path(relative_path_rgba),
                                                       n_pixels: png_header.width * png_header.height)

    if rgba_data_rgba != rgba_data_png
    {
        print("RGBA(\(rgba_data_rgba.count)) : \(rgba_data_rgba[0...7])")
        print("PNG (\(rgba_data_png.count )) : \(rgba_data_png[0...7])")
    }

    return rgba_data_rgba == rgba_data_png
}

func run_tests(test_cases:[String])
{
    for (i, test_case) in test_cases.enumerated()
    {
        let path_png:String  = "Tests/MaxPNGTests/unit/png/\(test_case).png"
        let path_rgba:String = "Tests/MaxPNGTests/unit/rgba/\(test_case).png.rgba"
        if test_decoded_identical(relative_path_png: path_png, relative_path_rgba: path_rgba)
        {
            print("\(green_bold)(\(i)) test '\(test_case)' passed\(color_off)\n")
        }
        else
        {
            print("\(red_bold)(\(i)) test '\(test_case)' failed\(color_off)\n")
        }
    }
}

let test_cases:[String] =
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
