import PNG

func redness(_ c:PNG.RGBA<UInt8>) -> Int 
{
    // score ‘redness’ by formula: R^2 / (2G + B + 1)
    return .init(c.r) * .init(c.r) / (2 * .init(c.g) + .init(c.b) + 1)
}

func border(input inputPath:String, output outputPath:String) 
{
    guard let input:PNG.Data.Rectangular = try? .decompress(path: inputPath) 
    else 
    {
        print("failed to decode '\(inputPath)'")
        return 
    }
    
    // extract palette 
    let format:PNG.Properties.Format = input.properties.format, 
        palette:[PNG.RGBA<UInt8>]
    switch format 
    {
        case    .indexed1(let _palette), 
                .indexed2(let _palette), 
                .indexed4(let _palette), 
                .indexed8(let _palette):
            palette = _palette
        
        default:
            print("input image is not indexed (color format '\(format.code)')")
            return 
    }
    
    // sort palette entries by redness
    let reddest:[Int] = palette.indices.sorted 
    {        
        return redness(palette[$0]) < redness(palette[$1])
    }
    // select the 16 reddest colors in the palette 
    let borderColors:ArraySlice = reddest.suffix(16)
    
    let image:[Int] = input.map{ $0 }!
    
    let borderWidth:Int     = 16, 
        (x, y):(Int, Int)   = input.properties.size
    
    // new dimensions 
    let (xp, yp):(Int, Int) = (x + 2 * borderWidth, y + 2 * borderWidth)
    
    var output:[Int] = [] 
        output.reserveCapacity(xp * yp)
    
    guard !borderColors.isEmpty 
    else 
    {
        print("empty palette (corrupt PNG)")
        return 
    }
    
    // top border 
    for _ in 0 ..< xp * borderWidth 
    {
        output.append(borderColors.randomElement()!)
    }
    // left and right borders 
    for i:Int in 0 ..< y 
    {
        for _ in 0 ..< borderWidth 
        {
            output.append(borderColors.randomElement()!)
        }
        
        output.append(contentsOf: image[i * x ..< (i + 1) * x])
        
        for _ in 0 ..< borderWidth 
        {
            output.append(borderColors.randomElement()!)
        }
    }
    // bottom border 
    for _ in 0 ..< xp * borderWidth 
    {
        output.append(borderColors.randomElement()!)
    }
    
    guard let _:Void = 
        try? PNG.encode(indices: output, palette: palette, size: (xp, yp), 
                            as: format.code, path: outputPath)
    else 
    {
        print("failed to encode '\(outputPath)'")
        return 
    }
}
