import MaxPNGTests
import MaxPNG
import Glibc

let interlace_test_in:String = "interlace.png",
    interlace_test_out:String = "deinterlace.png",
    image_test_in:String = "taylor.png",
    image_test_out:String = "taylor_reconverted.png"

var passed:Bool = true

try decompose_png("Tests/" + interlace_test_in, output: "Tests/" + interlace_test_out)
try reencode_png_stream("Tests/" + image_test_in, output: "Tests/" + image_test_out)

try write_png("Tests/output.png", [[0, 0, 0, 255, 255, 255, 255, 0, 255], [255, 255, 255, 0, 0, 0, 0, 255, 0], [120, 120, 255, 150, 120, 255, 180, 120, 255]],
                header: PNGImageHeader(width: 3, height: 3, bit_depth: 8, color_type: .rgb, interlace: false))

print("Testing images \(image_test_in) == \(image_test_out)")
if try test_images_identical("Tests/" + image_test_in, "Tests/" + image_test_out)
{
    print("images identical")
    passed = passed && true
}
else
{
    print("images not identical")
    passed = false
}

print("Testing images \(interlace_test_in) == \(interlace_test_out)")
if try test_images_identical("Tests/" + interlace_test_in, "Tests/" + interlace_test_out)
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
