import MaxPNGTests
import MaxPNG

try process_png("Tests/taylor.png", output: "Tests/taylor_reconverted.png")
try write_png("Tests/output.png", [[0, 0, 0, 255, 255, 255, 255, 0, 255], [255, 255, 255, 0, 0, 0, 0, 255, 0], [120, 120, 255, 150, 120, 255, 180, 120, 255]], header: PNGImageHeader(width: 3, height: 3, bit_depth: 8, color_type: .rgb, interlace: false))
