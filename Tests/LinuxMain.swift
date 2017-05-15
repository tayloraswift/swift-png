@testable import MaxPNGTests
@testable import MaxPNG
import Glibc

let interlace_test_ref:String = "interlace.rgba",
    interlace_test_in:String = "interlace.png",
    interlace_test_out:String = "deinterlace.png",
    image_test_ref:String = "taylor.rgba",
    image_test_in:String = "taylor.png",
    image_test_out:String = "taylor_reconverted.png"

var passed:Bool = true

//let data:[RGBA<UInt16>] = load_rgb_data(absolute_path: absolute_unix_path("Tests/MaxPNGTests/unit/basi0g04.rgba"), npixels: 32*32)
//print(data)

run_tests(test_cases: test_cases)

try decompose_png("Tests/" + interlace_test_in, output: "Tests/" + interlace_test_out)
try reencode_png_stream("Tests/" + image_test_in, output: "Tests/" + image_test_out)

try write_png("Tests/output.png", [[0, 0, 0, 255, 255, 255, 255, 0, 255], [255, 255, 255, 0, 0, 0, 0, 255, 0], [120, 120, 255, 150, 120, 255, 180, 120, 255]],
                header: PNGHeader(width: 3, height: 3, bit_depth: 8, color_type: .rgb, interlace: false))

print("Testing images \(image_test_ref) == \(image_test_out)")
if try test_decoded_identical(relative_path_png: "Tests/" + image_test_out, relative_path_rgba: "Tests/" + image_test_ref)
{
    print("images identical")
    passed = passed && true
}
else
{
    print("images not identical")
    passed = false
}

print("Testing images \(interlace_test_ref) == \(interlace_test_out)")
if try test_decoded_identical(relative_path_png: "Tests/" + interlace_test_out, relative_path_rgba: "Tests/" + interlace_test_ref)
{
    print("images identical")
    passed = passed && true
}
else
{
    print("images not identical")
    passed = false
}

exit(passed ? 0 : 1)
