import PNG

#if BUILD_EXAMPLES

func __examples() throws
{
    // Decode a PNG file to a type of your choice in just one function call.
    let (pixels, (x: width, y: height)) = try PNG.rgba(path: "example.png", of: UInt8.self)
}

#endif
