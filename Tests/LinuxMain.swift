@testable import MaxPNGTests
@testable import MaxPNG
import Glibc

try encode_png(path: "Tests/output.png",
               raw_data: [0, 0, 0, 255, 255, 255, 255, 0, 255,
                          255, 255, 255, 0, 0, 0, 0, 255, 0,
                          120, 120, 255, 150, 120, 255, 180, 120, 255],
               properties: PNGProperties(width: 3, height: 3, bit_depth: 8, color: .rgb, interlaced: false)!)

run_tests(tests)

exit(0)
