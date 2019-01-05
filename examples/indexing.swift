import PNG

func nearest(to color:PNG.RGBA<UInt8>, in palette:[PNG.RGBA<UInt8>]) -> Int
{
    guard let (i, _):(Int, PNG.RGBA<UInt8>) = 
    (
        zip(palette.indices, palette).min 
        {
            let dr1:Int = .init($0.1.r) - .init(color.r), 
                dg1:Int = .init($0.1.g) - .init(color.g), 
                db1:Int = .init($0.1.b) - .init(color.b)
            let dr2:Int = .init($1.1.r) - .init(color.r), 
                dg2:Int = .init($1.1.g) - .init(color.g), 
                db2:Int = .init($1.1.b) - .init(color.b)
            
            let d1:Int = dr1 * dr1 + dg1 * dg1 + db1 * db1, 
                d2:Int = dr2 * dr2 + dg2 * dg2 + db2 * db2
            
            return d1 < d2
        }
    )
    else 
    {
        fatalError("empty palette")
    }
    
    return i
}

func indexing(input inputPath:String, output outputPath:String) 
{
    guard let (rgba, (x, y)):([PNG.RGBA<UInt8>], (x:Int, y:Int)) = 
        try? PNG.rgba(path: inputPath, of: UInt8.self) 
    else 
    {
        print("failed to decode '\(inputPath)'")
        return 
    }
    
    let palette:[PNG.RGBA<UInt8>] = 
    [
        .init(  0,   0,  45), 
        .init(  0,   0,  82), 
        .init(  0,   0, 135), 
        .init( 35,   0,  72),
        .init( 72,  18,  98), 
        .init(133,  63, 125), 
        .init(153,   0, 106), 
        .init(153,  16, 142), 
        .init(255,  46, 154), 
        
        .init(254,   1, 137),
        .init(250, 130, 147),
        .init(254, 157, 168),
        .init(255, 195, 198),
        .init(240, 227, 227)
    ]
    
    let indices:[Int] = rgba.map 
    {
        nearest(to: $0, in: palette)
    }
    
    guard let _:Void = 
        try? PNG.encode(indices: indices, palette: palette, size: (x, y), 
                            as: .indexed4, path: outputPath)
    else 
    {
        print("failed to encode '\(outputPath)'")
        return 
    }
}
