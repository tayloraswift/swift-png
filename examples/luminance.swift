import PNG

func luminance(input inputPath:String, output outputPath:String) 
{
    guard let (rgba, (x, y)):([PNG.RGBA<UInt8>], (x:Int, y:Int)) = 
        try? PNG.rgba(path: inputPath, of: UInt8.self) 
    else 
    {
        print("failed to decode '\(inputPath)'")
        return 
    }
    
    let v:[UInt8] = rgba.map 
    {
        (c:PNG.RGBA<UInt8>) in 
        
        // widen components to avoid overflow
        let r:UInt = .init(c.r), 
            g:UInt = .init(c.g), 
            b:UInt = .init(c.b)
        
        // use the luminance formula:
        // l = 1742/8192 R + 5859/8192 G + 591/8192 B
        return .init((r * 1742 + g * 5859 + b * 591) >> 13)
    }
    
    guard let _:Void = 
        try? PNG.encode(v: v, size: (x, y), as: .v8, path: outputPath)
    else 
    {
        print("failed to encode '\(outputPath)'")
        return 
    }
}
