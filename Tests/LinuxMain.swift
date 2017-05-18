import MaxPNGTests
import MaxPNG
import Glibc

var arguments:[String] = CommandLine.arguments
let _:String = arguments.removeFirst()
var verbose:Bool = false
var test_subset:Set<String> = []

for arg in arguments
{
    if arg == "-v" || arg == "-verbose" || arg == "--verbose"
    {
        verbose = true
    }
    else
    {
        test_subset.insert(arg)
    }
}

try encode_png(path: "Tests/output.png",
               raw_data: [0, 0, 0, 255, 255, 255, 255, 0, 255,
                          255, 255, 255, 0, 0, 0, 0, 255, 0,
                          120, 120, 255, 150, 120, 255, 180, 120, 255],
               properties: PNGProperties(width: 3, height: 3, bit_depth: 8, color: .rgb, interlaced: false)!)

run_tests(tests, verbose: verbose, only_run: test_subset.isEmpty ? nil : test_subset)

exit(0)
