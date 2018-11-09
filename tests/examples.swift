import PNG

#if BUILD_EXAMPLES

func __examples() throws
{
    // Decode a PNG file to a type of your choice in just one function call.
    let (pixels, (x: width, y: height)) = try PNG.rgba(path: "example.png", of: UInt8.self)

    pixels.withUnsafeBufferPointerToComponents
    {
        let properties:PNG.Properties = .init(size: (width, height),
                                            format: .rgba8,
                                        interlaced: false)
        PNG.Uncompressed(data: pixels, properties: properties)?.compress(path: "example-out.png")
    }
}

#endif
