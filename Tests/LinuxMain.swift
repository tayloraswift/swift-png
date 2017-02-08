@testable import MaxPNGTests

try skip_png("Tests/taylor.png")
try read_png("Tests/taylor.png")
let (png_header, png_scanlines) = try read_png_into_buffer("Tests/taylor.png")
try write_png("Tests/output.png", png_scanlines, header: png_header)
