import PNG

func lerp(_ a:UInt16, _ b:UInt16, by t:UInt16) -> UInt16
{
    let a32:UInt32 = .init(a), 
        b32:UInt32 = .init(b)
    
    let f1:UInt32  = .init(UInt16.max - t) + 1, 
        f2:UInt32  = .init(             t)
    return .init((a32 * f1 + b32 * f2) >> UInt16.bitWidth)
}

func sepia(input inputPath:String, output outputPath:String) 
{
    guard let input:PNG.Data.Uncompressed = try? .decompress(path: inputPath) 
    else 
    {
        print("failed to decode '\(inputPath)'")
        return 
    }
    
    let rectangular:PNG.Data.Rectangular = input.deinterlaced()
    
    // make sure we’re using a grayscale png 
    let format:PNG.Properties.Format = rectangular.properties.format
    guard !format.code.hasColor
    else 
    {
        print("input image is not grayscale (color format '\(format.code)')")
        return 
    }
    
    // define the black- and white-stops of the color ramp
    let black:PNG.RGBA<UInt16> = .init(12000, 5000, 6000, .max), 
        white:PNG.RGBA<UInt16> = .init(.max, .max, .max, .max)
    
    let sepia:[PNG.RGBA<UInt16>] = rectangular.v(of: UInt16.self).map 
    {
        (value:UInt16) in 
        
        let r:UInt16 = lerp(black.r, white.r, by: value), 
            g:UInt16 = lerp(black.g, white.g, by: value), 
            b:UInt16 = lerp(black.b, white.b, by: value)
        return .init(r, g, b)
    }
    
    // preserve some of the ancillary chunks 
    let ancillaries:PNG.Data.Ancillaries = 
    (
        rectangular.ancillaries.unique.filter{ $0.key.safeToCopy }, 
        rectangular.ancillaries.repeatable.filter{ $0.0.safeToCopy } 
    )
    
    guard let output:PNG.Data.Uncompressed = 
        try? .convert(rgba: sepia, size: rectangular.properties.size, to: .rgb16, 
                ancillaries: ancillaries)
    else 
    {
        print("failed to convert '\(inputPath)'")
        return 
    }
    
    guard let _:Void = try? output.compress(path: outputPath, level: 8)
    else 
    {
        print("failed to encode '\(outputPath)'")
        return 
    }
}
