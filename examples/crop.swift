import PNG

func crop(input inputPath:String, output outputPath:String) 
{
    guard let (rgba, (x, y)):([PNG.RGBA<UInt8>], (x:Int, y:Int)) = 
        try? PNG.rgba(path: inputPath, of: UInt8.self) 
    else 
    {
        print("failed to decode '\(inputPath)'")
        return 
    }
    
    // remove solid white borders
    let border:PNG.RGBA<UInt8> = .init(.max, .max, .max)
    
    var top:Int = 0 
    for i:Int in 0 ..< y 
    {
        guard (rgba[i * x ..< (i + 1) * x].allSatisfy{ $0 == border }) 
        else 
        {
            break 
        }
        
        top += 1
    }
    
    var bottom:Int = y 
    for i:Int in (0 ..< y).reversed()
    {
        guard (rgba[i * x ..< (i + 1) * x].allSatisfy{ $0 == border }) 
        else 
        {
            break 
        }
        
        bottom -= 1
    }
    
    var left:Int = 0 
    for j:Int in 0 ..< x 
    {
        guard ((0 ..< y).map{ rgba[$0 * x + j] }.allSatisfy{ $0 == border }) 
        else 
        {
            break 
        }
        
        left += 1
    }
    
    var right:Int = x 
    for j:Int in (0 ..< x).reversed()
    {
        guard ((0 ..< y).map{ rgba[$0 * x + j] }.allSatisfy{ $0 == border }) 
        else 
        {
            break 
        }
        
        right -= 1
    }
    
    guard   top  < bottom, 
            left < right 
    else 
    {
        print("image '\(inputPath)' is entirely borders")
        return 
    }
    
    let cropped:[PNG.RGBA<UInt8>] = (top ..< bottom).flatMap 
    {
        rgba[$0 * x + left ..< $0 * x + right]
    }
    
    guard let _:Void = 
        try? PNG.encode(  rgba: cropped, size: (right - left, bottom - top), 
                            as: .rgb8, path: outputPath)
    else 
    {
        print("failed to encode '\(outputPath)'")
        return 
    }
}
